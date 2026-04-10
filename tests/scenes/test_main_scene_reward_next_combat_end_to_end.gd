extends RefCounted

const MainScene = preload("res://scenes/main/main_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_reward_selection_returns_to_next_combat_loop(failures)
	return failures

func _test_reward_selection_returns_to_next_combat_loop(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var battle_scene = instance.get_node_or_null("BattleScene")
	var controller = instance.get_node_or_null("BattleScene/BattleController")
	var reward_panel = instance.get_node_or_null("BattleScene/UiLayer/RewardPanel")
	var summary_label = instance.get_node_or_null("StatusSummaryLabel")
	if battle_scene == null or controller == null or reward_panel == null or summary_label == null:
		failures.append("main scene should expose battle scene, controller, reward panel, and summary label before reward-next-combat checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("handle_wave_clear")
	await main_loop.process_frame
	_assert_true(reward_panel.visible, "reward panel should appear before reward selection", failures)
	var option_a = reward_panel.get_node_or_null("OptionButtons/OptionA")
	_assert_true(option_a != null, "reward panel should expose OptionA for end-to-end reward selection", failures)
	if option_a != null:
		option_a.emit_signal("pressed")
		await main_loop.process_frame
		_assert_true(not reward_panel.visible, "reward panel should hide after selecting a reward", failures)
		_assert_true(str(controller.call("get_state")) == "combat", "controller should return to combat after reward selection", failures)
		var current_wave: Dictionary = controller.call("get_current_wave")
		_assert_eq(int(current_wave.get("wave", -1)), 2, "reward selection should advance to wave 2", failures)
		var report: Dictionary = controller.call("get_last_tick_report")
		_assert_true(int(report.get("live_count", 0)) > 0, "next combat loop should re-seed live entities after reward selection", failures)
		controller.call("advance_debug_frames", 90, 0.016)
		await main_loop.process_frame
		var next_report: Dictionary = controller.call("get_last_tick_report")
		_assert_true(int(next_report.get("moved", 0)) > 0 or int(next_report.get("attacked", 0)) > 0, "next combat loop should resume active battle after reward selection", failures)
		_assert_true(String(summary_label.text).contains("Combat"), "main scene summary should return to combat messaging after reward selection", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
