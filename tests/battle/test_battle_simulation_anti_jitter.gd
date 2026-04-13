extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_attacker_does_not_ping_pong_horizontally_while_chasing(failures)
	return failures

func _test_attacker_does_not_ping_pong_horizontally_while_chasing(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	store.team_id[attacker] = 0
	store.team_id[target] = 1
	store.alive[attacker] = 1
	store.alive[target] = 1
	store.position_x[attacker] = -4.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.move_speed[attacker] = 4.0
	store.attack_range_sq[attacker] = 0.25
	store.radius[attacker] = 0.65
	store.radius[target] = 0.65
	grid.upsert(attacker, Vector2(-4.0, 0.0))
	grid.upsert(target, Vector2(0.0, 0.0))
	var xs: Array[float] = []
	for _step in range(6):
		simulation.tick_bucket(store, 0.1, 0, 1)
		xs.append(store.position_x[attacker])
	_assert_true(xs[1] >= xs[0] and xs[2] >= xs[1] and xs[3] >= xs[2], "attacker x movement should remain monotonic while approaching a target slot", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
