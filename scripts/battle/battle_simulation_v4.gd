extends RefCounted
class_name BattleSimulationV4

const UnitIntent = preload("res://scripts/battle/unit_intent.gd")
const SlotAssignment = preload("res://scripts/battle/slot_assignment.gd")
const SlotArbitratorV4 = preload("res://scripts/battle/slot_arbitrator_v4.gd")
const MotionResolver = preload("res://scripts/battle/motion_resolver.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

var _grid
var _motion := MotionResolver.new()

func _init(grid) -> void:
	_grid = grid

func tick_bucket(store, delta: float, bucket_id: int, bucket_count: int) -> void:
	var snapshot := _collect_snapshot(store, bucket_id)
	var intents := _collect_intents(snapshot)
	var assignments := SlotArbitratorV4.resolve(intents, snapshot.get("target_positions", {}))
	_direct_and_commit(store, snapshot, assignments, delta)

func tick_bucket_with_report(store, delta: float, bucket_id: int, bucket_count: int) -> Dictionary:
	tick_bucket(store, delta, bucket_id, bucket_count)
	var processed := 0
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		if int(store.bucket_id[entity_id]) != bucket_id:
			continue
		processed += 1
	return {"processed": processed, "bucket_index": bucket_id, "bucket_count": bucket_count}

func _collect_snapshot(store, bucket_id: int) -> Dictionary:
	var entities := []
	var target_positions := {}
	for entity_id in range(store.capacity):
		if not store.alive[entity_id]:
			continue
		if int(store.bucket_id[entity_id]) != bucket_id:
			continue
		var payload := {
			"entity_id": entity_id,
			"team_id": int(store.team_id[entity_id]),
			"position": Vector2(store.position_x[entity_id], store.position_y[entity_id]),
			"target_id": int(store.target_id[entity_id]),
			"intent_state": int(store.intent_state[entity_id]),
			"move_speed": float(store.move_speed[entity_id])
		}
		entities.append(payload)
		target_positions[entity_id] = payload.position
	return {"entities": entities, "target_positions": target_positions}

func _collect_intents(snapshot: Dictionary) -> Array:
	var intents: Array = []
	var entities: Array = snapshot.get("entities", [])
	for entity_variant in entities:
		var entity: Dictionary = entity_variant
		var target_id := _find_target(snapshot, int(entity.entity_id), int(entity.team_id))
		if target_id == -1:
			continue
		var intent := UnitIntent.new()
		intent.entity_id = int(entity.entity_id)
		intent.target_id = target_id
		intent.desired_slot_index = 0
		intent.current_pos = entity.position
		var target_position: Vector2 = snapshot.get("target_positions", {}).get(target_id, Vector2.ZERO)
		var distance := intent.current_pos.distance_to(target_position)
		intent.priority_weight = 1.0 / maxf(distance, 0.001)
		intents.append(intent)
	return intents

func _find_target(snapshot: Dictionary, entity_id: int, team_id: int) -> int:
	for entity_variant in snapshot.get("entities", []):
		var candidate: Dictionary = entity_variant
		if int(candidate.entity_id) == entity_id:
			continue
		if int(candidate.team_id) == team_id:
			continue
		return int(candidate.entity_id)
	return -1

func _direct_and_commit(store, snapshot: Dictionary, assignments: Dictionary, delta: float) -> void:
	for entity_variant in snapshot.get("entities", []):
		var entity: Dictionary = entity_variant
		var entity_id := int(entity.entity_id)
		var assignment = assignments.get(entity_id, null)
		if assignment == null:
			continue
		store.target_id[entity_id] = int(assignment.target_id)
		store.locked_target_id[entity_id] = int(assignment.target_id)
		store.locked_slot_index[entity_id] = int(assignment.assigned_slot_index)
		store.contact_slot[entity_id] = int(assignment.assigned_slot_index)
		if int(assignment.status) == SlotAssignment.STATUS_SUCCESS:
			var motion := _motion.resolve({
				"intent_state": Types.INTENT_STATE_APPROACH,
				"position": entity.position,
				"contact_anchor": assignment.global_pos,
				"move_speed": float(entity.move_speed),
				"delta": delta
			})
			var next_position: Vector2 = motion.get("next_position", entity.position)
			var velocity: Vector2 = motion.get("velocity", Vector2.ZERO)
			store.position_x[entity_id] = next_position.x
			store.position_y[entity_id] = next_position.y
			store.velocity_x[entity_id] = velocity.x
			store.velocity_y[entity_id] = velocity.y
			_grid.upsert(entity_id, next_position)
		else:
			store.velocity_x[entity_id] = 0.0
			store.velocity_y[entity_id] = 0.0
