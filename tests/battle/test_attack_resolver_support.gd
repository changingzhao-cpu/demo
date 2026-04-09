extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const AttackResolverScript = preload("res://scripts/battle/attack_resolver.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_support_pulse_heals_limited_allies(failures)
	_test_support_pulse_clamps_heal_to_max_hp(failures)
	_test_support_pulse_respects_cooldown(failures)
	return failures

func _test_support_pulse_heals_limited_allies(failures: Array[String]) -> void:
	var store = EntityStore.new(4)
	var resolver = AttackResolverScript.new()
	var support: int = store.allocate()
	var ally_a: int = store.allocate()
	var ally_b: int = store.allocate()
	var enemy: int = store.allocate()
	_prepare_support(store, support, 0.8)
	_prepare_unit(store, ally_a, 0, 10.0, 5.0)
	_prepare_unit(store, ally_b, 0, 10.0, 4.0)
	_prepare_unit(store, enemy, 1, 10.0, 2.0)

	var result: Dictionary = resolver.resolve_support_pulse(store, support, [ally_a, ally_b, enemy], 3.0, 2)
	_assert_true(bool(result.get("triggered", false)), "support pulse should trigger when cooldown is ready", failures)
	_assert_eq(int(result.get("affected", 0)), 2, "support pulse should affect up to the ally limit", failures)
	_assert_float_eq(store.hp[ally_a], 8.0, "support pulse should heal ally A", failures)
	_assert_float_eq(store.hp[ally_b], 7.0, "support pulse should heal ally B", failures)
	_assert_float_eq(store.hp[enemy], 2.0, "support pulse should not heal enemies", failures)
	_assert_float_eq(store.attack_cd[support], 0.8, "support pulse should set cooldown to attack_interval", failures)

func _test_support_pulse_clamps_heal_to_max_hp(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = AttackResolverScript.new()
	var support: int = store.allocate()
	var ally: int = store.allocate()
	_prepare_support(store, support, 1.1)
	_prepare_unit(store, ally, 0, 10.0, 9.5)

	var result: Dictionary = resolver.resolve_support_pulse(store, support, [ally], 3.0, 1)
	_assert_true(bool(result.get("triggered", false)), "support pulse should trigger for clamped heal case", failures)
	_assert_float_eq(store.hp[ally], 10.0, "support pulse should clamp healed hp to max_hp", failures)

func _test_support_pulse_respects_cooldown(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var resolver = AttackResolverScript.new()
	var support: int = store.allocate()
	var ally: int = store.allocate()
	_prepare_support(store, support, 0.9)
	store.attack_cd[support] = 0.2
	_prepare_unit(store, ally, 0, 10.0, 5.0)

	var result: Dictionary = resolver.resolve_support_pulse(store, support, [ally], 3.0, 1)
	_assert_false(bool(result.get("triggered", false)), "support pulse should not trigger while cooldown is active", failures)
	_assert_eq(int(result.get("affected", 0)), 0, "cooldown-blocked support pulse should affect nobody", failures)
	_assert_float_eq(store.hp[ally], 5.0, "cooldown-blocked support pulse should not change hp", failures)

func _prepare_support(store, entity_id: int, interval: float) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = 0
	store.attack_interval[entity_id] = interval
	store.attack_cd[entity_id] = 0.0

func _prepare_unit(store, entity_id: int, team_id: int, max_hp: float, hp: float) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = team_id
	store.max_hp[entity_id] = max_hp
	store.hp[entity_id] = hp

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
