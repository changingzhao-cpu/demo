extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"claim_success_rate_mean"'), "warning payload should persist aggregated claim_success_rate mean", failures)
	_assert_true(source.contains('"late_commit_deviation_mean"'), "warning payload should persist aggregated late_commit_deviation mean", failures)
	_assert_true(source.contains('"conflict_overlap_count_mean"'), "warning payload should persist aggregated conflict overlap mean", failures)
	_assert_true(source.contains('"warning_summary"'), "warning payload should persist warning summary block", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
