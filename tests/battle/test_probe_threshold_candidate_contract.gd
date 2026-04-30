extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	_assert_true(oscillation_source.contains('var threshold_candidate := {'), "oscillation sample should persist threshold candidate summary", failures)
	_assert_true(static_source.contains('var threshold_candidate := {'), "static zero deviation sample should persist threshold candidate summary", failures)
	_assert_true(oscillation_source.contains('"strategy": "low_false_positive"'), "oscillation sample should mark low_false_positive strategy", failures)
	_assert_true(static_source.contains('"comfort_upper_bound"'), "static zero deviation sample should persist comfort upper bound anchor", failures)
	_assert_true(oscillation_source.contains('"critical_lower_bound"'), "oscillation sample should persist critical lower bound anchor", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
