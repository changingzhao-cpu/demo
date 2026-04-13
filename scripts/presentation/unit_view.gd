extends Node2D
class_name UnitView

const BOUND_TINT := Color(0.45, 0.85, 1.0, 1.0)
const ENEMY_TINT := Color(0.95, 0.4, 0.4, 1.0)
const UNBOUND_TINT := Color(0.4, 0.4, 0.4, 0.4)
const DEAD_ALPHA := 0.35
const VISUAL_RADIUS := 3.0
const MAX_MOTION_STRENGTH := 1.0
const ATTACK_PULSE_BONUS := 0.24
const HIT_PULSE_BONUS := 0.36
const ATTACK_STATE_HOLD := 0.28
const HIT_STATE_HOLD := 0.2
const SOLDIER_IDLE_TEXTURE_PATH := "res://assets/battle/units/soldier_idle.png"
const SOLDIER_ATTACK_TEXTURE_PATH := "res://assets/battle/units/soldier_attack.png"
const GOOSE_IDLE_TEXTURE_PATH := "res://assets/battle/units/goose_idle.png"
const GOOSE_ATTACK_TEXTURE_PATH := "res://assets/battle/units/goose_attack.png"
const SOLDIER_IDLE_TEXTURE = preload("res://assets/battle/units/soldier_idle.png")
const SOLDIER_ATTACK_TEXTURE = preload("res://assets/battle/units/soldier_attack.png")
const GOOSE_IDLE_TEXTURE = preload("res://assets/battle/units/goose_idle.png")
const GOOSE_ATTACK_TEXTURE = preload("res://assets/battle/units/goose_attack.png")
const SOLDIER_SCALE := Vector2(0.22, 0.22)
const GOOSE_SCALE := Vector2(0.11, 0.11)

const VISUAL_STATE_IDLE := 0
const VISUAL_STATE_ATTACK := 1
const VISUAL_STATE_HIT := 2
const VISUAL_STATE_DEAD := 3
const UNIT_STATE_IDLE := 0
const UNIT_STATE_ATTACK := 1
const UNIT_STATE_ADVANCE := 3
const UNIT_STATE_DEAD := 4

const SOLDIER_ATTACK_POSE_OFFSET := Vector2(0.24, -0.08)
const GOOSE_ATTACK_POSE_OFFSET := Vector2(0.42, -0.14)
const GOOSE_ATTACK_POSE_ROTATION := 0.34
const SOLDIER_ATTACK_POSE_ROTATION := -0.18
const GOOSE_HIT_POSE_ROTATION := 0.1
const SOLDIER_HIT_POSE_ROTATION := 0.08
const GOOSE_HIT_POSE_OFFSET := Vector2(-0.12, 0.02)

var _entity_id: int = -1
var _is_bound := false
var _is_enemy := false
var _is_showing_death_state := false
var _supports_death_feedback := false
var _visual_tint := UNBOUND_TINT
var _visual_facing_sign := 1.0
var _visual_motion_strength := 0.0
var _attack_pulse_strength := 0.0
var _hit_pulse_strength := 0.0
var _attack_frame_timer := 0.0
var _hit_frame_timer := 0.0
var _visual_unit_state := UNIT_STATE_IDLE
var _body_pose_offset := Vector2.ZERO
var _body_pose_rotation := 0.0

func _init() -> void:
	_reset_visual_state()

func _ready() -> void:
	_ensure_sprite_nodes()
	_refresh_sprite_visuals()

func _draw() -> void:
	if not visible:
		return
	if _is_showing_death_state:
		draw_line(Vector2(-VISUAL_RADIUS - 0.6, -VISUAL_RADIUS - 0.45), Vector2(VISUAL_RADIUS + 0.6, VISUAL_RADIUS + 0.45), Color(1.0, 1.0, 1.0, _visual_tint.a * 0.55), 1.1)
		draw_line(Vector2(-VISUAL_RADIUS - 0.6, VISUAL_RADIUS + 0.45), Vector2(VISUAL_RADIUS + 0.6, -VISUAL_RADIUS - 0.45), Color(1.0, 1.0, 1.0, _visual_tint.a * 0.55), 1.1)

