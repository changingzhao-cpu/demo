extends RefCounted

const CONTRACT_PATH := "res://tests/battle/test_probe_warning_runtime_variation_contract.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(CONTRACT_PATH)
	_assert_true(source.contains('preload("res://tests/battle/battle_warning_sampler_core.gd")'), "variation contract should depend on warning sampler core", failures)
	_assert_true(not source.contains('preload("res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd")'), "variation contract should not depend on SceneTree warning fixture", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
