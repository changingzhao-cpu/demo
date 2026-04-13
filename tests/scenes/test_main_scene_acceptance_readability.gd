extends RefCounted

const TestCleanup = preload("res://tests/test_cleanup.gd")
const MainScene = preload("res://scenes/main/main_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_main_scene_exposes_acceptance_level_shell_nodes(failures)
	_test_main_scene_surfaces_reward_and_settle_guidance(failures)
	return failures

func _test_main_scene_exposes_acceptance_level_shell_nodes(failures: Array[String]) -> void:
	var instance = MainScene.instantiate()
	_assert_true(instance.get_node_or_null("TitleLabel") != null, "main scene should keep TitleLabel for acceptance readability", failures)
	_assert_true(instance.get_node_or_null("RunHintLabel") != null, "main scene should keep RunHintLabel for acceptance readability", failures)
	_assert_true(instance.get_node_or_null("StatusSummaryLabel") != null, "main scene should expose a StatusSummaryLabel", failures)
	_assert_true(instance.get_node_or_null("SettleHintLabel") != null, "main scene should expose a SettleHintLabel", failures)
	instance.queue_free()

func _test_main_scene_surfaces_reward_and_settle_guidance(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var battle_controller = instance.get_node_or_null("BattleScene/BattleController")
	var summary_label = instance.get_node_or_null("StatusSummaryLabel")
	var settle_hint = instance.get_node_or_null("SettleHintLabel")
	if battle_controller == null or summary_label == null or settle_hint == null:
		failures.append("main scene should expose controller and acceptance labels before runtime readability checks")
		if instance.get_parent() != null:
			await TestCleanup.release_tree_instance(main_loop, instance)
		return
	battle_controller.call("handle_wave_clear")
	await main_loop.process_frame
	_assert_true(String(summary_label.text).contains("Reward"), "main scene summary should mention Reward after wave clear", failures)
	battle_controller.call("handle_run_failed")
	await main_loop.process_frame
	_assert_true(String(summary_label.text).contains("Settle"), "main scene summary should mention Settle after run failure", failures)
	_assert_true(String(settle_hint.text).contains("Restart"), "main scene settle hint should explain how to continue after the run ends", failures)
	main_loop.root.remove_child(instance)
	instance.queue_free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
