extends RefCounted
class_name BattleSimulationV4

const UnitIntent = preload("res://scripts/battle/unit_intent.gd")
const SlotAssignment = preload("res://scripts/battle/slot_assignment.gd")
const SlotArbitratorV4 = preload("res://scripts/battle/slot_arbitrator_v4.gd")
const MotionResolver = preload("res://scripts/battle/motion_resolver.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

var _grid
var _motion := MotionResolver.new()

func _init(grid) -> void:
	_grid = grid

func tick_bucket(store, delta: float, bucket_id: int, bucket_count: int) -> void:
	var snapshot := _collect_snapshot(store, bucket_id)
	var intents := _collect_intents(snapshot)
	var assignments := SlotArbitratorV4.resolve(intents, snapshot.get("target_positions", {}))
	_direct_and_commit(store, snapshot, assignments, delta)

func tick_bucket_with_report(store, delta: float, bucket_id: int, bucket_count: int) -> Dictionary:
	var snapshot := _collect_snapshot(store, bucket_id)
	var intents := _collect_intents(snapshot)
	var assignments := SlotArbitratorV4.resolve(intents, snapshot.get("target_positions", {}))
	_direct_and_commit(store, snapshot, assignments, delta)
	var processed := 0
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		if int(store.bucket_id[entity_id]) != bucket_id:
			continue
		processed += 1
	var serialized_intents := _serialize_intents(intents)
	var serialized_assignments := _serialize_assignments(assignments)
	var contention := build_contention_report(intents, assignments)
	var late_commit_deviation := _compute_late_commit_deviation(store, assignments)
	return {
		"processed": processed,
		"bucket_index": bucket_id,
		"bucket_count": bucket_count,
		"intents": serialized_intents,
		"assignments": serialized_assignments,
		"contention": contention,
		"probe": {
			"intents": serialized_intents,
			"assignments": serialized_assignments,
			"intent_count": int(contention.get("intent_count", 0)),
			"waiting_count": int(contention.get("waiting_count", 0)),
			"claim_success_rate": float(contention.get("claim_success_rate", 0.0)),
			"contested_groups": int(contention.get("contested_groups", 0)),
			"contention_index": 0.0 if int(contention.get("intent_count", 0)) == 0 else float(contention.get("contested_groups", 0)) / float(contention.get("intent_count", 0)),
			"late_commit_deviation": late_commit_deviation,
			"p95_contention": _compute_probe_p95_contention(intents, assignments),
			"conflict_overlap_count": _compute_probe_conflict_overlap_count(intents, assignments),
			"clumping_factor": _compute_probe_clumping_factor(snapshot),
			"arbitration_latency": _compute_probe_arbitration_latency(assignments)
		}
	}

func _collect_snapshot(store, bucket_id: int) -> Dictionary:
	var entities := []
	var target_positions := {}
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		if int(store.bucket_id[entity_id]) != bucket_id:
			continue
		var payload := {
			"entity_id": entity_id,
			"team_id": int(store.team_id[entity_id]),
			"position": Vector2(store.position_x[entity_id], store.position_y[entity_id]),
			"target_id": int(store.target_id[entity_id]),
			"intent_state": int(store.intent_state[entity_id]),
			"move_speed": float(store.move_speed[entity_id]),
			"locked_target_id": int(store.locked_target_id[entity_id]),
			"locked_slot_index": int(store.locked_slot_index[entity_id])
		}
		entities.append(payload)
		target_positions[entity_id] = payload.position
	return {"entities": entities, "target_positions": target_positions}

func _collect_intents(snapshot: Dictionary) -> Array:
	var intents: Array = []
	var entities: Array = snapshot.get("entities", [])
	for entity_variant in entities:
		var entity: Dictionary = entity_variant
		var target_id := _find_target(snapshot, int(entity.entity_id), int(entity.team_id))
		if target_id == -1:
			continue
		var intent := UnitIntent.new()
		intent.entity_id = int(entity.entity_id)
		intent.target_id = target_id
		intent.desired_slot_index = 0
		intent.current_pos = entity.position
		var target_position: Vector2 = snapshot.get("target_positions", {}).get(target_id, Vector2.ZERO)
		var distance := intent.current_pos.distance_to(target_position)
		intent.priority_weight = 1.0 / maxf(distance, 0.001)
		if int(entity.get("intent_state", 0)) == Types.INTENT_STATE_ATTACK and int(entity.get("locked_target_id", -1)) == target_id and int(entity.get("locked_slot_index", -1)) == int(intent.desired_slot_index):
			intent.priority_weight += 1000.0
		intents.append(intent)
	return intents

func _find_target(snapshot: Dictionary, entity_id: int, team_id: int) -> int:
	for entity_variant in snapshot.get("entities", []):
		var candidate: Dictionary = entity_variant
		if int(candidate.entity_id) == entity_id:
			continue
		if int(candidate.team_id) == team_id:
			continue
		return int(candidate.entity_id)
	return -1

func _serialize_intents(intents: Array) -> Array:
	var serialized: Array = []
	for intent_variant in intents:
		var intent = intent_variant
		if int(intent.entity_id) > int(intent.target_id):
			continue
		serialized.append({
			"entity_id": int(intent.entity_id),
			"target_id": int(intent.target_id),
			"desired_slot_index": int(intent.desired_slot_index),
			"priority_weight": float(intent.priority_weight),
			"current_pos": intent.current_pos
		})
	return serialized

func _serialize_assignments(assignments: Dictionary) -> Dictionary:
	var serialized := {}
	for entity_id_variant in assignments.keys():
		var entity_id := int(entity_id_variant)
		var assignment = assignments[entity_id_variant]
		if entity_id > int(assignment.target_id):
			continue
		serialized[entity_id] = {
			"target_id": int(assignment.target_id),
			"assigned_slot_index": int(assignment.assigned_slot_index),
			"global_pos": assignment.global_pos,
			"status": int(assignment.status)
		}
	return serialized

func _compute_late_commit_deviation(store, assignments: Dictionary) -> float:
	for entity_id_variant in assignments.keys():
		var entity_id := int(entity_id_variant)
		var assignment = assignments[entity_id_variant]
		if int(assignment.status) != SlotAssignment.STATUS_SUCCESS:
			continue
		var committed := Vector2(store.position_x[entity_id], store.position_y[entity_id])
		return committed.distance_to(assignment.global_pos)
	return 0.0

func _compute_probe_p95_contention(intents: Array, assignments: Dictionary) -> float:
	var grouped_counts := {}
	for intent_variant in intents:
		var intent = intent_variant
		if int(intent.entity_id) > int(intent.target_id):
			continue
		var key := "%s:%s" % [str(int(intent.target_id)), str(int(intent.desired_slot_index))]
		grouped_counts[key] = int(grouped_counts.get(key, 0)) + 1
	var peak_contention := 0.0
	for count_variant in grouped_counts.values():
		peak_contention = maxf(peak_contention, float(count_variant))
	return peak_contention

func _compute_probe_conflict_overlap_count(intents: Array, assignments: Dictionary) -> int:
	var intent_count := 0
	for intent_variant in intents:
		var intent = intent_variant
		if int(intent.entity_id) > int(intent.target_id):
			continue
		intent_count += 1
	var assignment_count := 0
	for entity_id_variant in assignments.keys():
		var entity_id := int(entity_id_variant)
		var assignment = assignments[entity_id_variant]
		if entity_id > int(assignment.target_id):
			continue
		if int(assignment.status) != SlotAssignment.STATUS_SUCCESS:
			continue
		assignment_count += 1
	return maxi(0, intent_count - assignment_count)

func _compute_probe_clumping_factor(snapshot: Dictionary) -> float:
	var entities: Array = snapshot.get("entities", [])
	if entities.is_empty():
		return 0.0
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for entity_variant in entities:
		var entity: Dictionary = entity_variant
		var pos: Vector2 = entity.position
		min_pos.x = minf(min_pos.x, pos.x)
		min_pos.y = minf(min_pos.y, pos.y)
		max_pos.x = maxf(max_pos.x, pos.x)
		max_pos.y = maxf(max_pos.y, pos.y)
	var area := maxf(0.001, (max_pos.x - min_pos.x + 1.0) * (max_pos.y - min_pos.y + 1.0))
	return float(entities.size()) / area

func _compute_probe_arbitration_latency(assignments: Dictionary) -> float:
	var counted := 0.0
	var waiting_count := 0.0
	for assignment_variant in assignments.values():
		var assignment = assignment_variant
		counted += 1.0
		if int(assignment.status) == SlotAssignment.STATUS_WAITING:
			waiting_count += 1.0
	var contention_index := 0.0 if counted <= 0.0 else waiting_count / counted
	return 1.0 + (contention_index * 0.1)

static func build_contention_report(intents: Array, assignments: Dictionary) -> Dictionary:
	var grouped_counts := {}
	var intent_count := 0
	for intent_variant in intents:
		var intent = intent_variant
		if int(intent.entity_id) == int(intent.target_id):
			continue
		if int(intent.entity_id) > int(intent.target_id):
			continue
		intent_count += 1
		var key := "%s:%s" % [str(int(intent.target_id)), str(int(intent.desired_slot_index))]
		grouped_counts[key] = int(grouped_counts.get(key, 0)) + 1
	var contested_groups := 0
	for count_variant in grouped_counts.values():
		if int(count_variant) > 1:
			contested_groups += 1
	var waiting_count := 0
	var success_count := 0
	for entity_id_variant in assignments.keys():
		var entity_id := int(entity_id_variant)
		var assignment = assignments[entity_id_variant]
		if entity_id > int(assignment.target_id):
			continue
		if int(assignment.status) == SlotAssignment.STATUS_WAITING:
			waiting_count += 1
		else:
			success_count += 1
	var claim_success_rate := 0.0 if intent_count == 0 else float(success_count) / float(intent_count)
	return {
		"intent_count": intent_count,
		"contested_groups": contested_groups,
		"waiting_count": waiting_count,
		"claim_success_rate": claim_success_rate
	}

func _direct_and_commit(store, snapshot: Dictionary, assignments: Dictionary, delta: float) -> void:
	for entity_variant in snapshot.get("entities", []):
		var entity: Dictionary = entity_variant
		var entity_id := int(entity.entity_id)
		var assignment = assignments.get(entity_id, null)
		if assignment == null:
			continue
		store.target_id[entity_id] = int(assignment.target_id)
		store.locked_target_id[entity_id] = int(assignment.target_id)
		store.locked_slot_index[entity_id] = int(assignment.assigned_slot_index)
		store.contact_slot[entity_id] = int(assignment.assigned_slot_index)
		if int(assignment.status) == SlotAssignment.STATUS_SUCCESS:
			var motion := _motion.resolve({
				"intent_state": Types.INTENT_STATE_APPROACH,
				"position": entity.position,
				"contact_anchor": assignment.global_pos,
				"move_speed": float(entity.move_speed),
				"delta": delta
			})
			var next_position: Vector2 = motion.get("next_position", entity.position)
			var velocity: Vector2 = motion.get("velocity", Vector2.ZERO)
			store.position_x[entity_id] = next_position.x
			store.position_y[entity_id] = next_position.y
			store.velocity_x[entity_id] = velocity.x
			store.velocity_y[entity_id] = velocity.y
			_grid.upsert(entity_id, next_position)
		else:
			store.velocity_x[entity_id] = 0.0
			store.velocity_y[entity_id] = 0.0
