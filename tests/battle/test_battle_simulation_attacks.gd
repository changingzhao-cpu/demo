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
	_test_attacker_keeps_attacking_with_small_distance_jitter(failures)
	_test_attack_center_distance_stays_within_1_2(failures)
	_test_attack_pair_does_not_drift_while_both_units_are_attacking(failures)
	_test_unclaimed_slot_contact_does_not_snap_to_target_center(failures)
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

func _test_attacker_keeps_attacking_with_small_distance_jitter(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 100.0)
	store.position_x[attacker] = -0.95
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.attack_range_sq[attacker] = 0.25
	grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	grid.upsert(target, Vector2.ZERO)
	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.state[attacker], 1, "attacker should enter attack state at the engagement edge", failures)
	store.position_x[target] = 0.08
	grid.upsert(target, Vector2(store.position_x[target], store.position_y[target]))
	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.state[attacker], 1, "attacker should keep attacking under small contact jitter instead of dropping back to chase", failures)

func _test_attack_center_distance_stays_within_1_2(failures: Array[String]) -> void:
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
	grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	grid.upsert(target, Vector2.ZERO)
	for _step in range(6):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var attacker_position := Vector2(store.position_x[attacker], store.position_y[attacker])
	var target_position := Vector2(store.position_x[target], store.position_y[target])
	var attack_distance := attacker_position.distance_to(target_position)
	_assert_eq(store.state[attacker], 1, "attacker should still enter attack state after tightening center distance", failures)
	_assert_true(attack_distance <= 1.205, "attack center distance should stay within 1.2 once the attacker enters attack state (actual=%s)" % str(attack_distance), failures)

func _test_attack_pair_does_not_drift_while_both_units_are_attacking(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target, 1000.0)
	store.position_x[attacker] = -1.2
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.attack_range_sq[attacker] = 0.25
	store.attack_interval[attacker] = 10.0
	store.attack_cd[attacker] = 0.0
	store.move_speed[target] = 0.0
	store.attack_range_sq[target] = 0.0
	store.attack_interval[target] = 10.0
	store.attack_cd[target] = 10.0
	grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	grid.upsert(target, Vector2(store.position_x[target], store.position_y[target]))
	for _step in range(2):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var attacker_before := Vector2(store.position_x[attacker], store.position_y[attacker])
	var target_before := Vector2(store.position_x[target], store.position_y[target])
	for _step in range(10):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var attacker_after := Vector2(store.position_x[attacker], store.position_y[attacker])
	var target_after := Vector2(store.position_x[target], store.position_y[target])
	_assert_eq(store.state[attacker], 1, "attacker should stay in attack during stationary contact", failures)
	_assert_true(store.state[target] == 1, "stationary target fixture should also settle into attack once contact stays locked", failures)
	_assert_true(attacker_after.distance_to(attacker_before) < 0.05, "an attacker already locked in contact should not drift across the arena", failures)
	_assert_true(target_after.distance_to(target_before) < 0.05, "a stationary target should not get dragged while being attacked in place", failures)
	_assert_true(attacker_after.distance_to(target_after) <= 1.205, "locked attack contact should keep the pair within the engagement distance", failures)
	_assert_true(attacker_after.distance_to(target_after) >= 0.9, "locked contact should not collapse units into overlap", failures)
	_assert_true(store.hp[target] >= 890.0, "regression fixture should avoid large combat noise while measuring drift", failures)
	_assert_true(store.alive[attacker] == 1 and store.alive[target] == 1, "stationary-contact regression should keep both fixtures alive", failures)
	_assert_true(absf(store.velocity_x[attacker]) < 0.01 and absf(store.velocity_y[attacker]) < 0.01, "locked attacker should not accumulate velocity spikes while holding contact", failures)
	_assert_true(absf(store.velocity_x[target]) < 0.01 and absf(store.velocity_y[target]) < 0.01, "stationary target should not accumulate velocity spikes while being held in contact", failures)

func _test_unclaimed_slot_contact_does_not_snap_to_target_center(failures: Array[String]) -> void:
	var store = EntityStore.new(6)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var blocker_left: int = store.allocate()
	var blocker_right: int = store.allocate()
	var blocker_up: int = store.allocate()
	var blocker_down: int = store.allocate()
	var follower: int = store.allocate()
	var target: int = store.allocate()
	for blocker in [blocker_left, blocker_right, blocker_up, blocker_down, follower]:
		_prepare_attacker(store, blocker)
		store.attack_range_sq[blocker] = 0.25
	_prepare_target(store, target, 100.0)
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.position_x[blocker_left] = -1.2
	store.position_y[blocker_left] = 0.0
	store.position_x[blocker_right] = 1.2
	store.position_y[blocker_right] = 0.0
	store.position_x[blocker_up] = 0.0
	store.position_y[blocker_up] = -1.2
	store.position_x[blocker_down] = 0.0
	store.position_y[blocker_down] = 1.2
	store.position_x[follower] = -0.2
	store.position_y[follower] = -0.2
	grid.upsert(blocker_left, Vector2(store.position_x[blocker_left], store.position_y[blocker_left]))
	grid.upsert(blocker_right, Vector2(store.position_x[blocker_right], store.position_y[blocker_right]))
	grid.upsert(blocker_up, Vector2(store.position_x[blocker_up], store.position_y[blocker_up]))
	grid.upsert(blocker_down, Vector2(store.position_x[blocker_down], store.position_y[blocker_down]))
	grid.upsert(follower, Vector2(store.position_x[follower], store.position_y[follower]))
	grid.upsert(target, Vector2.ZERO)
	for _step in range(4):
		simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.engagement_slot[follower], -1, "follower fixture should have no free engagement slot in this regression", failures)
	var follower_before := Vector2(store.position_x[follower], store.position_y[follower])
	simulation.tick_bucket(store, 0.1, 0, 1)
	var follower_after := Vector2(store.position_x[follower], store.position_y[follower])
	var target_center := Vector2(store.position_x[target], store.position_y[target])
	_assert_true(follower_after.distance_to(target_center) > 0.6, "unit without a claimed slot should not snap onto the target center", failures)
	_assert_true(follower_after.distance_to(follower_before) < 0.8, "unit without a slot should not make a single-tick jump when contact begins", failures)
	_assert_true(store.state[follower] != BattleSimulationScript.UNIT_STATE_ATTACK, "unit without a slot should not enter ATTACK by snapping to target center", failures)
	_assert_true(store.target_id[follower] == target, "follower should still keep the same combat target while waiting for a slot", failures)
	_assert_true(store.engagement_target[follower] == target, "follower should still track the same engagement target while waiting for a slot", failures)
	_assert_true(store.engagement_slot[blocker_left] >= 0 and store.engagement_slot[blocker_right] >= 0 and store.engagement_slot[blocker_up] >= 0 and store.engagement_slot[blocker_down] >= 0, "all blocker fixtures should occupy the four engagement slots", failures)
	_assert_true(absf(store.velocity_x[follower]) < 8.0 and absf(store.velocity_y[follower]) < 8.0, "unit without a slot should not report a launch-like velocity spike", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
