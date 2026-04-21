extends RefCounted
class_name BattleSimulationV3

const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")
const CombatStateCore = preload("res://scripts/battle/combat_state_core.gd")
const ContactResolver = preload("res://scripts/battle/contact_resolver.gd")
const MotionResolver = preload("res://scripts/battle/motion_resolver.gd")

var _grid
var _core := CombatStateCore.new()
var _contact := ContactResolver.new()
var _motion := MotionResolver.new()
var _elapsed := 0.0

func _init(grid) -> void:
	_grid = grid

func tick_bucket(store, delta: float, bucket_id: int, bucket_count: int) -> void:
	_elapsed += delta
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		if int(store.bucket_id[entity_id]) != bucket_id:
			continue
		_tick_entity(store, entity_id, delta)

func _tick_entity(store, entity_id: int, delta: float) -> void:
	var target_id := _find_target(store, entity_id)
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var contact_result := {
		"distance_band": "none",
		"slot_assignment": -1,
		"is_in_contact": false,
		"contact_anchor": origin,
		"should_reposition": false
	}
	if target_id != -1:
		var occupied_slots: Array = []
		if int(store.contact_slot[entity_id]) >= 0:
			occupied_slots.append(int(store.contact_slot[entity_id]))
		contact_result = _contact.resolve({
			"entity_id": entity_id,
			"origin": origin,
			"target_id": target_id,
			"target_position": Vector2(store.position_x[target_id], store.position_y[target_id]),
			"occupied_slots": occupied_slots,
			"contact_distance": 1.2
		})
	var current_truth := _core.build_default_truth(entity_id)
	current_truth.intent_state = int(store.intent_state[entity_id])
	current_truth.target_id = target_id
	current_truth.contact_slot = int(store.contact_slot[entity_id])
	current_truth.attack_permission = bool(store.attack_permission[entity_id])
	current_truth.state_lock_until = float(store.state_lock_until[entity_id])
	var is_in_contact := bool(contact_result.get("is_in_contact", false))
	var slot_assignment := int(contact_result.get("slot_assignment", -1))
	var next_truth: Dictionary = _core.step_state(current_truth, {
		"has_target": target_id != -1,
		"is_in_contact": is_in_contact,
		"slot_assignment": slot_assignment,
		"attack_permission": false,
		"time": _elapsed
	})
	if is_in_contact and slot_assignment != -1 and int(current_truth.intent_state) == Types.INTENT_STATE_CONTACT:
		next_truth = _core.step_state(current_truth, {
			"has_target": true,
			"is_in_contact": true,
			"slot_assignment": slot_assignment,
			"attack_permission": true,
			"time": _elapsed
		})
	elif is_in_contact and slot_assignment != -1 and int(current_truth.intent_state) == Types.INTENT_STATE_APPROACH:
		next_truth.intent_state = Types.INTENT_STATE_CONTACT
		next_truth.contact_slot = slot_assignment
		next_truth.attack_permission = false
	elif target_id != -1 and int(current_truth.intent_state) == Types.INTENT_STATE_IDLE:
		next_truth.intent_state = Types.INTENT_STATE_APPROACH
		next_truth.contact_slot = -1
		next_truth.attack_permission = false
	elif not is_in_contact:
		next_truth.contact_slot = -1
		next_truth.attack_permission = false
		next_truth.intent_state = Types.INTENT_STATE_APPROACH
	if is_in_contact and slot_assignment != -1 and int(next_truth.intent_state) == Types.INTENT_STATE_APPROACH:
		next_truth.intent_state = Types.INTENT_STATE_CONTACT
		next_truth.contact_slot = slot_assignment
		next_truth.attack_permission = false
	if is_in_contact and slot_assignment != -1 and int(next_truth.intent_state) == Types.INTENT_STATE_CONTACT and int(current_truth.intent_state) == Types.INTENT_STATE_CONTACT:
		next_truth.intent_state = Types.INTENT_STATE_ATTACK
		next_truth.contact_slot = slot_assignment
		next_truth.attack_permission = true
		next_truth.state_lock_until = _elapsed + Types.ATTACK_LOCK_SECONDS
	store.target_id[entity_id] = target_id
	store.state[entity_id] = slot_assignment
	store.intent_state[entity_id] = int(next_truth.get("intent_state", Types.INTENT_STATE_IDLE))
	store.contact_slot[entity_id] = int(next_truth.get("contact_slot", -1))
	store.attack_permission[entity_id] = 1 if bool(contact_result.get("is_in_contact", false)) else 0
	store.state_lock_until[entity_id] = float(next_truth.get("state_lock_until", 0.0))
	var motion: Dictionary = _motion.resolve({
		"intent_state": int(next_truth.get("intent_state", Types.INTENT_STATE_IDLE)),
		"position": origin,
		"contact_anchor": contact_result.get("contact_anchor", origin),
		"move_speed": float(store.move_speed[entity_id]),
		"delta": delta
	})
	var next_position: Vector2 = motion.get("next_position", origin)
	var velocity: Vector2 = motion.get("velocity", Vector2.ZERO)
	store.position_x[entity_id] = next_position.x
	store.position_y[entity_id] = next_position.y
	store.velocity_x[entity_id] = velocity.x
	store.velocity_y[entity_id] = velocity.y
	_grid.upsert(entity_id, next_position)

func _find_target(store, entity_id: int) -> int:
	for candidate in range(store.capacity):
		if candidate == entity_id:
			continue
		if not store.alive[candidate]:
			continue
		if store.team_id[candidate] == store.team_id[entity_id]:
			continue
		return candidate
	return -1
