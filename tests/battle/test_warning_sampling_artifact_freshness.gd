extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"sample_count_completed"'), "warning sampling should persist sample_count_completed", failures)
	_assert_true(source.contains('"nonzero_scenario_count"'), "warning sampling should persist nonzero_scenario_count", failures)
	_assert_true(source.contains('run_count_completed": samples.size()'), "warning sampling should derive run_count_completed from samples size", failures)
	_assert_true(source.contains('sample_count_completed": samples.size()'), "warning sampling should derive sample_count_completed from samples size", failures)
	_assert_true(source.contains('nonzero_scenario_count": nonzero_scenario_count'), "warning sampling should derive nonzero scenario count from scenario summaries", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])

func _initialize() -> void:
	pass
