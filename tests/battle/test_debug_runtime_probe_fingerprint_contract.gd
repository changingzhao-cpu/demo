extends RefCounted

const SCRIPT_PATH := "res://tests/debug_runtime_probe.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('"v4_probe_fingerprint"'), "debug runtime probe script should export v4_probe_fingerprint", failures)
	_assert_true(source.contains('"v4_probe_baseline"'), "debug runtime probe script should export v4_probe_baseline", failures)
	_assert_true(source.contains('"claim_success_rate"'), "debug runtime probe script should keep claim_success_rate in fingerprint contract", failures)
	_assert_true(source.contains('"contention_index"'), "debug runtime probe script should keep contention_index in fingerprint contract", failures)
	_assert_true(source.contains('"late_commit_deviation"'), "debug runtime probe script should keep late_commit_deviation in fingerprint contract", failures)
	_assert_true(source.contains('"assignment_count"'), "debug runtime probe script should keep assignment_count in fingerprint contract", failures)
	_assert_true(source.contains('claim_success_rate='), "debug runtime probe script should export readable claim_success_rate baseline", failures)
	_assert_true(source.contains('contention_index='), "debug runtime probe script should export readable contention_index baseline", failures)
	_assert_true(source.contains('late_commit_deviation='), "debug runtime probe script should export readable late_commit_deviation baseline", failures)
	_assert_true(source.contains('assignment_count='), "debug runtime probe script should export readable assignment_count baseline", failures)
	_assert_true(source.contains('output["v4_probe_baseline"] = "claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s" % ['), "debug runtime probe script should emit canonical v4_probe_baseline format", failures)
	_assert_true(source.contains('claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s'), "debug runtime probe script should keep canonical baseline text sequence", failures)
	var baseline_key_order := ["claim_success_rate=", "contention_index=", "late_commit_deviation=", "assignment_count=%s"]
	var previous_index := -1
	for token_variant in baseline_key_order:
		var token := str(token_variant)
		var token_index := source.find(token)
		_assert_true(token_index != -1, "debug runtime probe script should include baseline token %s" % token, failures)
		if previous_index != -1 and token_index != -1:
			_assert_true(token_index > previous_index, "debug runtime probe script should keep canonical baseline token order", failures)
		previous_index = token_index
	_assert_true(source.count("var verify_probe: Dictionary = output.get(\"v4_probe\", {})") == 1, "debug runtime probe script should declare verify_probe only once", failures)
	_assert_true(source.count("var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)") == 1, "debug runtime probe script should open output file only once", failures)
	_assert_true(source.count("print(\"[PROBE] wrote %s\" % ProjectSettings.globalize_path(OUTPUT_PATH))") == 1, "debug runtime probe script should emit probe output banner only once", failures)
	_assert_true(not source.contains('"v4_probe_baseline_source"'), "debug runtime probe script should not persist baseline provenance wrapper outside golden sample fixtures", failures)
	_assert_true(not source.contains('"baseline_snapshot"'), "debug runtime probe script should not persist baseline snapshot outside golden sample fixtures", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
