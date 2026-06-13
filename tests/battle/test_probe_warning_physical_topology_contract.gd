extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"corridor_weight": 0.4'), "warning topology plan should weight corridor at 0.4", failures)
	_assert_true(source.contains('"funnel_weight": 0.4'), "warning topology plan should weight funnel at 0.4", failures)
	_assert_true(source.contains('"dynamic_orbit_weight": 0.2'), "warning topology plan should weight dynamic orbit at 0.2", failures)
	_assert_true(source.contains('"corridor_min_width": 1.2'), "warning topology plan should pin corridor minimum width", failures)
	_assert_true(source.contains('"funnel_entry_width": 10.0'), "warning topology plan should pin funnel entry width", failures)
	_assert_true(source.contains('"funnel_exit_width": 2.0'), "warning topology plan should pin funnel exit width", failures)
	_assert_true(source.contains('"orbit_motion": "irregular_sine"'), "warning topology plan should pin orbit motion pattern", failures)
	_assert_true(source.contains('"clumping_factor": "p95_contention/mean_contention"'), "warning topology plan should define clumping_factor formula", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
