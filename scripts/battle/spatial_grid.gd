extends RefCounted
class_name SpatialGrid

var cell_size: float
var _cells: Dictionary = {}
var _entity_to_cell: Dictionary = {}

func _init(grid_cell_size: float) -> void:
	cell_size = max(0.001, grid_cell_size)

func upsert(entity_id: int, position: Vector2) -> void:
	var next_cell := _world_to_cell(position)
	var previous_cell: Variant = _entity_to_cell.get(entity_id, null)
	if previous_cell == next_cell:
		return

	if previous_cell != null:
		_remove_from_cell(entity_id, previous_cell)

	_entity_to_cell[entity_id] = next_cell
	var bucket: Array[int] = []
	if _cells.has(next_cell):
		bucket = _cells[next_cell]
	bucket.append(entity_id)
	_cells[next_cell] = bucket

func remove(entity_id: int) -> void:
	var cell: Variant = _entity_to_cell.get(entity_id, null)
	if cell == null:
		return

	_remove_from_cell(entity_id, cell)
	_entity_to_cell.erase(entity_id)

func query_neighbors(position: Vector2) -> Array[int]:
	var center := _world_to_cell(position)
	var results: Array[int] = []
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 1, center.x + 2):
			var cell := Vector2i(x, y)
			if not _cells.has(cell):
				continue
			results.append_array(_cells[cell])
	return results

func get_cell_key(entity_id: int):
	return _entity_to_cell.get(entity_id, null)

func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(position.x / cell_size)),
		int(floor(position.y / cell_size))
	)

func _remove_from_cell(entity_id: int, cell: Vector2i) -> void:
	if not _cells.has(cell):
		return

	var bucket: Array[int] = _cells[cell]
	var index := bucket.find(entity_id)
	if index != -1:
		bucket.remove_at(index)

	if bucket.is_empty():
		_cells.erase(cell)
	else:
		_cells[cell] = bucket
