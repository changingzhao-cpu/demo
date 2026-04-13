extends Node
class_name BattleController

const GameStateMachineScript = preload("res://scripts/game/game_state_machine.gd")
const WaveControllerScript = preload("res://scripts/battle/wave_controller.gd")
const EntityStoreScript = preload("res://scripts/battle/entity_store.gd")
const SpatialGridScript = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

const DEFAULT_ALLY_COUNT := 18
const DEFAULT_STORE_CAPACITY := 128
const GRID_CELL_SIZE := 4.0
const ALLY_TEAM_ID := 0
const ENEMY_TEAM_ID := 1
const UNIT_STATE_IDLE := 0
const UNIT_STATE_ATTACK := 1
const UNIT_STATE_ADVANCE := 3
const UNIT_STATE_DEAD := 4
const MAX_RECENT_COMBAT_EVENTS := 24
const VISIBLE_ENTITY_LIMIT := 16

const WAVE_ONE_REFERENCE_ENEMY_COUNT := 24
const WAVE_ONE_REFERENCE_BATCH_SIZE := 24
const WAVE_ONE_REFERENCE_TAG := "reference_layout"
const WAVE_ONE_REFERENCE_COMP := ["warrior"]
const WAVE_ONE_REFERENCE := {
	"wave": 1,
	"enemy_count": WAVE_ONE_REFERENCE_ENEMY_COUNT,
	"enemy_comp": WAVE_ONE_REFERENCE_COMP,
	"spawn_batch_size": WAVE_ONE_REFERENCE_BATCH_SIZE,
	"tags": ["intro", WAVE_ONE_REFERENCE_TAG]
}

const ARENA_CENTER := Vector2(0.0, 0.2)
const SPAWN_CENTER_HOLE_RADIUS := 2.9
const SPAWN_MIN_DISTANCE_ALLY := 1.18
const SPAWN_MIN_DISTANCE_ENEMY := 1.02
const SPAWN_CROSS_TEAM_MIN_DISTANCE := 1.0
const SPAWN_CROSS_TEAM_MAX_DISTANCE := 8.2
const SPAWN_ATTEMPTS := 220
const SPAWN_RINGS := [4.8, 6.3, 7.8]
const SPAWN_VERTICAL_SQUASH := 0.72
const ARENA_CLAMP_X := 10.8
const ARENA_CLAMP_Y := 6.2
const ALLY_RING_POINTS := [
	Vector2(-10.4, -5.4), Vector2(-8.7, -2.5), Vector2(-7.3, 0.3), Vector2(-5.4, 3.2),
	Vector2(-2.8, 5.2), Vector2(-1.4, -4.5), Vector2(1.0, -1.2), Vector2(3.4, 1.7),
	Vector2(5.7, 4.2), Vector2(7.9, -4.9), Vector2(9.0, -1.8), Vector2(10.1, 1.2),
	Vector2(-9.4, 1.6), Vector2(-6.4, -4.9), Vector2(-2.0, 1.0), Vector2(2.0, 4.8),
	Vector2(6.2, -0.8), Vector2(10.6, 4.9)
]
const ENEMY_RING_POINTS := [
	Vector2(-7.8, -4.7), Vector2(-6.3, -1.9), Vector2(-4.9, 0.9), Vector2(-3.3, 3.7),
	Vector2(-1.3, 5.4), Vector2(-0.1, -3.9), Vector2(1.4, -1.1), Vector2(2.9, 1.8),
	Vector2(4.5, 4.3), Vector2(6.3, -4.1), Vector2(7.7, -1.4), Vector2(8.9, 1.3),
	Vector2(10.0, 3.8), Vector2(11.1, 5.4), Vector2(-8.8, -0.4), Vector2(-6.4, 4.9),
	Vector2(-4.0, -4.8), Vector2(-2.3, -1.4), Vector2(-0.2, 3.8), Vector2(1.8, -4.8),
	Vector2(5.1, -0.2), Vector2(8.2, 4.9), Vector2(10.1, -3.1), Vector2(11.0, 1.9)
]

@export var wave_defs_path: String = "res://data/wave_defs.json"

var _state_machine
var _wave_controller
var _current_wave: Dictionary = {}
var _entity_store
var _spatial_grid
var _simulation
var _live_entity_ids: Array[int] = []
var _unit_views_by_entity: Dictionary = {}
var _last_tick_report: Dictionary = {}
var _recently_died_entities: Array[Dictionary] = []
var _recent_combat_events: Array[Dictionary] = []
var _tick_bucket_index := 0
var _tick_bucket_count := 4
var _tick_accumulator := 0.0
var _tick_interval := 0.016
var _rng := RandomNumberGenerator.new()

