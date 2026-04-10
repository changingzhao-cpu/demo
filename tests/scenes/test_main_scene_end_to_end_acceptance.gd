extends RefCounted

const MainScene = preload("res://scenes/main/main_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_main_scene_surfaces_combat_and_reward_progression(failures)
	return failures

func _test_main_scene_surfaces_combat_and_reward_progression(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = MainScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var battle_controller = instance.get_node_or_null("BattleScene/BattleController")
	var summary_label = instance.get_node_or_null("StatusSummaryLabel")
	if battle_controller == null or summary_label == null:
		failures.append("main scene should expose battle controller and summary label for end-to-end acceptance checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	battle_controller.call("advance_debug_frames", 90, 0.016)
	await main_loop.process_frame
	var report: Dictionary = battle_controller.call("get_last_tick_report")
	_assert_true(int(report.get("moved", 0)) > 0 or int(report.get("attacked", 0)) > 0, "main scene loop should surface active combat before reward/settle", failures)
	battle_controller.call("handle_wave_clear")
	await main_loop.process_frame
	_assert_true(String(summary_label.text).contains("Reward"), "main scene should surface reward progression in the summary label", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
