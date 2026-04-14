extends Node2D

const EffectPoolScript = preload("res://scripts/presentation/effect_pool.gd")
const SCREEN_CENTER := Vector2(640.0, 392.0)
const SCREEN_SCALE := Vector2(28.0, 20.0)
const INIT_DISPLAY_COUNT := 42
const INIT_REGION_RADIUS := Vector2(344.0, 220.0)
const INIT_MIN_DISTANCE := 9.0
const INIT_JITTER := 5.0
const INIT_HOLD_SECONDS := 1.2
const DEBUG_FIXED_INITIAL_LAYOUT := true
const DEBUG_FIXED_INITIAL_LAYOUT_SEED := 20260414

@onready var _controller = $BattleController
@onready var _unit_layer: Node2D = $UnitLayer
@onready var _effect_layer: Node2D = $EffectLayer
@onready var _reward_panel = $UiLayer/RewardPanel
@onready var _state_label: Label = $UiLayer/StateLabel
@onready var _wave_label: Label = $UiLayer/WaveLabel
@onready var _phase_hint: Label = $UiLayer/PhaseHint

var _effect_pool
var _runtime_ready := false
var _initial_layout_rng := RandomNumberGenerator.new()
var _initial_layout_time := 0.0
var _initial_layout_active := true
var _initial_layout_positions: Dictionary = {}

func _ready() -> void:
	if DEBUG_FIXED_INITIAL_LAYOUT:
		_initial_layout_rng.seed = DEBUG_FIXED_INITIAL_LAYOUT_SEED
	else:
		_initial_layout_rng.randomize()
	_setup_effect_pool()
	if _controller != null:
		_controller.set_process(false)
	if _reward_panel != null and _reward_panel.has_signal("reward_selected"):
		_reward_panel.reward_selected.connect(_on_reward_selected)
	if _reward_panel != null:
		_reward_panel.visible = false
	call_deferred("_finish_runtime_bootstrap")

func _finish_runtime_bootstrap() -> void:
	_bind_runtime_views()
	_generate_initial_layout()
	_capture_initial_layout_world_mapping()
	_apply_initial_layout_to_views()
	_update_hud()
	_runtime_ready = true

func _process(delta: float) -> void:
	if not _runtime_ready:
		return
	if _controller == null or _reward_panel == null:
		return
	if _initial_layout_active:
		_initial_layout_time += delta
		_apply_initial_layout_to_views()
		_consume_combat_feedback()
		_update_hud()
		if _initial_layout_time >= INIT_HOLD_SECONDS:
			_initial_layout_active = false
		return
	if _controller.has_method("tick_combat"):
		_controller.call("tick_combat", delta)
	var state := str(_controller.call("get_state"))
	if state == "reward":
		if not _reward_panel.visible and _reward_panel.has_method("show_rewards"):
			_reward_panel.call("show_rewards", ["atk", "hp", "speed"])
	else:
		_reward_panel.visible = false
	_tick_effect_feedback(delta)
	_consume_death_feedback()
	_consume_combat_feedback()
	_sync_runtime_screen_space_views()
	_update_hud()

func _get_tempo_hint_text() -> String:
	if _initial_layout_active:
		return "Clash phase"
	if _controller == null:
		return "Auto battle"
	var report: Dictionary = _controller.call("get_last_tick_report")
	var moved := int(report.get("moved", 0))
	var attacked := int(report.get("attacked", 0))
	var combat_event_count := int(report.get("combat_event_count", 0))
	var in_range := int(report.get("in_range", 0))
	var targeted_count := int(report.get("targeted_count", 0))
	if attacked > 0 and combat_event_count >= 3:
		return "Impact burst"
	if attacked > 0 or in_range > 0 or combat_event_count > 0:
		return "Clash phase"
	if moved > 0 or targeted_count > 0:
		return "Scatter setup"
	return "Auto battle"

func _setup_effect_pool() -> void:
	_effect_pool = EffectPoolScript.new(_make_effect_record, 6, 8)

