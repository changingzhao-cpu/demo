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
	_assert_true(instance.get_node_or_null("ArenaGround") != null, "battle scene should contain a readable arena ground node", failures)
	_assert_true(instance.get_node_or_null("ArenaGroundRim") != null, "battle scene should contain a readable arena rim node", failures)
	var arena_ground = instance.get_node_or_null("ArenaGround")
	var arena_ground_rim = instance.get_node_or_null("ArenaGroundRim")
	_assert_true(arena_ground == null or (arena_ground is CanvasItem and not arena_ground.visible), "battle scene should not let the new arena ground dominate the screen by default", failures)
	_assert_true(arena_ground_rim == null or (arena_ground_rim is CanvasItem and not arena_ground_rim.visible), "battle scene should not let the new arena rim dominate the screen by default", failures)
	var frame = instance.get_node_or_null("BattlefieldFrame")
	var shadow = instance.get_node_or_null("ArenaShadow")
	var floor = instance.get_node_or_null("ArenaFloor")
	var rim = instance.get_node_or_null("ArenaRim")
	_assert_true(frame == null or (frame is CanvasItem and not frame.visible), "battle scene should not keep the old BattlefieldFrame overlay visible", failures)
	_assert_true(shadow == null or (shadow is CanvasItem and not shadow.visible), "battle scene should not keep the old ArenaShadow overlay visible", failures)
	_assert_true(floor == null or (floor is CanvasItem and not floor.visible), "battle scene should not keep the old ArenaFloor overlay visible", failures)
	_assert_true(rim == null or (rim is CanvasItem and not rim.visible), "battle scene should not keep the old ArenaRim overlay visible", failures)
	_assert_true(instance.get_node_or_null("FrontlineMarker") != null, "battle scene should contain a FrontlineMarker node", failures)
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
	_assert_true(unit_layer != null, "battle scene should expose UnitLayer after entering tree", failures)
	if unit_layer != null:
		_assert_true(unit_layer.global_position != Vector2.ZERO, "battle scene should offset the unit layer into a readable battlefield area", failures)
		var ally_view = unit_layer.get_node_or_null("UnitView0")
		var enemy_view = unit_layer.get_node_or_null("UnitView6")
		_assert_true(ally_view != null, "battle scene should expose an ally placeholder view", failures)
		_assert_true(enemy_view != null, "battle scene should expose an enemy placeholder view", failures)
		if ally_view != null and enemy_view != null:
			_assert_true(ally_view.visible, "ally placeholder should be visible after battle scene bootstrap", failures)
			_assert_true(enemy_view.visible, "enemy placeholder should be visible after battle scene bootstrap", failures)
			_assert_true(ally_view.has_method("get_visual_tint") or ally_view.get_node_or_null("BodySprite") != null, "ally placeholder should expose a readable visual presentation", failures)
			_assert_true(enemy_view.has_method("get_visual_tint") or enemy_view.get_node_or_null("BodySprite") != null, "enemy placeholder should expose a readable visual presentation", failures)
			if ally_view.has_method("get_visual_tint") and enemy_view.has_method("get_visual_tint"):
				_assert_true(ally_view.call("get_visual_tint") != enemy_view.call("get_visual_tint"), "battle scene should make ally and enemy placeholders visually distinct", failures)
			elif ally_view.get_node_or_null("BodySprite") != null and enemy_view.get_node_or_null("BodySprite") != null:
				_assert_true(ally_view.get_node("BodySprite").scale != enemy_view.get_node("BodySprite").scale, "battle scene should make ally and enemy placeholders visually distinct", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
