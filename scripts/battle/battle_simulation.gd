extends RefCounted
class_name BattleSimulation

const DEFAULT_CHASE_DISTANCE := 18.0
const DEFAULT_ATTACK_DAMAGE := 10.0
const DEFAULT_KNOCKBACK_DISTANCE := 0.42
const DEFAULT_LAUNCH_HEIGHT := 0.26
const ATTACK_TRIGGER_BUFFER := 0.18
const ATTACK_STICKY_MARGIN := 0.22
const ENGAGEMENT_CENTER_DISTANCE := 1.2
const PRECONTACT_SPACING_RADIUS := 1.85
const PRECONTACT_SPACING_STEP := 0.22
const SAME_TEAM_SPACING_RADIUS := 1.45
const SAME_TEAM_SPACING_STEP := 0.18
const ENEMY_CONTACT_RADIUS := 1.52
const ENEMY_CONTACT_STEP := 0.15
const FORMATION_LANE_STRENGTH := 0.26
const MAX_MOVE_STEP_MULTIPLIER := 3.5
const ALLY_TEAM_ID := 0
const ENEMY_TEAM_ID := 1
const UNIT_STATE_IDLE := 0
const UNIT_STATE_ATTACK := 1
const UNIT_STATE_ADVANCE := 3
const UNIT_STATE_DEAD := 4
const ENGAGEMENT_SLOT_OFFSETS := [
	Vector2(-1.0, 0.0),
	Vector2(1.0, 0.0),
	Vector2(0.0, -0.83),
	Vector2(0.0, 0.83)
]

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
		_release_engagement_slot_if_needed(store, entity_id, target_id)
		store.state[entity_id] = UNIT_STATE_IDLE
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		report["idle"] = int(report.get("idle", 0)) + 1
		return

	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	var attack_range := sqrt(maxf(0.0, store.attack_range_sq[entity_id]))
	var slot_index := _resolve_engagement_slot(store, entity_id, target_id)
	var engagement_target := _resolve_engagement_slot_position(store, target_id, slot_index) if slot_index >= 0 else target
	var distance := origin.distance_to(engagement_target)
	var trigger_distance: float = _get_attack_trigger_distance(store, entity_id, target_id, false)
	var sticky_distance: float = _get_attack_trigger_distance(store, entity_id, target_id, true)
	var allowed_distance := sticky_distance if store.state[entity_id] == UNIT_STATE_ATTACK else trigger_distance

	if distance > allowed_distance:
		var target_is_locked_in_attack: bool = target_id >= 0 and target_id < store.capacity and store.alive[target_id] and store.state[target_id] == UNIT_STATE_ATTACK
		var contact_distance: float = attack_range + store.radius[entity_id] + store.radius[target_id]
		var center_distance: float = origin.distance_to(target)
		if target_is_locked_in_attack and center_distance <= contact_distance + ATTACK_STICKY_MARGIN:
			store.state[entity_id] = UNIT_STATE_ATTACK
			store.velocity_x[entity_id] = 0.0
			store.velocity_y[entity_id] = 0.0
			store.engagement_blocked_time[entity_id] = 0.0
			store.engagement_target[entity_id] = target_id
			store.engagement_slot[entity_id] = slot_index
			report["in_range"] = int(report.get("in_range", 0)) + 1
			var should_drive_locked_pair: bool = entity_id < target_id
			var target_was_alive_locked := bool(store.alive[target_id])
			var did_hit_locked: bool = _attack_resolver.resolve_basic_attack(store, entity_id, target_id, DEFAULT_ATTACK_DAMAGE) if should_drive_locked_pair else false
			if did_hit_locked:
				report["attacked"] = int(report.get("attacked", 0)) + 1
				_append_event(report, entity_id, target_id, "attack", origin, target)
				var impact_direction_locked := _resolve_impact_direction(origin, target)
				var knockback_target_locked := target + impact_direction_locked * DEFAULT_KNOCKBACK_DISTANCE
				_append_event(report, entity_id, target_id, "knockback", origin, knockback_target_locked)
				_append_event(report, entity_id, target_id, "launch", origin, target + Vector2(0.0, -DEFAULT_LAUNCH_HEIGHT))
			if did_hit_locked and target_was_alive_locked and not store.alive[target_id]:
				report["killed"] = int(report.get("killed", 0)) + 1
				_append_event(report, entity_id, target_id, "kill", origin, target)
				_grid.remove(target_id)
				_release_engagement_slot_if_needed(store, entity_id, -1)
			if not did_hit_locked:
				report["idle"] = int(report.get("idle", 0)) + 1
			grid_upsert_pair(store, entity_id, target_id)
			return
		_move_toward_position(store, entity_id, engagement_target, delta)
		var moved_distance := origin.distance_to(Vector2(store.position_x[entity_id], store.position_y[entity_id]))
		_update_engagement_blocked_time(store, entity_id, moved_distance, delta)
		_apply_same_team_spacing(store, entity_id)
		_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
		store.state[entity_id] = UNIT_STATE_ADVANCE
		report["moved"] = int(report.get("moved", 0)) + 1
		return
	_clamp_to_engagement_anchor(store, entity_id, engagement_target)
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	origin = Vector2(store.position_x[entity_id], store.position_y[entity_id])
	if origin.distance_to(engagement_target) > 0.001:
		var target_in_attack_contact: bool = target_id >= 0 and target_id < store.capacity and store.alive[target_id] and store.state[target_id] == UNIT_STATE_ATTACK
		if target_in_attack_contact:
			store.state[entity_id] = UNIT_STATE_ATTACK
			store.velocity_x[entity_id] = 0.0
			store.velocity_y[entity_id] = 0.0
			report["in_range"] = int(report.get("in_range", 0)) + 1
			return
		store.state[entity_id] = UNIT_STATE_ADVANCE
		report["moved"] = int(report.get("moved", 0)) + 1
		return
	if slot_index >= 0:
		target = engagement_target

	_apply_same_team_spacing(store, entity_id)

	_release_engagement_slot_if_needed(store, entity_id, target_id)
	if store.engagement_slot[entity_id] == -1:
		store.state[entity_id] = UNIT_STATE_IDLE
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		report["idle"] = int(report.get("idle", 0)) + 1
		return

	if store.engagement_target[entity_id] != target_id:
		store.engagement_target[entity_id] = target_id
		store.engagement_slot[entity_id] = slot_index
		store.engagement_blocked_time[entity_id] = 0.0

	if slot_index >= 0:
		target = engagement_target

	_apply_same_team_spacing(store, entity_id)
	store.state[entity_id] = UNIT_STATE_ATTACK
	store.velocity_x[entity_id] = 0.0
	store.velocity_y[entity_id] = 0.0
	store.engagement_blocked_time[entity_id] = 0.0
	store.engagement_target[entity_id] = target_id
	store.engagement_slot[entity_id] = slot_index
	if slot_index >= 0:
		target = engagement_target

	report["in_range"] = int(report.get("in_range", 0)) + 1
	var target_was_alive := bool(store.alive[target_id])
	var did_hit: bool = _attack_resolver.resolve_basic_attack(store, entity_id, target_id, DEFAULT_ATTACK_DAMAGE)
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
		_release_engagement_slot_if_needed(store, entity_id, -1)
	if not did_hit:
		report["idle"] = int(report.get("idle", 0)) + 1
	grid_upsert_pair(store, entity_id, target_id)
	return

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

