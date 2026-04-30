extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"
const REQUIRED_SUITES := [
	'battle/test_debug_runtime_probe_v4_entry',
	'battle/test_debug_probe_backend_trace_v4_probe',
	'battle/test_debug_probe_identity_trace_v4_probe'
]

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	for suite_name_variant in REQUIRED_SUITES:
		var suite_name := str(suite_name_variant)
		_assert_true(source.contains('"%s"' % suite_name), "test_runner should include %s" % suite_name, failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
