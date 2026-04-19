extends RefCounted
class_name BattleSimulationV2

const Types = preload("res://scripts/battle/battle_simulation_v2_types.gd")
const DEFAULT_ATTACK_DAMAGE := Types.DEFAULT_ATTACK_DAMAGE
const ATTACK_CONTACT_DISTANCE := Types.ATTACK_CONTACT_DISTANCE
const DEFAULT_CHASE_DISTANCE := Types.DEFAULT_CHASE_DISTANCE

var _grid

func _init(grid) -> void:
	_grid = grid

func tick_bucket(store, delta: float, bucket_id: int, bucket_count: int) -> void:
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		if int(store.bucket_id[entity_id]) != bucket_id:
			continue
		_tick_entity(store, entity_id, delta)

func _tick_entity(store, entity_id: int, delta: float) -> void:
	var target_id := _acquire_target(store, entity_id)
	store.target_id[entity_id] = target_id
	if target_id == -1:
		store.state[entity_id] = Types.UNIT_STATE_IDLE
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		return
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	var distance := origin.distance_to(target)
	var slot_index := _resolve_slot_for_target(store, entity_id, target_id)
	if store.state[entity_id] == Types.UNIT_STATE_ATTACK and _can_hold_attack(store, entity_id, target_id, slot_index):
		store.engagement_slot[entity_id] = slot_index
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		return
	if distance <= ATTACK_CONTACT_DISTANCE and _can_enter_attack_with_slot(target_id, slot_index):
		store.state[entity_id] = Types.UNIT_STATE_ATTACK
		store.engagement_slot[entity_id] = slot_index
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		return
	store.state[entity_id] = Types.UNIT_STATE_ADVANCE
	store.engagement_slot[entity_id] = -1
	var direction := (target - origin).normalized()
	var step := minf(distance, store.move_speed[entity_id] * delta)
	var movement := direction * step
	store.position_x[entity_id] += movement.x
	store.position_y[entity_id] += movement.y
	store.velocity_x[entity_id] = movement.x / maxf(delta, 0.0001)
	store.velocity_y[entity_id] = movement.y / maxf(delta, 0.0001)
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))

func _acquire_target(store, entity_id: int) -> int:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var best_target := -1
	var best_distance_sq := INF
	for candidate in range(store.capacity):
		if candidate == entity_id:
			continue
		if not store.alive[candidate]:
			continue
		if store.team_id[candidate] == store.team_id[entity_id]:
			continue
		var distance_sq := origin.distance_squared_to(Vector2(store.position_x[candidate], store.position_y[candidate]))
		if distance_sq > DEFAULT_CHASE_DISTANCE * DEFAULT_CHASE_DISTANCE:
			continue
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = candidate
	return best_target

func _resolve_slot_for_target(store, entity_id: int, target_id: int) -> int:
	var current_slot := int(store.engagement_slot[entity_id])
	if current_slot >= 0 and _is_slot_free_for_target(store, entity_id, target_id, current_slot):
		return current_slot
	for slot_index in range(3):
		if _is_slot_free_for_target(store, entity_id, target_id, slot_index):
			return slot_index
	return -1

func _is_slot_free_for_target(store, entity_id: int, target_id: int, slot_index: int) -> bool:
	for candidate in range(store.capacity):
		if candidate == entity_id:
			continue
		if not store.alive[candidate]:
			continue
		if store.team_id[candidate] != store.team_id[entity_id]:
			continue
		if int(store.target_id[candidate]) != target_id:
			continue
		if int(store.engagement_slot[candidate]) == slot_index:
			return false
	return true

func _can_enter_attack_with_slot(target_id: int, slot_index: int) -> bool:
	return target_id != -1 and slot_index != -1

func _can_hold_attack(store, entity_id: int, target_id: int, slot_index: int) -> bool:
	if target_id == -1 or slot_index == -1:
		return false
	if not store.alive[target_id]:
		return false
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	return origin.distance_to(target) <= ATTACK_CONTACT_DISTANCE

func build_authoritative_battle_contract(store) -> Dictionary:
	var entities: Array = []
	if store == null:
		return {"ticksource": "battle_simulation_v2", "entities": entities}
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		entities.append({
			"entity_id": entity_id,
			"team_id": int(store.team_id[entity_id]),
			"state": int(store.state[entity_id]),
			"state_name": _state_name(int(store.state[entity_id])),
			"target_id": int(store.target_id[entity_id]),
			"logic_position": Vector2(store.position_x[entity_id], store.position_y[entity_id]),
			"logic_velocity": Vector2(store.velocity_x[entity_id], store.velocity_y[entity_id])
		})
	return {
		"ticksource": "battle_simulation_v2",
		"entities": entities
	}

func _state_name(state_value: int) -> String:
	match state_value:
		Types.UNIT_STATE_IDLE:
			return "IDLE"
		Types.UNIT_STATE_ATTACK:
			return "ATTACK"
		Types.UNIT_STATE_ADVANCE:
			return "ADVANCE"
		_:
			return str(state_value)

func debug_get_entity_truth_snapshot(store, entity_id: int) -> Dictionary:
	if store == null or entity_id < 0 or entity_id >= store.capacity:
		return {"entity_id": entity_id, "exists": false}
	if not store.alive[entity_id]:
		return {"entity_id": entity_id, "exists": false}
	return {
		"entity_id": entity_id,
		"exists": true,
		"source": "simulation_truth",
		"state": int(store.state[entity_id]),
		"state_name": _state_name(int(store.state[entity_id])),
		"target_id": int(store.target_id[entity_id]),
		"position": Vector2(store.position_x[entity_id], store.position_y[entity_id]),
		"velocity": Vector2(store.velocity_x[entity_id], store.velocity_y[entity_id])
	}

func tick_bucket_with_report(store, delta: float, bucket_id: int, bucket_count: int) -> Dictionary:
	tick_bucket(store, delta, bucket_id, bucket_count)
	return {}

func grid_upsert_pair(store, entity_id: int, target_id: int) -> void:
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	if target_id >= 0 and target_id < store.capacity and store.alive[target_id]:
		_grid.upsert(target_id, Vector2(store.position_x[target_id], store.position_y[target_id]))

func _state_name_from_types(state_value: int) -> String:
	return _state_name(state_value)

func _process_reportless_attack(_store, _entity_id: int, _target_id: int) -> void:
	return

func _release_unused_stub() -> void:
	return