func _make_effect_record():
	return {
		"active": false,
		"reset_count": 0,
		"play_count": 0,
		"last_key": "",
		"ttl": 0.0,
		"team": "",
		"position": Vector2.ZERO,
		"tint": Color.WHITE,
		"scale": Vector2.ONE,
		"visual_kind": "",
		"persistent": false
	}

func _bind_runtime_views() -> void:
	if _controller == null or _unit_layer == null or not _controller.has_method("select_visible_entity_ids"):
		return
	var child_count := _unit_layer.get_child_count()
	var visible_entity_ids: Array = _controller.call("select_visible_entity_ids", child_count)
	var bind_count := mini(visible_entity_ids.size(), child_count)
	var used_entity_ids := {}
	for index in range(bind_count):
		var entity_id := int(visible_entity_ids[index])
		used_entity_ids[entity_id] = true
		var view = _unit_layer.get_child(index)
		if _controller.has_method("unregister_unit_view_by_node"):
			_controller.call("unregister_unit_view_by_node", view)
		elif view.has_method("unbind_entity"):
			view.call("unbind_entity")
		if _controller.has_method("register_unit_view"):
			_controller.call("register_unit_view", entity_id, view)
		if view.has_method("apply_placeholder_style") and _controller.has_method("get_entity_visual_state"):
			var payload: Dictionary = _controller.call("get_entity_visual_state", entity_id)
			view.call("apply_placeholder_style", int(payload.get("team_id", 0)) == 1)
		if view.has_method("enable_death_feedback"):
			view.call("enable_death_feedback", true)
	for index in range(bind_count, child_count):
		var view = _unit_layer.get_child(index)
		if _controller.has_method("unregister_unit_view_by_node"):
			_controller.call("unregister_unit_view_by_node", view)
		elif view.has_method("unbind_entity"):
			view.call("unbind_entity")
		view.visible = false
	for child in _unit_layer.get_children():
		if child.has_method("get_entity_id"):
			var bound_entity_id := int(child.call("get_entity_id"))
			if bound_entity_id != -1 and not used_entity_ids.has(bound_entity_id):
				child.visible = false

func _generate_initial_layout() -> void:
	_initial_layout_positions.clear()
	if _controller == null or not _controller.has_method("get_visible_entity_screen_payloads"):
		return
	var payloads: Array = _controller.call("get_visible_entity_screen_payloads", INIT_DISPLAY_COUNT, SCREEN_CENTER, SCREEN_SCALE)
	var placed_points: Array[Vector2] = []
	for payload in payloads:
		var entity_id := int(payload.get("entity_id", -1))
		if entity_id == -1:
			continue
		var team_id := int(payload.get("team_id", -1))
		var point := _sample_initial_point(placed_points, team_id)
		placed_points.append(point)
		_initial_layout_positions[entity_id] = point

func _sample_initial_point(existing_points: Array[Vector2], team_id: int) -> Vector2:
	for _attempt in range(400):
		var angle := _initial_layout_rng.randf_range(0.0, TAU)
		var radius_x := INIT_REGION_RADIUS.x * sqrt(_initial_layout_rng.randf())
		var radius_y := INIT_REGION_RADIUS.y * sqrt(_initial_layout_rng.randf())
		var candidate := SCREEN_CENTER + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		candidate.x += _initial_layout_rng.randf_range(-INIT_JITTER, INIT_JITTER)
		candidate.y += _initial_layout_rng.randf_range(-INIT_JITTER, INIT_JITTER)
		candidate.x += -14.0 if team_id == 0 else 14.0
		if _fits_initial_spacing(candidate, existing_points):
			return candidate
	return SCREEN_CENTER + Vector2(_initial_layout_rng.randf_range(-160.0, 160.0), _initial_layout_rng.randf_range(-110.0, 110.0))

func _fits_initial_spacing(candidate: Vector2, existing_points: Array[Vector2]) -> bool:
	for point in existing_points:
		if point.distance_to(candidate) < INIT_MIN_DISTANCE:
			return false
	return true

