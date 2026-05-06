extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"funnel"'), "warning fixture should expose funnel scenario anchor", failures)
	_assert_true(source.contains('"dynamic_orbit"'), "warning fixture should expose dynamic orbit scenario anchor", failures)
	_assert_true(source.contains('"multi_flow_crossing"'), "warning fixture should expose multi-flow crossing scenario anchor", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
