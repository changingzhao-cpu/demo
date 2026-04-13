extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_first_seconds_show_formation_motion_and_combat_signals(failures)
	_test_battle_scene_hides_nonessential_overlay_nodes(failures)
	return failures

func _test_first_seconds_show_formation_motion_and_combat_signals(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	if controller == null or ally_view == null:
		failures.append("battle scene should expose controller and at least one unit view before first-seconds acceptance checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var start_position: Vector2 = ally_view.global_position
	var saw_attack_signal := false
	var saw_movement_signal := false
	for _step in range(90):
		await main_loop.process_frame
		var report: Dictionary = controller.call("get_last_tick_report")
		if int(report.get("moved", 0)) > 0:
			saw_movement_signal = true
		if int(report.get("attacked", 0)) > 0 or int(report.get("killed", 0)) > 0 or int(report.get("in_range", 0)) > 0:
			saw_attack_signal = true
	_assert_true(ally_view.global_position != start_position, "battle scene should visibly move units within the first seconds", failures)
	_assert_true(saw_movement_signal, "battle controller should report movement during the first seconds", failures)
	_assert_true(saw_attack_signal, "battle controller should report combat contact within the first seconds", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_battle_scene_hides_nonessential_overlay_nodes(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var frontline_marker = instance.get_node_or_null("FrontlineMarker")
	var left_band = instance.get_node_or_null("SpawnBandLeft")
	var right_band = instance.get_node_or_null("SpawnBandRight")
	if frontline_marker is CanvasItem:
		_assert_true(not frontline_marker.visible or frontline_marker.modulate.a <= 0.12, "battle scene should not leave a heavy frontline overlay on top of the artwork", failures)
	if left_band is CanvasItem:
		_assert_true(not left_band.visible or left_band.modulate.a <= 0.08, "battle scene should not leave a heavy ally staging overlay on top of the artwork", failures)
	if right_band is CanvasItem:
		_assert_true(not right_band.visible or right_band.modulate.a <= 0.08, "battle scene should not leave a heavy enemy staging overlay on top of the artwork", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
