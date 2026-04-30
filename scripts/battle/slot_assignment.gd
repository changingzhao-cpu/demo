extends RefCounted
class_name SlotAssignment

const STATUS_SUCCESS := 0
const STATUS_WAITING := 1
const STATUS_LOST := 2

var target_id: int = -1
var assigned_slot_index: int = -1
var global_pos: Vector2 = Vector2.ZERO
var status: int = STATUS_LOST
