extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationV2 = preload("res://scripts/battle/battle_simulation_v2.gd")
const BattleSimulationV2Types = preload("res://scripts/battle/battle_simulation_v2_types.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_v2_simulation_constructs(failures)
	_test_duel_enters_attack_after_contact(failures)
	_test_attack_hold_does_not_drift_in_duel(failures)
	_test_attack_exits_when_target_becomes_invalid(failures)
	_test_v2_skirmish_multi_attackers_do_not_rebind_attack_same_tick(failures)
	return failures

func _test_v2_simulation_constructs(failures: Array[String]) -> void:
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV2.new(grid)
	_assert_true(simulation != null, "battle_simulation_v2 should construct with SpatialGrid dependency", failures)

func _test_duel_enters_attack_after_contact(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV2.new(grid)
	var attacker := store.allocate()
	var target := store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target)
	store.position_x[attacker] = -2.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	for entity_id in [attacker, target]:
		grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	for _step in range(8):
		simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(int(store.state[attacker]), BattleSimulationV2Types.UNIT_STATE_ATTACK, "v2 duel attacker should enter ATTACK after reaching contact", failures)
	_assert_eq(int(store.target_id[attacker]), target, "v2 duel attacker should keep target id after entering ATTACK", failures)

func _test_attack_hold_does_not_drift_in_duel(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV2.new(grid)
	var attacker := store.allocate()
	var target := store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target)
	store.position_x[attacker] = -1.2
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	for entity_id in [attacker, target]:
		grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	for _step in range(2):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var before := Vector2(store.position_x[attacker], store.position_y[attacker])
	for _step in range(10):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[attacker], store.position_y[attacker])
	_assert_eq(int(store.state[attacker]), BattleSimulationV2Types.UNIT_STATE_ATTACK, "v2 duel attacker should remain in ATTACK during hold", failures)
	_assert_true(before.distance_to(after) <= 0.05, "v2 duel ATTACK hold should not drift while target stays valid", failures)

func _test_attack_exits_when_target_becomes_invalid(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV2.new(grid)
	var attacker := store.allocate()
	var target := store.allocate()
	_prepare_attacker(store, attacker)
	_prepare_target(store, target)
	store.position_x[attacker] = -1.2
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	for entity_id in [attacker, target]:
		grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	for _step in range(2):
		simulation.tick_bucket(store, 0.1, 0, 1)
	store.alive[target] = 0
	grid.remove(target)
	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_true(int(store.state[attacker]) != BattleSimulationV2Types.UNIT_STATE_ATTACK, "v2 duel attacker should exit ATTACK when target becomes invalid", failures)

func _test_v2_skirmish_multi_attackers_do_not_rebind_attack_same_tick(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV2.new(grid)
	var attacker_a := store.allocate()
	var attacker_b := store.allocate()
	var attacker_c := store.allocate()
	var target := store.allocate()
	for attacker in [attacker_a, attacker_b, attacker_c]:
		_prepare_attacker(store, attacker)
		store.attack_range_sq[attacker] = 0.25
	_prepare_target(store, target)
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.position_x[attacker_a] = -2.2
	store.position_y[attacker_a] = 0.0
	store.position_x[attacker_b] = -2.3
	store.position_y[attacker_b] = 0.4
	store.position_x[attacker_c] = -2.4
	store.position_y[attacker_c] = -0.4
	for entity_id in [attacker_a, attacker_b, attacker_c, target]:
		grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	for _step in range(20):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var attack_count := 0
	var target_count := 0
	for attacker in [attacker_a, attacker_b, attacker_c]:
		if int(store.state[attacker]) == BattleSimulationV2Types.UNIT_STATE_ATTACK:
			attack_count += 1
		if int(store.target_id[attacker]) == target:
			target_count += 1
	_assert_true(attack_count >= 2, "v2 skirmish should allow multiple attackers to stabilize on one target without same-tick rebind collapse", failures)
	_assert_true(target_count >= 2, "v2 skirmish should keep at least two attackers on the shared target instead of scattering target assignment", failures)
	var first_slot := int(store.engagement_slot[attacker_a])
	_assert_true(first_slot != -1, "v2 skirmish should assign a non-negative engagement slot to the first attacker", failures)
	for attacker in [attacker_b, attacker_c]:
		if int(store.state[attacker]) == BattleSimulationV2Types.UNIT_STATE_ATTACK:
			_assert_true(int(store.engagement_slot[attacker]) != first_slot, "v2 skirmish attackers should not share the same attack slot on one target", failures)
	for _step in range(5):
		simulation.tick_bucket(store, 0.1, 0, 1)
		for attacker in [attacker_a, attacker_b, attacker_c]:
			if int(store.state[attacker]) == BattleSimulationV2Types.UNIT_STATE_ATTACK:
				_assert_eq(int(store.target_id[attacker]), target, "v2 skirmish attacker should not rebind away from the shared target during stable attack hold", failures)
				_assert_true(int(store.engagement_slot[attacker]) != -1, "v2 skirmish attacker should keep a stable non-negative attack slot during hold", failures)
				_assert_true(float(store.velocity_x[attacker]) == 0.0 and float(store.velocity_y[attacker]) == 0.0, "v2 skirmish attacker should not keep movement velocity while holding attack", failures)
	var attack_slots := {}
	for attacker in [attacker_a, attacker_b, attacker_c]:
		if int(store.state[attacker]) == BattleSimulationV2Types.UNIT_STATE_ATTACK:
			attack_slots[int(store.engagement_slot[attacker])] = true
	_assert_true(attack_slots.size() >= 2, "v2 skirmish should keep at least two distinct attack slots occupied on the shared target", failures)

func _prepare_attacker(store, entity_id: int) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = 0
	store.bucket_id[entity_id] = 0
	store.move_speed[entity_id] = 6.0
	store.attack_range_sq[entity_id] = 0.25
	store.attack_interval[entity_id] = 0.5
	store.attack_cd[entity_id] = 0.0
	store.radius[entity_id] = 0.65
	store.hp[entity_id] = 100.0
	store.max_hp[entity_id] = 100.0

func _prepare_target(store, entity_id: int) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = 1
	store.bucket_id[entity_id] = 0
	store.move_speed[entity_id] = 0.0
	store.attack_range_sq[entity_id] = 0.0
	store.attack_interval[entity_id] = 10.0
	store.attack_cd[entity_id] = 10.0
	store.radius[entity_id] = 0.65
	store.hp[entity_id] = 100.0
	store.max_hp[entity_id] = 100.0

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
