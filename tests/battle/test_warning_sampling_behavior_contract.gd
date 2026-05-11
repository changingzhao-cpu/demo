extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"nonzero_scenario_count": nonzero_scenario_count'), "warning sampling should persist nonzero scenario count into artifacts", failures)
	_assert_true(source.contains('threshold_candidate["warning_band_upper_hint"] = float(corridor_summary.get("p95_contention_mean", 0.0))'), "warning threshold candidate should use corridor as upper hint", failures)
	_assert_true(source.contains('threshold_candidate["warning_band_hint"] = float(funnel_summary.get("p95_contention_mean", 0.0))'), "warning threshold candidate should use funnel as center hint", failures)
	_assert_true(source.contains('threshold_candidate["warning_band_lower_hint"] = float(orbit_summary.get("p95_contention_mean", 0.0))'), "warning threshold candidate should use dynamic orbit as lower hint", failures)
	_assert_true(source.contains('gate_results := {'), "warning sampling should persist gate results", failures)
	_assert_true(source.contains('"gate_b_warning_clumping_ordering"'), "warning sampling should expose clumping ordering gate", failures)
	_assert_true(source.contains('"gate_b_warning_latency_ordering"'), "warning sampling should expose latency ordering gate", failures)
	_assert_true(source.contains('"scenario_summaries": scenario_summaries'), "warning artifact should persist scenario summaries", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
