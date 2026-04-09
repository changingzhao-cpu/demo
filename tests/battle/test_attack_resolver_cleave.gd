extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const AttackResolverScript = preload("res://scripts/battle/attack_resolver.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_cleave_hits_primary_and_limited_secondary_targets(failures)
	_test_cleave_respects_max_secondary_target_count(failures)
	_test_cleave_skips_when_chance_is_zero(failures)
	return failures

func _test_cleave_hits_primary_and_limited_secondary_targets(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var resolver = AttackResolverScript.new()
	var attacker: int = store.allocate()
	var primary: int = store.allocate()
	var splash_a: int = store.allocate()
	var splash_b: int = store.allocate()
	_store_attack_ready(store, attacker, primary)
	_store_target(store, primary, 1, 10.0)
	_store_target(store, splash_a, 1, 10.0)
	_store_target(store, splash_b, 1, 10.0)

	var result: Dictionary = resolver.resolve_cleave_attack(store, attacker, primary, 3.0, [splash_a, splash_b], 1.0, 2, 0.5)
	_assert_true(bool(result.get("hit", false)), "cleave attack should resolve as a hit", failures)
	_assert_eq(int(result.get("secondary_hits", 0)), 2, "cleave should report two secondary hits", failures)
	_assert_float_eq(store.hp[primary], 7.0, "primary target should take full damage", failures)
	_assert_float_eq(store.hp[splash_a], 8.5, "secondary target A should take scaled cleave damage", failures)
	_assert_float_eq(store.hp[splash_b], 8.5, "secondary target B should take scaled cleave damage", failures)

func _test_cleave_respects_max_secondary_target_count(failures: Array[String]) -> void:
	var store = EntityStore.new(5)
	var resolver = AttackResolverScript.new()
	var attacker: int = store.allocate()
	var primary: int = store.allocate()
	var splash_a: int = store.allocate()
	var splash_b: int = store.allocate()
	var splash_c: int = store.allocate()
	_store_attack_ready(store, attacker, primary)
	_store_target(store, primary, 1, 12.0)
	_store_target(store, splash_a, 1, 12.0)
	_store_target(store, splash_b, 1, 12.0)
	_store_target(store, splash_c, 1, 12.0)

	var result: Dictionary = resolver.resolve_cleave_attack(store, attacker, primary, 4.0, [splash_a, splash_b, splash_c], 1.0, 1, 0.25)
	_assert_eq(int(result.get("secondary_hits", 0)), 1, "cleave should stop at the configured secondary target limit", failures)
	_assert_float_eq(store.hp[splash_a], 11.0, "first secondary target should take cleave damage", failures)
	_assert_float_eq(store.hp[splash_b], 12.0, "extra secondary targets should remain untouched", failures)
	_assert_float_eq(store.hp[splash_c], 12.0, "extra secondary targets should remain untouched", failures)

func _test_cleave_skips_when_chance_is_zero(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var resolver = AttackResolverScript.new()
	var attacker: int = store.allocate()
	var primary: int = store.allocate()
	var splash: int = store.allocate()
	_store_attack_ready(store, attacker, primary)
	_store_target(store, primary, 1, 9.0)
	_store_target(store, splash, 1, 9.0)

	var result: Dictionary = resolver.resolve_cleave_attack(store, attacker, primary, 2.0, [splash], 0.0, 2, 0.5)
	_assert_true(bool(result.get("hit", false)), "primary hit should still resolve when cleave chance is zero", failures)
	_assert_eq(int(result.get("secondary_hits", 0)), 0, "cleave chance zero should produce no secondary hits", failures)
	_assert_float_eq(store.hp[splash], 9.0, "secondary target should remain untouched when cleave does not trigger", failures)

func _store_attack_ready(store, attacker: int, target: int) -> void:
	store.attack_interval[attacker] = 0.75
	store.attack_cd[attacker] = 0.0
	store.target_id[attacker] = target
	store.alive[attacker] = 1
	store.team_id[attacker] = 0

func _store_target(store, entity_id: int, team_id: int, hp: float) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = team_id
	store.hp[entity_id] = hp
	store.max_hp[entity_id] = hp

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])

func _assert_float_eq(actual: float, expected: float, message: String, failures: Array[String], epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
