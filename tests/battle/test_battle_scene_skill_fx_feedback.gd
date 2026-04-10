extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_spawns_hit_flash_skill_ring_and_launch_feedback(failures)
	return failures

func _test_scene_spawns_hit_flash_skill_ring_and_launch_feedback(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var effect_layer = instance.get_node_or_null("EffectLayer")
	if controller == null or effect_layer == null:
		failures.append("battle scene should expose controller and effect layer before skill-fx checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("advance_debug_frames", 120, 0.016)
	for _step in range(8):
		await main_loop.process_frame
	var visual_kinds := _collect_visual_kinds(effect_layer)
	_assert_true(visual_kinds.has("hit_flash"), "battle scene should spawn hit flash feedback from combat events", failures)
	_assert_true(visual_kinds.has("skill_ring"), "battle scene should spawn skill ring feedback from combat events", failures)
	_assert_true(visual_kinds.has("launch_burst") or visual_kinds.has("knockback_trail"), "battle scene should spawn knockback or launch feedback from combat events", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _collect_visual_kinds(effect_layer: Node) -> Dictionary:
	var kinds := {}
	for child in effect_layer.get_children():
		if child.has_meta("visual_kind"):
			kinds[str(child.get_meta("visual_kind"))] = true
	return kinds

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
