extends RefCounted

const WARNING_FIXTURE_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_FIXTURE_PATH)
	_assert_true(source.contains('BattleWarningSamplerCore'), "warning fixture should reference BattleWarningSamplerCore", failures)
	_assert_true(source.contains('BattleWarningSamplerFactory'), "warning fixture should reference BattleWarningSamplerFactory", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
