extends RefCounted
class_name PushResolver

func resolve_pair(store, left_id: int, right_id: int) -> void:
	if left_id == right_id:
		return
	if not store.alive[left_id] or not store.alive[right_id]:
		return

	var dx: float = store.position_x[right_id] - store.position_x[left_id]
	var dy: float = store.position_y[right_id] - store.position_y[left_id]
	var combined_radius: float = store.radius[left_id] + store.radius[right_id]
	var distance_sq: float = dx * dx + dy * dy
	var combined_radius_sq: float = combined_radius * combined_radius
	if distance_sq >= combined_radius_sq:
		return

	if distance_sq == 0.0:
		dx = 0.0001
		dy = 0.0
		distance_sq = dx * dx

	var distance: float = sqrt(distance_sq)
	var overlap: float = combined_radius - distance
	if overlap <= 0.0:
		return

	var normal_x: float = dx / distance
	var normal_y: float = dy / distance
	var push_amount: float = overlap * 0.5
	store.position_x[left_id] -= normal_x * push_amount
	store.position_y[left_id] -= normal_y * push_amount
	store.position_x[right_id] += normal_x * push_amount
	store.position_y[right_id] += normal_y * push_amount
