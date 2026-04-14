extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_battle_scene_consumes_controller_death_events_for_effects(failures)
	_test_dead_unit_view_stops_rendering_as_alive(failures)
	return failures

func _test_battle_scene_consumes_controller_death_events_for_effects(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var effect_layer = instance.get_node_or_null("EffectLayer")
	if controller == null or effect_layer == null:
		failures.append("battle scene should expose controller and effect layer before death event binding checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("mark_first_enemy_dead_for_debug")
	await main_loop.process_frame
	_assert_true(effect_layer.get_child_count() > 0, "battle scene should create an effect after consuming a controller death event", failures)
	if effect_layer.get_child_count() > 0:
		var effect_node = effect_layer.get_child(0)
		_assert_eq(str(effect_node.get_meta("team")), "enemy", "death effect should keep enemy team metadata from the controller event", failures)
		_assert_true(effect_node.position != Vector2.ZERO, "death effect should preserve the death position from the controller event", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_dead_unit_view_stops_rendering_as_alive(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var unit_layer = instance.get_node_or_null("UnitLayer")
	if controller == null or unit_layer == null:
		failures.append("battle scene should expose controller and unit layer before dead view checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	var dead_entity_id := -1
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 1:
			store.hp[entity_id] = 0.1
			dead_entity_id = entity_id
			break
	controller.call("advance_debug_frames", 60, 0.016)
	await main_loop.process_frame
	var lingering_visible := false
	var dead_label_text := ""
	var saw_dead_bound_view := false
	for _step in range(240):
		controller.call("advance_debug_frames", 1, 0.016)
		await main_loop.process_frame
		for child in unit_layer.get_children():
			if not child.has_method("get_entity_id") or int(child.call("get_entity_id")) != dead_entity_id:
				continue
			if child.has_method("debug_get_sprite_snapshot"):
				var snapshot: Dictionary = child.call("debug_get_sprite_snapshot")
				dead_label_text = str(snapshot.get("alive_label_text", ""))
			if child.has_method("is_bound") and bool(child.call("is_bound")):
				saw_dead_bound_view = true
				if child is CanvasItem and child.visible:
					lingering_visible = true
			break
		if saw_dead_bound_view:
			break
	_assert_true(saw_dead_bound_view, "battle scene should keep the killed entity bound long enough to inspect its death visual sync", failures)
	_assert_true(not lingering_visible, "dead unit views should stop rendering as alive after a kill", failures)
	_assert_eq(dead_label_text, "%s:0" % str(dead_entity_id), "dead unit view label should flip to entity_id:0 after a kill", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
