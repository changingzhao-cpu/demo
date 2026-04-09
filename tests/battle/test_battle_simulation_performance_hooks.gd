extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_tick_bucket_reports_processed_entity_count(failures)
	_test_tick_bucket_respects_max_processed_entities(failures)
	_test_tick_bucket_reports_bucket_metadata(failures)
	return failures

func _test_tick_bucket_reports_processed_entity_count(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	_prepare_pair(store, grid, 0.0, 0.0, 2.0, 0.0)
	_prepare_pair(store, grid, 0.0, 4.0, 2.0, 4.0)

	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(report.get("processed", -1)), 4, "tick report should include the number of processed entities", failures)
	_assert_eq(int(report.get("bucket_index", -1)), 0, "tick report should include the bucket index", failures)
	_assert_eq(int(report.get("bucket_count", -1)), 1, "tick report should include the bucket count", failures)

func _test_tick_bucket_respects_max_processed_entities(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	_prepare_pair(store, grid, 0.0, 0.0, 2.0, 0.0)
	_prepare_pair(store, grid, 0.0, 4.0, 2.0, 4.0)

	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1, 2)
	_assert_eq(int(report.get("processed", -1)), 2, "tick report should stop at max_processed_entities", failures)
	_assert_eq(store.target_id[0], 1, "first processed entity should resolve a target", failures)
	_assert_eq(store.target_id[1], 0, "second processed entity should resolve a target", failures)
	_assert_eq(store.target_id[2], -1, "entities beyond the processing cap should remain untouched", failures)
	_assert_eq(store.target_id[3], -1, "entities beyond the processing cap should remain untouched", failures)

func _test_tick_bucket_reports_bucket_metadata(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	_prepare_pair(store, grid, 0.0, 0.0, 2.0, 0.0)
	_prepare_pair(store, grid, 0.0, 4.0, 2.0, 4.0)

	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 1, 2)
	_assert_eq(int(report.get("bucket_index", -1)), 1, "report should preserve bucket_index", failures)
	_assert_eq(int(report.get("bucket_count", -1)), 2, "report should preserve bucket_count", failures)
	_assert_eq(int(report.get("processed", -1)), 2, "only matching bucket entities should be counted as processed", failures)
	_assert_eq(store.target_id[0], -1, "bucket mismatch entity should not run", failures)
	_assert_eq(store.target_id[1], 0, "bucket match entity should run", failures)
	_assert_eq(store.target_id[2], -1, "bucket mismatch entity should not run", failures)
	_assert_eq(store.target_id[3], 2, "bucket match entity should run", failures)

func _prepare_pair(store, grid, ax: float, ay: float, bx: float, by: float) -> void:
	var attacker: int = store.allocate()
	var defender: int = store.allocate()
	store.team_id[attacker] = 1
	store.team_id[defender] = 2
	store.position_x[attacker] = ax
	store.position_y[attacker] = ay
	store.position_x[defender] = bx
	store.position_y[defender] = by
	store.move_speed[attacker] = 1.0
	store.move_speed[defender] = 1.0
	grid.upsert(attacker, Vector2(ax, ay))
	grid.upsert(defender, Vector2(bx, by))

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
