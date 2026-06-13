extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var cluster_index := source.find('"battle/test_runner_contract_cluster"')
	var block_bounds_index := source.find('"battle/test_probe_contract_block_bounds"')
	var projection_boundary_index := source.find('"battle/test_probe_contract_projection_boundary"')
	_assert_true(cluster_index != -1, "test_runner should include battle/test_runner_contract_cluster", failures)
	_assert_true(block_bounds_index != -1, "test_runner should include battle/test_probe_contract_block_bounds", failures)
	_assert_true(projection_boundary_index != -1, "test_runner should include battle/test_probe_contract_projection_boundary", failures)
	if cluster_index != -1 and block_bounds_index != -1:
		_assert_true(cluster_index < block_bounds_index, "runner contract cluster should stay before probe contract block bounds", failures)
	if block_bounds_index != -1 and projection_boundary_index != -1:
		_assert_true(block_bounds_index < projection_boundary_index, "probe contract block bounds should stay before probe contract projection boundary", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
