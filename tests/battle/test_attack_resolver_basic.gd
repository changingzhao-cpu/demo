extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const AttackResolverScript = preload("res://scripts/battle/attack_resolver.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_melee_hit_applies_damage_and_cooldown(failures)
	_test_cooldown_blocks_repeated_attack(failures)
	_test_death_marks_target_dead_and_clears_target(failures)
	return failures

func _test_melee_hit_applies_damage_and_cooldown(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = AttackResolverScript.new()
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	store.hp[target] = 10.0
	store.max_hp[target] = 10.0
	store.attack_interval[attacker] = 1.25
	store.attack_cd[attacker] = 0.0
	store.target_id[attacker] = target

	var hit: bool = resolver.resolve_basic_attack(store, attacker, target, 3.5)
	_assert_true(hit, "attack should resolve when cooldown is ready", failures)
	_assert_float_eq(store.hp[target], 6.5, "damage should reduce target hp", failures)
	_assert_float_eq(store.attack_cd[attacker], 1.25, "attack should set cooldown to attack_interval", failures)
	_assert_true(store.alive[target], "target should remain alive after non-lethal hit", failures)

func _test_cooldown_blocks_repeated_attack(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = AttackResolverScript.new()
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	store.hp[target] = 8.0
	store.max_hp[target] = 8.0
	store.attack_interval[attacker] = 0.8
	store.attack_cd[attacker] = 0.2
	store.target_id[attacker] = target

	var hit: bool = resolver.resolve_basic_attack(store, attacker, target, 2.0)
	_assert_false(hit, "attack should not resolve while cooldown is active", failures)
	_assert_float_eq(store.hp[target], 8.0, "cooldown-blocked attack should not change hp", failures)
	_assert_float_eq(store.attack_cd[attacker], 0.2, "cooldown-blocked attack should keep cooldown", failures)

func _test_death_marks_target_dead_and_clears_target(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = AttackResolverScript.new()
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	store.hp[target] = 4.0
	store.max_hp[target] = 4.0
	store.attack_interval[attacker] = 0.5
	store.attack_cd[attacker] = 0.0
	store.target_id[attacker] = target

	var hit: bool = resolver.resolve_basic_attack(store, attacker, target, 6.0)
	_assert_true(hit, "lethal attack should resolve", failures)
	_assert_float_eq(store.hp[target], 0.0, "lethal attack should clamp hp to zero", failures)
	_assert_false(store.alive[target], "target should be marked dead after lethal attack", failures)
	_assert_eq(store.target_id[attacker], -1, "attacker target should clear after lethal attack", failures)
	_assert_eq(store.target_id[target], -1, "dead target target_id should reset", failures)
	_assert_eq(store.team_id[target], -1, "dead target should reset slot metadata", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])

func _assert_float_eq(actual: float, expected: float, message: String, failures: Array[String], epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
