extends RefCounted

const ObjectPool = preload("res://scripts/battle/object_pool.gd")

class DummyPooled:
	extends RefCounted
	var id: int = -1
	var borrow_count: int = 0
	var reset_count: int = 0

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_prewarm_and_capacity(failures)
	_test_borrow_and_return_reuse(failures)
	_test_duplicate_return_guard(failures)
	return failures

func _test_prewarm_and_capacity(failures: Array[String]) -> void:
	var sequence := 0
	var pool = ObjectPool.new(
		func() -> DummyPooled:
			var item := DummyPooled.new()
			item.id = sequence
			sequence += 1
			return item,
		2,
		func(item: DummyPooled) -> void:
			item.reset_count += 1,
		func(item: DummyPooled) -> void:
			item.borrow_count += 1
	)

	_assert_eq(pool.capacity, 2, "pool capacity should match prewarm size", failures)
	_assert_eq(pool.available_count(), 2, "prewarmed objects should start available", failures)
	var first: DummyPooled = pool.borrow()
	var second: DummyPooled = pool.borrow()
	var third: DummyPooled = pool.borrow()
	_assert_true(first != null, "first borrow should succeed", failures)
	_assert_true(second != null, "second borrow should succeed", failures)
	_assert_eq(third, null, "borrow should return null when pool is exhausted", failures)
	_assert_eq(first.borrow_count, 1, "borrow hook should run for first item", failures)
	_assert_eq(second.borrow_count, 1, "borrow hook should run for second item", failures)
	_assert_eq(pool.available_count(), 0, "available_count should drop to zero when exhausted", failures)

func _test_borrow_and_return_reuse(failures: Array[String]) -> void:
	var next_id := 10
	var pool = ObjectPool.new(
		func() -> DummyPooled:
			var item := DummyPooled.new()
			item.id = next_id
			next_id += 1
			return item,
		1,
		func(item: DummyPooled) -> void:
			item.reset_count += 1,
		func(item: DummyPooled) -> void:
			item.borrow_count += 1
	)

	var first: DummyPooled = pool.borrow()
	pool.release(first)
	var reused: DummyPooled = pool.borrow()
	_assert_eq(reused, first, "returned object should be reused", failures)
	_assert_eq(reused.reset_count, 1, "release hook should run once before reuse", failures)
	_assert_eq(reused.borrow_count, 2, "borrow hook should run on every checkout", failures)

func _test_duplicate_return_guard(failures: Array[String]) -> void:
	var pool = ObjectPool.new(
		func() -> DummyPooled:
			return DummyPooled.new(),
		1,
		func(item: DummyPooled) -> void:
			item.reset_count += 1
	)

	var item: DummyPooled = pool.borrow()
	pool.release(item)
	pool.release(item)
	_assert_eq(pool.available_count(), 1, "duplicate release should not duplicate pool entries", failures)
	_assert_eq(item.reset_count, 1, "duplicate release should not run reset twice", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
