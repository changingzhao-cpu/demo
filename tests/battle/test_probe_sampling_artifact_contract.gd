extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	_assert_true(oscillation_source.contains('"artifact_format": "csv"') or static_source.contains('"artifact_format": "csv"'), "sampling should define csv artifact format", failures)
	_assert_true(oscillation_source.contains('"artifact_format_json": "json"') or static_source.contains('"artifact_format_json": "json"'), "sampling should define json artifact format", failures)
	_assert_true(oscillation_source.contains('"run_id"') or static_source.contains('"run_id"'), "sampling should define run_id field", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
