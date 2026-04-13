extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_combat_progress_changes_runtime_positions(failures)
	_test_opening_and_clash_keep_units_from_immediate_blob_overlap(failures)
	return failures

func _test_combat_progress_changes_runtime_positions(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var ally_view = instance.get_node_or_null("UnitLayer/UnitView0")
	var enemy_view = instance.get_node_or_null("UnitLayer/UnitView6")
	if ally_view == null or enemy_view == null:
		failures.append("battle scene should expose ally and enemy views before combat readability checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var ally_start: Vector2 = ally_view.global_position
	var enemy_start: Vector2 = enemy_view.global_position
	for _step in range(24):
		await main_loop.process_frame
	_assert_true(ally_view.global_position != ally_start or enemy_view.global_position != enemy_start, "combat readability should show at least one side moving during runtime", failures)
	_assert_true(float(ally_view.call("get_visual_motion_strength")) > 0.0, "ally view should expose motion strength during combat", failures)
	_assert_true(float(enemy_view.call("get_visual_motion_strength")) > 0.0, "enemy view should expose motion strength during combat", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_opening_and_clash_keep_units_from_immediate_blob_overlap(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var unit_layer = instance.get_node_or_null("UnitLayer")
	if unit_layer == null:
		failures.append("battle scene should expose unit layer before overlap readability checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var opening_min_distance := _minimum_visible_distance(unit_layer)
	for _step in range(90):
		await main_loop.process_frame
	var clash_min_distance := _minimum_visible_distance(unit_layer)
	_assert_true(opening_min_distance > 18.0, "opening layout should keep visible units separated enough to read target acquisition", failures)
	_assert_true(clash_min_distance > 6.0, "clash readability should not collapse all visible units into a single overlapping blob", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _minimum_visible_distance(unit_layer: Node) -> float:
	var positions: Array[Vector2] = []
	for child in unit_layer.get_children():
		if child is CanvasItem and child.visible and child is Node2D:
			positions.append(child.global_position)
	var best := INF
	for index in range(positions.size()):
		for next_index in range(index + 1, positions.size()):
			best = minf(best, positions[index].distance_to(positions[next_index]))
	return 0.0 if best == INF else best

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
