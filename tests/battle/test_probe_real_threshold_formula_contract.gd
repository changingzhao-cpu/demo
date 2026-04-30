extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"warning_formula": "min(old_escape_hit==true)*0.8"'), "real threshold formula should anchor warning formula", failures)
	_assert_true(source.contains('"error_formula": "mean(old_escape_hit==true)"'), "real threshold formula should anchor error formula", failures)
	_assert_true(source.contains('"primary_slice": "p95_contention"'), "real threshold formula should anchor p95 slice", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
