extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const PushResolverScript = preload("res://scripts/battle/push_resolver.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_overlap_resolves_symmetrically(failures)
	_test_non_overlap_stays_unchanged(failures)
	_test_zero_distance_is_stable(failures)
	return failures

func _test_overlap_resolves_symmetrically(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = PushResolverScript.new()
	var a: int = store.allocate()
	var b: int = store.allocate()
	store.position_x[a] = 0.0
	store.position_y[a] = 0.0
	store.position_x[b] = 1.0
	store.position_y[b] = 0.0
	store.radius[a] = 1.0
	store.radius[b] = 1.0

	resolver.call("resolve_pair", store, a, b)

	_assert_float_eq(store.position_x[a], -0.5, "left entity should be pushed left by half overlap", failures)
	_assert_float_eq(store.position_x[b], 1.5, "right entity should be pushed right by half overlap", failures)
	_assert_float_eq(store.position_y[a], 0.0, "y for left entity should stay unchanged", failures)
	_assert_float_eq(store.position_y[b], 0.0, "y for right entity should stay unchanged", failures)

func _test_non_overlap_stays_unchanged(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = PushResolverScript.new()
	var a: int = store.allocate()
	var b: int = store.allocate()
	store.position_x[a] = 0.0
	store.position_y[a] = 0.0
	store.position_x[b] = 5.0
	store.position_y[b] = 0.0
	store.radius[a] = 1.0
	store.radius[b] = 1.0

	resolver.call("resolve_pair", store, a, b)

	_assert_float_eq(store.position_x[a], 0.0, "non-overlap should not move entity a", failures)
	_assert_float_eq(store.position_x[b], 5.0, "non-overlap should not move entity b", failures)

func _test_zero_distance_is_stable(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = PushResolverScript.new()
	var a: int = store.allocate()
	var b: int = store.allocate()
	store.position_x[a] = 3.0
	store.position_y[a] = 7.0
	store.position_x[b] = 3.0
	store.position_y[b] = 7.0
	store.radius[a] = 1.0
	store.radius[b] = 1.0

	resolver.call("resolve_pair", store, a, b)

	_assert_true(is_finite(store.position_x[a]), "zero-distance resolution should keep finite x for entity a", failures)
	_assert_true(is_finite(store.position_x[b]), "zero-distance resolution should keep finite x for entity b", failures)
	_assert_true(is_finite(store.position_y[a]), "zero-distance resolution should keep finite y for entity a", failures)
	_assert_true(is_finite(store.position_y[b]), "zero-distance resolution should keep finite y for entity b", failures)
	var dx: float = store.position_x[b] - store.position_x[a]
	var dy: float = store.position_y[b] - store.position_y[a]
	var distance_sq: float = dx * dx + dy * dy
	_assert_true(distance_sq > 0.0, "zero-distance resolution should separate the pair", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_float_eq(actual: float, expected: float, message: String, failures: Array[String], epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
