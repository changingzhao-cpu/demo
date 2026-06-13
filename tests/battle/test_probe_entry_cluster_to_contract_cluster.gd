extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var entry_suite_index := source.find('"battle/test_probe_entry_suite_membership"')
	var runner_v4_banner_index := source.find('"battle/test_runner_v4_banner_contract"')
	var contract_ordering_index := source.find('"battle/test_probe_contract_ordering"')
	_assert_true(entry_suite_index != -1, "test_runner should include battle/test_probe_entry_suite_membership", failures)
	_assert_true(runner_v4_banner_index != -1, "test_runner should include battle/test_runner_v4_banner_contract", failures)
	_assert_true(contract_ordering_index != -1, "test_runner should include battle/test_probe_contract_ordering", failures)
	if entry_suite_index != -1 and runner_v4_banner_index != -1:
		_assert_true(runner_v4_banner_index > entry_suite_index, "runner V4 banner contract should stay after the probe entry cluster", failures)
	if runner_v4_banner_index != -1 and contract_ordering_index != -1:
		_assert_true(contract_ordering_index > runner_v4_banner_index, "probe contract ordering should stay after the banner boundary", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
