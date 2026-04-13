extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_nearest_target_selection(failures)
	_test_cached_target_reused_without_retargeting(failures)
	_test_valid_target_lock_is_kept_even_when_a_closer_enemy_appears(failures)
	_test_out_of_range_target_reselects(failures)
	_test_bucketed_updates_only_process_matching_bucket(failures)
	return failures

func _test_valid_target_lock_is_kept_even_when_a_closer_enemy_appears(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var locked_target: int = store.allocate()
	var closer_target: int = store.allocate()
	store.team_id[attacker] = 0
	store.team_id[locked_target] = 1
	store.team_id[closer_target] = 1
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[locked_target] = 6.0
	store.position_y[locked_target] = 0.0
	store.position_x[closer_target] = 2.0
	store.position_y[closer_target] = 0.0
	store.target_id[attacker] = locked_target
	store.move_speed[attacker] = 4.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(locked_target, Vector2(6.0, 0.0))
	grid.upsert(closer_target, Vector2(2.0, 0.0))

	store.position_x[locked_target] = 17.5
	store.position_y[locked_target] = 0.0
	grid.upsert(locked_target, Vector2(17.5, 0.0))
	grid.upsert(closer_target, Vector2(2.0, 0.0))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.target_id[attacker], locked_target, "valid target lock should be kept until a hard invalidation happens", failures)
	_assert_true(store.target_id[attacker] != closer_target, "a closer enemy inside chase distance should not break an existing valid target lock", failures)

func _test_nearest_target_selection(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var near_target: int = store.allocate()
	var far_target: int = store.allocate()
	store.team_id[attacker] = 1
	store.team_id[near_target] = 2
	store.team_id[far_target] = 2
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[near_target] = 3.0
	store.position_y[near_target] = 0.0
	store.position_x[far_target] = 7.0
	store.position_y[far_target] = 0.0
	store.move_speed[attacker] = 4.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(near_target, Vector2(3.0, 0.0))
	grid.upsert(far_target, Vector2(7.0, 0.0))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.target_id[attacker], near_target, "simulation should choose the nearest enemy target", failures)

func _test_cached_target_reused_without_retargeting(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var cached_target: int = store.allocate()
	var closer_new_target: int = store.allocate()
	store.team_id[attacker] = 1
	store.team_id[cached_target] = 2
	store.team_id[closer_new_target] = 2
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[cached_target] = 6.0
	store.position_y[cached_target] = 0.0
	store.position_x[closer_new_target] = 2.0
	store.position_y[closer_new_target] = 0.0
	store.target_id[attacker] = cached_target
	store.move_speed[attacker] = 5.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(cached_target, Vector2(6.0, 0.0))
	grid.upsert(closer_new_target, Vector2(2.0, 0.0))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.target_id[attacker], cached_target, "targeting should keep a valid locked enemy target within chase range instead of switching to a closer enemy", failures)

func _test_out_of_range_target_reselects(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var stale_target: int = store.allocate()
	var replacement: int = store.allocate()
	store.team_id[attacker] = 1
	store.team_id[stale_target] = 2
	store.team_id[replacement] = 2
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[stale_target] = 30.0
	store.position_y[stale_target] = 0.0
	store.position_x[replacement] = 4.0
	store.position_y[replacement] = 0.0
	store.target_id[attacker] = stale_target
	store.move_speed[attacker] = 3.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(stale_target, Vector2(30.0, 0.0))
	grid.upsert(replacement, Vector2(4.0, 0.0))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.target_id[attacker], replacement, "out-of-range target should be replaced by a nearby enemy", failures)

func _test_bucketed_updates_only_process_matching_bucket(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker_a: int = store.allocate()
	var attacker_b: int = store.allocate()
	var enemy_a: int = store.allocate()
	var enemy_b: int = store.allocate()
	store.team_id[attacker_a] = 1
	store.team_id[attacker_b] = 1
	store.team_id[enemy_a] = 2
	store.team_id[enemy_b] = 2
	store.position_x[attacker_a] = 0.0
	store.position_y[attacker_a] = 0.0
	store.position_x[attacker_b] = 0.0
	store.position_y[attacker_b] = 1.0
	store.position_x[enemy_a] = 3.0
	store.position_y[enemy_a] = 0.0
	store.position_x[enemy_b] = 4.0
	store.position_y[enemy_b] = 1.0
	store.move_speed[attacker_a] = 1.0
	store.move_speed[attacker_b] = 1.0
	grid.upsert(attacker_a, Vector2(0.0, 0.0))
	grid.upsert(attacker_b, Vector2(0.0, 1.0))
	grid.upsert(enemy_a, Vector2(3.0, 0.0))
	grid.upsert(enemy_b, Vector2(4.0, 1.0))

	simulation.tick_bucket(store, 0.1, 0, 2)
	_assert_true(store.target_id[attacker_a] != -1, "bucket 0 entity should be processed", failures)
	_assert_eq(store.target_id[attacker_b], -1, "bucket 1 entity should not be processed yet", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
