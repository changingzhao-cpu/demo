extends RefCounted

const COMFORT_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(COMFORT_PATH)
	_assert_true(source.contains('"peak_to_peak_drift"'), "comfort stability summary should persist peak_to_peak_drift", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
