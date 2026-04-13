extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_boot_places_unit_views_inside_battlefield_region(failures)
	return failures

func _test_boot_places_unit_views_inside_battlefield_region(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	var enemy_view = instance.get_node_or_null("UnitLayer/UnitView6")
	if ally_view == null or enemy_view == null:
		failures.append("battle scene should expose ally and enemy views before viewport visibility checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	_assert_true(ally_view.global_position.x > 180.0, "ally view should appear well inside the visible battlefield instead of hugging the edge", failures)
	_assert_true(enemy_view.global_position.x < 1100.0, "enemy view should appear well inside the visible battlefield instead of drifting offscreen", failures)
	_assert_true(ally_view.global_position.y > 150.0, "ally view should appear vertically inside the main battlefield window", failures)
	_assert_true(enemy_view.global_position.y > 150.0, "enemy view should appear vertically inside the main battlefield window", failures)
	_assert_true(ally_view.global_position.y < 610.0, "ally view should stay inside the main battlefield window instead of slipping below the frame", failures)
	_assert_true(enemy_view.global_position.y < 610.0, "enemy view should stay inside the main battlefield window instead of slipping below the frame", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
