extends RefCounted

const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const MEDIUM_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	var medium_source := FileAccess.get_file_as_string(MEDIUM_PATH)
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(static_source.contains('"csv_output_path"'), "comfort family should persist csv output path", failures)
	_assert_true(medium_source.contains('"csv_output_path"'), "warning family should persist csv output path", failures)
	_assert_true(oscillation_source.contains('"svg_output_path"'), "critical family should persist svg output path", failures)
	_assert_true(oscillation_source.contains('"json_output_path"'), "critical family should persist json output path", failures)
	_assert_true(oscillation_source.contains('"run_count_completed"'), "critical family should persist completed run count", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
