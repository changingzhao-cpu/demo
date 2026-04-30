extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner_v4.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('[TEST] Starting V4 test run...'), "test_runner_v4 should keep the V4 runner banner", failures)
	_assert_true(source.contains('[TEST] All %d V4 suite(s) passed.'), "test_runner_v4 should keep the V4 pass banner", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
