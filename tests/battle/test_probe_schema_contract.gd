extends RefCounted

const BattleSimulationV4 = preload("res://scripts/battle/battle_simulation_v4.gd")
const SlotAssignment = preload("res://scripts/battle/slot_assignment.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	var intents := [
		{
			"entity_id": 1,
			"target_id": 100,
			"desired_slot_index": 0,
			"priority_weight": 1.0,
			"current_pos": Vector2(0, 0)
		},
		{
			"entity_id": 2,
			"target_id": 100,
			"desired_slot_index": 0,
			"priority_weight": 0.8,
			"current_pos": Vector2(1, 0)
		}
	]
	var assignments := {
		1: {
			"target_id": 100,
			"assigned_slot_index": 0,
			"global_pos": Vector2(4, 0),
			"status": SlotAssignment.STATUS_SUCCESS
		},
		2: {
			"target_id": 100,
			"assigned_slot_index": -1,
			"global_pos": Vector2(4, 0),
			"status": SlotAssignment.STATUS_WAITING
		}
	}
	var snapshot := {
		"entities": [
			{"entity_id": 1, "position": Vector2(0, 0)},
			{"entity_id": 2, "position": Vector2(1, 0)},
			{"entity_id": 100, "position": Vector2(4, 0)}
		]
	}
	var runtime := BattleSimulationV4.new(null)
	var schema := {
		"p95_contention": runtime._compute_probe_p95_contention(intents, assignments),
		"conflict_overlap_count": runtime._compute_probe_conflict_overlap_count(intents, assignments),
		"clumping_factor": runtime._compute_probe_clumping_factor(snapshot),
		"arbitration_latency": runtime._compute_probe_arbitration_latency(assignments)
	}
	_assert_true(int(runtime._compute_probe_conflict_overlap_count(intents, {
		1: assignments[1]
	})) == 1, "waiting assignments should not count as resolved overlaps", failures)
	_assert_true(schema.has("p95_contention"), "probe schema should include p95_contention", failures)
	_assert_true(schema.has("conflict_overlap_count"), "probe schema should include conflict_overlap_count", failures)
	_assert_true(schema.has("clumping_factor"), "probe schema should include clumping_factor", failures)
	_assert_true(schema.has("arbitration_latency"), "probe schema should include arbitration_latency", failures)
	_assert_true(float(schema.get("p95_contention", 0.0)) > 0.0, "p95_contention should be non-zero under contested intents", failures)
	_assert_true(int(schema.get("conflict_overlap_count", 0)) > 0, "conflict_overlap_count should be non-zero under slot conflict", failures)
	_assert_true(float(schema.get("clumping_factor", 0.0)) > 0.0, "clumping_factor should be non-zero under clustered positions", failures)
	_assert_true(float(schema.get("arbitration_latency", 0.0)) > 1.0, "arbitration_latency should rise above base latency under waiting assignments", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
