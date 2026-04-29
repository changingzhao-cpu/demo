extends RefCounted

const SCRIPT_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('shadow_warning'), "oscillation sample should define a contention shadow warning payload", failures)
	_assert_true(source.contains('push_warning("contention_shadow_hit'), "oscillation sample should emit contention shadow warning", failures)
	_assert_true(source.contains('attack_rebind_escapes='), "oscillation sample should still keep legacy escape output path", failures)
	_assert_true(not source.contains('payload["contention_shadow_warning"]'), "oscillation sample should not expand payload contract for shadow warnings", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