func _get_attack_trigger_distance(store, entity_id: int, target_id: int, include_sticky_margin: bool) -> float:
	var attack_range := sqrt(maxf(0.0, store.attack_range_sq[entity_id]))
	var sticky_margin := ATTACK_STICKY_MARGIN if include_sticky_margin else 0.0
	return attack_range + ATTACK_TRIGGER_BUFFER + sticky_margin + store.radius[entity_id] + store.radius[target_id]

func _resolve_impact_direction(origin: Vector2, target: Vector2) -> Vector2:
	var direction := target - origin
	if direction == Vector2.ZERO:
		return Vector2.RIGHT
	return direction.normalized()

func _resolve_target(store, entity_id: int) -> int:
	var cached_target: int = store.target_id[entity_id]
	if _is_target_valid(store, entity_id, cached_target):
		return cached_target
	return _acquire_target(store, entity_id)

func _acquire_target(store, entity_id: int) -> int:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var best_target := -1
	var best_distance_sq := INF
	var nearby: Array[int] = _grid.query_neighbors(origin)
	if nearby.is_empty():
		for candidate in range(store.capacity):
			if candidate != entity_id and store.alive[candidate]:
				nearby.append(candidate)
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
	var target := Vector2(store.position_x[target_id], store.position_y[target_id])
	_move_toward_position(store, entity_id, target, delta)

