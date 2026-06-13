extends RefCounted

const RUNNER_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(RUNNER_PATH)
	_assert_true(source.contains('is Node') or source.contains('is SceneTree'), "runner should reject Node or SceneTree suites", failures)
	_assert_true(not source.contains('"battle/test_battle_runtime_probe_trace_contract"'), "runner should not keep SceneTree trace suite in generic TEST_SUITES", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
