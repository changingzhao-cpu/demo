extends RefCounted
class_name BattleSimulation

const DEFAULT_CHASE_DISTANCE := 12.0
const DEFAULT_ATTACK_DAMAGE := 3.5
const DEFAULT_KNOCKBACK_DISTANCE := 0.42
const DEFAULT_LAUNCH_HEIGHT := 0.26
const UNIT_STATE_IDLE := 0
const UNIT_STATE_ATTACK := 1
const UNIT_STATE_ADVANCE := 3
const UNIT_STATE_DEAD := 4

var _grid
var _push_resolver = preload("res://scripts/battle/push_resolver.gd").new()
var _attack_resolver = preload("res://scripts/battle/attack_resolver.gd").new()

func _init(grid) -> void:
	_grid = grid

func tick_bucket(store, delta: float, bucket_index: int, bucket_count: int) -> void:
	tick_bucket_with_report(store, delta, bucket_index, bucket_count)

func tick_bucket_with_report(store, delta: float, bucket_index: int, bucket_count: int, max_processed_entities: int = -1) -> Dictionary:
	var report: Dictionary = {
		"processed": 0,
		"bucket_index": bucket_index,
		"bucket_count": bucket_count,
		"moved": 0,
		"attacked": 0,
		"killed": 0,
		"idle": 0,
		"in_range": 0,
		"events": []
	}
	if bucket_count <= 0:
		return report

	var processed := 0
	for entity_id in range(store.capacity):
		if max_processed_entities >= 0 and processed >= max_processed_entities:
			break
		if not store.alive[entity_id]:
			continue
		if entity_id % bucket_count != bucket_index:
			continue
		_process_entity(store, entity_id, delta, report)
		processed += 1

	report["processed"] = processed
	return report

func _process_entity(store, entity_id: int, delta: float, report: Dictionary) -> void:
	if not store.alive[entity_id]:
		store.state[entity_id] = UNIT_STATE_DEAD
		return

	store.attack_cd[entity_id] = max(0.0, store.attack_cd[entity_id] - max(delta, 0.0))

	var target_id: int = _resolve_target(store, entity_id)
	store.target_id[entity_id] = target_id
	if target_id == -1:
		store.state[entity_id] = UNIT_STATE_IDLE
		report["idle"] = int(report.get("idle", 0)) + 1
		return

	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	var distance_sq := origin.distance_squared_to(target)
	if distance_sq <= max(0.0, store.attack_range_sq[entity_id]):
		report["in_range"] = int(report.get("in_range", 0)) + 1
		var target_was_alive := bool(store.alive[target_id])
		var did_hit: bool = _attack_resolver.resolve_basic_attack(store, entity_id, target_id, DEFAULT_ATTACK_DAMAGE)
		store.state[entity_id] = UNIT_STATE_ATTACK if did_hit else UNIT_STATE_IDLE
		if did_hit:
			report["attacked"] = int(report.get("attacked", 0)) + 1
			_append_event(report, entity_id, target_id, "attack", origin, target)
			var impact_direction := _resolve_impact_direction(origin, target)
			var knockback_target := target + impact_direction * DEFAULT_KNOCKBACK_DISTANCE
			_append_event(report, entity_id, target_id, "knockback", origin, knockback_target)
			_append_event(report, entity_id, target_id, "launch", origin, target + Vector2(0.0, -DEFAULT_LAUNCH_HEIGHT))
		if did_hit and target_was_alive and not store.alive[target_id]:
			report["killed"] = int(report.get("killed", 0)) + 1
			_append_event(report, entity_id, target_id, "kill", origin, target)
			_grid.remove(target_id)
		if not did_hit:
			report["idle"] = int(report.get("idle", 0)) + 1
		return

	_move_toward_target(store, entity_id, target_id, delta)
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	_push_resolver.call("resolve_pair", store, entity_id, target_id)
	store.state[entity_id] = UNIT_STATE_ADVANCE
	report["moved"] = int(report.get("moved", 0)) + 1

func _append_event(report: Dictionary, attacker_id: int, target_id: int, event_type: String, attacker_position: Vector2, target_position: Vector2) -> void:
	var events: Array = report.get("events", [])
	events.append({
		"type": event_type,
		"attacker_id": attacker_id,
		"target_id": target_id,
		"attacker_position": attacker_position,
		"target_position": target_position
	})
	report["events"] = events

func _resolve_impact_direction(origin: Vector2, target: Vector2) -> Vector2:
	var direction := target - origin
	if direction == Vector2.ZERO:
		return Vector2.RIGHT
	return direction.normalized()

func _resolve_target(store, entity_id: int) -> int:
	var cached_target: int = store.target_id[entity_id]
	if _is_target_valid(store, entity_id, cached_target):
		return cached_target

	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var best_target := -1
	var best_distance_sq := INF
	var nearby: Array[int] = _grid.query_neighbors(origin)
	for candidate in nearby:
		if not _is_enemy_candidate(store, entity_id, candidate):
			continue
		var distance_sq: float = origin.distance_squared_to(Vector2(store.position_x[candidate], store.position_y[candidate]))
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = candidate
	if best_target != -1:
		return best_target
	for candidate in range(store.capacity):
		if not _is_enemy_candidate(store, entity_id, candidate):
			continue
		var distance_sq: float = origin.distance_squared_to(Vector2(store.position_x[candidate], store.position_y[candidate]))
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = candidate
	return best_target

func _is_target_valid(store, entity_id: int, target_id: int) -> bool:
	if not _is_enemy_candidate(store, entity_id, target_id):
		return false
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	return origin.distance_to(target) <= DEFAULT_CHASE_DISTANCE

func _is_enemy_candidate(store, entity_id: int, candidate_id: int) -> bool:
	if candidate_id == -1 or candidate_id == entity_id:
		return false
	if not store.alive[candidate_id]:
		return false
	return store.team_id[candidate_id] != store.team_id[entity_id]

func _move_toward_target(store, entity_id: int, target_id: int, delta: float) -> void:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	var direction := target - origin
	if direction == Vector2.ZERO:
		return
	var distance := direction.length()
	var engage_boost := 1.0
	if distance > 8.0:
		engage_boost = 1.45
	elif distance > 4.0:
		engage_boost = 1.22
	var movement: Vector2 = direction.normalized() * store.move_speed[entity_id] * engage_boost * delta
	store.position_x[entity_id] += movement.x
	store.position_y[entity_id] += movement.y
