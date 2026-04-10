extends Node2D
class_name UnitView

const BOUND_TINT := Color(0.45, 0.85, 1.0, 1.0)
const ENEMY_TINT := Color(0.95, 0.4, 0.4, 1.0)
const UNBOUND_TINT := Color(0.4, 0.4, 0.4, 0.4)
const DEAD_ALPHA := 0.35
const VISUAL_RADIUS := 3.2
const MAX_MOTION_STRENGTH := 1.0
const ATTACK_PULSE_BONUS := 0.28
const HIT_PULSE_BONUS := 0.4

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
	var flash_tint := _visual_tint.lerp(Color.WHITE, minf(0.42, pulse_strength))
	if _is_enemy:
		_draw_enemy_goose_silhouette(readable_motion, flash_tint)
	else:
		_draw_ally_fighter_silhouette(readable_motion, flash_tint)
	if _hit_pulse_strength > 0.0:
		var hit_center := Vector2(_visual_facing_sign * 1.5, -0.7)
		draw_arc(hit_center, VISUAL_RADIUS + 0.55, -0.9, 0.9, 12, Color(1.0, 0.98, 0.9, minf(0.52, _hit_pulse_strength)), 1.1)
	if _is_showing_death_state:
		draw_line(Vector2(-VISUAL_RADIUS - 0.7, -VISUAL_RADIUS - 0.5), Vector2(VISUAL_RADIUS + 0.7, VISUAL_RADIUS + 0.5), Color(1.0, 1.0, 1.0, _visual_tint.a * 0.55), 1.2)
		draw_line(Vector2(-VISUAL_RADIUS - 0.7, VISUAL_RADIUS + 0.5), Vector2(VISUAL_RADIUS + 0.7, -VISUAL_RADIUS - 0.5), Color(1.0, 1.0, 1.0, _visual_tint.a * 0.55), 1.2)

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

func _draw_ally_fighter_silhouette(readable_motion: float, flash_tint: Color) -> void:
	var body_color := flash_tint
	var head_color := flash_tint.lerp(Color.WHITE, 0.2)
	var cape_color := Color(0.18, 0.24, 0.35, flash_tint.a * 0.72)
	var stance_shift := Vector2(_visual_facing_sign * (0.25 + readable_motion * 0.45), sin(readable_motion * PI) * 0.22)
	var body_points := PackedVector2Array([
		Vector2(-1.2, -0.7) + stance_shift,
		Vector2(1.0, -1.05) + stance_shift,
		Vector2(1.45, 0.85) + stance_shift,
		Vector2(-0.85, 1.25) + stance_shift
	])
	var cape_points := PackedVector2Array([
		Vector2(-1.35, -0.55) + stance_shift,
		Vector2(-2.45, 0.35) + stance_shift,
		Vector2(-1.65, 1.35) + stance_shift,
		Vector2(-0.35, 0.55) + stance_shift
	])
	draw_colored_polygon(cape_points, cape_color)
	draw_colored_polygon(body_points, body_color)
	draw_circle(Vector2(0.2, -2.0) + stance_shift, 0.82, head_color)
	var weapon_start := Vector2(0.95, -0.15) + stance_shift
	var weapon_tip := weapon_start + Vector2(_visual_facing_sign * (2.15 + _attack_pulse_strength * 1.2), -0.5)
	draw_line(weapon_start, weapon_tip, Color(1.0, 0.95, 0.78, flash_tint.a * 0.92), 1.0)
	draw_circle(weapon_tip, 0.36 + _attack_pulse_strength * 0.3, Color(1.0, 0.96, 0.86, flash_tint.a * 0.82))
	draw_line(Vector2(-0.35, 1.05) + stance_shift, Vector2(-0.9, 2.8) + stance_shift, Color(0.16, 0.18, 0.22, flash_tint.a * 0.9), 0.95)
	draw_line(Vector2(0.65, 1.0) + stance_shift, Vector2(1.15, 2.9) + stance_shift, Color(0.16, 0.18, 0.22, flash_tint.a * 0.9), 0.95)

func _draw_enemy_goose_silhouette(readable_motion: float, flash_tint: Color) -> void:
	var body_color := flash_tint.lerp(Color.WHITE, 0.08)
	var wing_color := Color(1.0, 1.0, 1.0, flash_tint.a * 0.88)
	var beak_color := Color(1.0, 0.75, 0.36, flash_tint.a * 0.95)
	var lunge_shift := Vector2(_visual_facing_sign * (0.3 + readable_motion * 0.55), -0.05)
	_draw_ellipse(Vector2.ZERO + lunge_shift, Vector2(2.15, 1.55), body_color)
	_draw_ellipse(Vector2(-0.55 * _visual_facing_sign, -0.05) + lunge_shift, Vector2(1.35, 0.95), wing_color)
	var neck_points := PackedVector2Array([
		Vector2(0.8 * _visual_facing_sign, -0.5) + lunge_shift,
		Vector2(1.6 * _visual_facing_sign, -1.8) + lunge_shift,
		Vector2(2.0 * _visual_facing_sign, -1.45) + lunge_shift,
		Vector2(1.25 * _visual_facing_sign, -0.25) + lunge_shift
	])
	draw_colored_polygon(neck_points, wing_color)
	draw_circle(Vector2(2.15 * _visual_facing_sign, -1.7) + lunge_shift, 0.58, wing_color)
	var beak := PackedVector2Array([
		Vector2(2.55 * _visual_facing_sign, -1.72) + lunge_shift,
		Vector2(3.45 * _visual_facing_sign, -1.55 - _attack_pulse_strength * 0.25) + lunge_shift,
		Vector2(2.75 * _visual_facing_sign, -1.2) + lunge_shift
	])
	draw_colored_polygon(beak, beak_color)
	draw_line(Vector2(-0.7, 0.95) + lunge_shift, Vector2(-1.15, 2.5) + lunge_shift, Color(0.4, 0.22, 0.1, flash_tint.a * 0.82), 0.85)
	draw_line(Vector2(0.4, 0.95) + lunge_shift, Vector2(0.0, 2.55) + lunge_shift, Color(0.4, 0.22, 0.1, flash_tint.a * 0.82), 0.85)
	if _attack_pulse_strength > 0.0:
		draw_arc(Vector2(2.0 * _visual_facing_sign, -1.55) + lunge_shift, 1.0 + _attack_pulse_strength * 0.35, -0.65, 0.65, 10, Color(1.0, 0.95, 0.88, 0.36), 0.9)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in range(20):
		var angle := TAU * float(step) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

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
