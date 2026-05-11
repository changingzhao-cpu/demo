extends RefCounted

const TARGET_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(TARGET_PATH)
	_assert_true(source.contains('scenario_summary["p95_contention_mean"] = float(scenario_summary.get("p95_contention_mean", 0.0)) / scenario_count'), "scenario summaries should normalize p95_contention_mean per scenario", failures)
	_assert_true(source.contains('scenario_summary["arbitration_latency_mean"] = float(scenario_summary.get("arbitration_latency_mean", 0.0)) / scenario_count'), "scenario summaries should normalize arbitration_latency_mean per scenario", failures)
	_assert_true(source.contains('scenario_summary["conflict_overlap_count_mean"] = float(scenario_summary.get("conflict_overlap_count_mean", 0.0)) / scenario_count'), "scenario summaries should normalize conflict_overlap_count_mean per scenario", failures)
	_assert_true(source.contains('scenario_summary["clumping_factor_mean"] = float(scenario_summary.get("clumping_factor_mean", 0.0)) / scenario_count'), "scenario summaries should normalize clumping_factor_mean per scenario", failures)
	_assert_true(source.contains('_assert_true(float(corridor_summary.get("p95_contention_mean", 0.0)) > float(funnel_summary.get("p95_contention_mean", 0.0)) and float(funnel_summary.get("p95_contention_mean", 0.0)) > float(orbit_summary.get("p95_contention_mean", 0.0)), "scenario summaries should show corridor > funnel > dynamic_orbit p95 contention"'), "scenario summaries should assert p95 contention divergence order", failures)
	_assert_true(source.contains('_assert_true(float(orbit_summary.get("arbitration_latency_mean", 0.0)) > float(funnel_summary.get("arbitration_latency_mean", 0.0)) and float(funnel_summary.get("arbitration_latency_mean", 0.0)) > float(corridor_summary.get("arbitration_latency_mean", 0.0)), "scenario summaries should show dynamic_orbit > funnel > corridor arbitration latency"'), "scenario summaries should assert arbitration latency divergence order", failures)
	_assert_true(source.contains('_assert_true(float(corridor_summary.get("conflict_overlap_count_mean", 0.0)) > float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) and float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) > float(orbit_summary.get("conflict_overlap_count_mean", 0.0)), "scenario summaries should show corridor > funnel > dynamic_orbit overlap"'), "scenario summaries should assert overlap divergence order", failures)
	_assert_true(source.contains('_assert_true(float(corridor_summary.get("clumping_factor_mean", 0.0)) > float(funnel_summary.get("clumping_factor_mean", 0.0)) and float(funnel_summary.get("clumping_factor_mean", 0.0)) > float(orbit_summary.get("clumping_factor_mean", 0.0)), "scenario summaries should show corridor > funnel > dynamic_orbit clumping"'), "scenario summaries should assert clumping divergence order", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
