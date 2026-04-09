extends RefCounted

const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_register_and_neighbor_query(failures)
	_test_move_updates_grid_membership(failures)
	_test_remove_entity(failures)
	return failures

func _test_register_and_neighbor_query(failures: Array[String]) -> void:
	var grid = SpatialGrid.new(10.0)
	grid.upsert(1, Vector2(2.0, 2.0))
	grid.upsert(2, Vector2(9.0, 9.0))
	grid.upsert(3, Vector2(11.0, 1.0))
	grid.upsert(4, Vector2(25.0, 25.0))

	_assert_eq(grid.get_cell_key(1), Vector2i(0, 0), "entity 1 cell should be (0,0)", failures)
	_assert_eq(grid.get_cell_key(3), Vector2i(1, 0), "entity 3 cell should be (1,0)", failures)

	var nearby: Array[int] = grid.query_neighbors(Vector2(5.0, 5.0))
	nearby.sort()
	_assert_eq(nearby, [1, 2, 3], "9-cell query should include adjacent cells only", failures)

func _test_move_updates_grid_membership(failures: Array[String]) -> void:
	var grid = SpatialGrid.new(10.0)
	grid.upsert(7, Vector2(1.0, 1.0))
	grid.upsert(8, Vector2(18.0, 1.0))
	grid.upsert(7, Vector2(21.0, 2.0))

	_assert_eq(grid.get_cell_key(7), Vector2i(2, 0), "moved entity should report new cell", failures)

	var old_neighbors: Array[int] = grid.query_neighbors(Vector2(1.0, 1.0))
	old_neighbors.sort()
	_assert_eq(old_neighbors, [8], "moved entity should leave old neighborhood", failures)

	var new_neighbors: Array[int] = grid.query_neighbors(Vector2(21.0, 2.0))
	new_neighbors.sort()
	_assert_eq(new_neighbors, [7, 8], "moved entity should appear in new neighborhood", failures)

func _test_remove_entity(failures: Array[String]) -> void:
	var grid = SpatialGrid.new(10.0)
	grid.upsert(10, Vector2(5.0, 5.0))
	grid.upsert(11, Vector2(6.0, 6.0))
	grid.remove(10)

	_assert_eq(grid.get_cell_key(10), null, "removed entity should no longer have a cell", failures)

	var neighbors: Array[int] = grid.query_neighbors(Vector2(5.0, 5.0))
	neighbors.sort()
	_assert_eq(neighbors, [11], "removed entity should disappear from neighbor query", failures)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
