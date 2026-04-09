extends RefCounted

const EffectPoolScript = preload("res://scripts/presentation/effect_pool.gd")

class DummyEffect:
	extends RefCounted
	var active: bool = false
	var play_count: int = 0
	var reset_count: int = 0
	var last_key: String = ""
	var ttl: float = 0.0
	var team: String = ""

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_enemy_corpse_expires_after_ttl(failures)
	_test_ally_corpse_limit_replaces_oldest(failures)
	_test_enemy_cleanup_returns_effect_to_pool(failures)
	return failures

func _test_enemy_corpse_expires_after_ttl(failures: Array[String]) -> void:
	var pool = _make_pool(3)
	var corpse: DummyEffect = pool.spawn_enemy_corpse(0.5)
	pool.tick_corpses(0.25)
	_assert_true(corpse.active, "enemy corpse should remain active before ttl expires", failures)
	pool.tick_corpses(0.30)
	_assert_false(corpse.active, "enemy corpse should deactivate after ttl expires", failures)

func _test_ally_corpse_limit_replaces_oldest(failures: Array[String]) -> void:
	var pool = _make_pool(4, 2)
	var first: DummyEffect = pool.spawn_ally_corpse()
	var second: DummyEffect = pool.spawn_ally_corpse()
	var third: DummyEffect = pool.spawn_ally_corpse()
	_assert_false(first.active, "oldest ally corpse should be replaced when the limit is exceeded", failures)
	_assert_true(second.active, "newer ally corpse should remain active", failures)
	_assert_true(third.active, "latest ally corpse should remain active", failures)

func _test_enemy_cleanup_returns_effect_to_pool(failures: Array[String]) -> void:
	var pool = _make_pool(2)
	var corpse: DummyEffect = pool.spawn_enemy_corpse(0.2)
	pool.tick_corpses(0.25)
	var reused: DummyEffect = pool.play_effect("hit")
	_assert_eq(reused, corpse, "expired enemy corpse should return to the shared pool", failures)

func _make_pool(capacity: int, ally_limit: int = 8):
	return EffectPoolScript.new(
		func() -> DummyEffect:
			return DummyEffect.new(),
		capacity,
		ally_limit
	)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
