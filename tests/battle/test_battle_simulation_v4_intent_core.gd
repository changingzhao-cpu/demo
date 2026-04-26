extends RefCounted

const EntityStore = preload("res://scripts/battle/entity_store.gd")
const SpatialGrid = preload("res://scripts/battle/spatial_grid.gd")
const BattleSimulationV4 = preload("res://scripts/battle/battle_simulation_v4.gd")
const SlotArbitratorV4 = preload("res://scripts/battle/slot_arbitrator_v4.gd")
const UnitIntent = preload("res://scripts/battle/unit_intent.gd")
const Types = preload("res://scripts/battle/battle_simulation_v3_types.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_single_unit_gets_success_assignment(failures)
	_test_conflicting_claims_produce_unique_assignment(failures)
	_test_waiting_assignment_soft_holds_without_chase_velocity(failures)
	_test_assignment_survives_into_next_tick_snapshot(failures)
	_test_attack_holder_keeps_slot_against_new_claimer(failures)
	_test_success_assignment_moves_toward_global_anchor(failures)
	_test_attack_holder_priority_beats_nearer_new_claimer(failures)
	_test_conflict_report_exposes_intents_and_assignments(failures)
	_test_conflict_report_exposes_contention_metrics(failures)
	_test_non_conflict_report_has_zero_contention(failures)
	_test_contention_report_counts_multiple_contested_groups(failures)
	_test_contention_report_handles_empty_inputs(failures)
	_test_assignment_report_exposes_global_anchor(failures)
	_test_assignment_report_exposes_waiting_status(failures)
	_test_assignment_report_exposes_waiting_slot_index(failures)
	_test_assignment_report_exposes_success_slot_index(failures)
	_test_assignment_report_exposes_success_status(failures)
	_test_assignment_report_exposes_waiting_target_id(failures)
	_test_assignment_report_exposes_success_target_id(failures)
	_test_assignment_report_exposes_waiting_global_anchor(failures)
	_test_assignment_report_exposes_success_global_anchor(failures)
	_test_intent_report_exposes_current_pos(failures)
	_test_intent_report_exposes_desired_slot_index(failures)
	_test_intent_report_exposes_target_id(failures)
	_test_intent_report_exposes_entity_id(failures)
	_test_intent_report_exposes_priority_weight(failures)
	_test_intent_report_counts_attacker_and_target_entries(failures)
	_test_attack_holder_intent_report_exposes_boosted_priority_weight(failures)
	_test_intent_report_hides_reverse_side_entries(failures)
	_test_assignment_report_exposes_exact_conflict_pair(failures)
	_test_contention_metrics_align_with_serialized_reports(failures)
	_test_assignment_report_only_serializes_attacker_side_in_duel(failures)
	_test_assignment_report_only_serializes_attacker_side_in_holder_conflict(failures)
	return failures

func _test_success_assignment_moves_toward_global_anchor(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-4.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var before := Vector2(store.position_x[0], store.position_y[0])
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[0], store.position_y[0])
	_assert_true(after.distance_to(Vector2.ZERO) < before.distance_to(Vector2.ZERO), "success assignment should move the unit toward assignment.global_pos", failures)

func _test_attack_holder_priority_beats_nearer_new_claimer(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-0.5, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(store.locked_slot_index[0]), 0, "attack holder priority should beat a nearer new claimer", failures)
	_assert_eq(int(store.locked_slot_index[1]), -1, "nearer new claimer should wait when attack holder priority wins", failures)

func _test_conflict_report_exposes_intents_and_assignments(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	var attacker_intents := 0
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("target_id", -1)) == 2:
			attacker_intents += 1
	_assert_eq(int(attacker_intents), 2, "conflict report should expose both attacker intents", failures)
	_assert_true(assignments.has(0) and assignments.has(1), "conflict report should expose assignments for both attackers", failures)
	var first_assignment: Dictionary = assignments.get(0, {})
	var second_assignment: Dictionary = assignments.get(1, {})
	_assert_true(int(first_assignment.get("target_id", -1)) == 2 and int(second_assignment.get("target_id", -1)) == 2, "conflict report should expose shared target ids", failures)
	_assert_true(int(first_assignment.get("status", -1)) != int(second_assignment.get("status", -1)), "conflict report should expose success versus waiting split", failures)

func _test_conflict_report_exposes_contention_metrics(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), 2, "contention report should count attacker claims", failures)
	_assert_eq(int(contention.get("contested_groups", -1)), 1, "contention report should count one contested target-slot group", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "contention report should count one waiting assignment", failures)
	_assert_eq(float(contention.get("claim_success_rate", -1.0)), 0.5, "contention report should expose exact attacker claim success rate", failures)