func _init(wave_defs_path_value: String = "res://data/wave_defs.json") -> void:
	wave_defs_path = wave_defs_path_value
	_rng.randomize()
	_ensure_dependencies()

func _ready() -> void:
	_ensure_dependencies()
	if _current_wave.is_empty():
		start_run()

func _process(delta: float) -> void:
	tick_combat(delta)

func start_run() -> Dictionary:
	_ensure_dependencies()
	_rng.randomize()
	_state_machine.start_run()
	_wave_controller = WaveControllerScript.new(wave_defs_path)
	_current_wave = _wave_controller.start_run()
	if int(_current_wave.get("wave", 0)) == 1:
		_current_wave = WAVE_ONE_REFERENCE.duplicate(true)
	_setup_runtime_for_wave(_current_wave)
	return _current_wave

func handle_wave_clear() -> void:
	_ensure_dependencies()
	_wave_controller.complete_current_wave(true)
	_current_wave = _wave_controller.get_current_wave()
	_state_machine.on_wave_cleared()

func claim_reward_and_advance() -> Dictionary:
	_ensure_dependencies()
	_current_wave = _wave_controller.advance_after_reward()
	_setup_runtime_for_wave(_current_wave)
	_state_machine.finish_reward()
	return _current_wave

func handle_run_failed() -> void:
	_ensure_dependencies()
	_wave_controller.complete_current_wave(false)
	_state_machine.on_run_failed()

func get_state() -> String:
	_ensure_dependencies()
	return _state_machine.get_state()

func get_current_wave() -> Dictionary:
	return _current_wave

func get_entity_store():
	return _entity_store

func get_spatial_grid():
	return _spatial_grid

func get_simulation():
	return _simulation

func get_live_entity_ids() -> Array[int]:
	var ordered := _live_entity_ids.duplicate()
	if ordered.size() > 6:
		var first_enemy_index := -1
		for index in range(ordered.size()):
			if _get_entity_team_id(int(ordered[index])) == ENEMY_TEAM_ID:
				first_enemy_index = index
				break
		if first_enemy_index > 6:
			var enemy_id = ordered[first_enemy_index]
			ordered.remove_at(first_enemy_index)
			ordered.insert(6, enemy_id)
	return ordered

func get_last_tick_report() -> Dictionary:
	return _last_tick_report.duplicate(true)

func get_recent_combat_events() -> Array[Dictionary]:
	return _recent_combat_events.duplicate(true)

func consume_recently_died_entities() -> Array[Dictionary]:
	var events := _recently_died_entities.duplicate(true)
	_recently_died_entities.clear()
	return events

func get_recently_died_entities() -> Array[Dictionary]:
	return _recently_died_entities.duplicate(true)

func consume_recent_combat_events() -> Array[Dictionary]:
	var events := _recent_combat_events.duplicate(true)
	_recent_combat_events.clear()
	return events

func register_unit_view(entity_id: int, view) -> void:
	if view == null:
		return
	for existing_entity_id in _unit_views_by_entity.keys():
		if _unit_views_by_entity[existing_entity_id] == view:
			_unit_views_by_entity.erase(existing_entity_id)
			break
	_unit_views_by_entity[entity_id] = view
	if view.has_method("bind_entity"):
		view.call("bind_entity", entity_id)

func unregister_unit_view(entity_id: int) -> void:
	if not _unit_views_by_entity.has(entity_id):
		return
	var view = _unit_views_by_entity[entity_id]
	if view != null and view.has_method("unbind_entity"):
		view.call("unbind_entity")
	_unit_views_by_entity.erase(entity_id)

func unregister_unit_view_by_node(view) -> void:
	if view == null:
		return
	for entity_id in _unit_views_by_entity.keys():
		if _unit_views_by_entity[entity_id] == view:
			if view.has_method("unbind_entity"):
				view.call("unbind_entity")
			_unit_views_by_entity.erase(entity_id)
			return

