extends RefCounted

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func _load_battle_scene() -> PackedScene:
	return load(BATTLE_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_contains_runtime_layers(failures)
	_test_controller_bootstrap_exposes_unit_views(failures)
	_test_runtime_keeps_units_visible_after_initial_layout(failures)
	_test_runtime_preserves_spread_after_initial_layout(failures)
	_test_runtime_keeps_visible_views_near_screen_bounds(failures)
	_test_runtime_view_spread_matches_controller_payload_spread(failures)
	return failures

func _test_runtime_preserves_spread_after_initial_layout(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before spread preservation checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var unit_layer = instance.get_node_or_null("UnitLayer")
	var initial_positions: Dictionary = {}
	if unit_layer != null:
		for child in unit_layer.get_children():
			if child.visible and child is Node2D and child.has_method("get_entity_id"):
				initial_positions[int(child.call("get_entity_id"))] = child.global_position
		var runtime := instance as Node
		if runtime != null:
			runtime.call("_process", 1.3)
			await main_loop.process_frame
		var moved_positions: Dictionary = {}
		for child in unit_layer.get_children():
			if child.visible and child is Node2D and child.has_method("get_entity_id"):
				moved_positions[int(child.call("get_entity_id"))] = child.global_position
		_assert_true(moved_positions.size() >= 12, "runtime should keep enough visible units for spread checks", failures)
		var preserved_count := 0
		for entity_id in initial_positions.keys():
			if not moved_positions.has(entity_id):
				continue
			if initial_positions[entity_id].distance_to(moved_positions[entity_id]) <= 220.0:
				preserved_count += 1
		_assert_true(preserved_count >= 12, "runtime should preserve most initial screen positions instead of snapping units into a new cluster", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_runtime_keeps_visible_views_near_screen_bounds(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before runtime screen bound checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var runtime := instance as Node
	if runtime != null:
		runtime.call("_process", 1.3)
		await main_loop.process_frame
	var unit_layer = instance.get_node_or_null("UnitLayer")
	var on_screen_count := 0
	if unit_layer != null:
		for child in unit_layer.get_children():
			if not child.visible or not child is Node2D:
				continue
			var view := child as Node2D
			if view == null:
				continue
			var position: Vector2 = view.global_position
			if position.x >= 120.0 and position.x <= 1160.0 and position.y >= 120.0 and position.y <= 720.0:
				on_screen_count += 1
		_assert_true(on_screen_count >= 12, "runtime should keep many visible unit views within battle screen bounds instead of exploding to huge coordinates", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_runtime_view_spread_matches_controller_payload_spread(failures: Array[String]) -> void:
	var battle_scene = _load_battle_scene()
	_assert_true(battle_scene != null, "battle scene should load before runtime spread parity checks", failures)
	if battle_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = battle_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var runtime := instance as Node
	if runtime != null:
		runtime.call("_process", 1.3)
		await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var unit_layer = instance.get_node_or_null("UnitLayer")
	if controller != null and unit_layer != null and controller.has_method("get_visible_entity_screen_payloads"):
		var payloads: Array = controller.call("get_visible_entity_screen_payloads", unit_layer.get_child_count(), Vector2(640.0, 392.0), Vector2(28.0, 20.0))
		var payload_positions: Array[Vector2] = []
		for payload_variant in payloads:
			var payload: Dictionary = payload_variant
			payload_positions.append(payload.get("position", Vector2.ZERO))
		var view_positions: Array[Vector2] = []
		for child in unit_layer.get_children():
			if child.visible and child is Node2D and child.has_method("get_entity_id"):
				view_positions.append((child as Node2D).global_position)
		_assert_true(_x_spread(payload_positions) >= 180.0, "controller runtime payloads should still expose meaningful spread during battle scene runtime", failures)
		_assert_true(_x_spread(view_positions) >= 180.0, "battle scene runtime views should preserve controller payload spread instead of collapsing into two anchors", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _x_spread(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var min_x := positions[0].x
	var max_x := positions[0].x
	for position in positions:
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
	return max_x - min_x

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
