extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const MEDIUM_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	var medium_source := FileAccess.get_file_as_string(MEDIUM_PATH)
	_assert_true(static_source.contains('"zone": "comfort"'), "static zero deviation sample should anchor comfort zone", failures)
	_assert_true(oscillation_source.contains('"zone": "warning"') or oscillation_source.contains('"zone": "critical"'), "oscillation sample should anchor warning or critical zone", failures)
	_assert_true(medium_source.contains('"sample_name": "medium_density_filled_slots"'), "medium-density fixture should anchor sample name", failures)
	_assert_true(medium_source.contains('"zone": "warning"'), "medium-density fixture should anchor warning zone", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
