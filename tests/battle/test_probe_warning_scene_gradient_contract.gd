extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('scenario_clumping = 1.8'), "corridor should keep strongest clumping", failures)
	_assert_true(source.contains('scenario_clumping = 1.65'), "funnel should keep mid clumping", failures)
	_assert_true(source.contains('scenario_clumping = 1.35'), "dynamic orbit should keep lowest clumping", failures)
	_assert_true(source.contains('scenario_latency = 0.31'), "dynamic orbit should keep peak arbitration latency", failures)
	_assert_true(source.contains('scenario_duration = 9.0'), "corridor should keep longest duration", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
