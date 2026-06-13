extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var contract_boundary := source.find('"battle/test_probe_contract_block_bounds"')
	var projection_boundary := source.find('"battle/test_battle_projection"')
	_assert_true(contract_boundary != -1, "test_runner should include battle/test_probe_contract_block_bounds", failures)
	_assert_true(projection_boundary != -1, "test_runner should include battle/test_battle_projection", failures)
	if contract_boundary != -1 and projection_boundary != -1:
		_assert_true(contract_boundary < projection_boundary, "probe contract boundary tests should stay before battle/test_battle_projection", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
