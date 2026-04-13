extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationScript = preload("res://scripts/battle/battle_simulation.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_tick_bucket_applies_damage_when_target_is_in_range(failures)
	_test_tick_bucket_can_kill_target_when_damage_is_lethal(failures)
	_test_in_range_attack_does_not_push_entities_apart(failures)
	_test_attacker_enters_attack_state_after_reaching_engagement_slot(failures)
	_test_crowded_attackers_do_not_all_stall_without_attacking(failures)
	return failures

func _test_crowded_attackers_do_not_all_stall_without_attacking(failures: Array[String]) -> void:
	var store = EntityStore.new(5)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var target: int = store.allocate()
	store.team_id[target] = 1
	store.alive[target] = 1
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.radius[target] = 0.65
	store.max_hp[target] = 100.0
	store.hp[target] = 100.0
	grid.upsert(target, Vector2.ZERO)
	var attackers: Array[int] = []
	for index in range(4):
		var attacker: int = store.allocate()
		attackers.append(attacker)
		_prepare_attacker(store, attacker)
		store.position_x[attacker] = -3.0 - float(index) * 0.2
		store.position_y[attacker] = float(index) * 0.4
		grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	for _step in range(12):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var attackers_in_attack := 0
	for attacker in attackers:
		if store.state[attacker] == 1:
			attackers_in_attack += 1
	_assert_true(attackers_in_attack >= 1, "crowded attackers should not all stall without entering attack", failures)

func _test_attacker_enters_attack_state_after_reaching_engagement_slot(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 100.0)
	store.position_x[attacker] = -1.4
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.attack_range_sq[attacker] = 0.25
	grid.upsert(attacker, Vector2(-1.4, 0.0))
	grid.upsert(target, Vector2(0.0, 0.0))
	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.engagement_target[attacker], target, "attacker should claim the target as its engagement target", failures)
	_assert_true(store.engagement_slot[attacker] >= 0, "attacker should claim an engagement slot before attacking", failures)
	for _step in range(5):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var slot_position: Vector2 = Vector2(store.position_x[target], store.position_y[target]) + BattleSimulationScript.ENGAGEMENT_SLOT_OFFSETS[store.engagement_slot[attacker]]
	var attacker_position: Vector2 = Vector2(store.position_x[attacker], store.position_y[attacker])
	_assert_true(attacker_position.distance_to(slot_position) < 0.35, "attacker should move toward its claimed engagement slot instead of only chasing target center", failures)
	_assert_eq(store.state[attacker], 1, "attacker should enter attack state after reaching its engagement slot", failures)

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
