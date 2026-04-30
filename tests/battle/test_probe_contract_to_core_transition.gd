extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var final_block_order_index := source.find('"battle/test_probe_contract_final_block_order"')
	var projection_index := source.find('"battle/test_battle_projection"')
	_assert_true(final_block_order_index != -1, "test_runner should include battle/test_probe_contract_final_block_order", failures)
	_assert_true(projection_index != -1, "test_runner should include battle/test_battle_projection", failures)
	if final_block_order_index != -1 and projection_index != -1:
		_assert_true(projection_index > final_block_order_index, "core battle tests should stay after the final probe contract block test", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
