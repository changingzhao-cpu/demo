extends RefCounted

const COMFORT_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const CRITICAL_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var comfort_source := FileAccess.get_file_as_string(COMFORT_PATH)
	var warning_source := FileAccess.get_file_as_string(WARNING_PATH)
	var critical_source := FileAccess.get_file_as_string(CRITICAL_PATH)
	_assert_true(comfort_source.contains('"samples"'), "comfort payload should persist sample array", failures)
	_assert_true(warning_source.contains('"samples"'), "warning payload should persist sample array", failures)
	_assert_true(critical_source.contains('"samples"'), "critical payload should persist sample array", failures)
	_assert_true(comfort_source.contains('"fingerprint_zone_summary"'), "comfort payload should persist fingerprint summary", failures)
	_assert_true(warning_source.contains('"fingerprint_zone_summary"'), "warning payload should persist fingerprint summary", failures)
	_assert_true(critical_source.contains('"sample_name": "oscillation"'), "critical payload should persist fingerprint summary", failures)
	_assert_true(comfort_source.contains('"threshold_candidate"'), "comfort payload should persist threshold candidate block", failures)
	_assert_true(warning_source.contains('"threshold_candidate"'), "warning payload should persist threshold candidate block", failures)
	_assert_true(critical_source.contains('"threshold_formula"'), "critical payload should persist threshold formula block", failures)
	_assert_true(critical_source.contains('"fitted_thresholds"'), "critical payload should persist fitted thresholds block", failures)
	_assert_true(critical_source.contains('"gate_results"'), "critical payload should persist gate results block", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
