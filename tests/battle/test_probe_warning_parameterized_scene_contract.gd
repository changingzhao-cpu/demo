extends RefCounted

const WARNING_PATH := "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(WARNING_PATH)
	_assert_true(source.contains('"scenario_param"'), "warning samples should persist scenario_param block", failures)
	_assert_true(source.contains('"min_width": 1.2'), "warning samples should persist corridor min width", failures)
	_assert_true(source.contains('"entry_width": 10.0'), "warning samples should persist funnel entry width", failures)
	_assert_true(source.contains('"exit_width": 2.0'), "warning samples should persist funnel exit width", failures)
	_assert_true(source.contains('"motion": "irregular_sine"'), "warning samples should persist orbit motion type", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
