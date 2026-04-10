extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_reward_panel_exposes_stage_copy_and_heading(failures)
	_test_show_rewards_updates_hint_text_and_options(failures)
	return failures

func _test_reward_panel_exposes_stage_copy_and_heading(failures: Array[String]) -> void:
	var panel_scene: PackedScene = load("res://scenes/ui/reward_panel.tscn")
	_assert_true(panel_scene != null, "reward panel scene should load", failures)
	if panel_scene == null:
		return
	var instance = panel_scene.instantiate()
	_assert_true(instance.get_node_or_null("PanelFrame") != null, "reward panel should expose a PanelFrame", failures)
	_assert_true(instance.get_node_or_null("PanelFrame/TitleLabel") != null, "reward panel should expose a TitleLabel", failures)
	_assert_true(instance.get_node_or_null("PanelFrame/HintLabel") != null, "reward panel should expose a HintLabel", failures)
	instance.free()

func _test_show_rewards_updates_hint_text_and_options(failures: Array[String]) -> void:
	var panel_scene: PackedScene = load("res://scenes/ui/reward_panel.tscn")
	if panel_scene == null:
		failures.append("reward panel scene should load before readability checks")
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = panel_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	if instance.has_method("show_rewards"):
		instance.call("show_rewards", ["atk", "hp", "speed"])
	var title_label = instance.get_node_or_null("PanelFrame/TitleLabel")
	var hint_label = instance.get_node_or_null("PanelFrame/HintLabel")
	var option_a = instance.get_node_or_null("OptionButtons/OptionA")
	_assert_true(title_label != null, "reward panel should expose TitleLabel after entering tree", failures)
	_assert_true(hint_label != null, "reward panel should expose HintLabel after entering tree", failures)
	_assert_true(option_a != null, "reward panel should expose OptionA for stage readability", failures)
	if title_label != null:
		_assert_true(String(title_label.text).contains("Reward"), "reward panel title should identify the reward phase", failures)
	if hint_label != null:
		_assert_true(String(hint_label.text).contains("Choose"), "reward panel hint should ask the player to choose a reward", failures)
	if option_a != null:
		_assert_true(String(option_a.text).contains("atk"), "reward panel should still surface reward option labels", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
