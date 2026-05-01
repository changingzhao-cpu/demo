extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"confidence_warning"'), "critical aggregation should expose confidence warning field", failures)
	_assert_true(source.contains('"old_escape_true_count"'), "critical aggregation should expose old escape true count", failures)
	_assert_true(source.contains('"confidence_insufficient"'), "critical aggregation should expose insufficient-confidence warning value", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
