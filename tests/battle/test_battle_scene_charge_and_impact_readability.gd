extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_first_second_shows_charge_and_impact_feedback(failures)
	return failures

func _test_first_second_shows_charge_and_impact_feedback(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	var enemy_view = instance.get_node_or_null("UnitLayer/UnitView6")
	if controller == null or ally_view == null or enemy_view == null:
		failures.append("battle scene should expose controller plus ally and enemy views before charge-impact checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var ally_start: Vector2 = ally_view.global_position
	var enemy_start: Vector2 = enemy_view.global_position
	var saw_movement := false
	var saw_attack := false
	var saw_impact := false
	var saw_knockback_or_airborne := false
	for _step in range(60):
		await main_loop.process_frame
		var report: Dictionary = controller.call("get_last_tick_report")
		if int(report.get("moved", 0)) > 0:
			saw_movement = true
		if int(report.get("attacked", 0)) > 0 or int(report.get("killed", 0)) > 0:
			saw_attack = true
		var events: Array = report.get("events", [])
		for event in events:
			var event_type := str(event.get("type", ""))
			if event_type == "attack" or event_type == "kill":
				saw_impact = true
			if event_type == "knockback" or event_type == "launch":
				saw_knockback_or_airborne = true
	var ally_displacement: float = ally_view.global_position.distance_to(ally_start)
	var enemy_displacement: float = enemy_view.global_position.distance_to(enemy_start)
	_assert_true(ally_displacement > 18.0 or enemy_displacement > 18.0, "battle scene should show obvious approach movement within the first second", failures)
	_assert_true(saw_movement, "battle controller should report charge movement within the first second", failures)
	_assert_true(saw_attack, "battle controller should report attack contact within the first second", failures)
	_assert_true(saw_impact, "combat report should expose impact events instead of only silent movement", failures)
	_assert_true(saw_knockback_or_airborne, "combat report should expose knockback or airborne feedback within the first second", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
