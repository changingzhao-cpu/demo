extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var entry_index := source.find('"battle/test_debug_runtime_probe_v4_entry"')
	var contract_index := source.find('"battle/test_debug_runtime_probe_fingerprint_contract"')
	_assert_true(entry_index != -1, "test_runner should include battle/test_debug_runtime_probe_v4_entry", failures)
	_assert_true(contract_index != -1, "test_runner should include battle/test_debug_runtime_probe_fingerprint_contract", failures)
	if entry_index != -1 and contract_index != -1:
		_assert_true(entry_index < contract_index, "debug runtime probe entry should stay before the fingerprint contract block", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
