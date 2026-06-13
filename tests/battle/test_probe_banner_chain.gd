extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var runner_v4_banner_index := source.find('"battle/test_runner_v4_banner_contract"')
	var runner_banner_index := source.find('"battle/test_runner_banner_contract"')
	var contract_ordering_chain_index := source.find('"battle/test_probe_contract_ordering_chain"')
	_assert_true(runner_v4_banner_index != -1, "test_runner should include battle/test_runner_v4_banner_contract", failures)
	_assert_true(runner_banner_index != -1, "test_runner should include battle/test_runner_banner_contract", failures)
	_assert_true(contract_ordering_chain_index != -1, "test_runner should include battle/test_probe_contract_ordering_chain", failures)
	if runner_v4_banner_index != -1 and runner_banner_index != -1:
		_assert_true(runner_banner_index > runner_v4_banner_index, "main runner banner contract should stay after V4 runner banner contract", failures)
	if runner_banner_index != -1 and contract_ordering_chain_index != -1:
		_assert_true(contract_ordering_chain_index > runner_banner_index, "probe contract ordering chain should stay after main runner banner contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
