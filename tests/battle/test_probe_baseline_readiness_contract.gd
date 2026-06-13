extends RefCounted

const SCRIPT_PATH := "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	_assert_true(source.contains('"sample_name": "oscillation"'), "oscillation should remain the first golden baseline sample", failures)
	_assert_true(source.contains('"snapshot_version": 1'), "oscillation baseline snapshot should keep snapshot version 1", failures)
	_assert_true(source.contains('"baseline_text": v4_probe_baseline'), "oscillation baseline snapshot should keep baseline text mapping", failures)
	_assert_true(source.contains('"fingerprint": v4_probe_fingerprint'), "oscillation baseline snapshot should keep fingerprint mapping", failures)
	_assert_true(source.contains('"baseline_source": v4_probe_fingerprint'), "oscillation baseline snapshot should keep provenance mapping", failures)
	_assert_true(source.contains('"capture_context"'), "oscillation baseline snapshot should keep capture context", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
