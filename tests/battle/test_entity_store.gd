extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_initialization(failures)
	_test_allocate_until_full(failures)
	_test_recycle_freed_id(failures)
	_test_reset_slot_defaults(failures)
	return failures

func _test_initialization(failures: Array[String]) -> void:
	var store := EntityStore.new(4)
	_assert_eq(store.capacity, 4, "capacity should match constructor input", failures)
	_assert_eq(store.active_count, 0, "active_count should start at 0", failures)
	_assert_eq(store.free_count(), 4, "free_count should equal capacity initially", failures)
	_assert_eq(store.position_x.size(), 4, "position_x array should be pre-sized", failures)
	_assert_eq(store.hp.size(), 4, "hp array should be pre-sized", failures)
	for id in range(4):
		_assert_false(store.alive[id], "slot %d should start dead" % id, failures)
		_assert_eq(store.target_id[id], -1, "slot %d target should default to -1" % id, failures)

func _test_allocate_until_full(failures: Array[String]) -> void:
	var store := EntityStore.new(2)
	var first := store.allocate()
	var second := store.allocate()
	var third := store.allocate()
	_assert_eq(first, 0, "first allocated id should be 0", failures)
	_assert_eq(second, 1, "second allocated id should be 1", failures)
	_assert_eq(third, -1, "allocate should return -1 when full", failures)
	_assert_eq(store.active_count, 2, "active_count should stop at capacity", failures)
	_assert_eq(store.free_count(), 0, "free_count should be 0 when full", failures)
	_assert_true(store.alive[first], "first allocated slot should be alive", failures)
	_assert_true(store.alive[second], "second allocated slot should be alive", failures)

func _test_recycle_freed_id(failures: Array[String]) -> void:
	var store := EntityStore.new(3)
	var first := store.allocate()
	var second := store.allocate()
	var third := store.allocate()
	store.release(second)
	var recycled := store.allocate()
	_assert_eq(recycled, second, "released id should be reused first", failures)
	_assert_eq(store.active_count, 3, "active_count should return to full after reallocation", failures)
	_assert_true(store.alive[first], "first slot should remain alive", failures)
	_assert_true(store.alive[recycled], "recycled slot should be alive again", failures)
	_assert_true(store.alive[third], "third slot should remain alive", failures)

func _test_reset_slot_defaults(failures: Array[String]) -> void:
	var store := EntityStore.new(1)
	var id := store.allocate()
	store.position_x[id] = 13.5
	store.position_y[id] = -7.25
	store.velocity_x[id] = 2.0
	store.velocity_y[id] = 3.0
	store.team_id[id] = 9
	store.unit_type_id[id] = 5
	store.hp[id] = 10.0
	store.max_hp[id] = 20.0
	store.attack_range_sq[id] = 16.0
	store.attack_cd[id] = 1.5
	store.attack_interval[id] = 0.75
	store.move_speed[id] = 4.0
	store.radius[id] = 1.25
	store.target_id[id] = 7
	store.state[id] = 3
	store.bucket_id[id] = 2
	store.grid_id[id] = 99
	store.release(id)
	_assert_false(store.alive[id], "released slot should be dead", failures)
	_assert_eq(store.position_x[id], 0.0, "position_x should reset", failures)
	_assert_eq(store.position_y[id], 0.0, "position_y should reset", failures)
	_assert_eq(store.velocity_x[id], 0.0, "velocity_x should reset", failures)
	_assert_eq(store.velocity_y[id], 0.0, "velocity_y should reset", failures)
	_assert_eq(store.team_id[id], -1, "team_id should reset", failures)
	_assert_eq(store.unit_type_id[id], -1, "unit_type_id should reset", failures)
	_assert_eq(store.hp[id], 0.0, "hp should reset", failures)
	_assert_eq(store.max_hp[id], 0.0, "max_hp should reset", failures)
	_assert_eq(store.attack_range_sq[id], 0.0, "attack_range_sq should reset", failures)
	_assert_eq(store.attack_cd[id], 0.0, "attack_cd should reset", failures)
	_assert_eq(store.attack_interval[id], 0.0, "attack_interval should reset", failures)
	_assert_eq(store.move_speed[id], 0.0, "move_speed should reset", failures)
	_assert_eq(store.radius[id], 0.0, "radius should reset", failures)
	_assert_eq(store.target_id[id], -1, "target_id should reset", failures)
	_assert_eq(store.state[id], 0, "state should reset", failures)
	_assert_eq(store.bucket_id[id], -1, "bucket_id should reset", failures)
	_assert_eq(store.grid_id[id], -1, "grid_id should reset", failures)
	_assert_eq(store.active_count, 0, "active_count should decrement after release", failures)
	_assert_eq(store.free_count(), 1, "free_count should recover after release", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
