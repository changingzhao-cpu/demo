extends RefCounted

const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(static_source.contains('--family=comfort') or oscillation_source.contains('--family=comfort'), "sampling family contract should anchor comfort family selector", failures)
	_assert_true(static_source.contains('"density_level": "comfort"') or oscillation_source.contains('"density_level": "comfort"'), "sampling family contract should anchor comfort density level", failures)
	_assert_true(oscillation_source.contains('--family=critical') or oscillation_source.contains('--family=warning'), "sampling family contract should anchor warning/critical family selector", failures)
	_assert_true(oscillation_source.contains('"sample_count": 10') or oscillation_source.contains('"sample_count": 20'), "sampling family contract should anchor family run counts", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
