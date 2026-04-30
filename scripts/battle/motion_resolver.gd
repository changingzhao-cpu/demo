extends RefCounted
class_name MotionResolver

const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func resolve(input: Dictionary) -> Dictionary:
	var position: Vector2 = input.get("position", Vector2.ZERO)
	var anchor: Vector2 = input.get("contact_anchor", position)
	var move_speed := float(input.get("move_speed", 0.0))
	var delta := float(input.get("delta", 0.0))
	var intent_state := int(input.get("intent_state", Types.INTENT_STATE_IDLE))
	if intent_state == Types.INTENT_STATE_ATTACK or intent_state == Types.INTENT_STATE_IDLE:
		return {"next_position": position, "velocity": Vector2.ZERO}
	var direction := (anchor - position).normalized()
	var step := minf(position.distance_to(anchor), move_speed * delta)
	var movement := direction * step
	if intent_state == Types.INTENT_STATE_CONTACT:
		movement *= 0.5
	if intent_state == Types.INTENT_STATE_RECOVER:
		movement *= 0.75
	return {
		"next_position": position + movement,
		"velocity": movement / maxf(delta, 0.0001)
	}
