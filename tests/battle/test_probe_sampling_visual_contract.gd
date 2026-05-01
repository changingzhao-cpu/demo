extends RefCounted

const COMFORT_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const CRITICAL_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var comfort_source := FileAccess.get_file_as_string(COMFORT_PATH)
	var warning_source := FileAccess.get_file_as_string(WARNING_PATH)
	var critical_source := FileAccess.get_file_as_string(CRITICAL_PATH)
	_assert_true(comfort_source.contains('"sample_count"') and comfort_source.contains('"x_axis"') and comfort_source.contains('"y_axis"'), "comfort fixture should describe scatter metadata", failures)
	_assert_true(warning_source.contains('"sample_count"') and warning_source.contains('"x_axis"') and warning_source.contains('"y_axis"'), "warning fixture should describe scatter metadata", failures)
	_assert_true(critical_source.contains('"sample_count"') and critical_source.contains('"x_axis"') and critical_source.contains('"y_axis"'), "critical fixture should describe scatter metadata", failures)
	_assert_true(comfort_source.contains('"claim_success_rate"') and comfort_source.contains('"assignment_count"'), "comfort CSV should keep core metrics columns", failures)
	_assert_true(warning_source.contains('"claim_success_rate"') and warning_source.contains('"assignment_count"'), "warning CSV should keep core metrics columns", failures)
	_assert_true(critical_source.contains('"claim_success_rate"') and critical_source.contains('"assignment_count"'), "critical CSV should keep core metrics columns", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
