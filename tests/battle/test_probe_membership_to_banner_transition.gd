extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var suite_membership_index := source.find('"battle/test_probe_contract_suite_membership"')
	var runner_membership_index := source.find('"battle/test_v4_runner_suite_membership"')
	var banner_index := source.find('"battle/test_runner_v4_banner_contract"')
	_assert_true(suite_membership_index != -1, "test_runner should include battle/test_probe_contract_suite_membership", failures)
	_assert_true(runner_membership_index != -1, "test_runner should include battle/test_v4_runner_suite_membership", failures)
	_assert_true(banner_index != -1, "test_runner should include battle/test_runner_v4_banner_contract", failures)
	if suite_membership_index != -1 and runner_membership_index != -1:
		_assert_true(runner_membership_index > suite_membership_index, "V4 runner suite membership should stay after probe contract suite membership", failures)
	if runner_membership_index != -1 and banner_index != -1:
		_assert_true(banner_index > runner_membership_index, "runner V4 banner contract should stay after V4 runner suite membership", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
