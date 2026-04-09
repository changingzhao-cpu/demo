extends RefCounted
class_name BattleSimulation

const DEFAULT_CHASE_DISTANCE := 12.0

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
		"bucket_count": bucket_count
	}
	if bucket_count <= 0:
		return report

	var processed: int = 0
	for entity_id in range(store.capacity):
		if max_processed_entities >= 0 and processed >= max_processed_entities:
			break
		if not store.alive[entity_id]:
			continue
		if entity_id % bucket_count != bucket_index:
			continue
		_process_entity(store, entity_id, delta)
		processed += 1

	report["processed"] = processed
	return report

func _process_entity(store, entity_id: int, delta: float) -> void:
	var target_id: int = _resolve_target(store, entity_id)
	store.target_id[entity_id] = target_id
	if target_id == -1:
		return

	_move_toward_target(store, entity_id, target_id, delta)
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	_push_resolver.call("resolve_pair", store, entity_id, target_id)

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
	var movement: Vector2 = direction.normalized() * store.move_speed[entity_id] * delta
	store.position_x[entity_id] += movement.x
	store.position_y[entity_id] += movement.y
