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
			_assert_true(ally_view.has_method("get_visual_tint"), "ally placeholder should expose visual tint", failures)
			_assert_true(enemy_view.has_method("get_visual_tint"), "enemy placeholder should expose visual tint", failures)
			if ally_view.has_method("get_visual_tint") and enemy_view.has_method("get_visual_tint"):
				_assert_true(ally_view.call("get_visual_tint") != enemy_view.call("get_visual_tint"), "battle scene should make ally and enemy placeholders visually distinct", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
