extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('var scenarios: Array[String] = ["corridor", "dynamic_orbit", "funnel"]'), "warning fixture should keep runtime scenario set", failures)
	_assert_true(source.contains('scenario: String = scenarios[run_id % scenarios.size()]'), "warning fixture should still choose scenario at runtime", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
