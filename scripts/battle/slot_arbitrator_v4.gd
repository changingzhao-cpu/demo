extends RefCounted
class_name SlotArbitratorV4

const SlotAssignment = preload("res://scripts/battle/slot_assignment.gd")

static func resolve(intents: Array, target_positions: Dictionary) -> Dictionary:
	var grouped := {}
	for intent_variant in intents:
		var intent = intent_variant
		if intent == null:
			continue
		if int(intent.target_id) == -1:
			continue
		var key := "%s:%s" % [str(intent.target_id), str(intent.desired_slot_index)]
		if not grouped.has(key):
			grouped[key] = []
		grouped[key].append(intent)
	var assignments := {}
	for key in grouped.keys():
		var contenders: Array = grouped[key]
		contenders.sort_custom(func(a, b): return float(a.priority_weight) > float(b.priority_weight) or (is_equal_approx(float(a.priority_weight), float(b.priority_weight)) and int(a.entity_id) < int(b.entity_id)))
		for index in range(contenders.size()):
			var intent = contenders[index]
			var assignment := SlotAssignment.new()
			assignment.target_id = int(intent.target_id)
			assignment.global_pos = target_positions.get(int(intent.target_id), Vector2.ZERO)
			if index == 0:
				assignment.assigned_slot_index = int(intent.desired_slot_index)
				assignment.status = SlotAssignment.STATUS_SUCCESS
			else:
				assignment.assigned_slot_index = -1
				assignment.status = SlotAssignment.STATUS_WAITING
			assignments[int(intent.entity_id)] = assignment
	return assignments
