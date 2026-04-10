extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_reward_panel_scene_loads_and_exposes_buttons(failures)
	_test_reward_panel_emits_selection_result(failures)
	return failures

func _test_reward_panel_scene_loads_and_exposes_buttons(failures: Array[String]) -> void:
	var panel_scene: PackedScene = load("res://scenes/ui/reward_panel.tscn")
	_assert_true(panel_scene != null, "reward panel scene should load", failures)
	if panel_scene == null:
		return
	var instance = panel_scene.instantiate()
	_assert_true(instance.get_node_or_null("OptionButtons") != null, "reward panel should contain OptionButtons container", failures)
	_assert_true(instance.get_node_or_null("OptionButtons/OptionA") != null, "reward panel should expose OptionA button", failures)
	_assert_true(instance.get_node_or_null("OptionButtons/OptionB") != null, "reward panel should expose OptionB button", failures)
	_assert_true(instance.get_node_or_null("OptionButtons/OptionC") != null, "reward panel should expose OptionC button", failures)
	instance.free()

func _test_reward_panel_emits_selection_result(failures: Array[String]) -> void:
	var panel_scene: PackedScene = load("res://scenes/ui/reward_panel.tscn")
	if panel_scene == null:
		failures.append("reward panel scene should load before signal checks")
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = panel_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	_assert_true(instance.has_signal("reward_selected"), "reward panel should define reward_selected signal", failures)
	_assert_true(instance.has_method("show_rewards"), "reward panel should expose show_rewards", failures)
	var received := -1
	if instance.has_signal("reward_selected"):
		instance.reward_selected.connect(func(index: int) -> void:
			received = index
		)
	if instance.has_method("show_rewards"):
		instance.call("show_rewards", ["atk", "hp", "speed"])
	var option_b = instance.get_node_or_null("OptionButtons/OptionB")
	_assert_true(option_b != null, "reward panel should expose OptionB for selection", failures)
	if option_b != null:
		option_b.emit_signal("pressed")
		await main_loop.process_frame
		_assert_eq(received, 1, "reward panel should emit the selected reward index", failures)
		_assert_false(instance.visible, "reward panel should hide after a reward is selected", failures)
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
