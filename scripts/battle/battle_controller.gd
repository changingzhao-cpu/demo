extends Node
class_name BattleController

const GameStateMachineScript = preload("res://scripts/game/game_state_machine.gd")
const WaveControllerScript = preload("res://scripts/battle/wave_controller.gd")
const EntityStoreScript = preload("res://scripts/battle/entity_store.gd")
const SpatialGridScript = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

const DEFAULT_ALLY_COUNT := 6
const DEFAULT_STORE_CAPACITY := 128
const GRID_CELL_SIZE := 4.0
const ALLY_TEAM_ID := 0
const ENEMY_TEAM_ID := 1
const ALLY_SCATTER_CENTER_X := -10.4
const ENEMY_SCATTER_CENTER_X := 10.2
const ALLY_SCATTER_WIDTH := 5.1
const ENEMY_SCATTER_WIDTH := 1.85
const ALLY_SCATTER_HEIGHT := 6.0
const ENEMY_SCATTER_HEIGHT := 3.6
const ALLY_FORWARD_PULL := 1.15
const ENEMY_FORWARD_PULL := 1.28
const MIN_ALLY_SPAWN_DISTANCE := 1.26
const MIN_ENEMY_SPAWN_DISTANCE := 0.86
const ENEMY_SWARM_FRONT_BIAS := 0.78
const ENEMY_SWARM_VERTICAL_CLUSTER := 0.67
const MAX_SPAWN_POSITION_ATTEMPTS := 24
const MAX_RECENT_COMBAT_EVENTS := 24

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
	return _live_entity_ids.duplicate()

func get_last_tick_report() -> Dictionary:
	return _last_tick_report

func get_recent_combat_events() -> Array[Dictionary]:
	return _recent_combat_events.duplicate(true)

func consume_recently_died_entities() -> Array[Dictionary]:
	var events := _recently_died_entities.duplicate(true)
	_recently_died_entities.clear()
	return events

func consume_recent_combat_events() -> Array[Dictionary]:
	var events := _recent_combat_events.duplicate(true)
	_recent_combat_events.clear()
	return events

func register_unit_view(entity_id: int, view) -> void:
	if view == null:
		return
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

func sync_unit_views() -> void:
	if _entity_store == null:
		return
	for entity_id in _unit_views_by_entity.keys():
		_sync_view_with_runtime_state(_unit_views_by_entity[entity_id], int(entity_id))
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
		_update_combat_state_after_tick()
		if get_state() != "combat":
			break

	_refresh_last_tick_report()
	sync_unit_views()

func force_refresh_runtime_state() -> void:
	_record_recent_deaths()
	_refresh_last_tick_report()
	sync_unit_views()

func get_runtime_snapshot() -> Dictionary:
	return {
		"state": get_state(),
		"live_count": _count_living_entities(),
		"death_count": _recently_died_entities.size(),
		"combat_event_count": _recent_combat_events.size(),
		"targeted_count": _count_entities_with_targets(),
		"advancing_count": _count_entities_in_state(3),
		"last_tick_report": _last_tick_report.duplicate(true)
	}

func debug_get_runtime_snapshot() -> Dictionary:
	return get_runtime_snapshot()

func _count_entities_with_targets() -> int:
	var count := 0
	if _entity_store == null:
		return count
	for entity_id in _live_entity_ids:
		if _entity_is_alive(entity_id) and _entity_store.target_id[entity_id] != -1:
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

func get_entity_visual_state(entity_id: int) -> Dictionary:
	return {
		"entity_id": entity_id,
		"position": _get_entity_position(entity_id),
		"is_alive": _entity_is_alive(entity_id),
		"team_id": _get_entity_team_id(entity_id),
		"move_speed": _get_entity_move_speed(entity_id),
		"facing_sign": _get_entity_facing_sign(entity_id)
	}

func get_all_entity_visual_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for entity_id in _live_entity_ids:
		states.append(get_entity_visual_state(entity_id))
	return states

func mark_entity_dead_for_debug(entity_id: int) -> void:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return
	_entity_store.alive[entity_id] = 0
	force_refresh_runtime_state()

func mark_first_enemy_dead_for_debug() -> void:
	for entity_id in _live_entity_ids:
		if _get_entity_team_id(entity_id) == ENEMY_TEAM_ID and _entity_is_alive(entity_id):
			mark_entity_dead_for_debug(entity_id)
			return

