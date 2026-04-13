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
		_assert_true(controller.has_method("get_live_entity_ids"), "battle controller should expose live runtime entities for scene binding", failures)
		_assert_true(controller.has_method("select_visible_entity_ids"), "battle scene runtime binding should expose visible-entity selection", failures)
		var live_entity_ids: Array = controller.call("get_live_entity_ids")
		_assert_true(live_entity_ids.size() > 0, "battle scene should expose live runtime entities", failures)
		_assert_true(unit_layer.get_child_count() >= 12, "battle scene should expose a fixed readable pool of unit views", failures)
		_assert_true(unit_layer.get_child_count() < live_entity_ids.size(), "battle scene should bind a readable subset rather than one view per entity", failures)
		var visible_entity_ids: Array = controller.call("select_visible_entity_ids", unit_layer.get_child_count())
		_assert_true(visible_entity_ids.size() <= unit_layer.get_child_count(), "visible entity binding should fit inside the pooled runtime views", failures)
		_assert_true(visible_entity_ids.size() > 0, "visible entity binding should select a non-empty readable subset", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
