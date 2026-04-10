extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_combat_progress_changes_runtime_positions(failures)
	return failures

func _test_combat_progress_changes_runtime_positions(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	var enemy_view = instance.get_node_or_null("UnitLayer/UnitView6")
	if ally_view == null or enemy_view == null:
		failures.append("battle scene should expose ally and enemy views before combat readability checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var ally_start: Vector2 = ally_view.global_position
	var enemy_start: Vector2 = enemy_view.global_position
	for _step in range(24):
		await main_loop.process_frame
	_assert_true(ally_view.global_position != ally_start or enemy_view.global_position != enemy_start, "combat readability should show at least one side moving during runtime", failures)
	_assert_true(float(ally_view.call("get_visual_motion_strength")) > 0.0, "ally view should expose motion strength during combat", failures)
	_assert_true(float(enemy_view.call("get_visual_motion_strength")) > 0.0, "enemy view should expose motion strength during combat", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