func bind_entity(entity_id: int) -> void:
	_ensure_sprite_nodes()
	_entity_id = entity_id
	_is_bound = true
	_is_showing_death_state = false
	_supports_death_feedback = false
	visible = true
	_update_visual_tint()
	_refresh_sprite_visuals()

func debug_get_sprite_snapshot() -> Dictionary:
	_ensure_sprite_nodes()
	var body: Sprite2D = get_node_or_null("BodySprite")
	var overlay: Sprite2D = get_node_or_null("HitOverlay")
	return {
		"view_visible": visible,
		"bound": _is_bound,
		"entity_id": _entity_id,
		"body_exists": body != null,
		"body_visible": body != null and body.visible,
		"body_texture": body.texture.resource_path if body != null and body.texture != null else "",
		"body_scale": body.scale if body != null else Vector2.ZERO,
		"body_modulate": body.modulate if body != null else Color.TRANSPARENT,
		"overlay_exists": overlay != null,
		"overlay_visible": overlay != null and overlay.visible
	}

func unbind_entity() -> void:
	_entity_id = -1
	_is_bound = false
	_reset_visual_state()

func sync_from_entity(world_position: Vector2, is_alive: bool) -> void:
	sync_from_entity_visual(world_position, is_alive, 1 if _is_enemy else 0, _visual_motion_strength, _visual_facing_sign, _visual_unit_state)

func sync_from_entity_visual(world_position: Vector2, is_alive: bool, team_id: int, move_speed: float, facing_sign: float, unit_state: int = UNIT_STATE_IDLE) -> void:
	if not _is_bound:
		visible = false
		return
	position = world_position
	_is_enemy = team_id == 1
	_visual_facing_sign = facing_sign if absf(facing_sign) > 0.0 else (-1.0 if _is_enemy else 1.0)
	_visual_motion_strength = clampf(absf(move_speed) / 2.0, 0.0, MAX_MOTION_STRENGTH)
	_visual_unit_state = unit_state
	_tick_pose_timers(0.016)
	if is_alive and unit_state == UNIT_STATE_ATTACK:
		_attack_frame_timer = maxf(_attack_frame_timer, ATTACK_STATE_HOLD)
	_is_showing_death_state = false
	visible = is_alive
	_update_visual_tint()
	_refresh_sprite_visuals()
	queue_redraw()
	if not is_alive:
		_attack_pulse_strength = 0.0
		_hit_pulse_strength = 0.0
		_attack_frame_timer = 0.0
		_hit_frame_timer = 0.0
		_visual_motion_strength = 0.0
		_visual_unit_state = UNIT_STATE_DEAD
		_refresh_sprite_visuals()
		queue_redraw()

func _tick_pose_timers(delta: float) -> void:
	if _attack_frame_timer > 0.0:
		_attack_frame_timer = maxf(_attack_frame_timer - delta, 0.0)
	else:
		_attack_pulse_strength = maxf(_attack_pulse_strength - delta * 0.8, 0.0)
	if _hit_frame_timer > 0.0:
		_hit_frame_timer = maxf(_hit_frame_timer - delta, 0.0)
	else:
		_hit_pulse_strength = maxf(_hit_pulse_strength - delta, 0.0)

func _is_showing_attack_pose() -> bool:
	return _visual_unit_state == UNIT_STATE_ATTACK or _attack_frame_timer > 0.0 or _attack_pulse_strength > 0.0

func _is_showing_hit_pose() -> bool:
	return _visual_unit_state != UNIT_STATE_DEAD and (_hit_frame_timer > 0.0 or _hit_pulse_strength > 0.0)

