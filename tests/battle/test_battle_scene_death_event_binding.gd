extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_battle_scene_consumes_controller_death_events_for_effects(failures)
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

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
