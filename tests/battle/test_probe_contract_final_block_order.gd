extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var before_core_index := source.find('"battle/test_probe_contract_block_before_core_tests"')
	var cluster_order_index := source.find('"battle/test_probe_contract_cluster_ordering"')
	var projection_index := source.find('"battle/test_battle_projection"')
	_assert_true(before_core_index != -1, "test_runner should include battle/test_probe_contract_block_before_core_tests", failures)
	_assert_true(cluster_order_index != -1, "test_runner should include battle/test_probe_contract_cluster_ordering", failures)
	_assert_true(projection_index != -1, "test_runner should include battle/test_battle_projection", failures)
	if before_core_index != -1 and cluster_order_index != -1:
		_assert_true(before_core_index < cluster_order_index, "probe contract block before core tests should stay before cluster ordering", failures)
	if cluster_order_index != -1 and projection_index != -1:
		_assert_true(cluster_order_index < projection_index, "probe contract cluster ordering should stay before battle/test_battle_projection", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
