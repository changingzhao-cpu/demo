extends RefCounted

const HIGH_DENSITY_PATH := "res://tests/battle/test_battle_runtime_probe_high_density_contention.gd"
const NARROW_PATH := "res://tests/battle/test_battle_runtime_probe_narrow_corridor_contention.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var high_density_source := FileAccess.get_file_as_string(HIGH_DENSITY_PATH)
	var narrow_source := FileAccess.get_file_as_string(NARROW_PATH)
	_assert_true(high_density_source.contains('"sample_name": "high_density_contention"'), "high-density fixture should anchor sample name", failures)
	_assert_true(high_density_source.contains('"zone": "critical"'), "high-density fixture should anchor critical zone", failures)
	_assert_true(narrow_source.contains('"sample_name": "narrow_corridor_contention"'), "narrow corridor fixture should anchor sample name", failures)
	_assert_true(narrow_source.contains('"zone": "warning"') or narrow_source.contains('"zone": "critical"'), "narrow corridor fixture should anchor warning or critical zone", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
