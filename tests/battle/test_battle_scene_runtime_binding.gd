extends RefCounted

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func _load_battle_scene() -> PackedScene:
	return load(BATTLE_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_contains_runtime_layers(failures)
	_test_controller_bootstrap_exposes_unit_views(failures)
	return failures

func _test_scene_contains_runtime_layers(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load", failures)
	if battle_scene == null:
		return
	var instance = battle_scene.instantiate()
	_assert_true(instance.get_node_or_null("UnitLayer") != null, "battle scene should contain a UnitLayer node", failures)
	_assert_true(instance.get_node_or_null("EffectLayer") != null, "battle scene should contain an EffectLayer node", failures)
	_assert_true(instance.get_node_or_null("UiLayer") != null, "battle scene should contain a UiLayer node", failures)
	instance.free()

func _test_controller_bootstrap_exposes_unit_views(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before runtime binding checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var unit_layer = instance.get_node_or_null("UnitLayer")
	_assert_true(controller != null, "battle scene should expose BattleController after entering tree", failures)
	_assert_true(unit_layer != null, "battle scene should expose UnitLayer after entering tree", failures)
	if controller != null and unit_layer != null:
		var live_entity_ids: Array = controller.call("get_live_entity_ids")
		_assert_true(live_entity_ids.size() > 0, "battle scene should expose live runtime entities", failures)
		_assert_true(unit_layer.get_child_count() >= 30, "battle scene should expose a larger initialization view pool", failures)
		var visible_views := 0
		for child in unit_layer.get_children():
			if child.visible:
				visible_views += 1
		_assert_true(visible_views >= 30, "battle scene should show about 30 or more units on the initialization screen", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