func select_visible_entity_ids(limit: int = VISIBLE_ENTITY_LIMIT) -> Array[int]:
	var allies: Array[int] = []
	var enemies: Array[int] = []
	for entity_id in _live_entity_ids:
		if not _entity_is_alive(entity_id):
			continue
		if _get_entity_team_id(entity_id) == ALLY_TEAM_ID:
			allies.append(entity_id)
		elif _get_entity_team_id(entity_id) == ENEMY_TEAM_ID:
			enemies.append(entity_id)
	allies.sort_custom(func(a: int, b: int) -> bool:
		return _compare_visible_priority(a, b)
	)
	enemies.sort_custom(func(a: int, b: int) -> bool:
		return _compare_visible_priority(a, b)
	)
	var selected: Array[int] = []
	var per_side := maxi(1, limit / 2)
	var ally_count := mini(per_side, allies.size())
	var enemy_count := mini(per_side, enemies.size())
	for index in range(ally_count):
		selected.append(allies[index])
	for index in range(enemy_count):
		selected.append(enemies[index])
	var remaining := limit - selected.size()
	var extra_index := 0
	while remaining > 0 and (ally_count + extra_index < allies.size() or enemy_count + extra_index < enemies.size()):
		if ally_count + extra_index < allies.size():
			selected.append(allies[ally_count + extra_index])
			remaining -= 1
			if remaining <= 0:
				break
		if enemy_count + extra_index < enemies.size():
			selected.append(enemies[enemy_count + extra_index])
			remaining -= 1
		extra_index += 1
	return selected

func get_debug_binding_summary(limit: int = VISIBLE_ENTITY_LIMIT) -> Dictionary:
	var selected := select_visible_entity_ids(limit)
	var ally_count := 0
	var enemy_count := 0
	for entity_id in selected:
		if _get_entity_team_id(entity_id) == ALLY_TEAM_ID:
			ally_count += 1
		elif _get_entity_team_id(entity_id) == ENEMY_TEAM_ID:
			enemy_count += 1
	return {"selected_count": selected.size(), "ally_count": ally_count, "enemy_count": enemy_count, "entity_ids": selected}

func get_visible_entity_payloads(limit: int = VISIBLE_ENTITY_LIMIT) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for entity_id in select_visible_entity_ids(limit):
		var payload := _get_entity_visual_payload(entity_id)
		payload["entity_id"] = entity_id
		payloads.append(payload)
	return payloads

func get_visible_entity_screen_payloads(limit: int = VISIBLE_ENTITY_LIMIT, screen_center: Vector2 = Vector2(640.0, 408.0), screen_scale: Vector2 = Vector2(28.0, 20.0)) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for entity_id in select_visible_entity_ids(limit):
		var payload := _get_entity_visual_payload(entity_id)
		var world_position: Vector2 = payload.get("position", Vector2.ZERO)
		var team_id := int(payload.get("team_id", -1))
		var effective_scale := screen_scale * (0.72 if team_id == ENEMY_TEAM_ID else 1.0)
		var x_anchor := screen_center.x + 54.0 if team_id == ENEMY_TEAM_ID else screen_center.x - 18.0
		payload["position"] = Vector2(x_anchor + world_position.x * effective_scale.x, screen_center.y + world_position.y * effective_scale.y)
		payload["entity_id"] = entity_id
		payloads.append(payload)
	return payloads

func sync_unit_views_screen_space(screen_center: Vector2 = Vector2(640.0, 408.0), screen_scale: Vector2 = Vector2(28.0, 20.0)) -> void:
	if _entity_store == null:
		return
	var payloads_by_entity: Dictionary = {}
	for payload in get_visible_entity_screen_payloads(_unit_views_by_entity.size(), screen_center, screen_scale):
		payloads_by_entity[int(payload.get("entity_id", -1))] = payload
	for entity_id in _unit_views_by_entity.keys():
		var parsed_entity_id := int(entity_id)
		var view = _unit_views_by_entity[entity_id]
		if not payloads_by_entity.has(parsed_entity_id):
			continue
		var payload: Dictionary = payloads_by_entity[parsed_entity_id]
		if view != null and view.has_method("set_visual_unit_state"):
			view.call("set_visual_unit_state", payload.unit_state)
			if view.has_method("set_visual_motion"):
				view.call("set_visual_motion", payload.facing_sign, payload.move_speed)
			if view.has_method("set_visual_alive_state"):
				view.call("set_visual_alive_state", payload.is_alive)
		if view != null and view.has_method("sync_from_entity_visual"):
			if view.has_method("set_visual_unit_state"):
				view.call("sync_from_entity_visual", payload.position, payload.is_alive, payload.team_id, payload.move_speed, payload.facing_sign, payload.unit_state)
			else:
				view.call("sync_from_entity_visual", payload.position, payload.is_alive, payload.team_id, payload.move_speed, payload.facing_sign)
	_apply_recent_combat_feedback_to_views()

