extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"run_count_completed": samples.size()'), "warning sampling should derive run_count_completed from samples size", failures)
	_assert_true(source.contains('"sample_count": 50'), "warning sampling plan should target 50 runs", failures)
	_assert_true(source.contains('float(corridor_summary.get("p95_contention_mean", 0.0)) > float(funnel_summary.get("p95_contention_mean", 0.0)) and float(funnel_summary.get("p95_contention_mean", 0.0)) > float(orbit_summary.get("p95_contention_mean", 0.0))'), "warning sampling should preserve p95 ordering at 50-run scale", failures)
	_assert_true(source.contains('float(corridor_summary.get("conflict_overlap_count_mean", 0.0)) > float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) and float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) > float(orbit_summary.get("conflict_overlap_count_mean", 0.0))'), "warning sampling should preserve overlap ordering at 50-run scale", failures)
	_assert_true(source.contains('float(corridor_summary.get("clumping_factor_mean", 0.0)) > float(funnel_summary.get("clumping_factor_mean", 0.0)) and float(funnel_summary.get("clumping_factor_mean", 0.0)) > float(orbit_summary.get("clumping_factor_mean", 0.0))'), "warning sampling should preserve clumping ordering at 50-run scale", failures)
	_assert_true(source.contains('float(orbit_summary.get("arbitration_latency_mean", 0.0)) > float(funnel_summary.get("arbitration_latency_mean", 0.0)) and float(funnel_summary.get("arbitration_latency_mean", 0.0)) > float(corridor_summary.get("arbitration_latency_mean", 0.0))'), "warning sampling should preserve latency ordering at 50-run scale", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
