extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var runtime_probe_index := source.find('"battle/test_debug_runtime_probe_fingerprint_contract"')
	var oscillation_index := source.find('"battle/test_runtime_probe_oscillation_fingerprint_contract"')
	var matrix_index := source.find('"battle/test_v4_probe_contract_matrix"')
	_assert_true(runtime_probe_index != -1, "test_runner should contain runtime probe fingerprint contract", failures)
	_assert_true(oscillation_index != -1, "test_runner should contain oscillation fingerprint contract", failures)
	_assert_true(matrix_index != -1, "test_runner should contain probe contract matrix", failures)
	if runtime_probe_index != -1 and oscillation_index != -1:
		_assert_true(runtime_probe_index < oscillation_index, "test_runner should place runtime probe fingerprint contract before oscillation fingerprint contract", failures)
	if oscillation_index != -1 and matrix_index != -1:
		_assert_true(oscillation_index < matrix_index, "test_runner should place oscillation fingerprint contract before probe contract matrix", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
