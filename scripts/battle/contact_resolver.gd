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
	var direction := (origin - target_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	return {
		"distance_band": "contact" if distance <= contact_distance else "approach",
		"slot_assignment": slot_assignment,
		"is_in_contact": distance <= contact_distance and slot_assignment != -1,
		"contact_anchor": target_position + direction * contact_distance,
		"should_reposition": distance <= contact_distance and slot_assignment == -1
	}