func _map_world_to_runtime_screen(world_position: Vector2, team_id: int) -> Vector2:
	var effective_scale := SCREEN_SCALE * (0.72 if team_id == 1 else 1.0)
	var x_anchor := SCREEN_CENTER.x + 54.0 if team_id == 1 else SCREEN_CENTER.x - 18.0
	return Vector2(x_anchor + world_position.x * effective_scale.x, SCREEN_CENTER.y + world_position.y * effective_scale.y)

func _capture_initial_layout_world_mapping() -> void:
	if _controller == null:
		return
	var payloads: Array = _controller.call("get_visible_entity_payloads", _unit_layer.get_child_count()) if _controller.has_method("get_visible_entity_payloads") else []
	for payload in payloads:
		var entity_id := int(payload.get("entity_id", -1))
		if entity_id == -1:
			continue
		var team_id := int(payload.get("team_id", 0))
		var target_screen_position: Vector2 = _initial_layout_positions.get(entity_id, _map_world_to_runtime_screen(payload.get("position", Vector2.ZERO), team_id))
		var effective_scale := SCREEN_SCALE * (0.72 if team_id == 1 else 1.0)
		var x_anchor := SCREEN_CENTER.x + 54.0 if team_id == 1 else SCREEN_CENTER.x - 18.0
		var remapped_world := Vector2(
			(target_screen_position.x - x_anchor) / maxf(effective_scale.x, 0.0001),
			(target_screen_position.y - SCREEN_CENTER.y) / maxf(effective_scale.y, 0.0001)
		)
		if _controller.has_method("get_entity_store"):
			var store = _controller.call("get_entity_store")
			store.position_x[entity_id] = remapped_world.x
			store.position_y[entity_id] = remapped_world.y
			if _controller.has_method("refresh_entity_in_spatial_grid"):
				_controller.call("refresh_entity_in_spatial_grid", entity_id)
	_refresh_depth_sort_for_visible_views()

func _apply_initial_layout_to_views() -> void:
	if _controller == null:
		return
	var payloads: Array = _controller.call("get_visible_entity_screen_payloads", _unit_layer.get_child_count(), SCREEN_CENTER, SCREEN_SCALE)
	for payload in payloads:
		var entity_id := int(payload.get("entity_id", -1))
		if entity_id == -1:
			continue
		var runtime_screen_position: Vector2 = payload.get("position", SCREEN_CENTER)
		var view: Node2D = _find_bound_view(entity_id)
		if view == null:
			continue
		if view.has_method("sync_from_entity_visual"):
			view.call("sync_from_entity_visual", runtime_screen_position, true, int(payload.get("team_id", 0)), 0.0, float(payload.get("facing_sign", 1.0)), int(payload.get("unit_state", 0)))
	_refresh_depth_sort_for_visible_views()

