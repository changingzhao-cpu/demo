extends RefCounted

const ContactResolver = preload("res://scripts/battle/contact_resolver.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_contact_resolver_returns_anchor_and_slot(failures)
	_test_contact_resolver_flags_reposition_when_slot_missing(failures)
	return failures

func _test_contact_resolver_returns_anchor_and_slot(failures: Array[String]) -> void:
	var resolver = ContactResolver.new()
	var result: Dictionary = resolver.resolve({
		"entity_id": 1,
		"origin": Vector2(-0.9, 0.0),
		"target_id": 2,
		"target_position": Vector2.ZERO,
		"occupied_slots": [],
		"contact_distance": 1.2
	})
	_assert_true(bool(result.get("is_in_contact", false)), "contact resolver should mark in-contact pair", failures)
	_assert_eq(int(result.get("slot_assignment", -1)), 0, "contact resolver should assign first free slot", failures)
	_assert_true(result.get("contact_anchor", null) is Vector2, "contact resolver should output contact anchor", failures)

func _test_contact_resolver_flags_reposition_when_slot_missing(failures: Array[String]) -> void:
	var resolver = ContactResolver.new()
	var result: Dictionary = resolver.resolve({
		"entity_id": 1,
		"origin": Vector2(-1.0, 0.0),
		"target_id": 2,
		"target_position": Vector2.ZERO,
		"occupied_slots": [0, 1, 2],
		"contact_distance": 1.2
	})
	_assert_true(bool(result.get("should_reposition", false)), "contact resolver should ask reposition when all slots are occupied", failures)
	_assert_eq(int(result.get("slot_assignment", -1)), -1, "contact resolver should not fabricate slot assignment", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
