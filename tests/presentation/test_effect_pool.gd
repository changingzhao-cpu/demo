extends RefCounted

const EffectPoolScript = preload("res://scripts/presentation/effect_pool.gd")

class DummyEffect:
	extends RefCounted
	var active: bool = false
	var play_count: int = 0
	var reset_count: int = 0
	var last_key: String = ""

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_play_effect_borrows_and_marks_active(failures)
	_test_release_effect_returns_item_to_pool(failures)
	_test_capacity_limit_returns_null_when_exhausted(failures)
	return failures

func _test_play_effect_borrows_and_marks_active(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(
		func() -> DummyEffect:
			return DummyEffect.new(),
		2
	)
	var effect: DummyEffect = pool.play_effect("hit")
	_assert_true(effect != null, "play_effect should return an effect when capacity is available", failures)
	_assert_true(effect.active, "play_effect should mark the borrowed effect active", failures)
	_assert_eq(effect.play_count, 1, "play_effect should record a play event", failures)
	_assert_eq(effect.last_key, "hit", "play_effect should store the requested effect key", failures)

func _test_release_effect_returns_item_to_pool(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(
		func() -> DummyEffect:
			return DummyEffect.new(),
		1
	)
	var first: DummyEffect = pool.play_effect("slash")
	pool.release_effect(first)
	var reused: DummyEffect = pool.play_effect("slash")
	_assert_eq(reused, first, "release_effect should return the effect to the pool", failures)
	_assert_eq(reused.reset_count, 1, "release_effect should reset the effect once", failures)
	_assert_eq(pool.available_count(), 0, "re-borrowing the only effect should exhaust availability", failures)

func _test_capacity_limit_returns_null_when_exhausted(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(
		func() -> DummyEffect:
			return DummyEffect.new(),
		1
	)
	var first: DummyEffect = pool.play_effect("fireball")
	var second: DummyEffect = pool.play_effect("fireball")
	_assert_true(first != null, "first play_effect call should succeed", failures)
	_assert_eq(second, null, "play_effect should return null when the pool is exhausted", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
