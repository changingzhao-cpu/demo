extends RefCounted

const SCRIPT_PATH := "res://scripts/battle/battle_simulation_v4.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('"probe"'), "battle_simulation_v4 should expose probe payload", failures)
	_assert_true(source.contains('"claim_success_rate"'), "battle_simulation_v4 should keep claim_success_rate in probe contract", failures)
	_assert_true(source.contains('"contention_index"'), "battle_simulation_v4 should keep contention_index in probe contract", failures)
	_assert_true(source.contains('"late_commit_deviation"'), "battle_simulation_v4 should keep late_commit_deviation in probe contract", failures)
	_assert_true(source.contains('"assignments"'), "battle_simulation_v4 should keep assignments in probe contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
