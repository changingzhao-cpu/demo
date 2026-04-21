extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationV3 = preload("res://scripts/battle/battle_simulation_v3.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_duel_enters_contact_before_attack(failures)
	_test_attack_hold_has_no_drift(failures)
	return failures

func _test_duel_enters_contact_before_attack(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV3.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var contact_debug: Array[String] = []
	var saw_contact := false
	for tick in range(9):
		simulation.tick_bucket(store, 0.1, 0, 1)
		contact_debug.append("tick=%d state=%d pos=(%.2f,%.2f) target=%d slot=%d contact=%s raw_slot=%d" % [tick, int(store.intent_state[0]), float(store.position_x[0]), float(store.position_y[0]), int(store.target_id[0]), int(store.contact_slot[0]), str(bool(store.attack_permission[0])), int(store.state[0])])
		if int(store.intent_state[0]) == Types.INTENT_STATE_CONTACT:
			saw_contact = true
	if not saw_contact:
		failures.append("duel contact trace: %s" % [" | ".join(contact_debug)])
	_assert_true(saw_contact, "duel should stabilize in CONTACT before ATTACK", failures)
	_assert_eq(int(store.intent_state[0]), Types.INTENT_STATE_ATTACK, "duel should later enter ATTACK", failures)
	return
	_assert_eq(int(store.intent_state[0]), Types.INTENT_STATE_ATTACK, "duel should later enter ATTACK", failures)

func _test_attack_hold_has_no_drift(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV3.new(grid)
	_prepare(store, 0, 0, Vector2(-1.1, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	for _step in range(4):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var before := Vector2(store.position_x[0], store.position_y[0])
	for _step in range(10):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[0], store.position_y[0])
	_assert_true(before.distance_to(after) <= 0.05, "attack hold should not drift in duel", failures)

func _prepare(store, entity_id: int, team_id: int, pos: Vector2, move_speed: float) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = team_id
	store.bucket_id[entity_id] = 0
	store.move_speed[entity_id] = move_speed
	store.position_x[entity_id] = pos.x
	store.position_y[entity_id] = pos.y

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
