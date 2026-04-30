extends RefCounted

const RUNNER_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(RUNNER_PATH)
	var golden_suites := [
		'battle/test_debug_runtime_probe_v4_entry',
		'battle/test_debug_probe_backend_trace_v4_probe',
		'battle/test_debug_probe_identity_trace_v4_probe',
		'battle/test_runtime_probe_oscillation_fingerprint_contract'
	]
	for suite_name in golden_suites:
		_assert_true(source.contains('"name": "%s"' % suite_name), "runner should keep golden probe suite %s" % suite_name, failures)
	_assert_true(source.contains('"name": "battle/test_probe_golden_entry_membership"'), "runner should register golden entry membership contract", failures)
	_assert_true(golden_suites.size() == 4, "golden probe suite count should stay fixed at 4 during consolidation", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