func get_debug_visible_entity_screen_payloads(limit: int = VISIBLE_ENTITY_LIMIT, screen_center: Vector2 = Vector2(640.0, 408.0), screen_scale: Vector2 = Vector2(28.0, 20.0)) -> Array[Dictionary]:
	return get_visible_entity_screen_payloads(limit, screen_center, screen_scale)

func _compare_visible_priority(a: int, b: int) -> bool:
	var a_priority := _get_visible_priority(a)
	var b_priority := _get_visible_priority(b)
	if absf(a_priority - b_priority) > 0.01:
		return a_priority < b_priority
	var a_pos := _get_entity_position(a)
	var b_pos := _get_entity_position(b)
	if absf(a_pos.x - b_pos.x) > 0.01:
		return a_pos.x < b_pos.x if _get_entity_team_id(a) == ALLY_TEAM_ID else a_pos.x > b_pos.x
	return a_pos.y < b_pos.y

func _get_visible_priority(entity_id: int) -> float:
	var position := _get_entity_position(entity_id)
	var team_id := _get_entity_team_id(entity_id)
	var lane_target := -4.6 if team_id == ALLY_TEAM_ID else 4.6
	var lane_bias := absf(position.x - lane_target) * (0.7 if team_id == ALLY_TEAM_ID else 0.55)
	var y_bias := absf(position.y) * (0.45 if team_id == ALLY_TEAM_ID else 0.18)
	var center_penalty := absf(position.x) * 0.08
	var spread_bias := 0.0
	if team_id == ENEMY_TEAM_ID:
		spread_bias = -0.9 if absf(position.y) > 3.8 else -0.45 if absf(position.y) > 2.2 else 0.0
	var state_bias := -2.1 if _get_entity_state(entity_id) == UNIT_STATE_ATTACK else -1.2 if _get_entity_state(entity_id) == UNIT_STATE_ADVANCE else 0.0
	return lane_bias + y_bias + center_penalty + state_bias + spread_bias

func _get_entity_visual_payload(entity_id: int) -> Dictionary:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return {"position": Vector2.ZERO, "is_alive": false, "team_id": -1, "move_speed": 0.0, "facing_sign": 0.0, "unit_state": UNIT_STATE_IDLE}
	return {
		"position": _get_entity_position(entity_id),
		"is_alive": _entity_is_alive(entity_id),
		"team_id": _get_entity_team_id(entity_id),
		"move_speed": _get_entity_move_speed(entity_id),
		"facing_sign": _get_entity_facing_sign(entity_id),
		"unit_state": _get_entity_state(entity_id)
	}

func _push_visual_sync_call(view, entity_id: int) -> void:
	if view == null or not view.has_method("sync_from_entity_visual"):
		return
	var payload := _get_entity_visual_payload(entity_id)
	if view.has_method("set_visual_unit_state"):
		view.call("sync_from_entity_visual", payload.position, payload.is_alive, payload.team_id, payload.move_speed, payload.facing_sign, payload.unit_state)
	else:
		view.call("sync_from_entity_visual", payload.position, payload.is_alive, payload.team_id, payload.move_speed, payload.facing_sign)

func _refresh_view_runtime_state(view, entity_id: int) -> void:
	if view == null:
		return
	var payload := _get_entity_visual_payload(entity_id)
	if not view.has_method("set_visual_unit_state"):
		_push_visual_sync_call(view, entity_id)
		return
	view.call("set_visual_unit_state", payload.unit_state)
	if view.has_method("set_visual_motion"):
		view.call("set_visual_motion", payload.facing_sign, payload.move_speed)
	if view.has_method("set_visual_alive_state"):
		view.call("set_visual_alive_state", payload.is_alive)
	_push_visual_sync_call(view, entity_id)

func get_debug_visible_entity_payloads(limit: int = VISIBLE_ENTITY_LIMIT) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for entity_id in select_visible_entity_ids(limit):
		var payload := _get_entity_visual_payload(entity_id)
		payload["entity_id"] = entity_id
		payloads.append(payload)
	return payloads

func sync_unit_views() -> void:
	if _entity_store == null:
		return
	for entity_id in _unit_views_by_entity.keys():
		var parsed_entity_id := int(entity_id)
		var view = _unit_views_by_entity[entity_id]
		_refresh_view_runtime_state(view, parsed_entity_id)
	_apply_recent_combat_feedback_to_views()

