extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_controller_exposes_recent_combat_event_api(failures)
	return failures

func _test_controller_exposes_recent_combat_event_api(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("get_recent_combat_events"), "battle controller should expose recent combat events", failures)
	_assert_true(controller.has_method("consume_recent_combat_events"), "battle controller should expose a consuming combat event API", failures)
	if controller.has_method("get_recent_combat_events"):
		var events: Array = controller.call("get_recent_combat_events")
		_assert_true(events is Array, "recent combat events API should return an Array", failures)
	if controller.has_method("consume_recent_combat_events"):
		var consumed: Array = controller.call("consume_recent_combat_events")
		_assert_true(consumed is Array, "consume_recent_combat_events should return an Array", failures)
	controller.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
