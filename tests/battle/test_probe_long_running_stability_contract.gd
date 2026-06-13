extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"long_running_stability"'), "critical payload should expose long_running_stability block", failures)
	_assert_true(source.contains('"late_commit_deviation_drift"'), "critical payload should expose late_commit_deviation_drift", failures)
	_assert_true(source.contains('"stability_window_seconds"'), "critical payload should expose stability window length", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
