extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(source.contains('"error_threshold_value": _compute_error_threshold_weighted'), "critical fixture should derive error threshold from weighted aggregation", failures)
	_assert_true(source.contains('"engagement_time_weight"'), "critical fixture should persist engagement time weights", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
