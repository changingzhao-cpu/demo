extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_report_counts_attack_and_kill_events(failures)
	_test_report_counts_movement_when_target_is_out_of_range(failures)
	return failures

func _test_report_counts_attack_and_kill_events(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 3.0)
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.5
	store.position_y[target] = 0.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(target, Vector2(0.5, 0.0))

	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(report.get("attacked", 0)), 1, "combat report should count in-range attacks", failures)
	_assert_eq(int(report.get("killed", 0)), 1, "combat report should count lethal hits", failures)
	_assert_eq(int(report.get("in_range", 0)), 1, "combat report should count entities already in attack range", failures)

func _test_report_counts_movement_when_target_is_out_of_range(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 10.0)
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 4.0
	store.position_y[target] = 0.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(target, Vector2(4.0, 0.0))

	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_true(int(report.get("moved", 0)) >= 1, "combat report should count movers when targets are out of range", failures)
	_assert_eq(int(report.get("attacked", 0)), 0, "combat report should not count attacks while still chasing", failures)

func _prepare_attacker(store, attacker: int) -> void:
	store.alive[attacker] = 1
	store.team_id[attacker] = 0
	store.attack_interval[attacker] = 0.5
	store.attack_cd[attacker] = 0.0
	store.attack_range_sq[attacker] = 1.0
	store.move_speed[attacker] = 2.0
	store.max_hp[attacker] = 10.0
	store.hp[attacker] = 10.0

func _prepare_target(store, target: int, hp: float) -> void:
	store.alive[target] = 1
	store.team_id[target] = 1
	store.max_hp[target] = hp
	store.hp[target] = hp

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
