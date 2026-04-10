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
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	if controller == null or phase_hint == null or effect_layer == null or ally_view == null:
		failures.append("battle scene should expose controller, phase hint, effect layer, and a unit view before tempo acceptance checks")
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
	var saw_attack_by_one_second := false
	for step in range(180):
		await main_loop.process_frame
		var report: Dictionary = controller.call("get_last_tick_report")
		if step == 10:
			early_text = String(phase_hint.text)
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
	_assert_true(ally_view.global_position.distance_to(start_position) > 18.0, "battle scene should move from scatter setup into active melee by the tempo acceptance window", failures)
	_assert_true(saw_attack_by_one_second, "battle scene should reach attack contact by around the first second", failures)
	_assert_true(clash_effect_count > 0, "battle scene should already show combat effects by the clash phase", failures)
	_assert_true(impact_effect_count >= clash_effect_count, "battle scene should sustain or intensify visible effects by the later impact phase", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
