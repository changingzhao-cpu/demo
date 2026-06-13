extends RefCounted

const BattleProjection = preload("res://scripts/battle/battle_projection.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_projection_returns_truth_only_payload(failures)
	return failures

func _test_projection_returns_truth_only_payload(failures: Array[String]) -> void:
	var projection = BattleProjection.new()
	var payload: Dictionary = projection.build_authoritative_contract([
		{"entity_id": 1, "intent_state": 3, "target_id": 2, "position": Vector2.ZERO, "velocity": Vector2.ZERO}
	])
	_assert_eq(str(payload.get("ticksource", "")), "battle_simulation_v3", "projection should report v3 tick source", failures)
	_assert_true(payload.has("entities"), "projection should include entities", failures)
	_assert_true(not payload.has("combat_events"), "projection should not invent extra business fields", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
