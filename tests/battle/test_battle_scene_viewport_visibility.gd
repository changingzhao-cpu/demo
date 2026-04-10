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
	_assert_true(ally_view.global_position.x > 120.0, "ally view should appear inside the visible battlefield instead of near the screen edge", failures)
	_assert_true(enemy_view.global_position.x < 1160.0, "enemy view should appear inside the visible battlefield instead of offscreen", failures)
	_assert_true(ally_view.global_position.y > 120.0, "ally view should appear vertically inside the battlefield", failures)
	_assert_true(enemy_view.global_position.y > 120.0, "enemy view should appear vertically inside the battlefield", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
