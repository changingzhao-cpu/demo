extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	_assert_true(static_source.contains('"zone": "comfort"'), "static zero deviation sample should anchor comfort zone", failures)
	_assert_true(oscillation_source.contains('"zone": "warning"') or oscillation_source.contains('"zone": "critical"'), "oscillation sample should anchor warning or critical zone", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
