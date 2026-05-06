extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('scenario_contention = 0.72'), "corridor should keep the highest contention anchor", failures)
	_assert_true(source.contains('scenario_contention = 0.66'), "funnel should keep the second-highest contention anchor", failures)
	_assert_true(source.contains('scenario_contention = 0.48'), "dynamic orbit should keep the lowest contention anchor", failures)
	_assert_true(source.contains('scenario_latency = 0.31'), "dynamic orbit should keep the highest latency anchor", failures)
	_assert_true(source.contains('scenario_clumping = 1.8'), "corridor should keep the highest clumping anchor", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
