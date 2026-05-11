extends RefCounted

const CORE_PATH := "res://tests/battle/battle_warning_sampler_core.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(CORE_PATH)
	_assert_true(source.contains('"scene_type": _scenario'), "warning sampling output should persist scene_type field", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
