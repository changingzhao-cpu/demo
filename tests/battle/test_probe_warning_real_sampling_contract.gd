extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"debug_force_simulation_backend"'), "warning fixture should switch controller backend to v4", failures)
	_assert_true(source.contains('"debug_get_runtime_trace_payload"'), "warning fixture should collect runtime probe payload", failures)
	_assert_true(source.contains('"claim_success_rate"'), "warning fixture should persist real claim_success_rate samples", failures)
	_assert_true(source.contains('"late_commit_deviation"'), "warning fixture should persist real late_commit_deviation samples", failures)
	_assert_true(source.contains('"conflict_overlap_count"'), "warning fixture should persist real conflict overlap count", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