func _write_combat_feedback_probe(events: Array) -> void:
	if not OS.is_debug_build() or _controller == null:
		return
	var entries: Array = []
	for event in events:
		var event_type := str(event.get("type", ""))
		var attacker_id := int(event.get("attacker_id", -1))
		var target_id := int(event.get("target_id", -1))
		entries.append({
			"type": event_type,
			"attacker_id": attacker_id,
			"attacker_view_bound": _controller.call("debug_has_bound_view", attacker_id) if _controller.has_method("debug_has_bound_view") else false,
			"target_id": target_id,
			"target_view_bound": _controller.call("debug_has_bound_view", target_id) if _controller.has_method("debug_has_bound_view") else false
		})
	var file := FileAccess.open("user://combat_feedback_probe.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"events": entries}, "\t"))
		file.close()

func _consume_combat_feedback() -> void:
	if _controller == null or _effect_pool == null or not _controller.has_method("consume_recent_combat_events"):
		return
	var combat_events: Array = _controller.call("consume_recent_combat_events")
	_write_combat_feedback_probe(combat_events)
	for combat_event in combat_events:
		var event_type := str(combat_event.get("type", ""))
		var target_position: Vector2 = combat_event.get("target_position", Vector2.ZERO)
		if event_type == "attack":
			_effect_pool.call("spawn_visual_event", "hit_flash", target_position, "enemy", 0.08)
		elif event_type == "knockback":
			_effect_pool.call("spawn_visual_event", "knockback_trail", target_position, "enemy", 0.1)
		elif event_type == "launch":
			_effect_pool.call("spawn_visual_event", "launch_burst", target_position, "enemy", 0.1)
	_sync_effect_nodes()
	if _controller.has_method("apply_recent_combat_feedback_to_views"):
		_controller.call("apply_recent_combat_feedback_to_views")
	if OS.is_debug_build() and _unit_layer != null:
		var pulse_entries: Array = []
		for child in _unit_layer.get_children():
			if child.visible and child.has_method("get_entity_id") and child.has_method("debug_get_pose_snapshot"):
				pulse_entries.append({
					"entity_id": int(child.call("get_entity_id")),
					"pose": child.call("debug_get_pose_snapshot")
				})
		var pulse_file := FileAccess.open("user://combat_pulse_probe.json", FileAccess.WRITE)
		if pulse_file != null:
			pulse_file.store_string(JSON.stringify({"views": pulse_entries}, "\t"))
			pulse_file.close()
	_refresh_depth_sort_for_visible_views()

func _sync_runtime_screen_space_views() -> void:
	if _controller == null:
		return
	if OS.is_debug_build() and _controller.has_method("get_visible_entity_screen_payloads"):
		var payload_probe: Array = _controller.call("get_visible_entity_screen_payloads", 6, SCREEN_CENTER, SCREEN_SCALE)
		var probe_file := FileAccess.open("user://runtime_payload_probe.json", FileAccess.WRITE)
		if probe_file != null:
			probe_file.store_string(JSON.stringify({"payloads": payload_probe}, "\t"))
			probe_file.close()
	if _controller.has_method("sync_unit_views_for_battle_scene"):
		_controller.call("sync_unit_views_for_battle_scene", SCREEN_CENTER, SCREEN_SCALE)
	elif _controller.has_method("sync_unit_views_screen_space"):
		_controller.call("sync_unit_views_screen_space", SCREEN_CENTER, SCREEN_SCALE)
	else:
		_controller.call("sync_unit_views")
	_refresh_depth_sort_for_visible_views()
	if _effect_layer != null:
		_effect_layer.position = Vector2.ZERO
		_effect_layer.scale = Vector2.ONE
	if OS.is_debug_build() and _unit_layer != null:
		var view_entries: Array = []
		for child in _unit_layer.get_children():
			if child is Node2D and child.visible and child.has_method("get_entity_id"):
				view_entries.append({
					"entity_id": int(child.call("get_entity_id")),
					"position": child.global_position,
					"pose": child.call("debug_get_pose_snapshot") if child.has_method("debug_get_pose_snapshot") else {}
				})
		var view_file := FileAccess.open("user://runtime_view_probe.json", FileAccess.WRITE)
		if view_file != null:
			view_file.store_string(JSON.stringify({"views": view_entries}, "\t"))
			view_file.close()

func _debug_dump_transition_probe(stage: String) -> void:
	if _unit_layer == null or _controller == null:
		return
	var entries: Array = []
	for child in _unit_layer.get_children():
		if not child.has_method("get_entity_id"):
			continue
		var entity_id := int(child.call("get_entity_id"))
		if entity_id == -1:
			continue
		entries.append({
			"entity_id": entity_id,
			"visible": child.visible,
			"position": child.position,
			"global_position": child.global_position
		})
	var path := "user://transition_%s_probe.json" % stage
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"stage": stage, "entries": entries}, "\t"))
		file.close()

