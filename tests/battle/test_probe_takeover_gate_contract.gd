extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	_assert_true(oscillation_source.contains('"sample_count": 20'), "oscillation sampling should anchor 20-run critical family scale", failures)
	_assert_true(oscillation_source.contains('"gate_results"'), "oscillation sample should persist gate_results summary", failures)
	_assert_true(oscillation_source.contains('"critical_hit_rate"'), "oscillation sample should persist critical hit rate gate", failures)
	_assert_true(static_source.contains('"fast_false_positive_rate"'), "static sample should persist fast false positive gate", failures)
	_assert_true(oscillation_source.contains('"takeover_ready"'), "oscillation sample should persist takeover readiness decision", failures)
	_assert_true(oscillation_source.contains('"gate_c_no_false_positive_records"'), "oscillation sample should persist gate C no-false-positive record anchor", failures)
	_assert_true(oscillation_source.contains('"warning_threshold_value"'), "oscillation sample should persist warning threshold value anchor", failures)
	_assert_true(oscillation_source.contains('"error_threshold_value"'), "oscillation sample should persist error threshold value anchor", failures)
	_assert_true(oscillation_source.contains('"gate_a_critical_hit_rate"'), "sampling should persist gate A execution anchor", failures)
	_assert_true(static_source.contains('"gate_b_fast_false_positive_rate"'), "sampling should persist gate B execution anchor", failures)
	_assert_true(oscillation_source.contains('"gate_c_no_false_positive_records"'), "sampling should persist gate C execution anchor", failures)
	_assert_true(oscillation_source.contains('"old_escape_hit_records"'), "sampling should persist old escape hit records for gate A", failures)
	_assert_true(static_source.contains('"false_positive_records"'), "sampling should persist false positive records for gate B", failures)
	_assert_true(oscillation_source.contains('"takeover_blockers"'), "sampling should persist takeover blocker list", failures)
	_assert_true(oscillation_source.contains('"takeover_ready"'), "sampling should persist explicit takeover readiness decision", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
