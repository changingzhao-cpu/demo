extends RefCounted
class_name CombatStateCore

const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func build_default_truth(entity_id: int) -> Dictionary:
	return {
		"entity_id": entity_id,
		"intent_state": Types.INTENT_STATE_IDLE,
		"target_id": -1,
		"contact_slot": -1,
		"attack_permission": false,
		"state_lock_until": 0.0
	}

func step_state(current_truth: Dictionary, inputs: Dictionary) -> Dictionary:
	var next_truth := current_truth.duplicate(true)
	var time_now := float(inputs.get("time", 0.0))
	var has_target := bool(inputs.get("has_target", false))
	var is_in_contact := bool(inputs.get("is_in_contact", false))
	var slot_assignment := int(inputs.get("slot_assignment", -1))
	var attack_permission := bool(inputs.get("attack_permission", false))
	if not has_target:
		next_truth.intent_state = Types.INTENT_STATE_IDLE
		next_truth.target_id = -1
		next_truth.contact_slot = -1
		next_truth.attack_permission = false
		return next_truth
	if int(next_truth.intent_state) == Types.INTENT_STATE_ATTACK and time_now < float(next_truth.state_lock_until):
		next_truth.attack_permission = true
		return next_truth
	if is_in_contact and slot_assignment != -1 and not attack_permission:
		next_truth.intent_state = Types.INTENT_STATE_CONTACT
		next_truth.contact_slot = slot_assignment
		next_truth.attack_permission = false
		return next_truth
	if is_in_contact and slot_assignment != -1 and attack_permission:
		next_truth.intent_state = Types.INTENT_STATE_ATTACK
		next_truth.contact_slot = slot_assignment
		next_truth.attack_permission = true
		next_truth.state_lock_until = time_now + Types.ATTACK_LOCK_SECONDS
		return next_truth
	if is_in_contact:
		next_truth.intent_state = Types.INTENT_STATE_CONTACT
		return next_truth
	next_truth.intent_state = Types.INTENT_STATE_APPROACH
	return next_truth
