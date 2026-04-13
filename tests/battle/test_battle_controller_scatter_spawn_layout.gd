extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"
const ALLY_TEAM_ID := 0
const ENEMY_TEAM_ID := 1

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_start_run_uses_scatter_layout_with_clear_density_difference(failures)
	_test_enemy_scatter_layout_stays_stable_across_multiple_runs(failures)
	return failures

func _test_enemy_scatter_layout_stays_stable_across_multiple_runs(failures: Array[String]) -> void:
	for _iteration in range(8):
		var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
		controller.start_run()
		var store = controller.call("get_entity_store")
		var live_entity_ids: Array = controller.call("get_live_entity_ids")
		var enemy_positions: Array[Vector2] = []
		for entity_id_variant in live_entity_ids:
			var entity_id := int(entity_id_variant)
			if store.team_id[entity_id] == ENEMY_TEAM_ID:
				enemy_positions.append(Vector2(store.position_x[entity_id], store.position_y[entity_id]))
		var cluster_count := _vertical_cluster_balance(enemy_positions, 1.0)
		_assert_true(cluster_count >= 4, "goose opening should consistently keep several readable pockets across runs", failures)
		controller.free()

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
	_assert_eq(ally_positions.size(), 18, "wave 1 should seed a fuller ally group closer to the reference opening", failures)
	_assert_eq(enemy_positions.size(), 24, "wave 1 should seed a fuller goose group closer to the reference opening", failures)
	if ally_positions.size() == 18:
		_assert_true(_x_spread(ally_positions) >= 15.0, "ally opening should spread across a broad arena width", failures)
		_assert_true(_y_spread(ally_positions) >= 9.0, "ally opening should occupy multiple vertical lanes", failures)
		_assert_true(_min_pair_distance(ally_positions) > 1.0, "ally opening should avoid overlapping start points", failures)
		_assert_true(not _is_mechanical_grid(ally_positions), "ally opening should not read as a mechanical slot grid", failures)
		_assert_true(_vertical_cluster_balance(ally_positions, 1.0) >= 5, "ally opening should break into several readable pockets", failures)
	if enemy_positions.size() == 24:
		_assert_true(_x_spread(enemy_positions) >= 15.0, "goose opening should also spread across a broad arena width", failures)
		_assert_true(_y_spread(enemy_positions) >= 9.0, "goose opening should occupy multiple vertical lanes", failures)
		_assert_true(_min_pair_distance(enemy_positions) > 0.9, "goose opening should avoid overlapping start points", failures)
		_assert_true(not _is_mechanical_grid(enemy_positions), "goose opening should not read as a rigid slot strip", failures)
		_assert_true(_vertical_cluster_balance(enemy_positions, 1.0) >= 4, "goose opening should break into several readable pockets", failures)
	if ally_positions.size() == 18 and enemy_positions.size() == 24:
		_assert_true(_minimum_center_distance(ally_positions, enemy_positions) >= 1.0, "opening formations should leave readable room before first contact", failures)
		_assert_true(_minimum_center_distance(ally_positions, enemy_positions) <= 8.5, "opening formations should still feel engaged in the same arena", failures)
		_assert_true(_average_pair_distance(ally_positions) > 4.8, "allies should open as a loose distributed group", failures)
		_assert_true(_average_pair_distance(enemy_positions) > 4.0, "geese should open as a loose distributed swarm", failures)
		_assert_true(_x_spread(ally_positions) >= 0.85 * _x_spread(enemy_positions), "ally opening should be comparably wide to the goose spread", failures)
		_assert_true(absf(_average_x(ally_positions) - _average_x(enemy_positions)) <= 6.0, "opening should no longer split into two distant left-right camps", failures)
		_assert_true(_row_cluster_count(ally_positions) >= 5, "ally opening should read as many local clusters, not one flat row", failures)
		_assert_true(_row_cluster_count(enemy_positions) >= 5, "goose opening should read as many local clusters, not one flat row", failures)
		_assert_true(_leftmost_x(enemy_positions) < _rightmost_x(ally_positions), "two sides should interleave inside the same arena instead of spawning as isolated camps", failures)
		_assert_true(_team_gap(ally_positions, enemy_positions) < 0.0, "opening should intentionally overlap horizontally in arena space", failures)
		_assert_true(_center_hole_radius(ally_positions, enemy_positions) >= 2.2, "opening should preserve a readable loose center pocket like the reference", failures)
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

func _minimum_center_distance(ally_positions: Array[Vector2], enemy_positions: Array[Vector2]) -> float:
	var best := INF
	for ally_position in ally_positions:
		for enemy_position in enemy_positions:
			best = minf(best, ally_position.distance_to(enemy_position))
	return 0.0 if best == INF else best

func _row_cluster_count(positions: Array[Vector2]) -> int:
	if positions.is_empty():
		return 0
	var ys: Array[float] = []
	for position in positions:
		ys.append(position.y)
	ys.sort()
	var clusters := 1
	for index in range(1, ys.size()):
		if absf(ys[index] - ys[index - 1]) > 0.7:
			clusters += 1
	return clusters

func _vertical_cluster_balance(positions: Array[Vector2], threshold: float) -> int:
	if positions.is_empty():
		return 0
	var ys: Array[float] = []
	for position in positions:
		ys.append(position.y)
	ys.sort()
	var clusters := 1
	for index in range(1, ys.size()):
		if absf(ys[index] - ys[index - 1]) > threshold:
			clusters += 1
	return clusters

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

func _center_hole_radius(ally_positions: Array[Vector2], enemy_positions: Array[Vector2]) -> float:
	var positions: Array[Vector2] = []
	positions.append_array(ally_positions)
	positions.append_array(enemy_positions)
	if positions.is_empty():
		return 0.0
	var center := Vector2.ZERO
	for position in positions:
		center += position
	center /= float(positions.size())
	var best := INF
	for position in positions:
		best = minf(best, position.distance_to(center))
	return 0.0 if best == INF else best

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
