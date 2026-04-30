extends RefCounted

const SCRIPT_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('attack_rebind_escapes='), "oscillation sample should keep legacy escape error payload", failures)
	_assert_true(source.contains('push_warning("contention_shadow_hit='), "oscillation sample should emit contention shadow warning text", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