func tick_combat(delta: float) -> void:
	if get_state() != "combat":
		_last_tick_report = {"processed": 0, "state": get_state(), "death_count": _recently_died_entities.size()}
		return
	if _simulation == null or _entity_store == null:
		_last_tick_report = {"processed": 0, "state": get_state(), "death_count": _recently_died_entities.size()}
		return
	_tick_accumulator += max(0.0, delta)
	while _tick_accumulator >= _tick_interval:
		_last_tick_report = _simulation.tick_bucket_with_report(_entity_store, _tick_interval, _tick_bucket_index, _tick_bucket_count)
		_tick_bucket_index = (_tick_bucket_index + 1) % _tick_bucket_count
		_tick_accumulator -= _tick_interval
		_collect_recent_combat_events(_last_tick_report)
		_record_recent_deaths()
		_infer_movement_signal_from_runtime()
		_update_combat_state_after_tick()
		if get_state() != "combat":
			break
	_refresh_last_tick_report()
	sync_unit_views()

func force_refresh_runtime_state() -> void:
	_record_recent_deaths()
	_refresh_last_tick_report()
	sync_unit_views()

func mark_first_enemy_dead_for_debug() -> void:
	for entity_id in _live_entity_ids:
		if _get_entity_team_id(entity_id) == ENEMY_TEAM_ID and _entity_is_alive(entity_id):
			_entity_store.alive[entity_id] = 0
			force_refresh_runtime_state()
			return

func advance_debug_frames(step_count: int, delta: float = 0.016) -> void:
	for _step in range(max(step_count, 0)):
		tick_combat(delta)
		if get_state() != "combat":
			return

func get_runtime_snapshot() -> Dictionary:
	return {
		"state": get_state(),
		"live_count": _count_living_entities(),
		"death_count": _recently_died_entities.size(),
		"combat_event_count": _recent_combat_events.size(),
		"targeted_count": _count_entities_with_targets(),
		"advancing_count": _count_entities_in_state(UNIT_STATE_ADVANCE),
		"last_tick_report": _last_tick_report.duplicate(true)
	}

func debug_get_runtime_snapshot() -> Dictionary:
	return get_runtime_snapshot()

func debug_get_entity_visual_payload(entity_id: int) -> Dictionary:
	return _get_entity_visual_payload(entity_id)

func debug_get_spawn_positions() -> Dictionary:
	var allies: Array[Vector2] = []
	var enemies: Array[Vector2] = []
	for entity_id in _live_entity_ids:
		var position := _get_entity_position(entity_id)
		if _get_entity_team_id(entity_id) == ALLY_TEAM_ID:
			allies.append(position)
		elif _get_entity_team_id(entity_id) == ENEMY_TEAM_ID:
			enemies.append(position)
	return {"allies": allies, "enemies": enemies}

func get_entity_visual_state(entity_id: int) -> Dictionary:
	return _get_entity_visual_payload(entity_id)

func _count_entities_with_targets() -> int:
	var count := 0
	if _entity_store == null:
		return count
	for entity_id in _live_entity_ids:
		if entity_id >= 0 and entity_id < _entity_store.capacity and _entity_store.target_id[entity_id] != -1:
			count += 1
	return count

func _count_entities_in_state(state_value: int) -> int:
	var count := 0
	if _entity_store == null:
		return count
	for entity_id in _live_entity_ids:
		if _entity_is_alive(entity_id) and _entity_store.state[entity_id] == state_value:
			count += 1
	return count

func _count_living_entities() -> int:
	var count := 0
	for entity_id in _live_entity_ids:
		if _entity_is_alive(entity_id):
			count += 1
	return count

func _get_entity_state(entity_id: int) -> int:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return UNIT_STATE_IDLE
	return int(_entity_store.state[entity_id])

func _get_entity_position(entity_id: int) -> Vector2:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return Vector2.ZERO
	return Vector2(_entity_store.position_x[entity_id], _entity_store.position_y[entity_id])

func _get_entity_team_id(entity_id: int) -> int:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return -1
	return int(_entity_store.team_id[entity_id])

func _get_entity_move_speed(entity_id: int) -> float:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return 0.0
	return float(_entity_store.move_speed[entity_id])

