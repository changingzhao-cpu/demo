extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var lines := source.split("\n")
	var boundary_index := -1
	var tail_index := -1
	var next_boundary_index := -1
	var cluster_ordering_index := -1
	var final_order_index := -1
	var core_transition_index := -1
	var projection_index := -1
	for i in range(lines.size()):
		var line := lines[i]
		if line.contains('"battle/test_probe_contract_projection_boundary"'):
			boundary_index = i
		elif line.contains('"battle/test_probe_contract_tail_adjacency"'):
			tail_index = i
		elif line.contains('"battle/test_probe_contract_block_before_core_tests"'):
			next_boundary_index = i
		elif line.contains('"battle/test_probe_contract_cluster_ordering"'):
			cluster_ordering_index = i
		elif line.contains('"battle/test_probe_contract_final_block_order"'):
			final_order_index = i
		elif line.contains('"battle/test_probe_contract_to_core_transition"'):
			core_transition_index = i
		elif line.contains('"battle/test_battle_projection"'):
			projection_index = i
	_assert_true(boundary_index != -1, "test_runner should include battle/test_probe_contract_projection_boundary", failures)
	_assert_true(tail_index != -1, "test_runner should include battle/test_probe_contract_tail_adjacency", failures)
	_assert_true(next_boundary_index != -1, "test_runner should include battle/test_probe_contract_block_before_core_tests", failures)
	_assert_true(cluster_ordering_index != -1, "test_runner should include battle/test_probe_contract_cluster_ordering", failures)
	_assert_true(final_order_index != -1, "test_runner should include battle/test_probe_contract_final_block_order", failures)
	_assert_true(core_transition_index != -1, "test_runner should include battle/test_probe_contract_to_core_transition", failures)
	_assert_true(projection_index != -1, "test_runner should include battle/test_battle_projection", failures)
	var late_chain_index := -1
	for i in range(lines.size()):
		var line := lines[i]
		if line.contains('"battle/test_probe_contract_late_chain"'):
			late_chain_index = i
	_assert_true(late_chain_index != -1, "test_runner should include battle/test_probe_contract_late_chain", failures)
	if boundary_index != -1 and late_chain_index != -1:
		_assert_true(late_chain_index == boundary_index + 1, "probe contract late chain test should stay immediately after the projection boundary test", failures)
	if late_chain_index != -1 and tail_index != -1:
		_assert_true(tail_index == late_chain_index + 1, "probe contract tail adjacency test should stay immediately after the late chain test", failures)
	if tail_index != -1 and next_boundary_index != -1:
		_assert_true(next_boundary_index > tail_index, "probe contract block before core tests should stay after the tail adjacency test", failures)
	if next_boundary_index != -1 and cluster_ordering_index != -1:
		_assert_true(cluster_ordering_index > next_boundary_index, "probe contract cluster ordering test should stay after the block before core tests boundary", failures)
	if cluster_ordering_index != -1 and final_order_index != -1:
		_assert_true(final_order_index > cluster_ordering_index, "probe contract final block order test should stay after the cluster ordering test", failures)
	if final_order_index != -1 and core_transition_index != -1:
		_assert_true(core_transition_index > final_order_index, "probe contract to core transition test should stay after the final block order test", failures)
	if core_transition_index != -1 and projection_index != -1:
		_assert_true(projection_index > core_transition_index, "battle/test_battle_projection should stay after the probe contract to core transition test", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
