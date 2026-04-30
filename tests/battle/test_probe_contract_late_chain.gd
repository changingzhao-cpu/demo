extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var block_bounds_index := source.find('"battle/test_probe_contract_block_bounds"')
	var projection_boundary_index := source.find('"battle/test_probe_contract_projection_boundary"')
	var tail_adjacency_index := source.find('"battle/test_probe_contract_tail_adjacency"')
	_assert_true(block_bounds_index != -1, "test_runner should include battle/test_probe_contract_block_bounds", failures)
	_assert_true(projection_boundary_index != -1, "test_runner should include battle/test_probe_contract_projection_boundary", failures)
	_assert_true(tail_adjacency_index != -1, "test_runner should include battle/test_probe_contract_tail_adjacency", failures)
	if block_bounds_index != -1 and projection_boundary_index != -1:
		_assert_true(projection_boundary_index > block_bounds_index, "probe contract projection boundary should stay after block bounds", failures)
	if projection_boundary_index != -1 and tail_adjacency_index != -1:
		_assert_true(tail_adjacency_index > projection_boundary_index, "probe contract tail adjacency should stay after projection boundary", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