func _resolve_visual_state() -> int:
	if _visual_unit_state == UNIT_STATE_DEAD:
		return VISUAL_STATE_DEAD
	if _is_showing_hit_pose():
		return VISUAL_STATE_HIT
	if _is_showing_attack_pose():
		return VISUAL_STATE_ATTACK
	return VISUAL_STATE_IDLE

func _resolve_goose_body_texture(visual_state: int):
	return GOOSE_ATTACK_TEXTURE if visual_state == VISUAL_STATE_ATTACK else GOOSE_IDLE_TEXTURE

func _resolve_goose_overlay_texture(visual_state: int):
	return GOOSE_ATTACK_TEXTURE if visual_state == VISUAL_STATE_HIT else null

func _resolve_soldier_body_texture(visual_state: int):
	return SOLDIER_ATTACK_TEXTURE if visual_state == VISUAL_STATE_ATTACK else SOLDIER_IDLE_TEXTURE

func _resolve_body_rotation(visual_state: int) -> float:
	if _is_enemy:
		if visual_state == VISUAL_STATE_ATTACK:
			return GOOSE_ATTACK_POSE_ROTATION
		if visual_state == VISUAL_STATE_HIT:
			return GOOSE_HIT_POSE_ROTATION
		return 0.0
	if visual_state == VISUAL_STATE_ATTACK:
		return SOLDIER_ATTACK_POSE_ROTATION
	if visual_state == VISUAL_STATE_HIT:
		return SOLDIER_HIT_POSE_ROTATION
	return 0.0

func _resolve_body_offset(visual_state: int) -> Vector2:
	if _is_enemy:
		if visual_state == VISUAL_STATE_ATTACK:
			return GOOSE_ATTACK_POSE_OFFSET
		if visual_state == VISUAL_STATE_HIT:
			return GOOSE_HIT_POSE_OFFSET
		return Vector2.ZERO
	if visual_state == VISUAL_STATE_ATTACK:
		return SOLDIER_ATTACK_POSE_OFFSET
	return Vector2.ZERO

func _resolve_body_scale() -> Vector2:
	var base_scale := GOOSE_SCALE if _is_enemy else SOLDIER_SCALE
	var scale := base_scale * Vector2(-1.0 if _visual_facing_sign < 0.0 else 1.0, 1.0)
	var visual_state := _resolve_visual_state()
	if visual_state == VISUAL_STATE_ATTACK:
		scale *= Vector2(1.14, 0.94)
	elif visual_state == VISUAL_STATE_HIT:
		scale *= Vector2(0.96, 1.04)
	return scale

func _resolve_overlay_scale() -> Vector2:
	return GOOSE_SCALE * Vector2(-1.0 if _visual_facing_sign < 0.0 else 1.0, 1.0) * Vector2(1.05, 1.05)

func get_visual_facing_sign() -> float:
	return _visual_facing_sign

func get_visual_motion_strength() -> float:
	return clampf(_visual_motion_strength + _attack_pulse_strength + _hit_pulse_strength, 0.0, MAX_MOTION_STRENGTH + HIT_PULSE_BONUS)

func set_visual_motion(facing_sign: float, move_speed: float) -> void:
	_visual_facing_sign = facing_sign if absf(facing_sign) > 0.0 else _visual_facing_sign
	_visual_motion_strength = clampf(absf(move_speed) / 2.0, 0.0, MAX_MOTION_STRENGTH)
	_refresh_sprite_visuals()
	queue_redraw()

func trigger_attack_pulse() -> void:
	_attack_pulse_strength = ATTACK_PULSE_BONUS
	_attack_frame_timer = maxf(_attack_frame_timer, ATTACK_STATE_HOLD)
	_visual_unit_state = UNIT_STATE_ATTACK
	_refresh_sprite_visuals()
	queue_redraw()

