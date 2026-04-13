extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_boot_spreads_units_within_team_regions(failures)
	return failures

func _test_boot_spreads_units_within_team_regions(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var ally_views := _collect_views(instance, 0, 6)
	var enemy_views := _collect_views(instance, 6, 6)
	_assert_eq(ally_views.size(), 6, "battle scene should expose six ally views for formation readability", failures)
	_assert_eq(enemy_views.size(), 6, "battle scene should expose six enemy views for formation readability", failures)
	if ally_views.size() == 6:
		_assert_true(_min_pair_distance(ally_views) > 18.0, "ally formation should not visually collapse into a single cluster on boot", failures)
		_assert_true(_average_x(ally_views) < 610.0, "ally formation should start on the left half of the battlefield", failures)
	if enemy_views.size() == 6:
		_assert_true(_min_pair_distance(enemy_views) > 18.0, "enemy formation should not visually collapse into a single cluster on boot", failures)
		_assert_true(_average_x(enemy_views) > 670.0, "enemy formation should start on the right half of the battlefield", failures)
	_assert_true(absf(_average_x(enemy_views) - _average_x(ally_views)) > 120.0 if ally_views.size() == 6 and enemy_views.size() == 6 else true, "opening should keep ally and enemy visible groups separated across the screen", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _collect_views(instance, start_index: int, count: int) -> Array[Node2D]:
	var views: Array[Node2D] = []
	for offset in range(count):
		var view = instance.get_node_or_null("UnitLayer/UnitView%d" % (start_index + offset))
		if view is Node2D:
			views.append(view)
	return views

func _min_pair_distance(views: Array[Node2D]) -> float:
	var best := INF
	for index in range(views.size()):
		for next_index in range(index + 1, views.size()):
			best = minf(best, views[index].global_position.distance_to(views[next_index].global_position))
	return 0.0 if best == INF else best

func _average_x(views: Array[Node2D]) -> float:
	if views.is_empty():
		return 0.0
	var sum := 0.0
	for view in views:
		sum += view.global_position.x
	return sum / float(views.size())

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
