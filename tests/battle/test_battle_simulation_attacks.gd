extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_tick_bucket_applies_damage_when_target_is_in_range(failures)
	_test_tick_bucket_can_kill_target_when_damage_is_lethal(failures)
	_test_in_range_attack_does_not_push_entities_apart(failures)
	return failures

func _test_tick_bucket_applies_damage_when_target_is_in_range(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 100.0)
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 1.25
	store.position_y[target] = 0.0
	grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	grid.upsert(target, Vector2(store.position_x[target], store.position_y[target]))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_true(store.hp[target] == 90.0, "battle simulation should apply the configured 10 damage when an enemy is in attack range", failures)
	_assert_true(store.attack_cd[attacker] > 0.0, "battle simulation should set attack cooldown after landing a hit", failures)

func _test_tick_bucket_can_kill_target_when_damage_is_lethal(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 10.0)
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 1.25
	store.position_y[target] = 0.0
	grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	grid.upsert(target, Vector2(store.position_x[target], store.position_y[target]))

	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_false(bool(store.alive[target]), "battle simulation should be able to kill targets through attack resolution", failures)
	_assert_eq(store.hp[target], 0.0, "lethal battle simulation hit should clamp hp to zero", failures)

func _prepare_attacker(store, attacker: int) -> void:
	store.alive[attacker] = 1
	store.team_id[attacker] = 0
	store.attack_interval[attacker] = 0.5
	store.attack_cd[attacker] = 0.0
	store.attack_range_sq[attacker] = 1.7
	store.move_speed[attacker] = 6.0
	store.max_hp[attacker] = 100.0
	store.hp[attacker] = 100.0
	store.radius[attacker] = 0.65

func _prepare_target(store, target: int, hp: float) -> void:
	store.alive[target] = 1
	store.team_id[target] = 1
	store.max_hp[target] = hp
	store.hp[target] = hp
	store.radius[target] = 0.65

func _test_in_range_attack_does_not_push_entities_apart(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 100.0)
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 1.25
	store.position_y[target] = 0.0
	grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	grid.upsert(target, Vector2(store.position_x[target], store.position_y[target]))
	var before_attacker := Vector2(store.position_x[attacker], store.position_y[attacker])
	var before_target := Vector2(store.position_x[target], store.position_y[target])
	simulation.tick_bucket(store, 0.1, 0, 1)
	var after_attacker := Vector2(store.position_x[attacker], store.position_y[attacker])
	var after_target := Vector2(store.position_x[target], store.position_y[target])
	_assert_true(after_attacker.distance_to(before_attacker) < 0.05, "attacker should hold position once already in attack range", failures)
	_assert_true(after_target.distance_to(before_target) < 0.05, "target should not get shoved away simply because combat started in range", failures)
	_assert_true(after_attacker.distance_to(after_target) <= before_attacker.distance_to(before_target) + 0.02, "in-range attack logic should not create visible separation at contact start", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
