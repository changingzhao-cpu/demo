extends RefCounted

const RUNNER_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(RUNNER_PATH)
	_assert_true(source.contains('"name": "battle/test_debug_runtime_probe_fingerprint_contract"'), "main runner should keep debug runtime probe fingerprint contract in slow layer", failures)
	_assert_true(source.contains('"name": "battle/test_runtime_probe_oscillation_fingerprint_contract"'), "main runner should keep oscillation fingerprint contract in slow layer", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
