extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var entry_index := source.find('"battle/test_debug_runtime_probe_v4_entry"')
	var backend_index := source.find('"battle/test_debug_probe_backend_trace_v4_probe"')
	var identity_index := source.find('"battle/test_debug_probe_identity_trace_v4_probe"')
	var fingerprint_index := source.find('"battle/test_debug_runtime_probe_fingerprint_contract"')
	_assert_true(entry_index != -1, "test_runner should include battle/test_debug_runtime_probe_v4_entry", failures)
	_assert_true(backend_index != -1, "test_runner should include battle/test_debug_probe_backend_trace_v4_probe", failures)
	_assert_true(identity_index != -1, "test_runner should include battle/test_debug_probe_identity_trace_v4_probe", failures)
	_assert_true(fingerprint_index != -1, "test_runner should include battle/test_debug_runtime_probe_fingerprint_contract", failures)
	if entry_index != -1 and backend_index != -1:
		_assert_true(backend_index > entry_index, "backend trace probe test should stay after debug runtime probe entry", failures)
	if backend_index != -1 and identity_index != -1:
		_assert_true(identity_index > backend_index, "identity trace probe test should stay after backend trace probe test", failures)
	if identity_index != -1 and fingerprint_index != -1:
		_assert_true(fingerprint_index > identity_index, "debug runtime probe fingerprint contract should stay after identity trace probe test", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
