extends RefCounted

const CORE_PATH := "res://tests/battle/battle_warning_sampler_core.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(CORE_PATH)
	_assert_true(not source.contains('scenario_contention = 0.72'), "warning sampler should stop hard-coding corridor contention", failures)
	_assert_true(not source.contains('scenario_contention = 0.48'), "warning sampler should stop hard-coding dynamic_orbit contention", failures)
	_assert_true(not source.contains('scenario_contention = 0.66'), "warning sampler should stop hard-coding funnel contention", failures)
	_assert_true(not source.contains('scenario_overlap = 6'), "warning sampler should stop hard-coding corridor overlap", failures)
	_assert_true(not source.contains('scenario_overlap = 4'), "warning sampler should stop hard-coding dynamic_orbit overlap", failures)
	_assert_true(not source.contains('scenario_overlap = 5'), "warning sampler should stop hard-coding funnel overlap", failures)
	_assert_true(not source.contains('scenario_latency = 0.18'), "warning sampler should stop hard-coding corridor latency", failures)
	_assert_true(not source.contains('scenario_latency = 0.31'), "warning sampler should stop hard-coding dynamic_orbit latency", failures)
	_assert_true(not source.contains('scenario_latency = 0.22'), "warning sampler should stop hard-coding funnel latency", failures)
	_assert_true(source.contains('"contention_index": probe_p95_contention'), "warning sampler should derive contention_index from probe p95 contention", failures)
	_assert_true(source.contains('"late_commit_deviation": probe_latency'), "warning sampler should derive late_commit_deviation from probe latency", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
