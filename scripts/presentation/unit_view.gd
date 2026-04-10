extends Node2D
class_name UnitView

const BOUND_TINT := Color(0.45, 0.85, 1.0, 1.0)
const ENEMY_TINT := Color(0.95, 0.4, 0.4, 1.0)
const UNBOUND_TINT := Color(0.4, 0.4, 0.4, 0.4)
const DEAD_ALPHA := 0.35
const VISUAL_RADIUS := 7.5
const MAX_MOTION_STRENGTH := 1.0
const ATTACK_PULSE_BONUS := 0.35
const HIT_PULSE_BONUS := 0.45

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

func _init() -> void:
	_reset_visual_state()

func _draw() -> void:
	if not visible:
		return
	var pulse_strength := _attack_pulse_strength + _hit_pulse_strength
	var readable_motion := clampf(_visual_motion_strength + pulse_strength, 0.0, MAX_MOTION_STRENGTH + HIT_PULSE_BONUS)
	var body_radius := VISUAL_RADIUS * (1.0 + readable_motion * 0.18)
	var ring_radius := body_radius + 2.5 + readable_motion
	var trail_offset := Vector2(-_visual_facing_sign * (2.0 + readable_motion * 3.0), 0.0)
	var trail_tint := Color(_visual_tint.r, _visual_tint.g, _visual_tint.b, _visual_tint.a * (0.16 + readable_motion * 0.28))
	var facing_tip := Vector2(_visual_facing_sign * (body_radius + 3.5 + _attack_pulse_strength), 0.0)
	var flash_tint := _visual_tint.lerp(Color.WHITE, minf(0.45, pulse_strength))
	draw_circle(trail_offset, body_radius * max(0.55, 1.0 - readable_motion * 0.22), trail_tint)
	draw_circle(Vector2.ZERO, body_radius, flash_tint)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, _visual_tint.a * (0.28 + readable_motion * 0.24)), 2.0)
	draw_line(Vector2.ZERO, facing_tip, Color(1.0, 1.0, 1.0, _visual_tint.a * (0.72 + _attack_pulse_strength * 0.3)), 2.0)
	draw_circle(facing_tip, 1.8 + readable_motion, Color(1.0, 1.0, 1.0, _visual_tint.a * 0.92))
	if _hit_pulse_strength > 0.0:
		draw_arc(Vector2.ZERO, ring_radius + 2.5, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, minf(0.6, _hit_pulse_strength)), 2.0)
	if _is_showing_death_state:
		draw_arc(Vector2.ZERO, ring_radius + 3.0, PI * 0.2, PI * 0.8, 12, Color(1.0, 1.0, 1.0, _visual_tint.a * 0.65), 2.0)
		draw_arc(Vector2.ZERO, ring_radius + 3.0, PI * 1.2, PI * 1.8, 12, Color(1.0, 1.0, 1.0, _visual_tint.a * 0.65), 2.0)

func bind_entity(entity_id: int) -> void:
	_entity_id = entity_id
	_is_bound = true
	_is_showing_death_state = false
	_supports_death_feedback = false
	visible = true
	_update_visual_tint()

func unbind_entity() -> void:
	_entity_id = -1
	_is_bound = false
	_reset_visual_state()

func sync_from_entity(world_position: Vector2, is_alive: bool) -> void:
	sync_from_entity_visual(world_position, is_alive, 1 if _is_enemy else 0, _visual_motion_strength, _visual_facing_sign)

func sync_from_entity_visual(world_position: Vector2, is_alive: bool, team_id: int, move_speed: float, facing_sign: float) -> void:
	if not _is_bound:
		visible = false
		return
	position = world_position
	_is_enemy = team_id == 1
	_visual_facing_sign = facing_sign if absf(facing_sign) > 0.0 else (-1.0 if _is_enemy else 1.0)
	_visual_motion_strength = clampf(absf(move_speed) / 2.0, 0.0, MAX_MOTION_STRENGTH)
	if _visual_motion_strength > 0.0:
		_attack_pulse_strength = maxf(_attack_pulse_strength - 0.04, 0.0)
		_hit_pulse_strength = maxf(_hit_pulse_strength - 0.05, 0.0)
	_is_showing_death_state = not is_alive and _supports_death_feedback
	visible = is_alive or _is_showing_death_state
	_update_visual_tint()
	queue_redraw()

func get_visual_facing_sign() -> float:
	return _visual_facing_sign

func get_visual_motion_strength() -> float:
	return clampf(_visual_motion_strength + _attack_pulse_strength + _hit_pulse_strength, 0.0, MAX_MOTION_STRENGTH + HIT_PULSE_BONUS)

func set_visual_motion(facing_sign: float, move_speed: float) -> void:
	_visual_facing_sign = facing_sign if absf(facing_sign) > 0.0 else _visual_facing_sign
	_visual_motion_strength = clampf(absf(move_speed) / 2.0, 0.0, MAX_MOTION_STRENGTH)
	_attack_pulse_strength = maxf(_attack_pulse_strength - 0.04, 0.0)
	_hit_pulse_strength = maxf(_hit_pulse_strength - 0.05, 0.0)
	queue_redraw()

func trigger_attack_pulse() -> void:
	_attack_pulse_strength = ATTACK_PULSE_BONUS
	queue_redraw()

func trigger_hit_pulse() -> void:
	_hit_pulse_strength = HIT_PULSE_BONUS
	queue_redraw()

func set_visual_alive_state(is_alive: bool) -> void:
	_is_showing_death_state = not is_alive and _supports_death_feedback
	visible = is_alive or _is_showing_death_state
	_update_visual_tint()
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
	queue_redraw()

func enable_death_feedback(enabled: bool = true) -> void:
	_supports_death_feedback = enabled
	if not enabled:
		_is_showing_death_state = false
		visible = _is_bound
	_update_visual_tint()

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
	modulate = Color.WHITE
	queue_redraw()
