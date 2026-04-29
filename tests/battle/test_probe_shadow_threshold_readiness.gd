extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	_assert_true(oscillation_source.contains('"warning_type": "contention_shadow_hit"'), "oscillation sample should describe contention shadow warning type", failures)
	_assert_true(oscillation_source.contains('"legacy_escape_hit": not focused_escapes.is_empty()'), "oscillation sample should expose legacy escape overlap flag", failures)
	_assert_true(static_source.contains('"sample_name": "static_zero_deviation"'), "static zero deviation sample should name its shadow observation context", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
