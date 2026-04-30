extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var entry_cluster_end := source.find('"battle/test_probe_entry_suite_membership"')
	var contract_cluster_start := source.find('"battle/test_probe_contract_ordering"')
	_assert_true(entry_cluster_end != -1, "test_runner should include battle/test_probe_entry_suite_membership", failures)
	_assert_true(contract_cluster_start != -1, "test_runner should include battle/test_probe_contract_ordering", failures)
	if entry_cluster_end != -1 and contract_cluster_start != -1:
		_assert_true(contract_cluster_start > entry_cluster_end, "probe contract cluster should stay after the probe entry cluster", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
