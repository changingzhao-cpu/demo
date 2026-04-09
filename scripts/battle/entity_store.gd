extends RefCounted
class_name EntityStore

var capacity: int
var active_count: int = 0

var position_x: PackedFloat32Array
var position_y: PackedFloat32Array
var velocity_x: PackedFloat32Array
var velocity_y: PackedFloat32Array
var team_id: PackedInt32Array
var unit_type_id: PackedInt32Array
var hp: PackedFloat32Array
var max_hp: PackedFloat32Array
var attack_range_sq: PackedFloat32Array
var attack_cd: PackedFloat32Array
var attack_interval: PackedFloat32Array
var move_speed: PackedFloat32Array
var radius: PackedFloat32Array
var target_id: PackedInt32Array
var state: PackedInt32Array
var alive: PackedByteArray
var bucket_id: PackedInt32Array
var grid_id: PackedInt32Array

var _free_ids: Array[int] = []

func _init(max_entities: int) -> void:
	capacity = max(0, max_entities)
	position_x.resize(capacity)
	position_y.resize(capacity)
	velocity_x.resize(capacity)
	velocity_y.resize(capacity)
	team_id.resize(capacity)
	unit_type_id.resize(capacity)
	hp.resize(capacity)
	max_hp.resize(capacity)
	attack_range_sq.resize(capacity)
	attack_cd.resize(capacity)
	attack_interval.resize(capacity)
	move_speed.resize(capacity)
	radius.resize(capacity)
	target_id.resize(capacity)
	state.resize(capacity)
	alive.resize(capacity)
	bucket_id.resize(capacity)
	grid_id.resize(capacity)

	_free_ids.resize(capacity)
	for id in range(capacity):
		_free_ids[id] = id
		_reset_slot(id)

func allocate() -> int:
	if _free_ids.is_empty():
		return -1

	var id: int = _free_ids.pop_front()
	_reset_slot(id)
	alive[id] = 1
	active_count += 1
	return id

func release(id: int) -> void:
	if not _is_valid_id(id):
		return
	if alive[id] == 0:
		return

	_reset_slot(id)
	_free_ids.push_front(id)
	active_count = max(0, active_count - 1)

func free_count() -> int:
	return _free_ids.size()

func _reset_slot(id: int) -> void:
	position_x[id] = 0.0
	position_y[id] = 0.0
	velocity_x[id] = 0.0
	velocity_y[id] = 0.0
	team_id[id] = -1
	unit_type_id[id] = -1
	hp[id] = 0.0
	max_hp[id] = 0.0
	attack_range_sq[id] = 0.0
	attack_cd[id] = 0.0
	attack_interval[id] = 0.0
	move_speed[id] = 0.0
	radius[id] = 0.0
	target_id[id] = -1
	state[id] = 0
	alive[id] = 0
	bucket_id[id] = -1
	grid_id[id] = -1

func _is_valid_id(id: int) -> bool:
	return id >= 0 and id < capacity
