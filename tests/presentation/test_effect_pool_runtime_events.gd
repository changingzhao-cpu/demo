extends RefCounted

const EffectPoolScript = preload("res://scripts/presentation/effect_pool.gd")

class DummyEffect:
	extends RefCounted
	var active: bool = false
	var last_key: String = ""
	var play_count: int = 0
	var reset_count: int = 0
	var ttl: float = 0.0
	var team: String = ""

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_enemy_death_event_spawns_temporary_corpse(failures)
	_test_ally_death_event_spawns_persistent_corpse(failures)
	_test_enemy_corpse_expires_after_tick(failures)
	return failures

func _test_enemy_death_event_spawns_temporary_corpse(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect, 2, 2)
	_assert_true(pool.has_method("on_enemy_unit_died"), "effect pool should expose on_enemy_unit_died", failures)
	if not pool.has_method("on_enemy_unit_died"):
		return
	var corpse = pool.call("on_enemy_unit_died", 1.25)
	_assert_true(corpse != null, "on_enemy_unit_died should spawn a corpse effect", failures)
	if corpse != null:
		_assert_eq(corpse.team, "enemy", "enemy death event should mark corpse as enemy", failures)
		_assert_eq(corpse.ttl, 1.25, "enemy death event should set corpse ttl", failures)

func _test_ally_death_event_spawns_persistent_corpse(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect, 2, 2)
	_assert_true(pool.has_method("on_ally_unit_died"), "effect pool should expose on_ally_unit_died", failures)
	if not pool.has_method("on_ally_unit_died"):
		return
	var corpse = pool.call("on_ally_unit_died")
	_assert_true(corpse != null, "on_ally_unit_died should spawn a corpse effect", failures)
	if corpse != null:
		_assert_eq(corpse.team, "ally", "ally death event should mark corpse as ally", failures)
		_assert_eq(corpse.ttl, -1.0, "ally death event should keep corpse persistent", failures)

func _test_enemy_corpse_expires_after_tick(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect, 1, 1)
	if not pool.has_method("on_enemy_unit_died"):
		failures.append("effect pool should expose on_enemy_unit_died before ticking corpse expiry")
		return
	var corpse = pool.call("on_enemy_unit_died", 0.2)
	pool.tick_corpses(0.25)
	_assert_false(corpse.active, "expired enemy corpse should be released back to the pool", failures)

func _make_effect() -> DummyEffect:
	return DummyEffect.new()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
