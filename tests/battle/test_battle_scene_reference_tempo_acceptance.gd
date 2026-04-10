extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_reference_tempo_progresses_from_scatter_to_clash_to_impact(failures)
	return failures

func _test_reference_tempo_progresses_from_scatter_to_clash_to_impact(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var phase_hint = instance.get_node_or_null("UiLayer/PhaseHint")
	var effect_layer = instance.get_node_or_null("EffectLayer")
	var unit_layer = instance.get_node_or_null("UnitLayer")
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	if controller == null or phase_hint == null or effect_layer == null or unit_layer == null or ally_view == null:
		failures.append("battle scene should expose controller, phase hint, effect layer, unit layer, and a unit view before tempo acceptance checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var start_position: Vector2 = ally_view.global_position
	var early_text := ""
	var clash_text := ""
	var impact_text := ""
	var clash_effect_count := 0
	var impact_effect_count := 0
	var early_distribution_ok := false
	var saw_attack_by_one_second := false
	for step in range(180):
		await main_loop.process_frame
		var report: Dictionary = controller.call("get_last_tick_report")
		if step == 10:
			early_text = String(phase_hint.text)
			early_distribution_ok = _has_side_separation(unit_layer)
		if step == 60:
			clash_text = String(phase_hint.text)
			clash_effect_count = effect_layer.get_child_count()
		if step == 179:
			impact_text = String(phase_hint.text)
			impact_effect_count = effect_layer.get_child_count()
		if step <= 60 and int(report.get("attacked", 0)) > 0:
			saw_attack_by_one_second = true
	_assert_true(early_text.contains("Scatter"), "battle scene should present an early scatter/setup tempo hint", failures)
	_assert_true(clash_text.contains("Clash") or clash_text.contains("Charge"), "battle scene should present a mid-tempo clash hint by around 1 second", failures)
	_assert_true(impact_text.contains("Impact") or impact_text.contains("Burst"), "battle scene should present a later impact hint by around 3 seconds", failures)
	_assert_true(phase_hint.text.length() <= 36, "tempo HUD hint should stay compact during runtime acceptance", failures)
	_assert_true(early_distribution_ok, "battle scene should keep visible left-right separation in the early scatter window", failures)
	_assert_true(ally_view.global_position.distance_to(start_position) > 18.0, "battle scene should move from scatter setup into active melee by the tempo acceptance window", failures)
	_assert_true(saw_attack_by_one_second, "battle scene should reach attack contact by around the first second", failures)
	_assert_true(clash_effect_count > 0, "battle scene should already show combat effects by the clash phase", failures)
	_assert_true(impact_effect_count >= clash_effect_count, "battle scene should sustain or intensify visible effects by the later impact phase", failures)
	_assert_true(_count_visible_views(unit_layer) >= 8, "battle scene should still show multiple unit views instead of collapsing into unreadable blobs", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _has_side_separation(unit_layer: Node) -> bool:
	var min_x := INF
	var max_x := -INF
	for child in unit_layer.get_children():
		if child is Node2D and child.visible:
			min_x = minf(min_x, child.global_position.x)
			max_x = maxf(max_x, child.global_position.x)
	return min_x != INF and max_x != -INF and (max_x - min_x) >= 180.0

func _count_visible_views(unit_layer: Node) -> int:
	var count := 0
	for child in unit_layer.get_children():
		if child is CanvasItem and child.visible:
			count += 1
	return count

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
