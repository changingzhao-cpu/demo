extends RefCounted

const COMFORT_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const CRITICAL_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var comfort_source := FileAccess.get_file_as_string(COMFORT_PATH)
	var warning_source := FileAccess.get_file_as_string(WARNING_PATH)
	var critical_source := FileAccess.get_file_as_string(CRITICAL_PATH)
	for source in [comfort_source, warning_source, critical_source]:
		_assert_true(str(source).contains("<svg"), "sampling SVG output should remain SVG-backed", failures)
		_assert_true(str(source).contains("viewBox"), "sampling SVG output should include viewBox", failures)
		_assert_true(str(source).contains("Safety Zone"), "sampling SVG output should label safety zone", failures)
		_assert_true(str(source).contains("Danger Zone"), "sampling SVG output should label danger zone", failures)
		_assert_true(str(source).contains("threshold-line"), "sampling SVG output should include threshold line marker", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
