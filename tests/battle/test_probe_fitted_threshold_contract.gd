extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"warning_threshold_value"'), "sampling should persist concrete warning threshold value", failures)
	_assert_true(source.contains('"error_threshold_value"'), "sampling should persist concrete error threshold value", failures)
	_assert_true(source.contains('"gate_results"'), "sampling should keep gate results payload", failures)
	_assert_true(source.contains('"critical_hit_rate"'), "sampling should keep gate A metric", failures)
	_assert_true(source.contains('"fast_false_positive_rate"'), "sampling should keep gate B metric", failures)
	_assert_true(source.contains('"gate_c_no_false_positive_records"'), "sampling should keep gate C metric", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