func mark_all_enemies_dead_for_debug() -> void:
	if _entity_store == null:
		return
	for entity_id in _live_entity_ids:
		if _get_entity_team_id(entity_id) == ENEMY_TEAM_ID:
			_entity_store.alive[entity_id] = 0
	force_refresh_runtime_state()
	_update_combat_state_after_tick()

func mark_all_allies_dead_for_debug() -> void:
	if _entity_store == null:
		return
	for entity_id in _live_entity_ids:
		if _get_entity_team_id(entity_id) == ALLY_TEAM_ID:
			_entity_store.alive[entity_id] = 0
	force_refresh_runtime_state()
	_update_combat_state_after_tick()

func advance_debug_frames(step_count: int, delta: float = 0.016) -> void:
	for _step in range(max(step_count, 0)):
		tick_combat(delta)
		if get_state() != "combat":
			return

func debug_trigger_reward() -> void:
	mark_all_enemies_dead_for_debug()

func debug_trigger_settle() -> void:
	mark_all_allies_dead_for_debug()

func debug_force_next_wave() -> void:
	if get_state() == "reward":
		claim_reward_and_advance()
		force_refresh_runtime_state()
	elif get_state() == "combat":
		handle_wave_clear()
		claim_reward_and_advance()
		force_refresh_runtime_state()

func debug_restart_run() -> void:
	start_run()
	force_refresh_runtime_state()

func clear_recently_died_entities() -> void:
	_recently_died_entities.clear()
	_refresh_last_tick_report()

func clear_debug_events() -> void:
	clear_recently_died_entities()
	_recent_combat_events.clear()

func debug_snapshot() -> Dictionary:
	return get_runtime_snapshot()

func get_recently_died_entities() -> Array[Dictionary]:
	return _recently_died_entities.duplicate(true)

func debug_get_recently_died_entities() -> Array[Dictionary]:
	return get_recently_died_entities()

func debug_force_refresh_runtime_state() -> void:
	force_refresh_runtime_state()

func debug_get_all_entity_visual_states() -> Array[Dictionary]:
	return get_all_entity_visual_states()

func debug_get_entity_visual_state(entity_id: int) -> Dictionary:
	return get_entity_visual_state(entity_id)

func debug_tick_once(delta: float = 0.016) -> void:
	tick_combat(delta)

func debug_get_last_tick_report() -> Dictionary:
	return get_last_tick_report()

func debug_consume_recently_died_entities() -> Array[Dictionary]:
	return consume_recently_died_entities()

func debug_get_recent_combat_events() -> Array[Dictionary]:
	return get_recent_combat_events()

func debug_force_enemy_death_feedback() -> void:
	mark_first_enemy_dead_for_debug()

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
	_last_tick_report = {
		"processed": 0,
		"state": get_state(),
		"death_count": 0,
		"moved": 0,
		"attacked": 0,
		"killed": 0,
		"idle": 0,
		"in_range": 0,
		"events": []
	}

func _record_recent_deaths() -> void:
	if _entity_store == null:
		return
	for entity_id in _live_entity_ids:
		if _entity_is_alive(entity_id):
			continue
		if _has_recent_death_for_entity(entity_id):
			continue
		_recently_died_entities.append({
			"entity_id": entity_id,
			"team": "enemy" if _get_entity_team_id(entity_id) == ENEMY_TEAM_ID else "ally",
			"position": _get_entity_position(entity_id)
		})

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
		_last_tick_report = {
			"processed": 0,
			"moved": 0,
			"attacked": 0,
			"killed": 0,
			"idle": 0,
			"in_range": 0,
			"events": []
		}
	_last_tick_report["state"] = get_state()
	_last_tick_report["death_count"] = _recently_died_entities.size()
	_last_tick_report["live_count"] = _count_living_entities()
	_last_tick_report["combat_event_count"] = _recent_combat_events.size()
	_last_tick_report["targeted_count"] = _count_entities_with_targets()
	_last_tick_report["advancing_count"] = _count_entities_in_state(3)

func _count_living_entities() -> int:
	var count := 0
	for entity_id in _live_entity_ids:
		if _entity_is_alive(entity_id):
			count += 1
	return count

