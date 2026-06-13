extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var matrix_index := source.find('"battle/test_v4_probe_contract_matrix"')
	var matrix_v4_runner_index := source.find('"battle/test_v4_probe_contract_matrix_v4_runner"')
	var suite_membership_index := source.find('"battle/test_probe_contract_suite_membership"')
	_assert_true(matrix_index != -1, "test_runner should include battle/test_v4_probe_contract_matrix", failures)
	_assert_true(matrix_v4_runner_index != -1, "test_runner should include battle/test_v4_probe_contract_matrix_v4_runner", failures)
	_assert_true(suite_membership_index != -1, "test_runner should include battle/test_probe_contract_suite_membership", failures)
	if matrix_index != -1 and matrix_v4_runner_index != -1:
		_assert_true(matrix_v4_runner_index > matrix_index, "V4 runner matrix contract should stay after probe contract matrix", failures)
	if matrix_v4_runner_index != -1 and suite_membership_index != -1:
		_assert_true(suite_membership_index > matrix_v4_runner_index, "probe contract suite membership should stay after V4 runner matrix contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
