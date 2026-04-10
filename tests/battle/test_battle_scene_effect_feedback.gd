extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_enemy_death_spawns_effect_feedback_in_effect_layer(failures)
	return failures

func _test_enemy_death_spawns_effect_feedback_in_effect_layer(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var effect_layer = instance.get_node_or_null("EffectLayer")
	if controller == null or effect_layer == null:
		failures.append("battle scene should expose controller and effect layer before effect feedback checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 1:
			store.alive[entity_id] = 0
			break
	controller.call("sync_unit_views")
	await main_loop.process_frame
	_assert_true(effect_layer.get_child_count() > 0, "battle scene should add visible effect feedback after an enemy death", failures)
	if effect_layer.get_child_count() > 0:
		var effect_node = effect_layer.get_child(0)
		_assert_true(effect_node is Node2D, "effect feedback should create a node inside EffectLayer", failures)
		_assert_true(effect_node.has_meta("team"), "effect feedback node should record which team died", failures)
		if effect_node.has_meta("team"):
			_assert_eq(str(effect_node.get_meta("team")), "enemy", "enemy death feedback should be tagged as enemy", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
