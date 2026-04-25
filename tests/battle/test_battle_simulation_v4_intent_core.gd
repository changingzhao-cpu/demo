extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationV4 = preload("res://scripts/battle/battle_simulation_v4.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_single_unit_gets_success_assignment(failures)
	_test_conflicting_claims_produce_unique_assignment(failures)
	_test_waiting_assignment_soft_holds_without_chase_velocity(failures)
	_test_assignment_survives_into_next_tick_snapshot(failures)
	_test_attack_holder_keeps_slot_against_new_claimer(failures)
	return failures

func _test_attack_holder_keeps_slot_against_new_claimer(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-3.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = 3
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(store.locked_slot_index[0]), 0, "attack holder should keep its assigned slot against a new claimer", failures)
	_assert_true(int(store.locked_slot_index[1]) != 0, "new claimer should not steal the attack holder slot", failures)

func _test_assignment_survives_into_next_tick_snapshot(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var first_slot := int(store.locked_slot_index[0])
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(store.locked_slot_index[0]), first_slot, "assigned slot should survive into the next tick snapshot", failures)
	_assert_true(first_slot != -1, "first tick should commit a concrete assigned slot", failures)

func _test_waiting_assignment_soft_holds_without_chase_velocity(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var before := Vector2(store.position_x[1], store.position_y[1])
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[1], store.position_y[1])
	if int(store.locked_slot_index[0]) == int(store.locked_slot_index[1]):
		failures.append("conflict fixture should produce a waiting loser before soft-hold assertions")
		return
	var waiting_id := 0 if int(store.locked_slot_index[0]) == -1 else 1
	var waiting_before := before if waiting_id == 1 else Vector2(store.position_x[0], store.position_y[0])
	var waiting_after := after if waiting_id == 1 else Vector2(store.position_x[0], store.position_y[0])
	_assert_true(waiting_after.distance_to(waiting_before) <= 0.001, "waiting assignment should soft-hold without forward movement", failures)
	_assert_true(absf(float(store.velocity_x[waiting_id])) <= 0.001 and absf(float(store.velocity_y[waiting_id])) <= 0.001, "waiting assignment should clear chase velocity", failures)
	_assert_eq(int(store.locked_slot_index[waiting_id]), -1, "waiting assignment should keep slot index at -1", failures)

func _test_single_unit_gets_success_assignment(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(report.get("processed", -1)), 2, "v4 report should count processed entities", failures)
	_assert_eq(int(store.target_id[0]), 1, "single unit should acquire the enemy target", failures)
	_assert_true(int(store.locked_slot_index[0]) != -1, "single unit should receive a resolved slot assignment", failures)

func _test_conflicting_claims_produce_unique_assignment(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(report.get("processed", -1)), 3, "v4 conflict tick should process all bucket entities", failures)
	_assert_true(int(store.target_id[0]) == 2 and int(store.target_id[1]) == 2, "both attackers should resolve the same target in the conflict fixture", failures)
	_assert_true(int(store.locked_slot_index[0]) != int(store.locked_slot_index[1]), "conflicting claims should resolve to unique assigned slots", failures)

func _prepare(store, entity_id: int, team_id: int, pos: Vector2, move_speed: float) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = team_id
	store.bucket_id[entity_id] = 0
	store.move_speed[entity_id] = move_speed
	store.position_x[entity_id] = pos.x
	store.position_y[entity_id] = pos.y
	store.velocity_x[entity_id] = 0.0
	store.velocity_y[entity_id] = 0.0
	store.target_id[entity_id] = -1
	store.contact_slot[entity_id] = -1
	store.intent_state[entity_id] = 0
	store.attack_permission[entity_id] = 0
	store.state_lock_until[entity_id] = 0.0
	store.locked_target_id[entity_id] = -1
	store.locked_slot_index[entity_id] = -1
	store.engagement_blocked_time[entity_id] = 0.0
	store.contact_settle_time[entity_id] = 0.0

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
