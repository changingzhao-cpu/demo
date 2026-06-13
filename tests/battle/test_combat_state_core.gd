extends RefCounted

const CombatStateCore = preload("res://scripts/battle/combat_state_core.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_contact_must_precede_attack(failures)
	_test_attack_lock_prevents_immediate_recover(failures)
	return failures

func _test_contact_must_precede_attack(failures: Array[String]) -> void:
	var core = CombatStateCore.new()
	var truth: Dictionary = core.build_default_truth(3)
	var next_truth: Dictionary = core.step_state(truth, {
		"has_target": true,
		"is_in_contact": true,
		"slot_assignment": 0,
		"attack_permission": false,
		"time": 0.2
	})
	_assert_eq(int(next_truth.get("intent_state", -1)), Types.INTENT_STATE_CONTACT, "core should enter CONTACT before ATTACK", failures)

func _test_attack_lock_prevents_immediate_recover(failures: Array[String]) -> void:
	var core = CombatStateCore.new()
	var truth := {
		"entity_id": 3,
		"intent_state": Types.INTENT_STATE_ATTACK,
		"target_id": 9,
		"contact_slot": 1,
		"attack_permission": true,
		"state_lock_until": 1.0
	}
	var next_truth: Dictionary = core.step_state(truth, {
		"has_target": true,
		"is_in_contact": false,
		"slot_assignment": 1,
		"attack_permission": false,
		"time": 0.6
	})
	_assert_eq(int(next_truth.get("intent_state", -1)), Types.INTENT_STATE_ATTACK, "core should keep ATTACK until lock window ends", failures)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
