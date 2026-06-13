extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"
const REQUIRED_SUITES := [
	'battle/test_debug_runtime_probe_fingerprint_contract',
	'battle/test_runtime_probe_oscillation_fingerprint_contract',
	'battle/test_v4_probe_contract_matrix',
	'battle/test_v4_probe_contract_matrix_v4_runner'
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
