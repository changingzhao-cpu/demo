extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var lines := source.split("\n")
	var runtime_index := -1
	var backend_index := -1
	var identity_index := -1
	for i in range(lines.size()):
		var line := lines[i]
		if line.contains('"battle/test_debug_runtime_probe_v4_entry"'):
			runtime_index = i
		elif line.contains('"battle/test_debug_probe_backend_trace_v4_probe"'):
			backend_index = i
		elif line.contains('"battle/test_debug_probe_identity_trace_v4_probe"'):
			identity_index = i
	_assert_true(runtime_index != -1, "test_runner should include battle/test_debug_runtime_probe_v4_entry", failures)
	_assert_true(backend_index != -1, "test_runner should include battle/test_debug_probe_backend_trace_v4_probe", failures)
	_assert_true(identity_index != -1, "test_runner should include battle/test_debug_probe_identity_trace_v4_probe", failures)
	if runtime_index != -1 and backend_index != -1:
		_assert_true(backend_index == runtime_index + 1, "backend trace probe test should stay immediately after debug runtime probe entry", failures)
	if backend_index != -1 and identity_index != -1:
		_assert_true(identity_index == backend_index + 1, "identity trace probe test should stay immediately after backend trace probe test", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
