extends RefCounted

const ARTIFACT_PATH := "user://critical_sampling.json"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(ARTIFACT_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	_assert_true(text != "", "critical sampling artifact should exist before takeover gate checks", failures)
	if text == "":
		return failures
	var json := JSON.new()
	var parse_result := json.parse(text)
	_assert_true(parse_result == OK, "critical sampling artifact should parse as json", failures)
	if parse_result != OK:
		return failures
	var payload: Dictionary = json.data
	var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
	var gate_results: Dictionary = unified_snapshot.get("gate_results", {})
	_assert_true(int(unified_snapshot.get("sample_count", -1)) == 20, "oscillation sampling should anchor 20-run critical family scale", failures)
	_assert_true(not gate_results.is_empty(), "oscillation sample should persist gate_results summary", failures)
	_assert_true(gate_results.has("critical_hit_rate"), "oscillation sample should persist critical hit rate gate", failures)
	_assert_true(static_source.contains('"fast_false_positive_rate"'), "static sample should persist fast false positive gate", failures)
	_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "critical unified snapshot should persist takeover readiness decision", failures)
	_assert_true(int(unified_snapshot.get("support_counts", {}).get("old_escape_true_count", -1)) == int(payload.get("fitted_thresholds", {}).get("old_escape_true_count", -2)), "critical unified snapshot should mirror old escape true count", failures)
	_assert_true(gate_results.has("gate_c_no_false_positive_records"), "oscillation sample should persist gate C no-false-positive record anchor", failures)
	_assert_true(payload.get("fitted_thresholds", {}).has("warning_threshold_value"), "oscillation sample should persist warning threshold value anchor", failures)
	_assert_true(payload.get("fitted_thresholds", {}).has("error_threshold_value"), "oscillation sample should persist error threshold value anchor", failures)
	_assert_true(gate_results.has("gate_a_critical_hit_rate"), "sampling should persist gate A execution anchor", failures)
	_assert_true(static_source.contains('"gate_b_fast_false_positive_rate"'), "sampling should persist gate B execution anchor", failures)
	_assert_true(gate_results.has("old_escape_hit_records"), "sampling should persist old escape hit records for gate A", failures)
	_assert_true(static_source.contains('"false_positive_records"'), "sampling should persist false positive records for gate B", failures)
	_assert_true(unified_snapshot.has("blockers"), "critical unified snapshot should persist blocker list", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