func _move_toward_position(store, entity_id: int, target: Vector2, delta: float) -> void:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var direction := target - origin
	if direction == Vector2.ZERO:
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		return
	var distance := direction.length()
	var move_vector := direction.normalized()
	var step_length := minf(distance, store.move_speed[entity_id] * MAX_MOVE_STEP_MULTIPLIER * delta)
	var movement := move_vector * step_length
	store.position_x[entity_id] += movement.x
	store.position_y[entity_id] += movement.y
	store.velocity_x[entity_id] = movement.x / maxf(delta, 0.0001)
	store.velocity_y[entity_id] = movement.y / maxf(delta, 0.0001)

func _resolve_engagement_slot(store, entity_id: int, target_id: int) -> int:
	if store.engagement_target[entity_id] == target_id and store.engagement_slot[entity_id] >= 0:
		return store.engagement_slot[entity_id]
	for slot_index in range(ENGAGEMENT_SLOT_OFFSETS.size()):
		if _is_engagement_slot_free(store, entity_id, target_id, slot_index):
			store.engagement_target[entity_id] = target_id
			store.engagement_slot[entity_id] = slot_index
			return slot_index
	store.engagement_target[entity_id] = target_id
	store.engagement_slot[entity_id] = -1
	return -1

func _is_engagement_slot_free(store, entity_id: int, target_id: int, slot_index: int) -> bool:
	for candidate in range(store.capacity):
		if candidate == entity_id or not store.alive[candidate]:
			continue
		if store.team_id[candidate] != store.team_id[entity_id]:
			continue
		if store.engagement_target[candidate] == target_id and store.engagement_slot[candidate] == slot_index:
			return false
	return true

func _resolve_engagement_slot_position(store, target_id: int, slot_index: int) -> Vector2:
	var target_position := Vector2(store.position_x[target_id], store.position_y[target_id])
	var raw_offset: Vector2 = ENGAGEMENT_SLOT_OFFSETS[slot_index]
	var normalized_offset: Vector2 = raw_offset.normalized() if raw_offset != Vector2.ZERO else Vector2.LEFT
	return target_position + normalized_offset * ENGAGEMENT_CENTER_DISTANCE

func _clamp_to_engagement_anchor(store, entity_id: int, engagement_target: Vector2) -> void:
	var target_id: int = int(store.target_id[entity_id])
	if target_id >= 0 and target_id < store.capacity and store.alive[target_id] and store.state[target_id] == UNIT_STATE_ATTACK and entity_id > target_id:
		store.velocity_x[entity_id] = 0.0
		store.velocity_y[entity_id] = 0.0
		return
	store.position_x[entity_id] = engagement_target.x
	store.position_y[entity_id] = engagement_target.y
	store.velocity_x[entity_id] = 0.0
	store.velocity_y[entity_id] = 0.0

