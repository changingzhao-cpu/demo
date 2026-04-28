extends RefCounted

const SCRIPT_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('"v4_probe_fingerprint"'), "oscillation fixture should persist v4_probe_fingerprint", failures)
	_assert_true(source.contains('"v4_probe_baseline"'), "oscillation fixture should persist v4_probe_baseline", failures)
	_assert_true(source.contains('claim_success_rate='), "oscillation fixture should persist readable claim_success_rate baseline", failures)
	_assert_true(source.contains('contention_index='), "oscillation fixture should persist readable contention_index baseline", failures)
	_assert_true(source.contains('late_commit_deviation='), "oscillation fixture should persist readable late_commit_deviation baseline", failures)
	_assert_true(source.contains('assignment_count='), "oscillation fixture should persist readable assignment_count baseline", failures)
	_assert_true(source.contains('v4_probe_baseline=claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s'), "oscillation fixture should emit a single canonical v4_probe_baseline line", failures)
	_assert_true(source.contains('claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s'), "oscillation fixture should keep canonical baseline text sequence", failures)
	var baseline_key_order := ["claim_success_rate=", "contention_index=", "late_commit_deviation=", "assignment_count=%s"]
	var previous_index := -1
	for token_variant in baseline_key_order:
		var token := str(token_variant)
		var token_index := source.find(token)
		_assert_true(token_index != -1, "oscillation fixture should include baseline token %s" % token, failures)
		if previous_index != -1 and token_index != -1:
			_assert_true(token_index > previous_index, "oscillation fixture should keep canonical baseline token order", failures)
		previous_index = token_index
	_assert_true(source.contains('"claim_success_rate": v4_probe.get("claim_success_rate", null),\n\t\t\t\t"contention_index": v4_probe.get("contention_index", null),\n\t\t\t\t"late_commit_deviation": v4_probe.get("late_commit_deviation", null),\n\t\t\t\t"assignment_count": int(v4_probe.get("assignments", {}).size()) if v4_probe.get("assignments", {}) is Dictionary else -1'), "oscillation fixture should keep canonical fingerprint field ordering", failures)
	_assert_true(source.contains('"v4_probe_baseline_source": v4_probe_fingerprint'), "oscillation fixture should archive baseline-to-fingerprint provenance", failures)
	_assert_true(source.contains('"baseline_snapshot"'), "oscillation fixture should persist baseline_snapshot", failures)
	_assert_true(source.contains('"sample_name": "oscillation"'), "oscillation fixture should fix baseline snapshot sample name", failures)
	_assert_true(source.contains('"snapshot_version": 1'), "oscillation fixture should fix baseline snapshot version", failures)
	_assert_true(source.contains('"baseline_text": v4_probe_baseline'), "oscillation fixture should map baseline snapshot text to v4_probe_baseline", failures)
	_assert_true(source.contains('"fingerprint": v4_probe_fingerprint'), "oscillation fixture should map baseline snapshot fingerprint to v4_probe_fingerprint", failures)
	_assert_true(source.contains('"baseline_source": v4_probe_fingerprint'), "oscillation fixture should map baseline snapshot source to v4_probe_fingerprint", failures)
	_assert_true(source.contains('"capture_context"'), "oscillation fixture should persist baseline snapshot capture context", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
