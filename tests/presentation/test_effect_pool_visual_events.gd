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
	var position := Vector2.ZERO
	var tint := Color.WHITE
	var scale := Vector2.ONE
	var visual_kind: String = ""
	var persistent: bool = false

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_enemy_visual_event_sets_runtime_visual_payload(failures)
	_test_ally_visual_event_sets_runtime_visual_payload(failures)
	_test_releasing_visual_effect_resets_visual_payload(failures)
	return failures

func _test_enemy_visual_event_sets_runtime_visual_payload(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect, 2, 2)
	_assert_true(pool.has_method("spawn_visual_event"), "effect pool should expose spawn_visual_event", failures)
	if not pool.has_method("spawn_visual_event"):
		return
	var effect = pool.call("spawn_visual_event", "enemy_corpse", Vector2(12.0, -4.0), "enemy", 0.6)
	_assert_true(effect != null, "spawn_visual_event should create an effect for enemy corpses", failures)
	if effect != null:
		_assert_eq(effect.position, Vector2(12.0, -4.0), "enemy visual event should keep its world position", failures)
		_assert_eq(effect.team, "enemy", "enemy visual event should keep enemy team metadata", failures)
		_assert_eq(effect.visual_kind, "enemy_corpse", "enemy visual event should expose its visual kind", failures)
		_assert_eq(effect.tint, Color(0.95, 0.4, 0.4, 0.45), "enemy visual event should use the enemy corpse tint", failures)
		_assert_eq(effect.scale, Vector2(0.85, 0.85), "enemy visual event should use the short-lived corpse scale", failures)
		_assert_false(effect.persistent, "enemy corpse visual event should not be persistent", failures)

func _test_ally_visual_event_sets_runtime_visual_payload(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect, 2, 2)
	var effect = pool.call("spawn_visual_event", "ally_corpse", Vector2(-7.5, 3.0), "ally", 0.2)
	_assert_true(effect != null, "spawn_visual_event should create an effect for ally corpses", failures)
	if effect != null:
		_assert_eq(effect.team, "ally", "ally visual event should keep ally team metadata", failures)
		_assert_eq(effect.visual_kind, "ally_corpse", "ally visual event should expose its visual kind", failures)
		_assert_eq(effect.tint, Color(0.45, 0.85, 1.0, 0.4), "ally visual event may still use ally corpse tint while remaining short-lived", failures)
		_assert_eq(effect.scale, Vector2(1.1, 1.1), "ally visual event may still use ally corpse scale while remaining short-lived", failures)
		_assert_false(effect.persistent, "ally corpse visual event should not be persistent when used as a short-lived visual event", failures)
		_assert_true(effect.ttl > 0.0, "ally visual event should keep a positive ttl so it can be released", failures)

func _test_releasing_visual_effect_resets_visual_payload(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect, 1, 1)
	var effect = pool.call("spawn_visual_event", "enemy_corpse", Vector2(1.0, 2.0), "enemy", 0.3)
	pool.release_effect(effect)
	_assert_eq(effect.position, Vector2.ZERO, "release_effect should reset visual event position", failures)
	_assert_eq(effect.tint, Color.WHITE, "release_effect should reset visual event tint", failures)
	_assert_eq(effect.visual_kind, "", "release_effect should clear visual event kind", failures)
	_assert_false(effect.persistent, "release_effect should clear visual event persistence", failures)

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