func _spawn_team(unit_count: int, team_id: int) -> void:
	var team_positions: Array[Vector2] = []
	for index in range(unit_count):
		var entity_id: int = _entity_store.allocate()
		if entity_id == -1:
			return
		_live_entity_ids.append(entity_id)
		_entity_store.team_id[entity_id] = team_id
		_entity_store.unit_type_id[entity_id] = 0
		_entity_store.hp[entity_id] = 10.0
		_entity_store.max_hp[entity_id] = 10.0
		_entity_store.attack_range_sq[entity_id] = 1.0
		_entity_store.attack_interval[entity_id] = 0.5
		_entity_store.attack_cd[entity_id] = 0.0
		_entity_store.move_speed[entity_id] = 2.0
		_entity_store.radius[entity_id] = 0.4
		var spawn_position := _get_spawn_position(index, team_id, team_positions)
		team_positions.append(spawn_position)
		_entity_store.position_x[entity_id] = spawn_position.x
		_entity_store.position_y[entity_id] = spawn_position.y
		_entity_store.bucket_id[entity_id] = entity_id % _tick_bucket_count
		_entity_store.grid_id[entity_id] = entity_id
		_entity_store.target_id[entity_id] = -1
		_entity_store.state[entity_id] = 0
		_spatial_grid.upsert(entity_id, spawn_position)

func _get_spawn_position(index: int, team_id: int, existing_positions: Array[Vector2]) -> Vector2:
	var center_x := ALLY_SCATTER_CENTER_X if team_id == ALLY_TEAM_ID else ENEMY_SCATTER_CENTER_X
	var width := ALLY_SCATTER_WIDTH if team_id == ALLY_TEAM_ID else ENEMY_SCATTER_WIDTH
	var height := ALLY_SCATTER_HEIGHT if team_id == ALLY_TEAM_ID else ENEMY_SCATTER_HEIGHT
	var forward_pull := ALLY_FORWARD_PULL if team_id == ALLY_TEAM_ID else ENEMY_FORWARD_PULL
	var min_distance := MIN_ALLY_SPAWN_DISTANCE if team_id == ALLY_TEAM_ID else MIN_ENEMY_SPAWN_DISTANCE
	var bias_sign := 1.0 if team_id == ALLY_TEAM_ID else -1.0
	var normalized_index := 0.0 if existing_positions.is_empty() else float(index) / float(max(1, existing_positions.size()))
	var fallback_y := remap(float(index % 3), 0.0, 2.0, -height * 0.4, height * 0.4)
	if team_id == ENEMY_TEAM_ID:
		fallback_y *= ENEMY_SWARM_VERTICAL_CLUSTER
	var fallback_position := Vector2(center_x + bias_sign * (forward_pull + normalized_index * width * 0.35), fallback_y)
	for _attempt in range(MAX_SPAWN_POSITION_ATTEMPTS):
		var candidate_x := center_x + bias_sign * _rng.randf_range(0.1, width)
		var candidate_y := _rng.randf_range(-height * 0.5, height * 0.5)
		candidate_x += bias_sign * _rng.randf_range(0.0, forward_pull)
		candidate_y += sin(float(index) * 1.37 + _rng.randf()) * 0.35
		if team_id == ENEMY_TEAM_ID:
			candidate_x += bias_sign * _rng.randf_range(ENEMY_SWARM_FRONT_BIAS * 0.4, ENEMY_SWARM_FRONT_BIAS)
			candidate_y *= ENEMY_SWARM_VERTICAL_CLUSTER
			candidate_y += remap(float(index % 2), 0.0, 1.0, -0.35, 0.35)
		var candidate := Vector2(candidate_x, candidate_y)
		if _is_spawn_position_valid(candidate, existing_positions, min_distance):
			return candidate
	return fallback_position

func _is_spawn_position_valid(candidate: Vector2, existing_positions: Array[Vector2], min_distance: float) -> bool:
	for existing_position in existing_positions:
		if existing_position.distance_to(candidate) < min_distance:
			return false
	return true

func _team_scatter_density(positions: Array[Vector2]) -> float:
	if positions.size() < 2:
		return 0.0
	var total_distance := 0.0
	var pair_count := 0
	for index in range(positions.size()):
		for next_index in range(index + 1, positions.size()):
			total_distance += positions[index].distance_to(positions[next_index])
			pair_count += 1
	return 0.0 if pair_count == 0 else total_distance / float(pair_count)

func _update_combat_state_after_tick() -> void:
	if _entity_store == null:
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

func _get_entity_position(entity_id: int) -> Vector2:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return Vector2.ZERO
	return Vector2(_entity_store.position_x[entity_id], _entity_store.position_y[entity_id])

func _get_entity_team_id(entity_id: int) -> int:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return -1
	return _entity_store.team_id[entity_id]

func _get_entity_move_speed(entity_id: int) -> float:
	if _entity_store == null or entity_id < 0 or entity_id >= _entity_store.capacity:
		return 0.0
	return _entity_store.move_speed[entity_id]

