extends RefCounted

const COMFORT_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var comfort_source := FileAccess.get_file_as_string(COMFORT_PATH)
	var warning_source := FileAccess.get_file_as_string(WARNING_PATH)
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	for source in [comfort_source, warning_source, oscillation_source]:
		_assert_true(str(source).contains('"arbitration_latency"'), "sampling payload should expose arbitration_latency", failures)
		_assert_true(str(source).contains('"conflict_overlap_count"'), "sampling payload should expose conflict_overlap_count", failures)
		_assert_true(str(source).contains('"gate_match_status"'), "sampling payload should expose gate_match_status", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
