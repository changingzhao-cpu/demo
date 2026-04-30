extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('[TEST] Starting test run...'), "test_runner should keep the main runner start banner", failures)
	_assert_true(source.contains('[TEST] All %d test suite(s) passed.'), "test_runner should keep the main runner pass banner", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