func _get_entity_facing_sign(entity_id: int) -> float:
	var team_id := _get_entity_team_id(entity_id)
	if team_id == ENEMY_TEAM_ID:
		return -1.0
	if team_id == ALLY_TEAM_ID:
		return 1.0
	return 0.0

func _view_uses_visual_sync(view) -> bool:
	return view != null and view.has_method("sync_from_entity_visual")

func _view_uses_basic_sync(view) -> bool:
	return view != null and view.has_method("sync_from_entity")

func _view_supports_placeholder_style(view) -> bool:
	return view != null and view.has_method("apply_placeholder_style")

func _view_supports_motion_state(view) -> bool:
	return view != null and view.has_method("set_visual_motion")

func _view_supports_alive_state(view) -> bool:
	return view != null and view.has_method("set_visual_alive_state")

func _view_uses_dead_feedback(view) -> bool:
	return view != null and view.has_method("is_death_feedback_enabled") and bool(view.call("is_death_feedback_enabled"))

func _set_view_visible_if_supported(view, is_visible: bool) -> void:
	if view == null:
		return
	if view is CanvasItem:
		view.visible = is_visible
		return
	for property in view.get_property_list():
		if str(property.get("name", "")) == "visible":
			view.set("visible", is_visible)
			return
	if view.has_method("set_visible"):
		view.call("set_visible", is_visible)

func _apply_non_scripted_view_state(view, position: Vector2, is_alive: bool) -> void:
	if view == null:
		return
	if view is Node2D:
		view.position = position
		view.visible = is_alive

func _sync_position_into_view(view, position: Vector2, is_alive: bool, team_id: int, move_speed: float, facing_sign: float) -> void:
	if view == null:
		return
	if _view_uses_visual_sync(view):
		view.call("sync_from_entity_visual", position, is_alive, team_id, move_speed, facing_sign)
	elif _view_uses_basic_sync(view):
		view.call("sync_from_entity", position, is_alive)
	else:
		_apply_non_scripted_view_state(view, position, is_alive)

func _set_view_visibility_for_legacy_dead_state(view, is_alive: bool) -> void:
	if view == null:
		return
	if is_alive:
		_set_view_visible_if_supported(view, true)
		return
	if _view_uses_dead_feedback(view):
		return
	_set_view_visible_if_supported(view, false)

func _apply_visual_state_to_view(view, team_id: int, is_alive: bool, facing_sign: float, move_speed: float) -> void:
	if view == null:
		return
	if _view_supports_placeholder_style(view):
		view.call("apply_placeholder_style", team_id == ENEMY_TEAM_ID)
	if _view_supports_motion_state(view):
		view.call("set_visual_motion", facing_sign, move_speed)
	if _view_supports_alive_state(view):
		view.call("set_visual_alive_state", is_alive)
	else:
		_set_view_visibility_for_legacy_dead_state(view, is_alive)
	if not is_alive and not _view_supports_alive_state(view) and not _view_uses_dead_feedback(view):
		_set_view_visible_if_supported(view, false)

func _apply_recent_combat_feedback_to_views() -> void:
	for event in _recent_combat_events:
		var event_type := str(event.get("type", ""))
		var attacker_id := int(event.get("attacker_id", -1))
		if attacker_id != -1 and _unit_views_by_entity.has(attacker_id):
			var attacker_view = _unit_views_by_entity[attacker_id]
			if attacker_view != null and attacker_view.has_method("trigger_attack_pulse") and event_type == "attack":
				attacker_view.call("trigger_attack_pulse")
		var target_id := int(event.get("target_id", -1))
		if target_id != -1 and _unit_views_by_entity.has(target_id) and (event_type == "attack" or event_type == "kill"):
			var target_view = _unit_views_by_entity[target_id]
			if target_view != null and target_view.has_method("trigger_hit_pulse"):
				target_view.call("trigger_hit_pulse")

func _sync_view_with_runtime_state(view, entity_id: int) -> void:
	if view == null:
		return
	var position := _get_entity_position(entity_id)
	var is_alive := _entity_is_alive(entity_id)
	var team_id := _get_entity_team_id(entity_id)
	var move_speed := _get_entity_move_speed(entity_id)
	var facing_sign := _get_entity_facing_sign(entity_id)
	_sync_position_into_view(view, position, is_alive, team_id, move_speed, facing_sign)
	_apply_visual_state_to_view(view, team_id, is_alive, facing_sign, move_speed)
