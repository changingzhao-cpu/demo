extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var suite_membership_index := source.find('"battle/test_probe_contract_suite_membership"')
	var runner_membership_index := source.find('"battle/test_v4_runner_suite_membership"')
	var block_to_entry_index := source.find('"battle/test_probe_block_to_entry_ordering"')
	_assert_true(suite_membership_index != -1, "test_runner should include battle/test_probe_contract_suite_membership", failures)
	_assert_true(runner_membership_index != -1, "test_runner should include battle/test_v4_runner_suite_membership", failures)
	_assert_true(block_to_entry_index != -1, "test_runner should include battle/test_probe_block_to_entry_ordering", failures)
	if suite_membership_index != -1 and runner_membership_index != -1:
		_assert_true(runner_membership_index > suite_membership_index, "V4 runner suite membership should stay after probe contract suite membership", failures)
	if runner_membership_index != -1 and block_to_entry_index != -1:
		_assert_true(block_to_entry_index > runner_membership_index, "probe block-to-entry ordering should stay after V4 runner suite membership", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
