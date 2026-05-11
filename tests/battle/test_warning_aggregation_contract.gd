extends RefCounted

const BattleWarningSamplerCore = preload("res://tests/battle/battle_warning_sampler_core.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	var corridor := BattleWarningSamplerCore.new("corridor", 0).sample({
		"p95_contention": 6.0,
		"conflict_overlap_count": 8,
		"clumping_factor": 0.9,
		"arbitration_latency": 1.6,
		"claim_success_rate": 0.2,
		"late_commit_deviation": 1.6,
		"assignments": {1: {"assigned_slot_index": 0}}
	})
	var funnel := BattleWarningSamplerCore.new("funnel", 1).sample({
		"p95_contention": 4.0,
		"conflict_overlap_count": 5,
		"clumping_factor": 0.6,
		"arbitration_latency": 1.2,
		"claim_success_rate": 0.4,
		"late_commit_deviation": 1.2,
		"assignments": {1: {"assigned_slot_index": 0}, 2: {"assigned_slot_index": 1}}
	})
	var orbit := BattleWarningSamplerCore.new("dynamic_orbit", 2).sample({
		"p95_contention": 2.0,
		"conflict_overlap_count": 2,
		"clumping_factor": 0.3,
		"arbitration_latency": 0.8,
		"claim_success_rate": 0.8,
		"late_commit_deviation": 0.8,
		"assignments": {1: {"assigned_slot_index": 0}, 2: {"assigned_slot_index": 1}, 3: {"assigned_slot_index": 2}}
	})
	_assert_true(float(corridor.get("p95_contention", 0.0)) > float(funnel.get("p95_contention", 0.0)) and float(funnel.get("p95_contention", 0.0)) > float(orbit.get("p95_contention", 0.0)), "aggregation contract should preserve p95 contention gradient", failures)
	_assert_true(float(corridor.get("claim_success_rate", 0.0)) < float(funnel.get("claim_success_rate", 0.0)) and float(funnel.get("claim_success_rate", 0.0)) < float(orbit.get("claim_success_rate", 0.0)), "aggregation contract should preserve claim success gradient", failures)
	_assert_true(float(corridor.get("claim_success_rate", 0.0)) != float(funnel.get("claim_success_rate", 0.0)) and float(funnel.get("claim_success_rate", 0.0)) != float(orbit.get("claim_success_rate", 0.0)), "aggregation contract should keep claim success non-constant across scenarios", failures)
	_assert_true(float(corridor.get("claim_success_rate", 0.0)) < 0.5 and float(orbit.get("claim_success_rate", 0.0)) > 0.5, "aggregation contract should widen claim success separation", failures)
	_assert_true(float(corridor.get("late_commit_deviation", 0.0)) > float(funnel.get("late_commit_deviation", 0.0)) and float(funnel.get("late_commit_deviation", 0.0)) > float(orbit.get("late_commit_deviation", 0.0)), "aggregation contract should preserve late commit deviation gradient", failures)
	_assert_true(float(corridor.get("contention_index", 0.0)) > float(funnel.get("contention_index", 0.0)) and float(funnel.get("contention_index", 0.0)) > float(orbit.get("contention_index", 0.0)), "aggregation contract should preserve contention index gradient", failures)
	_assert_true(int(corridor.get("conflict_overlap_count", 0)) > int(funnel.get("conflict_overlap_count", 0)) and int(funnel.get("conflict_overlap_count", 0)) > int(orbit.get("conflict_overlap_count", 0)), "aggregation contract should preserve overlap gradient", failures)
	_assert_true(float(corridor.get("clumping_factor", 0.0)) > float(funnel.get("clumping_factor", 0.0)) and float(funnel.get("clumping_factor", 0.0)) > float(orbit.get("clumping_factor", 0.0)), "aggregation contract should preserve clumping gradient", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