func trigger_hit_pulse() -> void:
	_hit_pulse_strength = HIT_PULSE_BONUS
	_hit_frame_timer = maxf(_hit_frame_timer, HIT_STATE_HOLD)
	_refresh_sprite_visuals()
	queue_redraw()

func set_visual_unit_state(unit_state: int) -> void:
	_visual_unit_state = unit_state
	if unit_state == UNIT_STATE_ATTACK:
		_attack_frame_timer = maxf(_attack_frame_timer, ATTACK_STATE_HOLD)
	_refresh_sprite_visuals()
	queue_redraw()

func get_visual_unit_state() -> int:
	return _visual_unit_state

func is_showing_attack_pose() -> bool:
	return _is_showing_attack_pose()

func is_showing_hit_pose() -> bool:
	return _is_showing_hit_pose()

func get_current_body_rotation() -> float:
	var body: Sprite2D = get_node_or_null("BodySprite")
	return 0.0 if body == null else body.rotation

func get_current_body_offset() -> Vector2:
	var body: Sprite2D = get_node_or_null("BodySprite")
	return Vector2.ZERO if body == null else body.position

func get_current_body_texture():
	var body: Sprite2D = get_node_or_null("BodySprite")
	return null if body == null else body.texture

func get_current_overlay_texture():
	var overlay: Sprite2D = get_node_or_null("HitOverlay")
	return null if overlay == null else overlay.texture

func has_attack_pose_variation() -> bool:
	return _resolve_body_offset(VISUAL_STATE_ATTACK) != Vector2.ZERO or absf(_resolve_body_rotation(VISUAL_STATE_ATTACK)) > 0.01

func has_hit_pose_variation() -> bool:
	return _resolve_body_offset(VISUAL_STATE_HIT) != Vector2.ZERO or absf(_resolve_body_rotation(VISUAL_STATE_HIT)) > 0.01 or _resolve_goose_overlay_texture(VISUAL_STATE_HIT) != null

func force_attack_pose() -> void:
	trigger_attack_pulse()

func force_hit_pose() -> void:
	trigger_hit_pulse()

func clear_pose_state() -> void:
	_attack_frame_timer = 0.0
	_hit_frame_timer = 0.0
	_attack_pulse_strength = 0.0
	_hit_pulse_strength = 0.0
	_visual_unit_state = UNIT_STATE_IDLE
	_refresh_sprite_visuals()
	queue_redraw()

func get_attack_pose_hold() -> float:
	return _attack_frame_timer

func get_hit_pose_hold() -> float:
	return _hit_frame_timer

func set_visual_alive_state(is_alive: bool) -> void:
	_is_showing_death_state = not is_alive and _supports_death_feedback
	visible = is_alive or _is_showing_death_state
	_update_visual_tint()
	_refresh_sprite_visuals()
	queue_redraw()

func get_entity_id() -> int:
	return _entity_id

func is_bound() -> bool:
	return _is_bound

func can_reuse() -> bool:
	return not _is_bound

func apply_placeholder_style(is_enemy: bool) -> void:
	_is_enemy = is_enemy
	_visual_facing_sign = -1.0 if is_enemy else 1.0
	visible = _is_bound
	_update_visual_tint()
	_refresh_sprite_visuals()
	queue_redraw()

func enable_death_feedback(enabled: bool = true) -> void:
	_supports_death_feedback = enabled
	if not enabled:
		_is_showing_death_state = false
		visible = _is_bound
	_update_visual_tint()
	_refresh_sprite_visuals()

func is_death_feedback_enabled() -> bool:
	return _supports_death_feedback

func get_visual_radius() -> float:
	return VISUAL_RADIUS

func get_visual_tint() -> Color:
	return _visual_tint

func is_showing_death_state() -> bool:
	return _is_showing_death_state

func reset_for_pool() -> void:
	_entity_id = -1
	_is_bound = false
	_reset_visual_state()

