extends RefCounted
class_name ContactResolver

func resolve_with_target_slots(input: Dictionary) -> Dictionary:
	var occupied_slots_by_target: Dictionary = input.get("occupied_slots_by_target", {})
	var target_id := int(input.get("target_id", -1))
	var occupied_slots: Array = occupied_slots_by_target.get(target_id, [])
	var next_input := input.duplicate(true)
	next_input.occupied_slots = occupied_slots
	return resolve(next_input)

func resolve(input: Dictionary) -> Dictionary:
	var origin: Vector2 = input.get("origin", Vector2.ZERO)
	var target_position: Vector2 = input.get("target_position", Vector2.ZERO)
	var occupied_slots: Array = input.get("occupied_slots", [])
	var contact_distance := float(input.get("contact_distance", 1.2))
	var distance := origin.distance_to(target_position)
	var slot_assignment := -1
	for slot_index in range(3):
		if not occupied_slots.has(slot_index):
			slot_assignment = slot_index
			break
	var direction := (target_position - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var is_within_contact := distance <= contact_distance + 0.001
	return {
		"distance_band": "contact" if is_within_contact else "approach",
		"slot_assignment": slot_assignment,
		"is_in_contact": is_within_contact and slot_assignment != -1,
		"contact_anchor": target_position - direction * contact_distance,
		"should_reposition": is_within_contact and slot_assignment == -1
	}