func _test_non_conflict_report_has_zero_contention(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), 1, "non-conflict report should count one intent", failures)
	_assert_eq(int(contention.get("contested_groups", -1)), 0, "non-conflict report should have zero contested groups", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 0, "non-conflict report should have zero waiting assignments", failures)
	_assert_eq(float(contention.get("claim_success_rate", -1.0)), 1.0, "non-conflict report should have full claim success rate", failures)

func _test_contention_report_counts_multiple_contested_groups(failures: Array[String]) -> void:
	var intents: Array = []
	intents.append(_make_intent(0, 10, 0, 1.0))
	intents.append(_make_intent(1, 10, 0, 0.9))
	intents.append(_make_intent(2, 11, 0, 1.0))
	intents.append(_make_intent(3, 11, 0, 0.9))
	intents.append(_make_intent(4, 12, 0, 1.0))
	var assignments := SlotArbitratorV4.resolve(intents, {
		10: Vector2.ZERO,
		11: Vector2.RIGHT,
		12: Vector2.LEFT
	})
	var report: Dictionary = BattleSimulationV4.build_contention_report(intents, assignments)
	_assert_eq(int(report.get("intent_count", -1)), 5, "multi-group report should count all claims", failures)
	_assert_eq(int(report.get("contested_groups", -1)), 2, "multi-group report should count two contested groups", failures)
	_assert_eq(int(report.get("waiting_count", -1)), 2, "multi-group report should count one waiter per contested group", failures)
	_assert_eq(float(report.get("claim_success_rate", -1.0)), 3.0 / 5.0, "multi-group report should expose exact success rate across groups", failures)

func _test_contention_report_handles_empty_inputs(failures: Array[String]) -> void:
	var report: Dictionary = BattleSimulationV4.build_contention_report([], {})
	_assert_eq(int(report.get("intent_count", -1)), 0, "empty contention report should have zero intents", failures)
	_assert_eq(int(report.get("contested_groups", -1)), 0, "empty contention report should have zero contested groups", failures)
	_assert_eq(int(report.get("waiting_count", -1)), 0, "empty contention report should have zero waiting assignments", failures)
	_assert_eq(float(report.get("claim_success_rate", -1.0)), 0.0, "empty contention report should have zero claim success rate", failures)