func _ensure_sprite_nodes() -> void:
	if get_node_or_null("BodySprite") == null:
		var sprite := Sprite2D.new()
		sprite.name = "BodySprite"
		sprite.centered = true
		add_child(sprite)
	if get_node_or_null("HitOverlay") == null:
		var overlay := Sprite2D.new()
		overlay.name = "HitOverlay"
		overlay.centered = true
		overlay.visible = false
		add_child(overlay)

func _apply_body_pose(body: Sprite2D, offset: Vector2, rotation_value: float) -> void:
	var facing_scale := -1.0 if _visual_facing_sign < 0.0 else 1.0
	body.position = Vector2(offset.x * facing_scale, offset.y)
	body.rotation = rotation_value * facing_scale

func _refresh_sprite_visuals() -> void:
	var body: Sprite2D = get_node_or_null("BodySprite")
	var hit_overlay: Sprite2D = get_node_or_null("HitOverlay")
	if body == null or hit_overlay == null:
		return
	body.visible = visible and _is_bound
	hit_overlay.visible = false
	if not body.visible:
		return
	var visual_state := _resolve_visual_state()
	body.texture = _resolve_goose_body_texture(visual_state) if _is_enemy else _resolve_soldier_body_texture(visual_state)
	body.scale = _resolve_body_scale()
	body.modulate = Color.WHITE
	_apply_body_pose(body, _resolve_body_offset(visual_state), _resolve_body_rotation(visual_state))
	if _is_enemy:
		var overlay_texture = _resolve_goose_overlay_texture(visual_state)
		if overlay_texture != null:
			hit_overlay.texture = overlay_texture
			hit_overlay.scale = _resolve_overlay_scale()
			hit_overlay.position = body.position
			hit_overlay.rotation = body.rotation
			hit_overlay.modulate = Color(1.0, 1.0, 1.0, minf(1.0, 0.7 + _hit_pulse_strength))
			hit_overlay.visible = true
		else:
			hit_overlay.texture = null
	else:
		hit_overlay.texture = null
	if visual_state == VISUAL_STATE_IDLE:
		body.position = Vector2.ZERO
		body.rotation = 0.0
		body.scale = (_resolve_body_scale() / Vector2(1.14, 0.94)) if _resolve_body_scale() != Vector2.ZERO and (body.scale.x != 0.0 and body.scale.y != 0.0) and false else (GOOSE_SCALE if _is_enemy else SOLDIER_SCALE) * Vector2(-1.0 if _visual_facing_sign < 0.0 else 1.0, 1.0)
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hit_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if visual_state == VISUAL_STATE_DEAD:
		body.modulate = Color(1.0, 1.0, 1.0, DEAD_ALPHA)
		if hit_overlay.visible:
			hit_overlay.modulate.a *= DEAD_ALPHA
	_body_pose_offset = body.position
	_body_pose_rotation = body.rotation
	queue_redraw()

func _update_visual_tint() -> void:
	if not _is_bound:
		_visual_tint = UNBOUND_TINT
	else:
		_visual_tint = ENEMY_TINT if _is_enemy else BOUND_TINT
		if _is_showing_death_state:
			_visual_tint = Color(_visual_tint.r, _visual_tint.g, _visual_tint.b, DEAD_ALPHA)
	modulate = Color.WHITE
	queue_redraw()

func _reset_visual_state() -> void:
	visible = false
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	z_index = 0
	_is_enemy = false
	_is_showing_death_state = false
	_supports_death_feedback = false
	_visual_tint = UNBOUND_TINT
	_visual_facing_sign = 1.0
	_visual_motion_strength = 0.0
	_attack_pulse_strength = 0.0
	_hit_pulse_strength = 0.0
	_attack_frame_timer = 0.0
	_hit_frame_timer = 0.0
	_visual_unit_state = UNIT_STATE_IDLE
	_body_pose_offset = Vector2.ZERO
	_body_pose_rotation = 0.0
	modulate = Color.WHITE
	_refresh_sprite_visuals()
	queue_redraw()
