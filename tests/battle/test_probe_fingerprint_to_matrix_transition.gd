extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var oscillation_index := source.find('"battle/test_runtime_probe_oscillation_fingerprint_contract"')
	var matrix_index := source.find('"battle/test_v4_probe_contract_matrix"')
	var matrix_v4_runner_index := source.find('"battle/test_v4_probe_contract_matrix_v4_runner"')
	_assert_true(oscillation_index != -1, "test_runner should include battle/test_runtime_probe_oscillation_fingerprint_contract", failures)
	_assert_true(matrix_index != -1, "test_runner should include battle/test_v4_probe_contract_matrix", failures)
	_assert_true(matrix_v4_runner_index != -1, "test_runner should include battle/test_v4_probe_contract_matrix_v4_runner", failures)
	if oscillation_index != -1 and matrix_index != -1:
		_assert_true(matrix_index == oscillation_index + 1 or matrix_index > oscillation_index, "probe contract matrix should stay after oscillation fingerprint contract", failures)
	if matrix_index != -1 and matrix_v4_runner_index != -1:
		_assert_true(matrix_v4_runner_index > matrix_index, "V4 runner matrix contract should stay after probe contract matrix", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
