extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_restarting_scene_changes_some_initial_positions_without_breaking_sides(failures)
	return failures

func _test_restarting_scene_changes_some_initial_positions_without_breaking_sides(failures: Array[String]) -> void:
	var first_positions := await _capture_positions()
	var second_positions := await _capture_positions()
	_assert_eq(first_positions.size(), 12, "first battle boot should expose 12 unit views", failures)
	_assert_eq(second_positions.size(), 12, "second battle boot should expose 12 unit views", failures)
	if first_positions.size() != 12 or second_positions.size() != 12:
		return
	var changed := false
	for index in range(12):
		if first_positions[index] != second_positions[index]:
			changed = true
		if index < 6:
			_assert_true(second_positions[index].x < 620.0, "randomized ally spawn should stay on the left side", failures)
		else:
			_assert_true(second_positions[index].x > 660.0, "randomized enemy spawn should stay on the right side", failures)
	_assert_true(changed, "battle boot should randomize at least some initial unit positions between runs", failures)

func _capture_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	for index in range(12):
		var view = instance.get_node_or_null("UnitLayer/UnitView%d" % index)
		if view is Node2D:
			positions.append(view.global_position)
	main_loop.root.remove_child(instance)
	instance.free()
	return positions

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
