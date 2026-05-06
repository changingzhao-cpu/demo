extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('scenario_overlap = 6'), "corridor should keep the highest overlap anchor", failures)
	_assert_true(source.contains('scenario_overlap = 5'), "funnel should keep the middle overlap anchor", failures)
	_assert_true(source.contains('scenario_overlap = 4'), "dynamic orbit should keep the lowest overlap anchor", failures)
	_assert_true(source.contains('scenario_duration = 9.0'), "corridor should keep the longest duration anchor", failures)
	_assert_true(source.contains('scenario_duration = 8.0'), "funnel should keep the second-longest duration anchor", failures)
	_assert_true(source.contains('scenario_duration = 6.0'), "dynamic orbit should keep the shortest duration anchor", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
