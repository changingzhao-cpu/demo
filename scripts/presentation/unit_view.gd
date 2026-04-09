extends Node2D
class_name UnitView

var _entity_id: int = -1

func _init() -> void:
	visible = false

func bind_entity(entity_id: int) -> void:
	_entity_id = entity_id
	visible = true

func unbind_entity() -> void:
	_entity_id = -1
	visible = false

func sync_from_entity(world_position: Vector2, is_alive: bool) -> void:
	global_position = world_position
	visible = _entity_id >= 0 and is_alive

func get_entity_id() -> int:
	return _entity_id
