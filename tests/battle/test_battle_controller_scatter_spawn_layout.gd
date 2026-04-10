extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"
const ALLY_TEAM_ID := 0
const ENEMY_TEAM_ID := 1

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_start_run_uses_scatter_layout_with_clear_density_difference(failures)
	return failures

func _test_start_run_uses_scatter_layout_with_clear_density_difference(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	if not controller.has_method("get_entity_store") or not controller.has_method("get_live_entity_ids"):
		failures.append("battle controller should expose runtime store and live entities for scatter layout checks")
		controller.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	var ally_positions: Array[Vector2] = []
	var enemy_positions: Array[Vector2] = []
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		var position := Vector2(store.position_x[entity_id], store.position_y[entity_id])
		if store.team_id[entity_id] == ALLY_TEAM_ID:
			ally_positions.append(position)
		elif store.team_id[entity_id] == ENEMY_TEAM_ID:
			enemy_positions.append(position)
	_assert_eq(ally_positions.size(), 6, "wave 1 should still seed six ally units for scatter layout checks", failures)
	_assert_eq(enemy_positions.size(), 5, "wave 1 should still seed five enemies for scatter layout checks", failures)
	if ally_positions.size() == 6:
		_assert_true(_x_spread(ally_positions) >= 2.8, "ally scatter layout should spread across multiple forward lanes instead of a tight column pair", failures)
		_assert_true(_min_pair_distance(ally_positions) > 1.1, "ally scatter layout should avoid overlapping starting positions", failures)
		_assert_true(not _is_mechanical_grid(ally_positions), "ally scatter layout should not look like a mechanical grid", failures)
		_assert_true(_x_spread(ally_positions) - _x_spread(enemy_positions) >= 0.35 if enemy_positions.size() == 5 else true, "ally scatter should remain visibly wider than the enemy swarm", failures)
	if enemy_positions.size() == 5:
		_assert_true(_x_spread(enemy_positions) <= 2.9, "enemy scatter layout should stay denser than allies", failures)
		_assert_true(_min_pair_distance(enemy_positions) > 0.8, "enemy scatter layout should avoid overlapping starting positions", failures)
		_assert_true(not _is_mechanical_grid(enemy_positions), "enemy scatter layout should not look like a mechanical grid", failures)
	if ally_positions.size() == 6 and enemy_positions.size() == 5:
		_assert_true(_average_x(ally_positions) < -6.0, "allies should still stage clearly on the left side", failures)
		_assert_true(_average_x(enemy_positions) > 7.2, "enemies should still stage clearly on the right side", failures)
		_assert_true(_x_spread(ally_positions) > _x_spread(enemy_positions), "ally scatter should be looser while enemy swarm remains denser", failures)
		_assert_true(_average_pair_distance(ally_positions) > _average_pair_distance(enemy_positions), "ally scatter should keep lower density than the enemy swarm", failures)
		_assert_true(_team_gap(ally_positions, enemy_positions) >= 11.5, "opening scatter should preserve a visible central engagement corridor", failures)
		_assert_true(_rightmost_x(ally_positions) < _leftmost_x(enemy_positions), "opening formations should not overlap across the center lane", failures)
		_assert_true(_rightmost_x(ally_positions) <= -3.6, "allies should not open too close to the center line", failures)
		_assert_true(_leftmost_x(enemy_positions) >= 5.0, "enemies should not open too close to the center line", failures)
		_assert_true(_y_spread(enemy_positions) <= 3.2, "enemy swarm should stay vertically compact instead of becoming a tall blob", failures)
		_assert_true(_y_spread(ally_positions) >= 3.0, "allies should use multiple vertical lanes for a readable opening", failures)
	controller.free()

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

func _y_spread(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var min_y := positions[0].y
	var max_y := positions[0].y
	for position in positions:
		min_y = minf(min_y, position.y)
		max_y = maxf(max_y, position.y)
	return max_y - min_y

func _leftmost_x(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var min_x := positions[0].x
	for position in positions:
		min_x = minf(min_x, position.x)
	return min_x

func _rightmost_x(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var max_x := positions[0].x
	for position in positions:
		max_x = maxf(max_x, position.x)
	return max_x

func _team_gap(ally_positions: Array[Vector2], enemy_positions: Array[Vector2]) -> float:
	return _leftmost_x(enemy_positions) - _rightmost_x(ally_positions)

func _min_pair_distance(positions: Array[Vector2]) -> float:
	var best := INF
	for index in range(positions.size()):
		for next_index in range(index + 1, positions.size()):
			best = minf(best, positions[index].distance_to(positions[next_index]))
	return 0.0 if best == INF else best

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

func _is_mechanical_grid(positions: Array[Vector2]) -> bool:
	if positions.size() < 4:
		return false
	var sorted_xs: Array[float] = []
	var sorted_ys: Array[float] = []
	for position in positions:
		sorted_xs.append(position.x)
		sorted_ys.append(position.y)
	sorted_xs.sort()
	sorted_ys.sort()
	return _has_repeated_gap_pattern(sorted_xs) or _has_repeated_gap_pattern(sorted_ys)

func _has_repeated_gap_pattern(values: Array[float]) -> bool:
	if values.size() < 4:
		return false
	var rounded_gaps: Array[float] = []
	for index in range(1, values.size()):
		rounded_gaps.append(snappedf(values[index] - values[index - 1], 0.05))
	var counts := {}
	for gap in rounded_gaps:
		counts[gap] = int(counts.get(gap, 0)) + 1
	for gap in counts.keys():
		if float(gap) > 0.0 and int(counts[gap]) >= values.size() - 2:
			return true
	return false

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
