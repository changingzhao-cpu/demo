extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"sample_count": 50'), "warning plan should expand to 50-run sampling", failures)
	_assert_true(source.contains('"scenario_family": "warning"'), "warning plan should tag scenario family", failures)
	_assert_true(source.contains('["corridor", "dynamic_orbit", "funnel"]'), "warning plan should include corridor/dynamic_orbit/funnel topology set", failures)
	_assert_true(source.contains('run_id % scenarios.size()'), "warning plan should rotate through warning topologies across runs", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