func _apply_precontact_spacing(store, entity_id: int, target_id: int) -> void:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var _target := Vector2(store.position_x[target_id], store.position_y[target_id])
	var nearby: Array[int] = _grid.query_neighbors(origin)
	var repulsion := Vector2.ZERO
	for candidate in nearby:
		if candidate == entity_id or candidate < 0 or candidate >= store.capacity:
			continue
		if not store.alive[candidate]:
			continue
		var candidate_position := Vector2(store.position_x[candidate], store.position_y[candidate])
		var offset := origin - candidate_position
		var distance := offset.length()
		if distance <= 0.001 or distance >= PRECONTACT_SPACING_RADIUS:
			continue
		var weight := (PRECONTACT_SPACING_RADIUS - distance) / PRECONTACT_SPACING_RADIUS
		if store.team_id[candidate] != store.team_id[entity_id]:
			var shared_target_bias := 1.0
			if candidate == target_id:
				shared_target_bias = 0.42
			weight *= 0.5 * shared_target_bias
		repulsion += offset.normalized() * weight
	if repulsion == Vector2.ZERO:
		return
	var step := repulsion.normalized() * minf(PRECONTACT_SPACING_STEP, repulsion.length() * 0.18)
	store.position_x[entity_id] += step.x
	store.position_y[entity_id] += step.y
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))

func _apply_same_team_spacing(store, entity_id: int) -> void:
	if store.state[entity_id] == UNIT_STATE_ATTACK:
		return
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var nearby: Array[int] = _grid.query_neighbors(origin)
	for candidate in nearby:
		if candidate == entity_id or candidate < 0 or candidate >= store.capacity:
			continue
		if not store.alive[candidate]:
			continue
		if store.team_id[candidate] != store.team_id[entity_id]:
			continue
		if store.state[candidate] == UNIT_STATE_ATTACK:
			continue
		var candidate_position := Vector2(store.position_x[candidate], store.position_y[candidate])
		var distance := origin.distance_to(candidate_position)
		if distance <= 0.001 or distance >= 0.6:
			continue
		var offset := (origin - candidate_position).normalized()
		store.position_x[entity_id] += offset.x * 0.04
		store.position_y[entity_id] += offset.y * 0.04
		origin = Vector2(store.position_x[entity_id], store.position_y[entity_id])
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))

func _update_engagement_blocked_time(store, entity_id: int, moved_distance: float, delta: float) -> void:
	if moved_distance <= 0.01:
		store.engagement_blocked_time[entity_id] += delta
	else:
		store.engagement_blocked_time[entity_id] = 0.0
	if store.engagement_blocked_time[entity_id] >= 0.35:
		store.engagement_slot[entity_id] = -1
		store.engagement_blocked_time[entity_id] = 0.0
		store.engagement_target[entity_id] = -1

func _release_engagement_slot_if_needed(store, entity_id: int, target_id: int) -> void:
	if target_id == -1 or not _is_target_valid(store, entity_id, target_id):
		store.engagement_slot[entity_id] = -1
		store.engagement_target[entity_id] = -1
		store.engagement_blocked_time[entity_id] = 0.0

func _apply_enemy_contact_resolution(store, entity_id: int) -> void:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var nearby: Array[int] = _grid.query_neighbors(origin)
	var repulsion := Vector2.ZERO
	for candidate in nearby:
		if candidate == entity_id or candidate < 0 or candidate >= store.capacity:
			continue
		if not store.alive[candidate]:
			continue
		if store.team_id[candidate] == store.team_id[entity_id]:
			continue
		var candidate_position := Vector2(store.position_x[candidate], store.position_y[candidate])
		var offset := origin - candidate_position
		var distance := offset.length()
		if distance <= 0.001 or distance >= ENEMY_CONTACT_RADIUS:
			continue
		var weight := (ENEMY_CONTACT_RADIUS - distance) / ENEMY_CONTACT_RADIUS
		repulsion += offset.normalized() * weight
	if repulsion == Vector2.ZERO:
		return
	var step := repulsion.normalized() * minf(ENEMY_CONTACT_STEP, repulsion.length() * 0.16)
	store.position_x[entity_id] += step.x
	store.position_y[entity_id] += step.y
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))

func grid_upsert_pair(store, entity_id: int, target_id: int) -> void:
	_grid.upsert(entity_id, Vector2(store.position_x[entity_id], store.position_y[entity_id]))
	if target_id >= 0 and target_id < store.capacity and store.alive[target_id]:
		_grid.upsert(target_id, Vector2(store.position_x[target_id], store.position_y[target_id]))
