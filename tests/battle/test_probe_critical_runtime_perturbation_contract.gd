extends RefCounted

const OscillationFixture = preload("res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd")
const ARTIFACT_PATH := "C:/Users/admin/AppData/Roaming/Godot/app_userdata/demo/critical_sampling.json"

func _read_artifact_text() -> String:
	return FileAccess.get_file_as_string(ARTIFACT_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	var text := _read_artifact_text()
	_assert_true(text != "", "critical sampling artifact should exist before perturbation contract checks", failures)
	if text == "":
		return failures
	var json := JSON.new()
	var parse_result := json.parse(text)
	_assert_true(parse_result == OK, "critical sampling artifact should parse as json for perturbation contract checks", failures)
	if parse_result != OK:
		return failures
	var payload: Dictionary = json.data
	var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
	var gate_results: Dictionary = unified_snapshot.get("gate_results", {})
	_assert_true(payload.has("anomaly_scan"), "critical artifact should expose anomaly_scan for perturbation hardening", failures)
	_assert_true(payload.has("perturbation_summary"), "critical artifact should expose perturbation_summary for perturbation hardening", failures)
	_assert_true(payload.has("perturbation_summary"), "real business baseline should still preserve perturbation_summary for later interpretation", failures)
	_assert_true(gate_results.has("takeover_ready"), "critical gate results should still expose takeover_ready during perturbation hardening", failures)
	_assert_true(typeof(payload.get("anomaly_scan", null)) == TYPE_DICTIONARY, "critical anomaly_scan should remain a dictionary", failures)
	_assert_true(typeof(payload.get("perturbation_summary", null)) == TYPE_DICTIONARY, "critical perturbation_summary should remain a dictionary", failures)
	_assert_true(payload.get("anomaly_scan", {}).has("attack_rebind_escape_count"), "critical anomaly_scan should expose attack_rebind_escape_count", failures)
	_assert_true(payload.get("anomaly_scan", {}).has("attack_rebind_recontact_count"), "critical anomaly_scan should expose attack_rebind_recontact_count", failures)
	_assert_true(payload.get("anomaly_scan", {}).has("attack_midband_drift_count"), "critical anomaly_scan should expose attack_midband_drift_count", failures)
	_assert_true(payload.get("perturbation_summary", {}).has("attack_rebind_escape_count"), "critical perturbation_summary should expose attack_rebind_escape_count", failures)
	_assert_true(payload.get("perturbation_summary", {}).has("attack_rebind_recontact_count"), "critical perturbation_summary should expose attack_rebind_recontact_count", failures)
	_assert_true(payload.get("perturbation_summary", {}).has("attack_midband_drift_count"), "critical perturbation_summary should expose attack_midband_drift_count", failures)
	_assert_true(gate_results.has("attack_rebind_escape_count"), "critical gate results should expose attack_rebind_escape_count", failures)
	_assert_true(gate_results.has("attack_rebind_recontact_count"), "critical gate results should expose attack_rebind_recontact_count", failures)
	_assert_true(gate_results.has("attack_midband_drift_count"), "critical gate results should expose attack_midband_drift_count", failures)
	_assert_true(int(payload.get("perturbation_summary", {}).get("attack_rebind_escape_count", -1)) == int(gate_results.get("attack_rebind_escape_count", -2)), "critical perturbation_summary should mirror gate attack_rebind_escape_count", failures)
	_assert_true(int(payload.get("perturbation_summary", {}).get("attack_rebind_recontact_count", -1)) == int(gate_results.get("attack_rebind_recontact_count", -2)), "critical perturbation_summary should mirror gate attack_rebind_recontact_count", failures)
	_assert_true(int(payload.get("perturbation_summary", {}).get("attack_midband_drift_count", -1)) == int(gate_results.get("attack_midband_drift_count", -2)), "critical perturbation_summary should mirror gate attack_midband_drift_count", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
