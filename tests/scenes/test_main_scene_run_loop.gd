extends RefCounted

const TestCleanup = preload("res://tests/test_cleanup.gd")
const MainScene = preload("res://scenes/main/main_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_main_scene_enters_combat_on_boot(failures)
	_test_main_scene_supports_reward_to_next_wave_transition(failures)
	_test_main_scene_preserves_ui_root_for_settle_phase(failures)
	return failures

func _test_main_scene_enters_combat_on_boot(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleScene/BattleController")
	_assert_true(controller != null, "main scene should expose battle controller after boot", failures)
	if controller != null:
		_assert_eq(str(controller.call("get_state")), "combat", "main scene should boot into combat", failures)
	await TestCleanup.release_tree_instance(main_loop, instance)

func _test_main_scene_supports_reward_to_next_wave_transition(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleScene/BattleController")
	var reward_panel = instance.get_node_or_null("BattleScene/UiLayer/RewardPanel")
	if controller == null or reward_panel == null:
		failures.append("main scene should expose battle reward flow components")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("handle_wave_clear")
	await main_loop.process_frame
	var option_a = reward_panel.get_node_or_null("OptionButtons/OptionA")
	_assert_true(option_a != null, "reward panel should expose OptionA from main scene", failures)
	if option_a != null:
		option_a.emit_signal("pressed")
		await main_loop.process_frame
		_assert_eq(str(controller.call("get_state")), "combat", "main scene should return to combat after reward selection", failures)
		var current_wave = controller.call("get_current_wave")
		_assert_eq(int(current_wave.get("wave", -1)), 2, "main scene should advance to wave 2 after reward selection", failures)
	await TestCleanup.release_tree_instance(main_loop, instance)

func _test_main_scene_preserves_ui_root_for_settle_phase(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleScene/BattleController")
	var ui_layer = instance.get_node_or_null("BattleScene/UiLayer")
	_assert_true(ui_layer != null, "main scene should expose battle UiLayer", failures)
	if controller != null:
		controller.call("handle_run_failed")
		await main_loop.process_frame
		_assert_eq(str(controller.call("get_state")), "settle", "main scene should support settle state", failures)
		_assert_true(ui_layer != null, "main scene should keep UiLayer available in settle state", failures)
	await TestCleanup.release_tree_instance(main_loop, instance)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