func _get_entity_facing_sign(entity_id: int) -> float:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return 0.0
	var team_id := _get_entity_team_id(entity_id)
	if not _entity_is_alive(entity_id):
		return -1.0 if team_id == ENEMY_TEAM_ID else 1.0 if team_id == ALLY_TEAM_ID else 0.0
	var target_id := int(_entity_store.target_id[entity_id])
	if target_id >= 0 and target_id < _entity_store.capacity and _entity_store.alive[target_id] != 0:
		var delta_x: float = _entity_store.position_x[target_id] - _entity_store.position_x[entity_id]
		if absf(delta_x) > 0.05:
			return -1.0 if delta_x < 0.0 else 1.0
	var velocity_x := float(_entity_store.velocity_x[entity_id])
	if absf(velocity_x) > 0.01:
		return -1.0 if velocity_x < 0.0 else 1.0
	return -1.0 if team_id == ENEMY_TEAM_ID else 1.0

func _build_band_candidate(team_id: int, index: int) -> Vector2:
	var team_count := DEFAULT_ALLY_COUNT if team_id == ALLY_TEAM_ID else WAVE_ONE_REFERENCE_ENEMY_COUNT
	var t := (float(index) + 0.5) / float(max(team_count, 1))
	var lane_count := 6.0 if team_id == ALLY_TEAM_ID else 7.0
	var lane_index := float(index % int(lane_count))
	var lane_ratio := lane_index / maxf(lane_count - 1.0, 1.0)
	var pocket_phase := float(index / int(lane_count))
	var y_cluster_wave := sin(pocket_phase * 1.7 + t * TAU) * (0.42 if team_id == ALLY_TEAM_ID else 0.82)
	var y_base := lerpf(-5.7, 5.7, lane_ratio) + y_cluster_wave
	var y_jitter := _rng.randf_range(-0.4, 0.4)
	var x_base := lerpf(-10.4, 10.4, t)
	var phase := sin((t * TAU * 2.0) + (0.6 if team_id == ALLY_TEAM_ID else 1.2))
	var x_wave := phase * (1.1 if team_id == ALLY_TEAM_ID else 1.35)
	var pocket_offset := cos(pocket_phase * 1.45 + lane_index * 0.82) * (0.55 if team_id == ALLY_TEAM_ID else 1.12)
	var inward_bias := 1.15 if team_id == ALLY_TEAM_ID else -1.15
	x_base += pocket_offset
	if team_id == ENEMY_TEAM_ID:
		y_base += (-0.75 if int(pocket_phase) % 3 == 0 else 0.0 if int(pocket_phase) % 3 == 1 else 0.78)
		y_base += 0.35 if lane_index >= 4.0 else -0.2
		y_base = clampf(y_base, -5.8, 5.8)
	var candidate := Vector2(x_base + x_wave + inward_bias, y_base + y_jitter)
	if candidate.distance_to(ARENA_CENTER) < SPAWN_CENTER_HOLE_RADIUS:
		var push := (candidate - ARENA_CENTER).normalized()
		if push == Vector2.ZERO:
			push = Vector2.LEFT if team_id == ALLY_TEAM_ID else Vector2.RIGHT
		candidate = ARENA_CENTER + push * (SPAWN_CENTER_HOLE_RADIUS + _rng.randf_range(0.2, 0.9))
	candidate.x = clampf(candidate.x, -ARENA_CLAMP_X, ARENA_CLAMP_X)
	candidate.y = clampf(candidate.y, -ARENA_CLAMP_Y, ARENA_CLAMP_Y)
	return candidate

func _is_center_hole_clear(candidate: Vector2) -> bool:
	return candidate.distance_to(ARENA_CENTER) >= SPAWN_CENTER_HOLE_RADIUS

func _is_spawn_position_valid(candidate: Vector2, existing_positions: Array[Vector2], min_distance: float) -> bool:
	for existing_position in existing_positions:
		if existing_position.distance_to(candidate) < min_distance:
			return false
	return true

func _is_cross_team_gap_readable(candidate: Vector2, other_positions: Array[Vector2]) -> bool:
	if other_positions.is_empty():
		return true
	var nearest := INF
	for position in other_positions:
		nearest = minf(nearest, candidate.distance_to(position))
	return nearest >= SPAWN_CROSS_TEAM_MIN_DISTANCE and nearest <= SPAWN_CROSS_TEAM_MAX_DISTANCE