func _test_assignment_report_exposes_global_anchor(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(assignment.get("global_pos", null), Vector2.ZERO, "assignment report should expose target global anchor", failures)

func _test_assignment_report_exposes_waiting_status(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment0: Dictionary = assignments.get(0, {})
	var assignment1: Dictionary = assignments.get(1, {})
	_assert_true(int(assignment0.get("status", -1)) == 1 or int(assignment1.get("status", -1)) == 1, "assignment report should expose waiting status on losing claimer", failures)

func _test_assignment_report_exposes_waiting_slot_index(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment0: Dictionary = assignments.get(0, {})
	var assignment1: Dictionary = assignments.get(1, {})
	var waiting_slot0 := int(assignment0.get("assigned_slot_index", -2))
	var waiting_slot1 := int(assignment1.get("assigned_slot_index", -2))
	_assert_true(waiting_slot0 == -1 or waiting_slot1 == -1, "assignment report should expose -1 slot index for waiting claimer", failures)

func _test_assignment_report_exposes_success_slot_index(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -1)), 0, "assignment report should expose resolved slot index for successful claimer", failures)

func _test_assignment_report_exposes_success_status(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(int(assignment.get("status", -1)), 0, "assignment report should expose success status for successful claimer", failures)

func _test_assignment_report_exposes_waiting_target_id(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment0: Dictionary = assignments.get(0, {})
	var assignment1: Dictionary = assignments.get(1, {})
	var waiting_target0 := int(assignment0.get("target_id", -1))
	var waiting_target1 := int(assignment1.get("target_id", -1))
	_assert_true(waiting_target0 == 2 or waiting_target1 == 2, "assignment report should preserve target id for waiting claimer", failures)

func _test_assignment_report_exposes_success_target_id(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(int(assignment.get("target_id", -1)), 1, "assignment report should preserve target id for successful claimer", failures)

func _test_assignment_report_exposes_waiting_global_anchor(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment0: Dictionary = assignments.get(0, {})
	var assignment1: Dictionary = assignments.get(1, {})
	var anchor0 = assignment0.get("global_pos", null)
	var anchor1 = assignment1.get("global_pos", null)
	_assert_true(anchor0 == Vector2.ZERO or anchor1 == Vector2.ZERO, "assignment report should preserve target global anchor for waiting claimer", failures)

func _test_assignment_report_exposes_success_global_anchor(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(assignment.get("global_pos", null), Vector2.ZERO, "assignment report should preserve target global anchor for successful claimer", failures)

func _test_intent_report_exposes_current_pos(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var start := Vector2(-2.0, 0.5)
	_prepare(store, 0, 0, start, 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var found := false
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) != 0:
			continue
		found = true
		_assert_eq(intent.get("current_pos", null), start, "intent report should expose current_pos", failures)
		break
	_assert_true(found, "intent report should include attacker intent entry", failures)

func _test_intent_report_exposes_desired_slot_index(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var found := false
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) != 0:
			continue
		found = true
		_assert_eq(int(intent.get("desired_slot_index", -1)), 0, "intent report should expose desired_slot_index", failures)
		break
	_assert_true(found, "intent report should include attacker intent entry for desired_slot_index", failures)

func _test_intent_report_exposes_target_id(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var found := false
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) != 0:
			continue
		found = true
		_assert_eq(int(intent.get("target_id", -1)), 1, "intent report should expose target_id", failures)
		break
	_assert_true(found, "intent report should include attacker intent entry for target_id", failures)

func _test_intent_report_exposes_entity_id(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	_assert_true(intents.size() > 0, "intent report should expose at least one intent entry", failures)
	var first_intent: Dictionary = intents[0]
	_assert_eq(int(first_intent.get("entity_id", -1)), 0, "intent report should expose entity_id", failures)

func _test_intent_report_exposes_priority_weight(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var found := false
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) != 0:
			continue
		found = true
		_assert_eq(float(intent.get("priority_weight", -1.0)), 0.5, "intent report should expose priority_weight", failures)
		break
	_assert_true(found, "intent report should include attacker intent entry for priority_weight", failures)

func _test_intent_report_counts_attacker_and_target_entries(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	_assert_eq(int(intents.size()), 1, "intent report should only expose attacker claim entries", failures)

func _test_attack_holder_intent_report_exposes_boosted_priority_weight(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-0.5, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var holder_weight := -1.0
	var claimer_weight := -1.0
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) == 0:
			holder_weight = float(intent.get("priority_weight", -1.0))
		elif int(intent.get("entity_id", -1)) == 1:
			claimer_weight = float(intent.get("priority_weight", -1.0))
	_assert_true(holder_weight > 1000.0, "attack-holder intent report should expose boosted priority_weight", failures)
	_assert_true(holder_weight > claimer_weight, "attack-holder boosted priority_weight should exceed new claimer weight", failures)

func _test_intent_report_hides_reverse_side_entries(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		_assert_true(int(intent.get("entity_id", -1)) <= int(intent.get("target_id", -1)), "intent report should hide reverse-side mirrored entries", failures)

func _test_assignment_report_exposes_exact_conflict_pair(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	_assert_eq(int(assignments.size()), 2, "assignment report should only expose attacker-side conflict pair", failures)
	_assert_true(assignments.has(0) and assignments.has(1), "assignment report should expose both attacker ids in conflict pair", failures)
	_assert_true(not assignments.has(2), "assignment report should hide reverse-side target assignment entry", failures)

func _test_contention_metrics_align_with_serialized_reports(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), intents.size(), "contention intent_count should match serialized intent entries", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "contention waiting_count should match serialized waiting entry count", failures)
	_assert_eq(int(assignments.size()), 2, "serialized assignments should stay aligned with attacker-side contention counts", failures)

func _test_assignment_report_only_serializes_attacker_side_in_duel(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	_assert_eq(int(assignments.size()), 1, "duel assignment report should only serialize attacker-side entry", failures)
	_assert_true(assignments.has(0), "duel assignment report should keep attacker entry", failures)
	_assert_true(not assignments.has(1), "duel assignment report should hide reverse-side target entry", failures)

func _test_assignment_report_only_serializes_attacker_side_in_holder_conflict(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-3.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	_assert_eq(int(assignments.size()), 2, "holder conflict assignment report should only serialize attacker-side entries", failures)
	_assert_true(assignments.has(0) and assignments.has(1), "holder conflict assignment report should keep both attacker entries", failures)
	_assert_true(not assignments.has(2), "holder conflict assignment report should hide reverse-side target entry", failures)

func _test_attack_holder_keeps_slot_against_new_claimer(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-3.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(store.locked_slot_index[0]), 0, "attack holder should keep its assigned slot against a new claimer", failures)
	_assert_true(int(store.locked_slot_index[1]) != 0, "new claimer should not steal the attack holder slot", failures)

func _test_assignment_survives_into_next_tick_snapshot(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var first_slot := int(store.locked_slot_index[0])
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(store.locked_slot_index[0]), first_slot, "assigned slot should survive into the next tick snapshot", failures)
	_assert_true(first_slot != -1, "first tick should commit a concrete assigned slot", failures)

func _test_waiting_assignment_soft_holds_without_chase_velocity(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var before := Vector2(store.position_x[1], store.position_y[1])
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[1], store.position_y[1])
	if int(store.locked_slot_index[0]) == int(store.locked_slot_index[1]):
		failures.append("conflict fixture should produce a waiting loser before soft-hold assertions")
		return
	var waiting_id := 0 if int(store.locked_slot_index[0]) == -1 else 1
	var waiting_before := before if waiting_id == 1 else Vector2(store.position_x[0], store.position_y[0])
	var waiting_after := after if waiting_id == 1 else Vector2(store.position_x[0], store.position_y[0])
	_assert_true(waiting_after.distance_to(waiting_before) <= 0.001, "waiting assignment should soft-hold without forward movement", failures)
	_assert_true(absf(float(store.velocity_x[waiting_id])) <= 0.001 and absf(float(store.velocity_y[waiting_id])) <= 0.001, "waiting assignment should clear chase velocity", failures)
	_assert_eq(int(store.locked_slot_index[waiting_id]), -1, "waiting assignment should keep slot index at -1", failures)

func _test_single_unit_gets_success_assignment(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(report.get("processed", -1)), 2, "v4 report should count processed entities", failures)
	_assert_eq(int(store.target_id[0]), 1, "single unit should acquire the enemy target", failures)
	_assert_true(int(store.locked_slot_index[0]) != -1, "single unit should receive a resolved slot assignment", failures)

func _test_conflicting_claims_produce_unique_assignment(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_eq(int(report.get("processed", -1)), 3, "v4 conflict tick should process all bucket entities", failures)
	_assert_true(int(store.target_id[0]) == 2 and int(store.target_id[1]) == 2, "both attackers should resolve the same target in the conflict fixture", failures)
	_assert_true(int(store.locked_slot_index[0]) != int(store.locked_slot_index[1]), "conflicting claims should resolve to unique assigned slots", failures)

func _make_intent(entity_id: int, target_id: int, desired_slot_index: int, priority_weight: float) -> UnitIntent:
	var intent := UnitIntent.new()
	intent.entity_id = entity_id
	intent.target_id = target_id
	intent.desired_slot_index = desired_slot_index
	intent.priority_weight = priority_weight
	return intent

func _prepare(store, entity_id: int, team_id: int, pos: Vector2, move_speed: float) -> void:
	store.alive[entity_id] = 1
	store.team_id[entity_id] = team_id
	store.bucket_id[entity_id] = 0
	store.move_speed[entity_id] = move_speed
	store.position_x[entity_id] = pos.x
	store.position_y[entity_id] = pos.y
	store.velocity_x[entity_id] = 0.0
	store.velocity_y[entity_id] = 0.0
	store.target_id[entity_id] = -1
	store.contact_slot[entity_id] = -1
	store.intent_state[entity_id] = 0
	store.attack_permission[entity_id] = 0
	store.state_lock_until[entity_id] = 0.0
	store.locked_target_id[entity_id] = -1
	store.locked_slot_index[entity_id] = -1
	store.engagement_blocked_time[entity_id] = 0.0
	store.contact_settle_time[entity_id] = 0.0

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
