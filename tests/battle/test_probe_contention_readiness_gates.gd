extends RefCounted

const V4_TEST_PATH := "res://tests/battle/test_battle_simulation_v4_intent_core.gd"
const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var v4_source := FileAccess.get_file_as_string(V4_TEST_PATH)
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(v4_source.contains('_test_probe_report_exposes_contention_index'), "v4 intent core should keep contention index readiness coverage", failures)
	_assert_true(v4_source.contains('_test_probe_report_exposes_late_commit_deviation'), "v4 intent core should keep late commit deviation readiness coverage", failures)
	_assert_true(v4_source.contains('_test_probe_contention_index_matches_contention_report'), "v4 intent core should keep contention/report alignment coverage", failures)
	_assert_true(oscillation_source.contains('_build_anomaly_scan('), "oscillation sample should still retain anomaly scan entry before contention-first upgrade", failures)
	_assert_true(oscillation_source.contains('var anomaly_scan := _build_anomaly_scan('), "oscillation sample should still build anomaly scan before contention-first upgrade", failures)
	_assert_true(not v4_source.contains('test_probe_contention_readiness_gates'), "v4 intent core should not inline contention readiness suite membership", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
