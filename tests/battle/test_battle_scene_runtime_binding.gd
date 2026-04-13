extends RefCounted

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func _load_battle_scene() -> PackedScene:
	return load(BATTLE_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_contains_runtime_layers(failures)
	_test_controller_bootstrap_exposes_unit_views(failures)
	_test_runtime_keeps_units_visible_after_initial_layout(failures)
	return failures

func _test_runtime_keeps_units_visible_after_initial_layout(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before runtime visibility checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var runtime = instance as Node
	var unit_layer = instance.get_node_or_null("UnitLayer")
	if runtime != null:
		runtime.call("_process", 1.3)
		await main_loop.process_frame
	if unit_layer != null:
		var visible_views := 0
		for child in unit_layer.get_children():
			if child.visible:
				visible_views += 1
		_assert_true(visible_views >= 12, "runtime should keep a substantial set of units visible after leaving the initial layout phase", failures)
		var controller = instance.get_node_or_null("BattleController")
		if controller != null and controller.has_method("select_visible_entity_ids"):
			var selected: Array = controller.call("select_visible_entity_ids", unit_layer.get_child_count())
			_assert_true(selected.size() >= 12, "runtime visible selection should still return a substantial unit set after combat starts", failures)
			var alive_selected := 0
			for entity_id in selected:
				var payload: Dictionary = controller.call("get_entity_visual_state", int(entity_id))
				if bool(payload.get("is_alive", false)):
					alive_selected += 1
			_assert_true(alive_selected >= 12, "runtime visible selection should still point at live units after combat starts", failures)
			var bound_visible_matches := 0
			for child in unit_layer.get_children():
				if child.visible and child.has_method("get_entity_id"):
					var entity_id := int(child.call("get_entity_id"))
					if selected.has(entity_id):
						bound_visible_matches += 1
			_assert_true(bound_visible_matches >= 12, "runtime visible views should remain bound to the selected live entities after combat starts", failures)
	main_loop.root.remove_child(instance)
	instance.free()

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
