extends Node2D

const EffectPoolScript = preload("res://scripts/presentation/effect_pool.gd")
const SCREEN_CENTER := Vector2(640.0, 408.0)
const SCREEN_SCALE := Vector2(28.0, 20.0)

@onready var _controller = $BattleController
@onready var _unit_layer: Node2D = $UnitLayer
@onready var _effect_layer: Node2D = $EffectLayer
@onready var _reward_panel = $UiLayer/RewardPanel
@onready var _state_label: Label = $UiLayer/StateLabel
@onready var _wave_label: Label = $UiLayer/WaveLabel
@onready var _phase_hint: Label = $UiLayer/PhaseHint

var _effect_pool
var _runtime_ready := false

func _ready() -> void:
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
	_sync_runtime_screen_space_views()
	_consume_death_feedback()
	_consume_combat_feedback()
	_update_hud()
	_runtime_ready = true

func _process(delta: float) -> void:
	if not _runtime_ready:
		return
	if _controller == null or _reward_panel == null:
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
	for index in range(child_count):
		var view = _unit_layer.get_child(index)
		if _controller.has_method("unregister_unit_view_by_node"):
			_controller.call("unregister_unit_view_by_node", view)
		elif view.has_method("unbind_entity"):
			view.call("unbind_entity")
		if index >= bind_count:
			view.visible = false
			continue
		var entity_id := int(visible_entity_ids[index])
		if _controller.has_method("register_unit_view"):
			_controller.call("register_unit_view", entity_id, view)
		if view.has_method("apply_placeholder_style") and _controller.has_method("get_entity_visual_state"):
			var payload: Dictionary = _controller.call("get_entity_visual_state", entity_id)
			view.call("apply_placeholder_style", int(payload.get("team_id", 0)) == 1)
		if view.has_method("enable_death_feedback"):
			view.call("enable_death_feedback", true)

func _sync_runtime_screen_space_views() -> void:
	if _controller == null:
		return
	if _controller.has_method("sync_unit_views_screen_space"):
		_controller.call("sync_unit_views_screen_space", SCREEN_CENTER, SCREEN_SCALE)
	else:
		_controller.call("sync_unit_views")
	if _effect_layer != null:
		_effect_layer.position = Vector2.ZERO
		_effect_layer.scale = Vector2.ONE
		for child in _effect_layer.get_children():
			if child is Node2D:
				child.position = SCREEN_CENTER + Vector2(child.position.x * SCREEN_SCALE.x, child.position.y * SCREEN_SCALE.y)

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

func _consume_combat_feedback() -> void:
	if _controller == null or _effect_pool == null or not _controller.has_method("consume_recent_combat_events"):
		return
	var combat_events: Array = _controller.call("consume_recent_combat_events")
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
	var shadow := ColorRect.new()
	shadow.name = "Shadow"
	shadow.visible = false
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(shadow)
	var lift := ColorRect.new()
	lift.name = "Lift"
	lift.visible = false
	lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(lift)
	var trail := ColorRect.new()
	trail.name = "Trail"
	trail.visible = false
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(trail)
	var ring := ColorRect.new()
	ring.name = "Ring"
	ring.visible = false
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(ring)
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.visible = false
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(flash)
	_effect_layer.add_child(node)
	return node

func _update_effect_node(node: Node2D, effect) -> void:
	if node == null or effect == null:
		return
	var visual_kind := str(effect.visual_kind)
	node.visible = bool(effect.active)
	node.position = SCREEN_CENTER + Vector2(effect.position.x * SCREEN_SCALE.x, effect.position.y * SCREEN_SCALE.y)
	node.scale = effect.scale
	node.set_meta("team", str(effect.team))
	node.set_meta("visual_kind", visual_kind)
	var body = node.get_node_or_null("Body")
	if body != null:
		if visual_kind == "skill_ring":
			body.offset_left = -8.0
			body.offset_top = -2.0
			body.offset_right = 8.0
			body.offset_bottom = 2.0
			body.rotation = 0.0
			body.color = Color(1.0, 0.82, 0.34, 0.24)
		elif visual_kind == "launch_burst":
			body.offset_left = -3.0
			body.offset_top = -6.0
			body.offset_right = 3.0
			body.offset_bottom = 0.0
			body.rotation = 0.0
			body.color = Color(1.0, 0.72, 0.34, 0.38)
		elif visual_kind == "knockback_trail":
			body.offset_left = -5.0
			body.offset_top = -1.0
			body.offset_right = 5.0
			body.offset_bottom = 1.0
			body.rotation = 0.08
			body.color = Color(0.96, 0.48, 0.4, 0.3)
		elif visual_kind == "hit_flash":
			body.offset_left = -2.0
			body.offset_top = -2.0
			body.offset_right = 2.0
			body.offset_bottom = 2.0
			body.rotation = 0.785398
			body.color = Color(1.0, 1.0, 0.9, 0.34)
		else:
			body.offset_left = -5.0
			body.offset_top = -5.0
			body.offset_right = 5.0
			body.offset_bottom = 5.0
			body.rotation = 0.0
			body.color = effect.tint
	var shadow = node.get_node_or_null("Shadow")
	if shadow is ColorRect:
		shadow.visible = false
	var lift = node.get_node_or_null("Lift")
	if lift is ColorRect:
		lift.visible = visual_kind == "launch_burst"
		lift.offset_left = -1.0
		lift.offset_top = -8.0
		lift.offset_right = 1.0
		lift.offset_bottom = 0.0
		lift.color = Color(1.0, 0.9, 0.58, 0.2)
		lift.rotation = 0.0
	var trail = node.get_node_or_null("Trail")
	if trail is ColorRect:
		trail.visible = visual_kind == "knockback_trail"
		trail.offset_left = -5.0
		trail.offset_top = -0.8
		trail.offset_right = 5.0
		trail.offset_bottom = 0.8
		trail.color = Color(1.0, 0.74, 0.42, 0.16)
		trail.rotation = 0.08
	var ring = node.get_node_or_null("Ring")
	if ring is ColorRect:
		ring.visible = false
	var flash = node.get_node_or_null("Flash")
	if flash is ColorRect:
		flash.visible = visual_kind == "hit_flash"
		flash.offset_left = -0.8
		flash.offset_top = -4.0
		flash.offset_right = 0.8
		flash.offset_bottom = 4.0
		flash.color = Color(1.0, 0.98, 0.76, 0.18)
		flash.rotation = 0.785398

func _on_reward_selected(_index: int) -> void:
	if _controller == null or not _controller.has_method("claim_reward_and_advance"):
		return
	_controller.call("claim_reward_and_advance")
	_bind_runtime_views()
	_sync_runtime_screen_space_views()
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
