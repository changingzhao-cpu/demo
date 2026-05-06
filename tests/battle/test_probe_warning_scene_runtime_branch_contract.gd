extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('match scenario'), "warning fixture should branch on scenario at runtime", failures)
	_assert_true(source.contains('"corridor"'), "warning fixture should keep corridor branch", failures)
	_assert_true(source.contains('"dynamic_orbit"'), "warning fixture should keep dynamic orbit branch", failures)
	_assert_true(source.contains('"funnel"'), "warning fixture should keep funnel branch", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
