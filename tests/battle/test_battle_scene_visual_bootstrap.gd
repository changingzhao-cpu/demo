extends RefCounted

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func _load_battle_scene() -> PackedScene:
	return load(BATTLE_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_contains_visual_battlefield_nodes(failures)
	_test_runtime_views_expose_enemy_and_ally_visual_difference(failures)
	return failures

func _test_scene_contains_visual_battlefield_nodes(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load", failures)
	if battle_scene == null:
		return
	var instance = battle_scene.instantiate()
	_assert_true(instance.get_node_or_null("BattlefieldBackdrop") != null, "battle scene should contain a BattlefieldBackdrop node", failures)
	var arena_ground = instance.get_node_or_null("ArenaGround")
	var arena_ground_rim = instance.get_node_or_null("ArenaGroundRim")
	var arena_floor = instance.get_node_or_null("ArenaFloor")
	var arena_shadow = instance.get_node_or_null("ArenaShadow")
	_assert_true(arena_ground == null or (arena_ground is CanvasItem and not arena_ground.visible), "battle scene should not let arena ground dominate the screen by default", failures)
	_assert_true(arena_ground_rim == null or (arena_ground_rim is CanvasItem and not arena_ground_rim.visible), "battle scene should not let arena rim dominate the screen by default", failures)
	_assert_true(arena_floor is CanvasItem and arena_floor.visible, "ArenaFloor should stay visible in the battle scene", failures)
	_assert_true(arena_shadow == null or (arena_shadow is CanvasItem and not arena_shadow.visible), "ArenaShadow should stay hidden when only ArenaFloor is retained", failures)
	_assert_true(arena_floor is Sprite2D, "ArenaFloor should use a Sprite2D to display the arena floor asset directly", failures)
	if arena_floor is Sprite2D:
		_assert_true(arena_floor.texture != null, "ArenaFloor should use the arena floor texture directly", failures)
		_assert_true(is_equal_approx(arena_floor.modulate.a, 1.0), "ArenaFloor should no longer use softened alpha", failures)
		_assert_true(arena_floor.centered, "ArenaFloor should stay centered in the battle scene", failures)
		_assert_true(arena_floor.position == Vector2(640, 360), "ArenaFloor should use screen-aligned placement for the arena background", failures)
	instance.free()

func _test_runtime_views_expose_enemy_and_ally_visual_difference(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before visual runtime checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var unit_layer = instance.get_node_or_null("UnitLayer")
	if unit_layer != null:
		var visible_views: Array = []
		for child in unit_layer.get_children():
			if child.visible:
				visible_views.append(child)
		_assert_true(visible_views.size() >= 30, "battle scene should surface many visible units on initialization", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
