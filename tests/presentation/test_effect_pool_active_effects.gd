extends RefCounted

const EffectPoolScript = preload("res://scripts/presentation/effect_pool.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_active_effects_exposes_current_enemy_and_ally_feedback(failures)
	return failures

func _test_active_effects_exposes_current_enemy_and_ally_feedback(failures: Array[String]) -> void:
	var pool = EffectPoolScript.new(_make_effect_record, 2, 4)
	pool.call("spawn_visual_event", "enemy_corpse", Vector2(3.0, 1.0), "enemy", 1.0)
	pool.call("spawn_visual_event", "ally_corpse", Vector2(-2.0, -1.5), "ally", 1.0)
	_assert_true(pool.has_method("get_active_effects"), "effect pool should expose a getter for active effects", failures)
	if not pool.has_method("get_active_effects"):
		return
	var active_effects: Array = pool.call("get_active_effects")
	_assert_eq(active_effects.size(), 2, "active effect getter should return both ally and enemy effects", failures)
	if active_effects.size() >= 2:
		_assert_true(str(active_effects[0].team) != "" or str(active_effects[1].team) != "", "active effects should preserve team metadata", failures)

func _make_effect_record():
	return {
		"active": false,
		"reset_count": 0,
		"play_count": 0,
		"last_key": "",
		"ttl": 0.0,
		"team": "",
		"position": Vector2.ZERO,
		"tint": Color.WHITE,
		"scale": Vector2.ONE,
		"visual_kind": "",
		"persistent": false
	}

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
