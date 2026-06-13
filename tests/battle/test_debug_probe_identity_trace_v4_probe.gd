extends RefCounted

const SCRIPT_PATH := "res://tests/battle/debug_probe_identity_trace.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('"v4_probe"'), "identity trace debug script should export v4_probe", failures)
	_assert_true(source.contains('"claim_success_rate"'), "identity trace debug script should assert claim_success_rate", failures)
	_assert_true(source.contains('"contention_index"'), "identity trace debug script should assert contention_index", failures)
	_assert_true(source.contains('"late_commit_deviation"'), "identity trace debug script should assert late_commit_deviation", failures)
	_assert_true(source.contains('"v4_probe_fingerprint"'), "identity trace debug script should export v4_probe_fingerprint", failures)
	_assert_true(source.contains('"v4_probe_baseline"'), "identity trace debug script should export v4_probe_baseline", failures)
	_assert_true(source.contains('"assignment_count"'), "identity trace debug script should export fingerprint assignment_count", failures)
	var claim_index := source.find('"claim_success_rate": v4_probe.get("claim_success_rate", null)')
	var contention_index := source.find('"contention_index": v4_probe.get("contention_index", null)')
	var late_commit_index := source.find('"late_commit_deviation": v4_probe.get("late_commit_deviation", null)')
	var assignment_index := source.find('"assignment_count": int(v4_probe.get("assignments", {}).size()) if v4_probe.get("assignments", {}) is Dictionary else -1')
	_assert_true(claim_index != -1 and contention_index != -1 and late_commit_index != -1 and assignment_index != -1 and claim_index < contention_index and contention_index < late_commit_index and late_commit_index < assignment_index, "identity trace debug script should keep canonical fingerprint field ordering", failures)
	_assert_true(source.contains('var v4_probe_baseline := "claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s" % ['), "identity trace debug script should declare canonical baseline variable", failures)
	_assert_true(not source.contains('"baseline_snapshot"'), "identity trace debug script should not persist baseline_snapshot outside oscillation sample", failures)
	var baseline_key_order := ["claim_success_rate=", "contention_index=", "late_commit_deviation=", "assignment_count=%s"]
	var previous_index := -1
	for token_variant in baseline_key_order:
		var token := str(token_variant)
		var token_index := source.find(token)
		_assert_true(token_index != -1, "identity trace debug script should include baseline token %s" % token, failures)
		if previous_index != -1 and token_index != -1:
			_assert_true(token_index > previous_index, "identity trace debug script should keep canonical baseline token order", failures)
		previous_index = token_index
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
