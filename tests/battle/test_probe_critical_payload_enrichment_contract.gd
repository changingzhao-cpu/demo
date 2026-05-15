extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"threshold_formula"'), "critical payload should persist threshold_formula key", failures)
	_assert_true(source.contains('"fitted_thresholds"'), "critical payload should persist fitted_thresholds key", failures)
	_assert_true(source.contains('"perturbation_summary"'), "critical payload should persist perturbation_summary key", failures)
	_assert_true(source.contains('"anomaly_scan"'), "critical payload should persist anomaly_scan key", failures)
	_assert_true(source.contains('gate_results["attack_rebind_escape_count"] = int(perturbation_summary.get("attack_rebind_escape_count", 0))'), "critical perturbation summary should mirror unified gate attack_rebind_escape_count", failures)
	_assert_true(source.contains('gate_results["attack_rebind_recontact_count"] = int(perturbation_summary.get("attack_rebind_recontact_count", 0))'), "critical perturbation summary should mirror unified gate attack_rebind_recontact_count", failures)
	_assert_true(source.contains('gate_results["attack_midband_drift_count"] = int(perturbation_summary.get("attack_midband_drift_count", 0))'), "critical perturbation summary should mirror unified gate attack_midband_drift_count", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