func _refresh_depth_sort_for_visible_views() -> void:
	if _unit_layer == null:
		return
	for child in _unit_layer.get_children():
		if child is Node2D and child.visible and child.has_method("refresh_depth_sort"):
			child.call("refresh_depth_sort")

func _find_bound_view(entity_id: int) -> Node2D:
	if _unit_layer == null:
		return null
	for child in _unit_layer.get_children():
		if child is Node2D and child.has_method("get_entity_id") and int(child.call("get_entity_id")) == entity_id:
			return child
	return null

func _tick_effect_feedback(delta: float) -> void:
	if _effect_pool != null and _effect_pool.has_method("tick_corpses"):
		_effect_pool.call("tick_corpses", delta)
	_sync_effect_nodes()

func _consume_death_feedback() -> void:
	if _controller == null or _effect_pool == null or not _controller.has_method("consume_recently_died_entities"):
		return
	var death_events: Array = _controller.call("consume_recently_died_entities")
	for death_event in death_events:
		var team := str(death_event.get("team", "ally"))
		var world_position: Vector2 = death_event.get("position", Vector2.ZERO)
		_effect_pool.call("spawn_visual_event", "%s_corpse" % team, world_position, team, 0.8)
	_sync_effect_nodes()

func _sync_effect_nodes() -> void:
	if _effect_layer == null or _effect_pool == null or not _effect_pool.has_method("get_active_effects"):
		return
	var active_effects: Array = _effect_pool.call("get_active_effects")
	while _effect_layer.get_child_count() > active_effects.size():
		var extra_child = _effect_layer.get_child(_effect_layer.get_child_count() - 1)
		_effect_layer.remove_child(extra_child)
		extra_child.queue_free()
	for index in range(active_effects.size()):
		var effect = active_effects[index]
		var node: Node2D = _effect_layer.get_child(index) if index < _effect_layer.get_child_count() else _create_effect_node()
		_update_effect_node(node, effect)

func _create_effect_node() -> Node2D:
	var node := Node2D.new()
	var body := ColorRect.new()
	body.name = "Body"
	body.offset_left = -8.0
	body.offset_top = -8.0
	body.offset_right = 8.0
	body.offset_bottom = 8.0
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(body)
	_effect_layer.add_child(node)
	return node

func _update_effect_node(node: Node2D, effect) -> void:
	if node == null or effect == null:
		return
	node.visible = bool(effect.active)
	node.position = SCREEN_CENTER + Vector2(effect.position.x * SCREEN_SCALE.x, effect.position.y * SCREEN_SCALE.y)
	node.scale = effect.scale
	var body = node.get_node_or_null("Body")
	if body is ColorRect:
		body.color = effect.tint

func _on_reward_selected(_index: int) -> void:
	if _controller == null or not _controller.has_method("claim_reward_and_advance"):
		return
	_controller.call("claim_reward_and_advance")
	_initial_layout_active = true
	_initial_layout_time = 0.0
	_bind_runtime_views()
	_generate_initial_layout()
	_capture_initial_layout_world_mapping()
	_apply_initial_layout_to_views()
	if _reward_panel != null:
		_reward_panel.visible = false
	_update_hud()

func _exit_tree() -> void:
	_runtime_ready = false
	if _effect_layer != null:
		for child in _effect_layer.get_children():
			_effect_layer.remove_child(child)
			child.queue_free()
	_effect_pool = null

func _update_hud() -> void:
	if _controller == null:
		return
	var state := str(_controller.call("get_state"))
	var current_wave: Dictionary = _controller.call("get_current_wave")
	var wave_number := int(current_wave.get("wave", 0))
	if _state_label != null:
		_state_label.text = "Combat" if state == "combat" else "Rewards" if state == "reward" else "Defeat"
	if _wave_label != null:
		_wave_label.text = "Wave %d" % wave_number
	if _phase_hint != null:
		if state == "reward":
			_phase_hint.text = "Choose a reward"
		elif state == "settle":
			_phase_hint.text = "Run ended. Restart"
		else:
			_phase_hint.text = _get_tempo_hint_text()
