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
	var shared_corridor := _sample("corridor", 0, 4.0, 1.0, 3, 0.22, 0.015)
	var shared_orbit := _sample("dynamic_orbit", 1, 4.0, 1.0, 3, 0.22, 0.015)
	var shared_funnel := _sample("funnel", 2, 4.0, 1.0, 3, 0.22, 0.015)
	_assert_true(float(shared_corridor.get("p95_contention", 0.0)) > float(shared_funnel.get("p95_contention", 0.0)) and float(shared_funnel.get("p95_contention", 0.0)) > float(shared_orbit.get("p95_contention", 0.0)), "aggregation contract should preserve contention ordering under shared runtime inputs", failures)
	_assert_true(float(shared_orbit.get("late_commit_deviation", 0.0)) > float(shared_funnel.get("late_commit_deviation", 0.0)) and float(shared_funnel.get("late_commit_deviation", 0.0)) > float(shared_corridor.get("late_commit_deviation", 0.0)), "aggregation contract should preserve late commit deviation ordering under shared runtime inputs", failures)
	_assert_true(absf(float(shared_corridor.get("p95_contention", 0.0)) - 7.4) > 0.01 or absf(float(shared_funnel.get("p95_contention", 0.0)) - 4.0) > 0.01 or absf(float(shared_orbit.get("p95_contention", 0.0)) - 1.4) > 0.01, "aggregation contract should not depend on one fixed golden triplet", failures)
	_assert_true(float(corridor.get("p95_contention", 0.0)) > float(funnel.get("p95_contention", 0.0)) and float(funnel.get("p95_contention", 0.0)) > float(orbit.get("p95_contention", 0.0)), "aggregation contract should preserve p95 contention gradient", failures)
	_assert_true(float(corridor.get("claim_success_rate", 0.0)) < float(funnel.get("claim_success_rate", 0.0)) and float(funnel.get("claim_success_rate", 0.0)) < float(orbit.get("claim_success_rate", 0.0)), "aggregation contract should preserve claim success gradient", failures)
	_assert_true(float(corridor.get("claim_success_rate", 0.0)) != float(funnel.get("claim_success_rate", 0.0)) and float(funnel.get("claim_success_rate", 0.0)) != float(orbit.get("claim_success_rate", 0.0)), "aggregation contract should keep claim success non-constant across scenarios", failures)
	_assert_true(float(corridor.get("claim_success_rate", 0.0)) < 0.5 and float(orbit.get("claim_success_rate", 0.0)) > 0.5, "aggregation contract should widen claim success separation", failures)
	_assert_true(float(orbit.get("claim_success_rate", 0.0)) - float(corridor.get("claim_success_rate", 0.0)) > 0.45, "aggregation contract should keep a large claim success spread", failures)
	_assert_true(float(orbit.get("late_commit_deviation", 0.0)) > float(funnel.get("late_commit_deviation", 0.0)) and float(funnel.get("late_commit_deviation", 0.0)) > float(corridor.get("late_commit_deviation", 0.0)), "aggregation contract should preserve late commit deviation gradient", failures)
	_assert_true(float(corridor.get("contention_index", 0.0)) > float(funnel.get("contention_index", 0.0)) and float(funnel.get("contention_index", 0.0)) > float(orbit.get("contention_index", 0.0)), "aggregation contract should preserve contention index gradient", failures)
	_assert_true(float(corridor.get("contention_index", 0.0)) - float(orbit.get("contention_index", 0.0)) > 8.0, "aggregation contract should keep a large contention index spread", failures)
	_assert_true(int(corridor.get("conflict_overlap_count", 0)) > int(funnel.get("conflict_overlap_count", 0)) and int(funnel.get("conflict_overlap_count", 0)) > int(orbit.get("conflict_overlap_count", 0)), "aggregation contract should preserve overlap gradient", failures)
	_assert_true(int(corridor.get("conflict_overlap_count", 0)) - int(orbit.get("conflict_overlap_count", 0)) >= 10, "aggregation contract should keep a large overlap spread", failures)
	_assert_true(float(corridor.get("clumping_factor", 0.0)) > float(funnel.get("clumping_factor", 0.0)) and float(funnel.get("clumping_factor", 0.0)) > float(orbit.get("clumping_factor", 0.0)), "aggregation contract should preserve clumping gradient", failures)
	_assert_true(float(corridor.get("clumping_factor", 0.0)) - float(orbit.get("clumping_factor", 0.0)) > 1.0, "aggregation contract should keep a large clumping spread", failures)
	return failures

func _sample(scenario: String, run_id: int, p95: float, latency: float, overlap: int, claim_success: float, clumping: float) -> Dictionary:
	var core := BattleWarningSamplerCore.new(scenario, run_id)
	return core.sample({
		"assignments": {"u0": "s0", "u1": "s1", "u2": "s2"},
		"p95_contention": p95,
		"arbitration_latency": latency,
		"conflict_overlap_count": overlap,
		"claim_success_rate": claim_success,
		"clumping_factor": clumping,
		"mean_contention": maxf(0.001, p95 / 5.0),
		"max_duration": 0
	})

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
