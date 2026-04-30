extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner_v4.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('"battle/test_v4_probe_contract_surface"'), "test_runner_v4 should include battle/test_v4_probe_contract_surface", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
