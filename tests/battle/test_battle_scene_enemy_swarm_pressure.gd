extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_enemy_swarm_reads_as_denser_and_more_pressuring_than_allies(failures)
	return failures

func _test_enemy_swarm_reads_as_denser_and_more_pressuring_than_allies(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var ally_positions := _collect_team_positions(instance, 0, 6)
	var enemy_positions := _collect_team_positions(instance, 6, 5)
	_assert_eq(ally_positions.size(), 6, "battle scene should expose six ally views for swarm-pressure checks", failures)
	_assert_eq(enemy_positions.size(), 5, "battle scene should expose five enemy views for swarm-pressure checks", failures)
	if ally_positions.size() == 6 and enemy_positions.size() == 5:
		_assert_true(_average_x(enemy_positions) - _average_x(ally_positions) >= 14.0, "enemy swarm should start as a forward pressure block opposite the allies", failures)
		_assert_true(_x_spread(enemy_positions) < _x_spread(ally_positions), "enemy swarm should read denser than the ally spread", failures)
		_assert_true(_average_pair_distance(enemy_positions) < _average_pair_distance(ally_positions), "enemy swarm should cluster more tightly than allies", failures)
		_assert_true(_nearest_neighbor_average(enemy_positions) < _nearest_neighbor_average(ally_positions), "enemy swarm should create stronger local clustering pressure than allies", failures)
		_assert_true(_average_x(enemy_positions) > 770.0, "enemy swarm should sit visually close enough to center to feel like it is pressing in", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _collect_team_positions(instance: Node, start_index: int, count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for offset in range(count):
		var view = instance.get_node_or_null("UnitLayer/UnitView%d" % (start_index + offset))
		if view is Node2D:
			positions.append(view.global_position)
	return positions

func _average_x(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var sum := 0.0
	for position in positions:
		sum += position.x
	return sum / float(positions.size())

func _x_spread(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var min_x := positions[0].x
	var max_x := positions[0].x
	for position in positions:
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
	return max_x - min_x

func _average_pair_distance(positions: Array[Vector2]) -> float:
	if positions.size() < 2:
		return 0.0
	var total := 0.0
	var pair_count := 0
	for index in range(positions.size()):
		for next_index in range(index + 1, positions.size()):
			total += positions[index].distance_to(positions[next_index])
			pair_count += 1
	return 0.0 if pair_count == 0 else total / float(pair_count)

func _nearest_neighbor_average(positions: Array[Vector2]) -> float:
	if positions.size() < 2:
		return 0.0
	var total := 0.0
	for index in range(positions.size()):
		var best := INF
		for next_index in range(positions.size()):
			if index == next_index:
				continue
			best = minf(best, positions[index].distance_to(positions[next_index]))
		total += 0.0 if best == INF else best
	return total / float(positions.size())

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
