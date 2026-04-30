extends RefCounted

const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const MEDIUM_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	var medium_source := FileAccess.get_file_as_string(MEDIUM_PATH)
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(static_source.contains('"sample_count": 10'), "comfort family should execute 10 runs", failures)
	_assert_true(medium_source.contains('"sample_count": 20'), "warning family should execute 20 runs", failures)
	_assert_true(oscillation_source.contains('"sample_count": 20'), "critical family should execute 20 runs", failures)
	_assert_true(static_source.contains('"artifact_format": "csv"') and static_source.contains('"artifact_format_json": "json"'), "comfort family should persist csv/json artifacts", failures)
	_assert_true(oscillation_source.contains('"svg_artifact": "scatter"'), "critical family should persist svg scatter artifact", failures)
	_assert_true(static_source.contains('"seed"') or medium_source.contains('"seed"') or oscillation_source.contains('"seed"'), "sampling families should anchor seed field", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