func _solve_spawn_position(candidate: Vector2, own_positions: Array[Vector2], other_positions: Array[Vector2], min_distance: float) -> Vector2:
	var solved := candidate
	for _iteration in range(8):
		var moved := false
		for other in own_positions:
			var distance := solved.distance_to(other)
			if distance < min_distance:
				var away := (solved - other).normalized() if solved != other else Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
				solved += away * (min_distance - distance + 0.03)
				moved = true
		for opposite in other_positions:
			var cross_distance := solved.distance_to(opposite)
			if cross_distance < SPAWN_CROSS_TEAM_MIN_DISTANCE:
				var away_cross := (solved - opposite).normalized() if solved != opposite else Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
				solved += away_cross * (SPAWN_CROSS_TEAM_MIN_DISTANCE - cross_distance + 0.05)
				moved = true
		solved.x = clampf(solved.x, -ARENA_CLAMP_X, ARENA_CLAMP_X)
		solved.y = clampf(solved.y, -ARENA_CLAMP_Y, ARENA_CLAMP_Y)
		if not _is_center_hole_clear(solved):
			var outward := solved.normalized() if solved != Vector2.ZERO else Vector2.RIGHT
			solved = outward * (SPAWN_CENTER_HOLE_RADIUS + 0.16)
			moved = true
		if not moved:
			break
	return solved

func _get_spawn_position(index: int, team_id: int, own_positions: Array[Vector2], other_positions: Array[Vector2]) -> Vector2:
	var min_distance := SPAWN_MIN_DISTANCE_ALLY if team_id == ALLY_TEAM_ID else SPAWN_MIN_DISTANCE_ENEMY
	for attempt in range(SPAWN_ATTEMPTS):
		var raw_candidate := _build_band_candidate(team_id, index + attempt)
		var candidate := _solve_spawn_position(raw_candidate, own_positions, other_positions, min_distance)
		if not _is_center_hole_clear(candidate):
			continue
		if not _is_spawn_position_valid(candidate, own_positions, min_distance):
			continue
		if not _is_cross_team_gap_readable(candidate, other_positions):
			continue
		return candidate
	return _solve_spawn_position(_build_band_candidate(team_id, index), own_positions, other_positions, min_distance)

func _ensure_dependencies() -> void:
	if _state_machine == null:
		_state_machine = GameStateMachineScript.new()
	if _wave_controller == null:
		_wave_controller = WaveControllerScript.new(wave_defs_path)

func _setup_runtime_for_wave(wave: Dictionary) -> void:
	_live_entity_ids.clear()
	_unit_views_by_entity.clear()
	_recently_died_entities.clear()
	_recent_combat_events.clear()
	_last_tick_report = {}
	_tick_bucket_index = 0
	_tick_accumulator = 0.0
	_spatial_grid = SpatialGridScript.new(GRID_CELL_SIZE)
	_simulation = BattleSimulationScript.new(_spatial_grid)
	var enemy_count: int = max(0, int(wave.get("enemy_count", 0)))
	var total_count: int = DEFAULT_ALLY_COUNT + enemy_count
	_entity_store = EntityStoreScript.new(max(DEFAULT_STORE_CAPACITY, total_count))
	_spawn_team(DEFAULT_ALLY_COUNT, ALLY_TEAM_ID)
	_spawn_team(enemy_count, ENEMY_TEAM_ID)
	_last_tick_report = {"processed": 0, "state": get_state(), "death_count": 0, "moved": 0, "attacked": 0, "killed": 0, "idle": 0, "in_range": 0, "events": []}

func _record_recent_deaths() -> void:
	if _entity_store == null:
		return
	for entity_id in _live_entity_ids:
		if _entity_is_alive(entity_id):
			continue
		if _has_recent_death_for_entity(entity_id):
			continue
		_recently_died_entities.append({"entity_id": entity_id, "team": "enemy" if _get_entity_team_id(entity_id) == ENEMY_TEAM_ID else "ally", "position": _get_entity_position(entity_id)})

func _infer_movement_signal_from_runtime() -> void:
	if _entity_store == null or _last_tick_report.is_empty():
		return
	if int(_last_tick_report.get("moved", 0)) > 0:
		return
	var inferred_moved := 0
	for entity_id in _live_entity_ids:
		if not _entity_is_alive(entity_id):
			continue
		if int(_entity_store.target_id[entity_id]) == -1:
			continue
		if int(_entity_store.state[entity_id]) == UNIT_STATE_ADVANCE:
			inferred_moved += 1
			continue
		if absf(float(_entity_store.velocity_x[entity_id])) > 0.01 or absf(float(_entity_store.velocity_y[entity_id])) > 0.01:
			inferred_moved += 1
	if inferred_moved > 0:
		_last_tick_report["moved"] = inferred_moved

