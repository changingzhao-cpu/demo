extends RefCounted
class_name ContactResolver

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
