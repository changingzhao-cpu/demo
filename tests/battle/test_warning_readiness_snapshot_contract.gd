extends RefCounted

const ARTIFACT_PATH := "user://warning_sampling.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(ARTIFACT_PATH)
	_assert_true(text != "", "warning artifact should exist before readiness snapshot checks", failures)
	if text == "":
		return failures
	var json := JSON.new()
	var parse_result := json.parse(text)
	_assert_true(parse_result == OK, "warning artifact should parse as json", failures)
	if parse_result != OK:
		return failures
	var payload: Dictionary = json.data
	var legacy_readiness_snapshot: Dictionary = payload.get("readiness_snapshot", {})
	var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
	var unified_thresholds: Dictionary = unified_snapshot.get("thresholds", {})
	var unified_counts: Dictionary = unified_snapshot.get("support_counts", {})
	var unified_gate_results: Dictionary = unified_snapshot.get("gate_results", {})
	var gate_results: Dictionary = payload.get("gate_results", {})
	var fitted_thresholds: Dictionary = payload.get("fitted_thresholds", {})
	var sampling_results: Dictionary = payload.get("sampling_results", {})
	_assert_true(not unified_snapshot.is_empty(), "unified snapshot should not be empty", failures)
	_assert_true(str(unified_snapshot.get("family", "")) == "warning", "unified snapshot should identify warning family", failures)
	_assert_has_keys(unified_snapshot, ["thresholds", "support_counts", "gate_results", "blockers"], "unified snapshot should expose", failures)
	_assert_has_keys(unified_thresholds, ["warning_upper_threshold_value", "warning_threshold_value", "warning_lower_threshold_value"], "unified snapshot should expose", failures)
	_assert_has_keys(unified_counts, ["nonzero_scenario_count"], "unified snapshot should expose", failures)
	_assert_has_keys(unified_gate_results, ["gate_b_warning_band_ordering", "gate_b_warning_overlap_ordering", "gate_b_warning_clumping_ordering", "gate_b_warning_latency_ordering", "sample_count"], "unified snapshot should keep", failures)
	_assert_numeric_or_int(unified_snapshot.get("confidence_score", null), "warning unified confidence score should remain numeric", failures)
	_assert_true(typeof(unified_snapshot.get("blockers", null)) == TYPE_ARRAY, "warning unified blockers should remain an array", failures)
	_assert_true(typeof(unified_snapshot.get("support_counts", null)) == TYPE_DICTIONARY, "warning unified support_counts should remain a dictionary", failures)
	_assert_true(typeof(unified_snapshot.get("thresholds", null)) == TYPE_DICTIONARY, "warning unified thresholds should remain a dictionary", failures)
	_assert_true(typeof(unified_snapshot.get("gate_results", null)) == TYPE_DICTIONARY, "warning unified gate results should remain a dictionary", failures)
	_assert_numeric_or_int(unified_snapshot.get("sample_count", null), "warning unified sample_count should remain numeric", failures)
	_assert_true(typeof(unified_snapshot.get("takeover_ready", null)) == TYPE_BOOL, "warning unified takeover_ready should remain a bool", failures)
	_assert_true(typeof(unified_snapshot.get("family", null)) == TYPE_STRING, "warning unified family should remain a string", failures)
	_assert_numeric_or_int(unified_thresholds.get("warning_upper_threshold_value", null), "warning unified upper threshold should remain numeric", failures)
	_assert_numeric_or_int(unified_thresholds.get("warning_threshold_value", null), "warning unified center threshold should remain numeric", failures)
	_assert_numeric_or_int(unified_thresholds.get("warning_lower_threshold_value", null), "warning unified lower threshold should remain numeric", failures)
	_assert_numeric_or_int(unified_counts.get("nonzero_scenario_count", null), "warning unified support count should remain numeric", failures)
	_assert_true(float(unified_thresholds.get("warning_upper_threshold_value", 0.0)) > float(unified_thresholds.get("warning_threshold_value", 0.0)) and float(unified_thresholds.get("warning_threshold_value", 0.0)) > float(unified_thresholds.get("warning_lower_threshold_value", 0.0)), "unified snapshot should preserve upper > center > lower threshold ordering", failures)
	_assert_true(float(unified_thresholds.get("warning_upper_threshold_value", 0.0)) > 0.0, "warning unified upper threshold should stay positive", failures)
	_assert_true(float(unified_thresholds.get("warning_threshold_value", 0.0)) > 0.0, "warning unified center threshold should stay positive", failures)
	_assert_true(float(unified_thresholds.get("warning_lower_threshold_value", 0.0)) > 0.0, "warning unified lower threshold should stay positive", failures)
	_assert_true(float(unified_snapshot.get("confidence_score", -1.0)) == 1.0, "warning unified snapshot should persist normalized confidence score", failures)
	_assert_true(float(unified_snapshot.get("confidence_score", -1.0)) >= 0.0 and float(unified_snapshot.get("confidence_score", -1.0)) <= 1.0, "warning unified confidence score should remain normalized", failures)
	_assert_true(Array(unified_snapshot.get("blockers", [])).is_empty(), "warning unified snapshot blockers should remain empty", failures)
	_assert_true(int(unified_counts.get("nonzero_scenario_count", -1)) == 3, "warning unified support count should stay at three scenarios", failures)
	_assert_true(float(unified_thresholds.get("warning_upper_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_upper_threshold_value", 0.0)), "unified snapshot should mirror fitted upper threshold", failures)
	_assert_true(float(unified_thresholds.get("warning_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_threshold_value", 0.0)), "unified snapshot should mirror fitted center threshold", failures)
	_assert_true(float(unified_thresholds.get("warning_lower_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_lower_threshold_value", 0.0)), "unified snapshot should mirror fitted lower threshold", failures)
	_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "unified snapshot should mirror takeover readiness", failures)
	_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(unified_gate_results.get("takeover_ready", true)), "unified snapshot should mirror nested takeover readiness", failures)
	_assert_true(int(unified_snapshot.get("sample_count", -1)) == int(sampling_results.get("sample_count_completed", -2)), "unified snapshot should mirror sample_count_completed", failures)
	_assert_true(int(unified_snapshot.get("sample_count", -1)) == int(gate_results.get("sample_count", -2)), "unified snapshot should mirror gate result sample_count", failures)
	_assert_true(int(unified_snapshot.get("sample_count", -1)) == int(unified_gate_results.get("sample_count", -2)), "unified nested gate sample_count should mirror unified sample_count", failures)
	_assert_true(int(unified_counts.get("nonzero_scenario_count", -1)) == int(sampling_results.get("nonzero_scenario_count", -2)), "unified snapshot should mirror nonzero_scenario_count", failures)
	_assert_true(not legacy_readiness_snapshot.is_empty(), "readiness snapshot should remain populated for compatibility", failures)
	_assert_true(str(legacy_readiness_snapshot.get("family", "")) == str(unified_snapshot.get("family", "")), "readiness snapshot should mirror unified family", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_upper_threshold_value", 0.0)) == float(unified_thresholds.get("warning_upper_threshold_value", 0.0)), "readiness snapshot should mirror unified upper threshold", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_threshold_value", 0.0)) == float(unified_thresholds.get("warning_threshold_value", 0.0)), "readiness snapshot should mirror unified center threshold", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_lower_threshold_value", 0.0)) == float(unified_thresholds.get("warning_lower_threshold_value", 0.0)), "readiness snapshot should mirror unified lower threshold", failures)
	_assert_true(bool(legacy_readiness_snapshot.get("takeover_ready", false)) == bool(unified_snapshot.get("takeover_ready", false)), "readiness snapshot should mirror unified takeover readiness", failures)
	_assert_true(int(legacy_readiness_snapshot.get("sample_count", -1)) == int(unified_snapshot.get("sample_count", -2)), "readiness snapshot should mirror unified sample_count", failures)
	_assert_true(int(legacy_readiness_snapshot.get("nonzero_scenario_count", -1)) == int(unified_counts.get("nonzero_scenario_count", -2)), "readiness snapshot should mirror unified nonzero_scenario_count", failures)
	_assert_true(int(legacy_readiness_snapshot.get("sample_count", -1)) == int(gate_results.get("sample_count", -2)), "readiness snapshot should mirror gate sample_count", failures)
	_assert_true(str(legacy_readiness_snapshot.get("family", "")) == "warning", "readiness snapshot should remain warning for compatibility", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_upper_threshold_value", 0.0)) > float(legacy_readiness_snapshot.get("warning_threshold_value", 0.0)) and float(legacy_readiness_snapshot.get("warning_threshold_value", 0.0)) > float(legacy_readiness_snapshot.get("warning_lower_threshold_value", 0.0)), "readiness snapshot should preserve threshold ordering while remaining secondary", failures)
	_assert_true(int(legacy_readiness_snapshot.get("nonzero_scenario_count", -1)) == 3, "readiness snapshot should keep the three-scenario support count for compatibility", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_upper_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_upper_threshold_value", 0.0)), "readiness snapshot should still mirror fitted upper threshold for compatibility", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_threshold_value", 0.0)), "readiness snapshot should still mirror fitted center threshold for compatibility", failures)
	_assert_true(float(legacy_readiness_snapshot.get("warning_lower_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_lower_threshold_value", 0.0)), "readiness snapshot should still mirror fitted lower threshold for compatibility", failures)
	_assert_true(int(legacy_readiness_snapshot.get("sample_count", -1)) == int(sampling_results.get("sample_count_completed", -2)), "readiness snapshot should still mirror completed sample count for compatibility", failures)
	_assert_true(int(legacy_readiness_snapshot.get("nonzero_scenario_count", -1)) == int(sampling_results.get("nonzero_scenario_count", -2)), "readiness snapshot should still mirror nonzero scenario count for compatibility", failures)
	_assert_true(bool(legacy_readiness_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "readiness snapshot should still mirror top-level gate takeover readiness", failures)
	_assert_true(typeof(legacy_readiness_snapshot.get("family", null)) == TYPE_STRING, "readiness snapshot family should remain a string", failures)
	_assert_true(typeof(legacy_readiness_snapshot.get("takeover_ready", null)) == TYPE_BOOL, "readiness snapshot takeover readiness should remain a bool", failures)
	_assert_numeric_or_int(legacy_readiness_snapshot.get("sample_count", null), "readiness snapshot sample count should remain numeric", failures)
	_assert_numeric_or_int(legacy_readiness_snapshot.get("nonzero_scenario_count", null), "readiness snapshot support count should remain numeric", failures)
	_assert_numeric_or_int(legacy_readiness_snapshot.get("warning_upper_threshold_value", null), "readiness snapshot upper threshold should remain numeric", failures)
	_assert_numeric_or_int(legacy_readiness_snapshot.get("warning_threshold_value", null), "readiness snapshot center threshold should remain numeric", failures)
	_assert_numeric_or_int(legacy_readiness_snapshot.get("warning_lower_threshold_value", null), "readiness snapshot lower threshold should remain numeric", failures)
	_assert_true(legacy_readiness_snapshot.size() >= 6, "readiness snapshot should remain populated with compatibility fields", failures)
	return failures

func _assert_has_keys(dict: Dictionary, keys: Array, prefix: String, failures: Array[String]) -> void:
	for key in keys:
		_assert_true(dict.has(key), "%s %s" % [prefix, str(key).replace("_", " ")], failures)

func _assert_numeric_or_int(value: Variant, message: String, failures: Array[String]) -> void:
	_assert_true(typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT, message, failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
