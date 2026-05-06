extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"scenario_summaries"'), "warning payload should persist scenario summaries", failures)
	_assert_true(source.contains('"corridor"'), "warning payload should summarize corridor scenario", failures)
	_assert_true(source.contains('"dynamic_orbit"'), "warning payload should summarize dynamic orbit scenario", failures)
	_assert_true(source.contains('"funnel"'), "warning payload should summarize funnel scenario", failures)
	_assert_true(source.contains('"claim_success_rate_mean"'), "warning scenario summary should persist claim success mean", failures)
	_assert_true(source.contains('"late_commit_deviation_mean"'), "warning scenario summary should persist late commit mean", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
