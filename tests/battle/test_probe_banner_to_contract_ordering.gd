extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var runner_banner_index := source.find('"battle/test_runner_banner_contract"')
	var contract_ordering_index := source.find('"battle/test_probe_contract_ordering"')
	_assert_true(runner_banner_index != -1, "test_runner should include battle/test_runner_banner_contract", failures)
	_assert_true(contract_ordering_index != -1, "test_runner should include battle/test_probe_contract_ordering", failures)
	if runner_banner_index != -1 and contract_ordering_index != -1:
		_assert_true(contract_ordering_index > runner_banner_index, "probe contract ordering should stay after the runner banner contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
