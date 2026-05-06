extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains("func _capture_corridor_sample"), "warning fixture should expose corridor executor", failures)
	_assert_true(source.contains("func _capture_dynamic_orbit_sample"), "warning fixture should expose dynamic orbit executor", failures)
	_assert_true(source.contains("func _capture_funnel_sample"), "warning fixture should expose funnel executor", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
