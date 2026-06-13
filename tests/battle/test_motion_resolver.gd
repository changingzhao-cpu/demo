extends RefCounted

const MotionResolver = preload("res://scripts/battle/motion_resolver.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_attack_state_does_not_move(failures)
	_test_approach_moves_toward_anchor(failures)
	return failures

func _test_attack_state_does_not_move(failures: Array[String]) -> void:
	var resolver = MotionResolver.new()
	var result: Dictionary = resolver.resolve({
		"intent_state": Types.INTENT_STATE_ATTACK,
		"position": Vector2(-1.0, 0.0),
		"contact_anchor": Vector2.ZERO,
		"move_speed": 6.0,
		"delta": 0.1
	})
	_assert_eq(result.get("next_position", Vector2.ZERO), Vector2(-1.0, 0.0), "motion resolver should freeze ATTACK position", failures)
	_assert_eq(result.get("velocity", Vector2.ONE), Vector2.ZERO, "motion resolver should zero ATTACK velocity", failures)

func _test_approach_moves_toward_anchor(failures: Array[String]) -> void:
	var resolver = MotionResolver.new()
	var result: Dictionary = resolver.resolve({
		"intent_state": Types.INTENT_STATE_APPROACH,
		"position": Vector2(-3.0, 0.0),
		"contact_anchor": Vector2(-1.0, 0.0),
		"move_speed": 6.0,
		"delta": 0.1
	})
	_assert_true(result.get("next_position", Vector2.ZERO).x > -3.0, "motion resolver should move APPROACH toward anchor", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
