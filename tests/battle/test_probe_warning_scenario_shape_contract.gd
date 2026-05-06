extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('scenario_contention = 0.72') and source.contains('scenario_overlap = 6'), "corridor should remain the densest scenario", failures)
	_assert_true(source.contains('scenario_latency = 0.31') and source.contains('scenario_overlap = 4'), "dynamic orbit should remain the highest-latency low-overlap scenario", failures)
	_assert_true(source.contains('scenario_contention = 0.66') and source.contains('scenario_duration = 8.0'), "funnel should remain the collapse-heavy mid-latency scenario", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
