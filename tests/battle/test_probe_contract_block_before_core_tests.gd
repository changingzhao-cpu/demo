extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var contract_block_index := source.find('"battle/test_probe_contract_block_bounds"')
	var core_block_index := source.find('"battle/test_battle_projection"')
	_assert_true(contract_block_index != -1, "test_runner should include battle/test_probe_contract_block_bounds", failures)
	_assert_true(core_block_index != -1, "test_runner should include battle/test_battle_projection", failures)
	if contract_block_index != -1 and core_block_index != -1:
		_assert_true(contract_block_index < core_block_index, "probe contract block should stay before core battle tests", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
