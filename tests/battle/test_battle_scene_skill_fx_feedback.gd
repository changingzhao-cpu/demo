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
	_assert_true(effect_layer.get_child_count() <= 10, "clash-stage effect feedback should stay bounded instead of flooding the center with overlays", failures)
	var skill_ring = _find_effect_node(effect_layer, "skill_ring")
	var hit_flash = _find_effect_node(effect_layer, "hit_flash")
	var launch_burst = _find_effect_node(effect_layer, "launch_burst")
	var knockback_trail = _find_effect_node(effect_layer, "knockback_trail")
	if skill_ring != null:
		_assert_true(skill_ring.position.y > 0.0, "skill ring should sit below unit center so it reads like a ground effect", failures)
		_assert_true(skill_ring.scale.x <= 0.8 and skill_ring.scale.y <= 0.5, "skill ring should stay compact instead of dominating the battlefield", failures)
	if hit_flash != null:
		_assert_true(hit_flash.position.y < 0.0, "hit flash should sit slightly above the target center", failures)
		_assert_true(hit_flash.scale.x <= 0.65 and hit_flash.scale.y <= 0.65, "hit flash should stay tight around the impacted unit", failures)
	if launch_burst != null:
		_assert_true(launch_burst.position.y < -4.0, "launch burst should bias upward to read as lift", failures)
		_assert_true(launch_burst.scale.y <= 0.85, "launch burst should stay bounded instead of towering over units", failures)
	if knockback_trail != null:
		_assert_true(absf(knockback_trail.position.x) >= 2.0, "knockback trail should show a clear horizontal displacement", failures)
		_assert_true(knockback_trail.scale.x <= 0.85, "knockback trail should stay compact instead of becoming a giant smear", failures)
		_assert_true(knockback_trail.scale.y <= 0.5, "knockback trail should stay thin enough not to cover the clash center", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _collect_visual_kinds(effect_layer: Node) -> Dictionary:
	var kinds := {}
	for child in effect_layer.get_children():
		if child.has_meta("visual_kind"):
			kinds[str(child.get_meta("visual_kind"))] = true
	return kinds

func _find_effect_node(effect_layer: Node, visual_kind: String) -> Node2D:
	for child in effect_layer.get_children():
		if child is Node2D and child.has_meta("visual_kind") and str(child.get_meta("visual_kind")) == visual_kind:
			return child
	return null

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
