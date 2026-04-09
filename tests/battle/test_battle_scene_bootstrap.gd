extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_instantiates_with_battle_controller_node(failures)
	_test_controller_starts_run_on_ready(failures)
	return failures

func _test_scene_instantiates_with_battle_controller_node(failures: Array[String]) -> void:
	var instance = BattleScene.instantiate()
	_assert_true(instance != null, "battle scene should instantiate", failures)
	var controller = instance.get_node_or_null("BattleController")
	_assert_true(controller != null, "battle scene should contain a BattleController node", failures)
	instance.free()

func _test_controller_starts_run_on_ready(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	var controller = instance.get_node_or_null("BattleController")
	_assert_true(controller != null, "battle scene should expose the controller after entering tree", failures)
	await main_loop.process_frame
	if controller != null:
		var current_wave = controller.call("get_current_wave")
		_assert_eq(int(current_wave.get("wave", -1)), 1, "battle scene should auto-start into wave 1", failures)
		_assert_eq(str(controller.call("get_state")), "combat", "battle scene should auto-start into combat state", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
