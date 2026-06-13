extends RefCounted

const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"
const MEDIUM_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"
const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	var medium_source := FileAccess.get_file_as_string(MEDIUM_PATH)
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	_assert_true(static_source.contains('"outlier_count"'), "comfort family should persist outlier count", failures)
	_assert_true(medium_source.contains('"outlier_count"'), "warning family should persist outlier count", failures)
	_assert_true(oscillation_source.contains('"outlier_count"'), "critical family should persist outlier count", failures)
	_assert_true(oscillation_source.contains('"outlier_samples"'), "critical family should persist outlier sample list", failures)
	_assert_true(oscillation_source.contains('"p95_contention"'), "critical family should anchor p95_contention scatter axis", failures)
	_assert_true(oscillation_source.contains('"max_duration"'), "critical family should anchor max_duration scatter axis", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
