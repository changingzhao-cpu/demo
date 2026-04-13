extends RefCounted

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func _load_battle_scene() -> PackedScene:
	return load(BATTLE_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_runtime_views_keep_bound_live_units_after_initial_layout(failures)
	return failures

func _test_runtime_views_keep_bound_live_units_after_initial_layout(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before runtime snapshot checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	instance.call("_process", 1.3)
	await main_loop.process_frame
	var unit_layer = instance.get_node_or_null("UnitLayer")
	var controller = instance.get_node_or_null("BattleController")
	_assert_true(unit_layer != null, "runtime snapshot test requires UnitLayer", failures)
	_assert_true(controller != null, "runtime snapshot test requires BattleController", failures)
	if unit_layer != null and controller != null:
		var selected: Array = controller.call("select_visible_entity_ids", unit_layer.get_child_count())
		var visible_bound_matches := 0
		for child in unit_layer.get_children():
			if not child.has_method("get_entity_id"):
				continue
			var entity_id := int(child.call("get_entity_id"))
			if entity_id == -1:
				continue
			var payload: Dictionary = controller.call("get_entity_visual_state", entity_id)
			if child.visible and bool(payload.get("is_alive", false)) and selected.has(entity_id):
				visible_bound_matches += 1
		_assert_true(visible_bound_matches >= 12, "runtime should keep at least 12 visible live bound units after initial layout", failures)
		var snapshot: Dictionary = instance.call("debug_get_runtime_view_snapshot")
		_assert_true(int(snapshot.get("visible_views", 0)) >= 12, "runtime debug snapshot should report visible views after combat starts", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
