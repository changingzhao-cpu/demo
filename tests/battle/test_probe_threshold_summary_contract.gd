extends RefCounted

const OSCILLATION_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"
const STATIC_PATH := "res://tests/battle/test_battle_runtime_probe_static_zero_deviation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var oscillation_source := FileAccess.get_file_as_string(OSCILLATION_PATH)
	var static_source := FileAccess.get_file_as_string(STATIC_PATH)
	var expected_tokens := [
		'"sample_name"',
		'"zone"',
		'"sample_count"',
		'"contention_index_min"',
		'"contention_index_mean"',
		'"contention_index_max"',
		'"late_commit_deviation_min"',
		'"late_commit_deviation_mean"',
		'"late_commit_deviation_max"',
		'"claim_success_rate_min"',
		'"claim_success_rate_mean"',
		'"claim_success_rate_max"',
		'"assignment_count_min"',
		'"assignment_count_mean"',
		'"assignment_count_max"',
		'"max_continuous_contention_ticks"'
	]
	for token in expected_tokens:
		_assert_true(oscillation_source.contains(token) or static_source.contains(token), "threshold summary contract should include %s" % token, failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
