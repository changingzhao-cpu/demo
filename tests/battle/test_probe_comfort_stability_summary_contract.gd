extends RefCounted

const COMFORT_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(COMFORT_PATH)
	_assert_true(source.contains('"stability_summary"'), "comfort payload should persist stability summary block", failures)
	_assert_true(source.contains('"late_commit_deviation_drift_mean"'), "comfort payload should persist late commit drift mean", failures)
	_assert_true(source.contains('"false_positive_free_ratio"'), "comfort payload should persist false-positive free ratio", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
