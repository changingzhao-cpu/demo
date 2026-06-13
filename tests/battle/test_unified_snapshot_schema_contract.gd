extends RefCounted

const WARNING_ARTIFACT_PATH := "user://warning_sampling.json"
const CRITICAL_ARTIFACT_PATH := "user://critical_sampling.json"

func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data

func run() -> Array[String]:
	var failures: Array[String] = []
	var warning_payload := _read_json(WARNING_ARTIFACT_PATH)
	var critical_payload := _read_json(CRITICAL_ARTIFACT_PATH)
	_assert_true(not warning_payload.is_empty(), "warning artifact should exist before unified snapshot checks", failures)
	_assert_true(not critical_payload.is_empty(), "critical artifact should exist before unified snapshot checks", failures)
	if warning_payload.is_empty() or critical_payload.is_empty():
		return failures
	var warning_unified: Dictionary = warning_payload.get("unified_snapshot", {})
	var critical_unified: Dictionary = critical_payload.get("unified_snapshot", {})
	var warning_thresholds: Dictionary = warning_unified.get("thresholds", {})
	var critical_thresholds: Dictionary = critical_unified.get("thresholds", {})
	var warning_gate_results: Dictionary = warning_unified.get("gate_results", {})
	var critical_gate_results: Dictionary = critical_unified.get("gate_results", {})
	var warning_support_counts: Dictionary = warning_unified.get("support_counts", {})
	var critical_support_counts: Dictionary = critical_unified.get("support_counts", {})
	_assert_true(str(warning_unified.get("family", "")) == "warning", "warning unified snapshot should identify warning family", failures)
	_assert_true(str(critical_unified.get("family", "")) == "critical", "critical unified snapshot should identify critical family", failures)
	_assert_true(warning_unified.has("thresholds") and critical_unified.has("thresholds"), "both unified snapshots should persist thresholds block", failures)
	_assert_true(warning_unified.has("gate_results") and critical_unified.has("gate_results"), "both unified snapshots should persist gate results", failures)
	_assert_true(warning_unified.has("support_counts") and critical_unified.has("support_counts"), "both unified snapshots should persist support counts", failures)
	_assert_true(typeof(warning_unified.get("confidence_score", null)) == TYPE_FLOAT or typeof(warning_unified.get("confidence_score", null)) == TYPE_INT, "warning unified snapshot should persist confidence score", failures)
	_assert_true(typeof(critical_unified.get("confidence_score", null)) == TYPE_FLOAT or typeof(critical_unified.get("confidence_score", null)) == TYPE_INT, "critical unified snapshot should persist confidence score", failures)
	_assert_true(float(warning_unified.get("confidence_score", -1.0)) >= 0.0 and float(warning_unified.get("confidence_score", -1.0)) <= 1.0, "warning unified snapshot should normalize confidence score", failures)
	_assert_true(float(critical_unified.get("confidence_score", -1.0)) >= 0.0 and float(critical_unified.get("confidence_score", -1.0)) <= 1.0, "critical unified snapshot should normalize confidence score", failures)
	_assert_true(float(warning_thresholds.get("warning_threshold_value", -1.0)) == float(warning_payload.get("fitted_thresholds", {}).get("warning_threshold_value", -2.0)), "warning unified snapshot should mirror fitted warning threshold", failures)
	_assert_true(float(critical_thresholds.get("warning_threshold_value", -1.0)) == float(critical_payload.get("fitted_thresholds", {}).get("warning_threshold_value", -2.0)), "critical unified snapshot should mirror fitted warning threshold", failures)
	_assert_true(float(critical_thresholds.get("error_threshold_value", -1.0)) == float(critical_payload.get("fitted_thresholds", {}).get("error_threshold_value", -2.0)), "critical unified snapshot should mirror fitted error threshold", failures)
	_assert_true(bool(warning_unified.get("takeover_ready", false)) == bool(warning_gate_results.get("takeover_ready", false)), "warning unified snapshot should mirror gate takeover readiness", failures)
	_assert_true(bool(critical_unified.get("takeover_ready", false)) == bool(critical_gate_results.get("takeover_ready", false)), "critical unified snapshot should mirror gate takeover readiness", failures)
	_assert_true(int(warning_unified.get("sample_count", -1)) == int(warning_payload.get("sampling_results", {}).get("sample_count_completed", -2)), "warning unified snapshot should mirror warning sample count", failures)
	_assert_true(int(critical_unified.get("sample_count", -1)) == int(critical_payload.get("fitted_thresholds", {}).get("fitted_from_sample_count", -2)), "critical unified snapshot should mirror critical sample count", failures)
	_assert_true(int(warning_support_counts.get("nonzero_scenario_count", -1)) == int(warning_payload.get("sampling_results", {}).get("nonzero_scenario_count", -2)), "warning unified snapshot should mirror support count", failures)
	_assert_true(int(critical_support_counts.get("old_escape_true_count", -1)) == int(critical_payload.get("fitted_thresholds", {}).get("old_escape_true_count", -2)), "critical unified snapshot should mirror support count", failures)
	_assert_true((warning_unified.get("blockers", []) as Array).is_empty(), "warning unified snapshot should keep empty blocker list", failures)
	_assert_true((critical_unified.get("blockers", []) as Array).size() == (critical_gate_results.get("takeover_blockers", []) as Array).size(), "critical unified snapshot should mirror blocker list size", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
