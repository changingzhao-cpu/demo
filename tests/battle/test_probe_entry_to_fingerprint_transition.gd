extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var lines := source.split("\n")
	var identity_index := -1
	var fingerprint_index := -1
	var oscillation_index := -1
	for i in range(lines.size()):
		var line := lines[i]
		if line.contains('"battle/test_debug_probe_identity_trace_v4_probe"'):
			identity_index = i
		elif line.contains('"battle/test_debug_runtime_probe_fingerprint_contract"'):
			fingerprint_index = i
		elif line.contains('"battle/test_runtime_probe_oscillation_fingerprint_contract"'):
			oscillation_index = i
	_assert_true(identity_index != -1, "test_runner should include battle/test_debug_probe_identity_trace_v4_probe", failures)
	_assert_true(fingerprint_index != -1, "test_runner should include battle/test_debug_runtime_probe_fingerprint_contract", failures)
	_assert_true(oscillation_index != -1, "test_runner should include battle/test_runtime_probe_oscillation_fingerprint_contract", failures)
	if identity_index != -1 and fingerprint_index != -1:
		_assert_true(fingerprint_index == identity_index + 1, "debug runtime probe fingerprint contract should stay immediately after identity trace probe test", failures)
	if fingerprint_index != -1 and oscillation_index != -1:
		_assert_true(oscillation_index == fingerprint_index + 1, "oscillation fingerprint contract should stay immediately after debug runtime probe fingerprint contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
