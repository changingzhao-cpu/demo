extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"corridor": {"claim_success_rate_mean": 0.0, "late_commit_deviation_mean": 0.0, "conflict_overlap_count_mean": 0.0, "clumping_factor_mean": 0.0, "p95_contention_mean": 0.0, "arbitration_latency_mean": 0.0}'), "warning fixture should initialize corridor summary", failures)
	_assert_true(source.contains('"dynamic_orbit": {"claim_success_rate_mean": 0.0, "late_commit_deviation_mean": 0.0, "conflict_overlap_count_mean": 0.0, "clumping_factor_mean": 0.0, "p95_contention_mean": 0.0, "arbitration_latency_mean": 0.0}'), "warning fixture should initialize dynamic orbit summary", failures)
	_assert_true(source.contains('"funnel": {"claim_success_rate_mean": 0.0, "late_commit_deviation_mean": 0.0, "conflict_overlap_count_mean": 0.0, "clumping_factor_mean": 0.0, "p95_contention_mean": 0.0, "arbitration_latency_mean": 0.0}'), "warning fixture should initialize funnel summary", failures)
	_assert_true(source.contains('scenario_summary["clumping_factor_mean"]'), "warning fixture should aggregate per-scenario clumping factor", failures)
	_assert_true(source.contains('scenario_summary["p95_contention_mean"]'), "warning fixture should aggregate per-scenario p95 contention", failures)
	_assert_true(source.contains('scenario_summary["arbitration_latency_mean"]'), "warning fixture should aggregate per-scenario arbitration latency", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
