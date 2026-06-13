extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationV3 = preload("res://scripts/battle/battle_simulation_v3.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_multi_attackers_get_distinct_contact_slots(failures)
	return failures

func _test_multi_attackers_get_distinct_contact_slots(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV3.new(grid)
	_prepare(store, 0, 0, Vector2(-2.2, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-2.3, 0.4), 6.0)
	_prepare(store, 2, 0, Vector2(-2.4, -0.4), 6.0)
	_prepare(store, 3, 1, Vector2.ZERO, 0.0)
	for _step in range(24):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var occupied := {}
	var debug_rows: Array[String] = []
	for attacker in [0, 1, 2]:
		debug_rows.append("id=%d state=%d target=%d slot=%d pos=(%.2f,%.2f)" % [attacker, int(store.intent_state[attacker]), int(store.target_id[attacker]), int(store.contact_slot[attacker]), float(store.position_x[attacker]), float(store.position_y[attacker])])
		if int(store.intent_state[attacker]) == Types.INTENT_STATE_ATTACK:
			occupied[int(store.contact_slot[attacker])] = true
	if occupied.size() < 2:
		failures.append("skirmish trace: %s" % [" | ".join(debug_rows)])
	_assert_true(occupied.size() >= 2, "skirmish should keep at least two distinct contact slots occupied", failures)

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