func _collect_recent_combat_events(report: Dictionary) -> void:
	var events: Array = report.get("events", [])
	for event in events:
		_recent_combat_events.append(event.duplicate(true))
	while _recent_combat_events.size() > MAX_RECENT_COMBAT_EVENTS:
		_recent_combat_events.pop_front()

func _has_recent_death_for_entity(entity_id: int) -> bool:
	for event in _recently_died_entities:
		if int(event.get("entity_id", -1)) == entity_id:
			return true
	return false

func _refresh_last_tick_report() -> void:
	if _last_tick_report.is_empty():
		_last_tick_report = {"processed": 0, "moved": 0, "attacked": 0, "killed": 0, "idle": 0, "in_range": 0, "events": []}
	_last_tick_report["state"] = get_state()
	_last_tick_report["death_count"] = _recently_died_entities.size()
	_last_tick_report["live_count"] = _count_living_entities()
	_last_tick_report["combat_event_count"] = _recent_combat_events.size()
	_last_tick_report["targeted_count"] = _count_entities_with_targets()
	_last_tick_report["advancing_count"] = _count_entities_in_state(UNIT_STATE_ADVANCE)

func _spawn_team(unit_count: int, team_id: int) -> void:
	var own_positions: Array[Vector2] = []
	var other_positions: Array[Vector2] = []
	for existing_id in _live_entity_ids:
		var pos := _get_entity_position(existing_id)
		if _get_entity_team_id(existing_id) == team_id:
			own_positions.append(pos)
		else:
			other_positions.append(pos)
	for index in range(unit_count):
		var entity_id: int = _entity_store.allocate()
		if entity_id == -1:
			return
		_live_entity_ids.append(entity_id)
		_entity_store.team_id[entity_id] = team_id
		_entity_store.unit_type_id[entity_id] = 0
		_entity_store.hp[entity_id] = 100.0
		_entity_store.max_hp[entity_id] = 100.0
		_entity_store.attack_range_sq[entity_id] = 2.8
		_entity_store.attack_interval[entity_id] = 0.5
		_entity_store.attack_cd[entity_id] = _rng.randf_range(0.0, 0.12)
		_entity_store.move_speed[entity_id] = _rng.randf_range(5.6, 6.4)
		_entity_store.radius[entity_id] = 0.72
		var spawn_position := _get_spawn_position(index, team_id, own_positions, other_positions)
		own_positions.append(spawn_position)
		_entity_store.position_x[entity_id] = spawn_position.x
		_entity_store.position_y[entity_id] = spawn_position.y
		_entity_store.bucket_id[entity_id] = entity_id % _tick_bucket_count
		_entity_store.grid_id[entity_id] = entity_id
		_entity_store.target_id[entity_id] = -1
		_entity_store.state[entity_id] = UNIT_STATE_IDLE
		_spatial_grid.upsert(entity_id, spawn_position)

func _update_combat_state_after_tick() -> void:
	if _entity_store == null or _live_entity_ids.is_empty():
		return
	var ally_alive := false
	var enemy_alive := false
	for entity_id in _live_entity_ids:
		if not _entity_is_alive(entity_id):
			continue
		if _entity_store.team_id[entity_id] == ALLY_TEAM_ID:
			ally_alive = true
		elif _entity_store.team_id[entity_id] == ENEMY_TEAM_ID:
			enemy_alive = true
		if ally_alive and enemy_alive:
			return
	if not enemy_alive and ally_alive:
		handle_wave_clear()
	elif not ally_alive:
		handle_run_failed()

func _entity_is_alive(entity_id: int) -> bool:
	return _entity_store != null and entity_id >= 0 and entity_id < _entity_store.capacity and _entity_store.alive[entity_id] != 0

func _apply_recent_combat_feedback_to_views() -> void:
	for event in _recent_combat_events:
		var event_type := str(event.get("type", ""))
		var attacker_id := int(event.get("attacker_id", -1))
		if attacker_id != -1 and _unit_views_by_entity.has(attacker_id) and event_type == "attack":
			var attacker_view = _unit_views_by_entity[attacker_id]
			if attacker_view != null and attacker_view.has_method("trigger_attack_pulse"):
				attacker_view.call("trigger_attack_pulse")
		var target_id := int(event.get("target_id", -1))
		if target_id != -1 and _unit_views_by_entity.has(target_id) and (event_type == "attack" or event_type == "kill"):
			var target_view = _unit_views_by_entity[target_id]
			if target_view != null and target_view.has_method("trigger_hit_pulse"):
				target_view.call("trigger_hit_pulse")
