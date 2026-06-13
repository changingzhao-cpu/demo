extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"warning_threshold_value": _compute_warning_threshold'), "critical fixture should derive warning threshold from aggregated samples", failures)
	_assert_true(source.contains('"error_threshold_value": _compute_error_threshold'), "critical fixture should derive error threshold from aggregated samples", failures)
	_assert_true(source.contains('"gate_a_critical_hit_rate": _compute_gate_a_critical_hit_rate'), "critical fixture should derive gate A from aggregated samples", failures)
	_assert_true(source.contains('"gate_b_fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate'), "critical fixture should derive gate B from aggregated samples", failures)
	_assert_true(source.contains('"gate_c_no_false_positive_records": _compute_gate_c_no_false_positive_records'), "critical fixture should derive gate C from aggregated samples", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
