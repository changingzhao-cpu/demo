extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_reward_panel_appears_when_wave_is_cleared(failures)
	_test_reward_selection_advances_back_to_combat(failures)
	return failures

func _test_reward_panel_appears_when_wave_is_cleared(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var reward_panel = instance.get_node_or_null("UiLayer/RewardPanel")
	_assert_true(controller != null, "battle scene should expose BattleController for reward transition checks", failures)
	_assert_true(reward_panel != null, "battle scene should expose RewardPanel under UiLayer", failures)
	if controller != null:
		controller.call("handle_wave_clear")
	await main_loop.process_frame
	if reward_panel != null:
		_assert_true(reward_panel.visible, "battle scene should show RewardPanel when entering reward state", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_reward_selection_advances_back_to_combat(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var reward_panel = instance.get_node_or_null("UiLayer/RewardPanel")
	if controller == null or reward_panel == null:
		failures.append("battle scene should expose controller and reward panel before reward selection checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("handle_wave_clear")
	await main_loop.process_frame
	var option_a = reward_panel.get_node_or_null("OptionButtons/OptionA")
	_assert_true(option_a != null, "reward panel should expose OptionA button for reward selection", failures)
	if option_a != null:
		option_a.emit_signal("pressed")
		await main_loop.process_frame
		_assert_eq(str(controller.call("get_state")), "combat", "reward selection should advance battle scene back to combat", failures)
		_assert_false(reward_panel.visible, "reward panel should hide after reward selection", failures)
		var current_wave = controller.call("get_current_wave")
		_assert_eq(int(current_wave.get("wave", -1)), 2, "reward selection should advance to the next wave", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
