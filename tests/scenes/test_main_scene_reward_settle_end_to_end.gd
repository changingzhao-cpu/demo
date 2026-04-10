extends RefCounted

const MainScene = preload("res://scenes/main/main_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_main_scene_surfaces_reward_and_settle_end_to_end(failures)
	return failures

func _test_main_scene_surfaces_reward_and_settle_end_to_end(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleScene/BattleController")
	var summary_label = instance.get_node_or_null("StatusSummaryLabel")
	var settle_hint = instance.get_node_or_null("SettleHintLabel")
	if controller == null or summary_label == null or settle_hint == null:
		failures.append("main scene should expose controller and summary labels before reward-settle end-to-end checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("handle_wave_clear")
	await main_loop.process_frame
	_assert_true(String(summary_label.text).contains("Reward"), "main scene should surface reward status after wave clear", failures)
	controller.call("handle_run_failed")
	await main_loop.process_frame
	_assert_true(String(summary_label.text).contains("Settle"), "main scene should surface settle status after run failure", failures)
	_assert_true(String(settle_hint.text).contains("Restart"), "main scene should explain restart after settle", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
