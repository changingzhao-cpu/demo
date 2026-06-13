extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var ordering_index := source.find('"battle/test_probe_contract_ordering"')
	var adjacency_index := source.find('"battle/test_probe_contract_block_adjacency"')
	_assert_true(ordering_index != -1, "test_runner should include battle/test_probe_contract_ordering", failures)
	_assert_true(adjacency_index != -1, "test_runner should include battle/test_probe_contract_block_adjacency", failures)
	if ordering_index != -1 and adjacency_index != -1:
		_assert_true(adjacency_index > ordering_index, "probe contract block adjacency should stay after probe contract ordering", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
