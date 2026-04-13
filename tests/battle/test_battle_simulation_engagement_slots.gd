extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_attackers_claim_different_slots_around_the_same_target(failures)
	return failures

func _test_attackers_claim_different_slots_around_the_same_target(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker_a: int = store.allocate()
	var attacker_b: int = store.allocate()
	var target: int = store.allocate()
	store.team_id[attacker_a] = 0
	store.team_id[attacker_b] = 0
	store.team_id[target] = 1
	store.alive[attacker_a] = 1
	store.alive[attacker_b] = 1
	store.alive[target] = 1
	store.position_x[attacker_a] = -3.0
	store.position_y[attacker_a] = 0.0
	store.position_x[attacker_b] = -3.0
	store.position_y[attacker_b] = 1.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.move_speed[attacker_a] = 4.0
	store.move_speed[attacker_b] = 4.0
	store.attack_range_sq[attacker_a] = 1.7
	store.attack_range_sq[attacker_b] = 1.7
	store.radius[attacker_a] = 0.65
	store.radius[attacker_b] = 0.65
	store.radius[target] = 0.65
	grid.upsert(attacker_a, Vector2(-3.0, 0.0))
	grid.upsert(attacker_b, Vector2(-3.0, 1.0))
	grid.upsert(target, Vector2(0.0, 0.0))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_true(store.engagement_slot[attacker_a] != store.engagement_slot[attacker_b], "attackers should claim different engagement slots", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
