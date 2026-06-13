extends RefCounted

const RUNNER_PATH := "res://tests/test_runner_v4.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(RUNNER_PATH)
	_assert_true(source.contains('"name": "battle/test_battle_simulation_v4_intent_core"'), "v4 runner should keep intent core suite in fast layer", failures)
	_assert_true(source.contains('"name": "battle/test_v4_probe_contract_surface"'), "v4 runner should keep probe surface suite in fast layer", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
