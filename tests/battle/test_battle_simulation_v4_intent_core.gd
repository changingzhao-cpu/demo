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
	_test_assignment_and_contention_reports_stay_consistent_in_duel(failures)
	_test_assignment_and_contention_reports_stay_consistent_in_conflict(failures)
	_test_intent_and_assignment_reports_share_target_id_in_duel(failures)
	_test_intent_and_assignment_reports_share_slot_index_in_duel(failures)
	_test_intent_and_assignment_reports_share_global_anchor_in_duel(failures)
	_test_conflict_reports_keep_shared_target_id_across_attackers(failures)
	_test_conflict_reports_preserve_distinct_assignment_statuses(failures)
	_test_conflict_reports_preserve_distinct_assignment_slot_indexes(failures)
	_test_conflict_reports_keep_shared_global_anchor_across_attackers(failures)
	_test_conflict_reports_keep_shared_slot_request_across_attackers(failures)
	_test_conflict_reports_keep_distinct_priority_weights_when_positions_differ(failures)
	_test_attack_holder_report_keeps_boosted_weight_above_waiting_assignment(failures)
	_test_conflict_reports_keep_waiting_assignment_anchor_equal_to_success_anchor(failures)
	_test_holder_fixture_reports_match_contention_counts(failures)
	_test_holder_fixture_preserves_attacker_side_assignment_pair(failures)
	_test_holder_fixture_preserves_attacker_side_intent_pair(failures)
	_test_holder_fixture_intents_and_assignments_share_target_id(failures)
	_test_holder_fixture_intents_and_assignments_share_slot_indexes(failures)
	_test_holder_fixture_intents_and_assignments_share_status_partition(failures)
	_test_holder_fixture_contention_matches_holder_status_partition(failures)
	_test_holder_fixture_priority_weight_order_matches_assignment_outcome(failures)
	_test_holder_fixture_report_matches_store_committed_slot_indexes(failures)
	_test_holder_fixture_report_matches_store_committed_target_ids(failures)
	_test_holder_fixture_report_matches_store_committed_statuses(failures)
	_test_holder_fixture_report_matches_store_committed_positions_for_success_unit(failures)
	_test_holder_fixture_waiting_unit_keeps_zero_velocity(failures)
	_test_holder_fixture_report_matches_store_committed_positions_for_waiting_unit(failures)
	_test_holder_fixture_report_matches_store_committed_velocities_for_success_unit(failures)
	_test_holder_fixture_report_matches_store_committed_velocities_for_waiting_unit(failures)
	_test_holder_fixture_report_matches_store_committed_target_lock_ids(failures)
	_test_holder_fixture_report_matches_store_committed_contact_slots(failures)
	_test_holder_fixture_report_matches_store_committed_locked_slot_indexes(failures)
	_test_holder_fixture_report_matches_store_committed_target_ids_for_both_attackers(failures)
	_test_holder_fixture_store_and_report_keep_same_success_anchor(failures)
	_test_holder_fixture_waiting_assignment_stays_off_contact_slot(failures)
	_test_holder_fixture_report_matches_store_committed_locked_target_for_holder(failures)
	_test_holder_fixture_report_matches_store_committed_locked_target_for_waiting_unit(failures)
	_test_holder_fixture_report_matches_store_committed_target_ids_array(failures)
	_test_holder_fixture_report_matches_store_committed_attack_permissions_default(failures)
	_test_holder_fixture_report_matches_store_committed_state_lock_defaults(failures)
	_test_holder_fixture_report_matches_store_committed_settle_time_defaults(failures)
	_test_holder_fixture_report_matches_store_committed_blocked_time_defaults(failures)
	_test_holder_fixture_success_unit_keeps_target_id_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_target_id_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_locked_slot_index_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_locked_slot_index_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_contact_slot_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_contact_slot_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_locked_target_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_locked_target_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_target_array_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_target_array_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_locked_target_array_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_locked_target_array_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_locked_slot_array_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_locked_slot_array_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_contact_slot_array_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_contact_slot_array_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_velocity_vector_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_velocity_vector_after_commit(failures)
	_test_holder_fixture_success_unit_moves_closer_to_anchor_after_commit(failures)
	_test_holder_fixture_waiting_unit_stays_same_distance_from_anchor_after_commit(failures)
	_test_holder_fixture_success_unit_keeps_horizontal_motion_toward_anchor(failures)
	_test_holder_fixture_waiting_unit_keeps_horizontal_position_after_commit(failures)
	_test_holder_fixture_waiting_unit_keeps_vertical_position_after_commit(failures)
	_test_holder_fixture_success_unit_preserves_target_anchor_in_report_after_motion(failures)
	_test_holder_fixture_waiting_unit_preserves_target_anchor_in_report_after_motion(failures)
	_test_holder_fixture_success_unit_report_status_matches_store_lock_shape(failures)
	_test_holder_fixture_waiting_unit_report_status_matches_store_lock_shape(failures)
	_test_holder_fixture_success_assignment_matches_store_target_and_slot_pair(failures)
	_test_holder_fixture_waiting_assignment_matches_store_target_and_slot_pair(failures)
	_test_holder_fixture_success_assignment_matches_store_contact_slot_pair(failures)
	_test_holder_fixture_waiting_assignment_matches_store_contact_slot_pair(failures)
	_test_holder_fixture_success_assignment_matches_store_locked_target_pair(failures)
	_test_holder_fixture_waiting_assignment_matches_store_locked_target_pair(failures)
	_test_holder_fixture_success_assignment_matches_store_locked_slot_pair(failures)
	_test_holder_fixture_waiting_assignment_matches_store_locked_slot_pair(failures)
	_test_holder_fixture_success_assignment_matches_store_locked_target_pair_after_motion(failures)
	_test_holder_fixture_waiting_assignment_matches_store_locked_target_pair_after_motion(failures)
	_test_holder_fixture_success_assignment_matches_store_locked_slot_pair_after_motion(failures)
	_test_holder_fixture_waiting_assignment_matches_store_locked_slot_pair_after_motion(failures)
	_test_holder_fixture_success_assignment_matches_store_contact_slot_after_motion(failures)
	_test_holder_fixture_waiting_assignment_matches_store_contact_slot_after_motion(failures)
	_test_holder_fixture_success_assignment_preserves_anchor_after_store_motion(failures)
	_test_holder_fixture_waiting_assignment_preserves_anchor_after_store_motion(failures)
	_test_holder_fixture_success_assignment_status_stays_success_after_store_motion(failures)
	_test_holder_fixture_waiting_assignment_status_stays_waiting_after_store_motion(failures)
	_test_holder_fixture_success_assignment_target_matches_target_array_after_store_motion(failures)
	_test_holder_fixture_waiting_assignment_target_matches_target_array_after_store_motion(failures)
	_test_holder_fixture_success_assignment_slot_matches_contact_slot_after_store_motion(failures)
	_test_holder_fixture_waiting_assignment_slot_matches_contact_slot_after_store_motion(failures)
	_test_holder_fixture_success_assignment_status_matches_contact_resolution_after_store_motion(failures)
	_test_holder_fixture_waiting_assignment_status_matches_contact_resolution_after_store_motion(failures)
	_test_holder_fixture_success_assignment_slot_matches_locked_slot_after_contact_resolution(failures)
	_test_holder_fixture_waiting_assignment_slot_matches_locked_slot_after_contact_resolution(failures)
	_test_holder_fixture_success_assignment_target_matches_locked_target_after_contact_resolution(failures)
	_test_holder_fixture_waiting_assignment_target_matches_locked_target_after_contact_resolution(failures)
	_test_holder_fixture_success_assignment_slot_matches_contact_slot_after_contact_resolution(failures)
	_test_holder_fixture_waiting_assignment_slot_matches_contact_slot_after_contact_resolution(failures)
	_test_holder_fixture_success_assignment_status_matches_locked_slot_shape_after_motion(failures)
	_test_holder_fixture_waiting_assignment_status_matches_unresolved_slot_shape_after_motion(failures)
	_test_holder_fixture_success_assignment_anchor_matches_target_position_after_motion(failures)
	_test_holder_fixture_waiting_assignment_anchor_matches_target_position_after_motion(failures)
	_test_holder_fixture_contention_success_rate_matches_assignment_partition_after_motion(failures)
	_test_holder_fixture_contention_waiting_count_matches_assignment_partition_after_motion(failures)
	_test_holder_fixture_contention_intent_count_matches_attacker_pair_after_motion(failures)
	_test_holder_fixture_contention_group_count_stays_single_after_motion(failures)
	_test_holder_fixture_contention_metrics_stay_consistent_with_serialized_assignments_after_motion(failures)
	_test_holder_fixture_contention_metrics_stay_consistent_with_serialized_intents_after_motion(failures)
	_test_holder_fixture_contention_success_rate_stays_half_after_motion(failures)
	_test_holder_fixture_contention_waiting_count_stays_one_after_motion(failures)
	_test_holder_fixture_contention_group_count_stays_one_after_motion_with_holder_lock(failures)
	_test_holder_fixture_contention_intent_count_matches_attacker_assignments_after_motion(failures)
	_test_holder_fixture_contention_waiting_count_matches_waiting_assignment_after_motion(failures)
	_test_holder_fixture_contention_success_rate_matches_success_assignment_after_motion(failures)
	_test_holder_fixture_contention_and_report_processed_count_stay_compatible(failures)
	_test_holder_fixture_processed_count_stays_above_attacker_intents(failures)
	_test_holder_fixture_contention_bucket_metadata_stays_constant(failures)
	_test_holder_fixture_processed_count_matches_bucket_entity_count(failures)
	_test_holder_fixture_contention_metrics_ignore_target_side_entity_after_motion(failures)
	_test_holder_fixture_assignment_report_ignores_target_side_entity_after_motion(failures)
	_test_holder_fixture_intent_report_ignores_target_side_entity_after_motion(failures)
	_test_holder_fixture_reported_attacker_ids_match_expected_pair_after_motion(failures)
	_test_holder_fixture_attacker_ids_remain_sorted_after_motion(failures)
	_test_holder_fixture_assignment_keys_remain_sorted_after_motion(failures)
	_test_holder_fixture_intent_priority_weights_remain_descending_after_motion(failures)
	_test_holder_fixture_success_assignment_stays_first_by_entity_id_after_motion(failures)
	_test_holder_fixture_waiting_assignment_stays_second_by_entity_id_after_motion(failures)
	_test_holder_fixture_attacker_intents_keep_expected_order_after_motion(failures)
	_test_holder_fixture_assignment_dictionary_keeps_two_attacker_entries_after_motion(failures)
	_test_holder_fixture_assignment_dictionary_excludes_target_side_entry_after_motion(failures)
	_test_holder_fixture_intent_dictionary_fields_stay_complete_after_motion(failures)
	_test_holder_fixture_assignment_dictionary_fields_stay_complete_after_motion(failures)
	_test_holder_fixture_contention_dictionary_fields_stay_complete_after_motion(failures)
	_test_holder_fixture_contention_rate_stays_bounded_after_motion(failures)
	_test_holder_fixture_success_unit_motion_updates_grid_position(failures)
	_test_holder_fixture_waiting_unit_does_not_touch_grid_position(failures)
	_test_holder_fixture_success_unit_appears_in_grid_neighbors_after_motion(failures)
	_test_holder_fixture_waiting_unit_stays_absent_from_grid_neighbors_after_motion(failures)
	_test_holder_fixture_reported_success_position_matches_store_after_motion(failures)
	_test_holder_fixture_waiting_position_stays_exact_after_motion(failures)
	_test_holder_fixture_success_velocity_matches_expected_step_after_motion(failures)
	_test_holder_fixture_waiting_velocity_remains_zero_after_motion(failures)
	_test_holder_fixture_success_position_uses_expected_delta_step(failures)
	_test_holder_fixture_success_position_and_velocity_stay_directionally_aligned(failures)
	_test_holder_fixture_waiting_position_and_velocity_stay_directionally_neutral(failures)
	_test_holder_fixture_success_grid_key_tracks_committed_position(failures)
	_test_holder_fixture_waiting_grid_key_stays_unset(failures)
	_test_holder_fixture_success_grid_neighbors_include_committed_unit_after_motion(failures)
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

func _test_assignment_and_contention_reports_stay_consistent_in_duel(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(assignments.size()), int(contention.get("intent_count", -1)), "duel assignment report should stay consistent with attacker-side contention intent_count", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 0, "duel contention should still have zero waiting assignments", failures)

func _test_assignment_and_contention_reports_stay_consistent_in_conflict(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(assignments.size()), int(contention.get("intent_count", -1)), "conflict assignment report should stay consistent with attacker-side contention intent_count", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "conflict contention should still have one waiting assignment", failures)

func _test_intent_and_assignment_reports_share_target_id_in_duel(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(intents.size() > 0 and assignments.has(0), "duel report should expose both intent and assignment for attacker", failures)
	var intent: Dictionary = intents[0]
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(int(intent.get("target_id", -1)), int(assignment.get("target_id", -2)), "intent and assignment reports should share target_id in duel", failures)

func _test_intent_and_assignment_reports_share_slot_index_in_duel(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(intents.size() > 0 and assignments.has(0), "duel report should expose both intent and assignment for slot comparison", failures)
	var intent: Dictionary = intents[0]
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(int(intent.get("desired_slot_index", -1)), int(assignment.get("assigned_slot_index", -2)), "intent and assignment reports should share slot index in duel", failures)

func _test_intent_and_assignment_reports_share_global_anchor_in_duel(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(intents.size() > 0 and assignments.has(0), "duel report should expose both intent and assignment for anchor comparison", failures)
	var assignment: Dictionary = assignments.get(0, {})
	_assert_eq(assignment.get("global_pos", null), Vector2.ZERO, "intent and assignment reports should share target global anchor in duel", failures)

func _test_conflict_reports_keep_shared_target_id_across_attackers(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_eq(int(intents.size()), 2, "conflict report should expose two attacker intents", failures)
	_assert_true(assignments.has(0) and assignments.has(1), "conflict report should expose both attacker assignments", failures)
	var first_intent: Dictionary = intents[0]
	var second_intent: Dictionary = intents[1]
	_assert_eq(int(first_intent.get("target_id", -1)), int(second_intent.get("target_id", -2)), "conflict intents should keep shared target_id", failures)
	_assert_eq(int(assignments.get(0, {}).get("target_id", -1)), int(assignments.get(1, {}).get("target_id", -2)), "conflict assignments should keep shared target_id", failures)

func _test_conflict_reports_preserve_distinct_assignment_statuses(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(assignments.has(0) and assignments.has(1), "conflict report should expose both attacker assignments for status comparison", failures)
	var first_status := int(assignments.get(0, {}).get("status", -1))
	var second_status := int(assignments.get(1, {}).get("status", -1))
	_assert_true(first_status != second_status, "conflict assignments should preserve distinct success and waiting statuses", failures)

func _test_conflict_reports_preserve_distinct_assignment_slot_indexes(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(assignments.has(0) and assignments.has(1), "conflict report should expose both attacker assignments for slot comparison", failures)
	var first_slot := int(assignments.get(0, {}).get("assigned_slot_index", -2))
	var second_slot := int(assignments.get(1, {}).get("assigned_slot_index", -2))
	_assert_true(first_slot != second_slot, "conflict assignments should preserve distinct resolved and waiting slot indexes", failures)

func _test_conflict_reports_keep_shared_global_anchor_across_attackers(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(assignments.has(0) and assignments.has(1), "conflict report should expose both attacker assignments for anchor comparison", failures)
	var first_anchor = assignments.get(0, {}).get("global_pos", null)
	var second_anchor = assignments.get(1, {}).get("global_pos", null)
	_assert_eq(first_anchor, second_anchor, "conflict assignments should keep shared global anchor across attackers", failures)

func _test_conflict_reports_keep_shared_slot_request_across_attackers(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	_assert_eq(int(intents.size()), 2, "conflict report should expose two attacker intents for slot request comparison", failures)
	var first_slot := int((intents[0] as Dictionary).get("desired_slot_index", -1))
	var second_slot := int((intents[1] as Dictionary).get("desired_slot_index", -2))
	_assert_eq(first_slot, second_slot, "conflict intents should keep shared desired slot request across attackers", failures)

func _test_conflict_reports_keep_distinct_priority_weights_when_positions_differ(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-2.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-0.5, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var intents: Array = report.get("intents", [])
	_assert_eq(int(intents.size()), 2, "conflict report should expose two attacker intents for weight comparison", failures)
	var first_weight := float((intents[0] as Dictionary).get("priority_weight", -1.0))
	var second_weight := float((intents[1] as Dictionary).get("priority_weight", -1.0))
	_assert_true(not is_equal_approx(first_weight, second_weight), "conflict intents should keep distinct priority weights when positions differ", failures)

func _test_attack_holder_report_keeps_boosted_weight_above_waiting_assignment(failures: Array[String]) -> void:
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
	var assignments: Dictionary = report.get("assignments", {})
	var holder_weight := -1.0
	var waiting_status := -1
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) == 0:
			holder_weight = float(intent.get("priority_weight", -1.0))
	waiting_status = int(assignments.get(1, {}).get("status", -1))
	_assert_true(holder_weight > 1000.0, "attack-holder report should keep boosted weight", failures)
	_assert_eq(waiting_status, 1, "new claimer should stay waiting in boosted-weight fixture", failures)

func _test_conflict_reports_keep_waiting_assignment_anchor_equal_to_success_anchor(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	var report: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var assignments: Dictionary = report.get("assignments", {})
	var first_anchor = assignments.get(0, {}).get("global_pos", null)
	var second_anchor = assignments.get(1, {}).get("global_pos", null)
	_assert_eq(first_anchor, second_anchor, "waiting and success assignments should share target anchor in conflict report", failures)

func _test_holder_fixture_reports_match_contention_counts(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(assignments.size()), int(contention.get("intent_count", -1)), "holder fixture assignment report should match attacker-side contention intent_count", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "holder fixture contention should keep one waiting assignment", failures)

func _test_holder_fixture_preserves_attacker_side_assignment_pair(failures: Array[String]) -> void:
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
	_assert_eq(int(assignments.size()), 2, "holder fixture should keep attacker-side assignment pair", failures)
	_assert_true(assignments.has(0) and assignments.has(1), "holder fixture should preserve both attacker-side assignment entries", failures)

func _test_holder_fixture_preserves_attacker_side_intent_pair(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	_assert_eq(int(intents.size()), 2, "holder fixture should keep attacker-side intent pair", failures)
	var first_id := int((intents[0] as Dictionary).get("entity_id", -1))
	var second_id := int((intents[1] as Dictionary).get("entity_id", -1))
	_assert_true((first_id == 0 and second_id == 1) or (first_id == 1 and second_id == 0), "holder fixture should preserve both attacker-side intent entries", failures)

func _test_holder_fixture_intents_and_assignments_share_target_id(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(intents.size() == 2 and assignments.has(0) and assignments.has(1), "holder fixture should expose attacker intents and assignments for target comparison", failures)
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		var entity_id := int(intent.get("entity_id", -1))
		var assignment: Dictionary = assignments.get(entity_id, {})
		_assert_eq(int(intent.get("target_id", -1)), int(assignment.get("target_id", -2)), "holder fixture intent and assignment should share target_id", failures)

func _test_holder_fixture_intents_and_assignments_share_slot_indexes(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(intents.size() == 2 and assignments.has(0) and assignments.has(1), "holder fixture should expose attacker intents and assignments for slot comparison", failures)
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		var entity_id := int(intent.get("entity_id", -1))
		var assignment: Dictionary = assignments.get(entity_id, {})
		if int(assignment.get("status", -1)) == 1:
			_assert_eq(int(intent.get("desired_slot_index", -1)), 0, "holder fixture waiting intent should keep requested slot index", failures)
			_assert_eq(int(assignment.get("assigned_slot_index", -2)), -1, "holder fixture waiting assignment should keep unresolved slot index", failures)
		else:
			_assert_eq(int(intent.get("desired_slot_index", -1)), int(assignment.get("assigned_slot_index", -2)), "holder fixture success intent and assignment should share slot index", failures)

func _test_holder_fixture_intents_and_assignments_share_status_partition(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	var success_count := 0
	var waiting_count := 0
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		var entity_id := int(intent.get("entity_id", -1))
		var assignment: Dictionary = assignments.get(entity_id, {})
		if int(assignment.get("status", -1)) == 1:
			waiting_count += 1
		else:
			success_count += 1
	_assert_eq(success_count, 1, "holder fixture should keep exactly one successful attacker assignment", failures)
	_assert_eq(waiting_count, 1, "holder fixture should keep exactly one waiting attacker assignment", failures)

func _test_holder_fixture_contention_matches_holder_status_partition(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), 2, "holder fixture contention should keep two attacker claims", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "holder fixture contention should match one waiting attacker", failures)
	_assert_eq(float(contention.get("claim_success_rate", -1.0)), 0.5, "holder fixture contention should match holder status partition", failures)

func _test_holder_fixture_priority_weight_order_matches_assignment_outcome(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	var holder_weight := -1.0
	var claimer_weight := -1.0
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		if int(intent.get("entity_id", -1)) == 0:
			holder_weight = float(intent.get("priority_weight", -1.0))
		elif int(intent.get("entity_id", -1)) == 1:
			claimer_weight = float(intent.get("priority_weight", -1.0))
	_assert_true(holder_weight > claimer_weight, "holder fixture priority ordering should favor successful holder assignment", failures)
	_assert_eq(int(assignments.get(0, {}).get("status", -1)), 0, "holder fixture should keep holder success assignment", failures)
	_assert_eq(int(assignments.get(1, {}).get("status", -1)), 1, "holder fixture should keep challenger waiting assignment", failures)

func _test_holder_fixture_report_matches_store_committed_slot_indexes(failures: Array[String]) -> void:
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
	_assert_eq(int(assignments.get(0, {}).get("assigned_slot_index", -2)), int(store.locked_slot_index[0]), "holder fixture report should match committed holder slot index", failures)
	_assert_eq(int(assignments.get(1, {}).get("assigned_slot_index", -2)), int(store.locked_slot_index[1]), "holder fixture report should match committed challenger slot index", failures)

func _test_holder_fixture_report_matches_store_committed_target_ids(failures: Array[String]) -> void:
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
	_assert_eq(int(assignments.get(0, {}).get("target_id", -2)), int(store.locked_target_id[0]), "holder fixture report should match committed holder target id", failures)
	_assert_eq(int(assignments.get(1, {}).get("target_id", -2)), int(store.locked_target_id[1]), "holder fixture report should match committed challenger target id", failures)

func _test_holder_fixture_report_matches_store_committed_statuses(failures: Array[String]) -> void:
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
	_assert_eq(int(assignments.get(0, {}).get("status", -2)), 0, "holder fixture report should keep holder success status", failures)
	_assert_eq(int(assignments.get(1, {}).get("status", -2)), 1, "holder fixture report should keep challenger waiting status", failures)

func _test_holder_fixture_report_matches_store_committed_positions_for_success_unit(failures: Array[String]) -> void:
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
	var before := Vector2(-1.0, 0.0)
	var after := Vector2(store.position_x[0], store.position_y[0])
	_assert_true(after.distance_to(Vector2.ZERO) < before.distance_to(Vector2.ZERO), "holder fixture should still move successful unit toward anchor", failures)
	_assert_eq(int(report.get("processed", -1)), 3, "holder fixture report should still count processed entities", failures)

func _test_holder_fixture_waiting_unit_keeps_zero_velocity(failures: Array[String]) -> void:
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
	_assert_eq(float(store.velocity_x[1]), 0.0, "holder fixture waiting unit should keep zero x velocity", failures)
	_assert_eq(float(store.velocity_y[1]), 0.0, "holder fixture waiting unit should keep zero y velocity", failures)

func _test_holder_fixture_report_matches_store_committed_positions_for_waiting_unit(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var waiting_before := Vector2(-3.0, 0.0)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, waiting_before, 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var waiting_after := Vector2(store.position_x[1], store.position_y[1])
	_assert_eq(waiting_after, waiting_before, "holder fixture waiting unit should keep committed position", failures)

func _test_holder_fixture_report_matches_store_committed_velocities_for_success_unit(failures: Array[String]) -> void:
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
	_assert_true(absf(float(store.velocity_x[0])) > 0.0 or absf(float(store.velocity_y[0])) > 0.0, "holder fixture success unit should keep non-zero committed velocity", failures)

func _test_holder_fixture_report_matches_store_committed_velocities_for_waiting_unit(failures: Array[String]) -> void:
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
	_assert_eq(float(store.velocity_x[1]), 0.0, "holder fixture waiting unit should keep zero committed x velocity", failures)
	_assert_eq(float(store.velocity_y[1]), 0.0, "holder fixture waiting unit should keep zero committed y velocity", failures)

func _test_holder_fixture_report_matches_store_committed_target_lock_ids(failures: Array[String]) -> void:
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
	_assert_eq(int(assignments.get(0, {}).get("target_id", -2)), int(store.locked_target_id[0]), "holder fixture report should match holder locked_target_id", failures)
	_assert_eq(int(assignments.get(1, {}).get("target_id", -2)), int(store.locked_target_id[1]), "holder fixture report should match challenger locked_target_id", failures)

func _test_holder_fixture_report_matches_store_committed_contact_slots(failures: Array[String]) -> void:
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
	_assert_eq(int(store.contact_slot[0]), 0, "holder fixture should keep holder committed contact slot", failures)
	_assert_eq(int(store.contact_slot[1]), -1, "holder fixture should keep challenger committed contact slot unresolved", failures)

func _test_holder_fixture_report_matches_store_committed_locked_slot_indexes(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_slot_index[0]), 0, "holder fixture should keep holder locked slot index", failures)
	_assert_eq(int(store.locked_slot_index[1]), -1, "holder fixture should keep challenger locked slot index unresolved", failures)

func _test_holder_fixture_report_matches_store_committed_target_ids_for_both_attackers(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[0]), 2, "holder fixture should keep holder locked target id", failures)
	_assert_eq(int(store.locked_target_id[1]), 2, "holder fixture should keep challenger locked target id", failures)

func _test_holder_fixture_store_and_report_keep_same_success_anchor(failures: Array[String]) -> void:
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
	_assert_eq(assignments.get(0, {}).get("global_pos", null), Vector2.ZERO, "holder fixture success anchor should stay on target origin in report", failures)
	_assert_true(Vector2(store.position_x[0], store.position_y[0]).distance_to(Vector2.ZERO) < 1.0, "holder fixture committed success position should move toward same target anchor", failures)

func _test_holder_fixture_waiting_assignment_stays_off_contact_slot(failures: Array[String]) -> void:
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
	_assert_eq(int(store.contact_slot[1]), -1, "holder fixture waiting assignment should stay off contact slot", failures)

func _test_holder_fixture_report_matches_store_committed_locked_target_for_holder(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[0]), 2, "holder fixture should keep holder locked target id committed", failures)

func _test_holder_fixture_report_matches_store_committed_locked_target_for_waiting_unit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[1]), 2, "holder fixture should keep waiting unit locked target id committed", failures)

func _test_holder_fixture_report_matches_store_committed_target_ids_array(failures: Array[String]) -> void:
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
	_assert_eq(int(store.target_id[0]), 2, "holder fixture should keep holder target id committed in store", failures)
	_assert_eq(int(store.target_id[1]), 2, "holder fixture should keep challenger target id committed in store", failures)

func _test_holder_fixture_report_matches_store_committed_attack_permissions_default(failures: Array[String]) -> void:
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
	_assert_eq(int(store.attack_permission[0]), 0, "holder fixture should keep holder attack permission default", failures)
	_assert_eq(int(store.attack_permission[1]), 0, "holder fixture should keep challenger attack permission default", failures)

func _test_holder_fixture_report_matches_store_committed_state_lock_defaults(failures: Array[String]) -> void:
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
	_assert_eq(float(store.state_lock_until[0]), 0.0, "holder fixture should keep holder state lock default", failures)
	_assert_eq(float(store.state_lock_until[1]), 0.0, "holder fixture should keep challenger state lock default", failures)

func _test_holder_fixture_report_matches_store_committed_settle_time_defaults(failures: Array[String]) -> void:
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
	_assert_eq(float(store.contact_settle_time[0]), 0.0, "holder fixture should keep holder contact settle time default", failures)
	_assert_eq(float(store.contact_settle_time[1]), 0.0, "holder fixture should keep challenger contact settle time default", failures)

func _test_holder_fixture_report_matches_store_committed_blocked_time_defaults(failures: Array[String]) -> void:
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
	_assert_eq(float(store.engagement_blocked_time[0]), 0.0, "holder fixture should keep holder engagement blocked time default", failures)
	_assert_eq(float(store.engagement_blocked_time[1]), 0.0, "holder fixture should keep challenger engagement blocked time default", failures)

func _test_holder_fixture_success_unit_keeps_target_id_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.target_id[0]), 2, "holder fixture should keep holder target id after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_target_id_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.target_id[1]), 2, "holder fixture should keep waiting unit target id after commit", failures)

func _test_holder_fixture_success_unit_keeps_locked_slot_index_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_slot_index[0]), 0, "holder fixture should keep success unit locked slot index after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_locked_slot_index_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_slot_index[1]), -1, "holder fixture should keep waiting unit locked slot index after commit", failures)

func _test_holder_fixture_success_unit_keeps_contact_slot_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.contact_slot[0]), 0, "holder fixture should keep success unit contact slot after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_contact_slot_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.contact_slot[1]), -1, "holder fixture should keep waiting unit contact slot after commit", failures)

func _test_holder_fixture_success_unit_keeps_locked_target_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[0]), 2, "holder fixture should keep success unit locked target after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_locked_target_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[1]), 2, "holder fixture should keep waiting unit locked target after commit", failures)

func _test_holder_fixture_success_unit_keeps_target_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.target_id[0]), 2, "holder fixture should keep success unit target array after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_target_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.target_id[1]), 2, "holder fixture should keep waiting unit target array after commit", failures)

func _test_holder_fixture_success_unit_keeps_locked_target_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[0]), 2, "holder fixture should keep success unit locked target array after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_locked_target_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_target_id[1]), 2, "holder fixture should keep waiting unit locked target array after commit", failures)

func _test_holder_fixture_success_unit_keeps_locked_slot_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_slot_index[0]), 0, "holder fixture should keep success unit locked slot array after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_locked_slot_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.locked_slot_index[1]), -1, "holder fixture should keep waiting unit locked slot array after commit", failures)

func _test_holder_fixture_success_unit_keeps_contact_slot_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.contact_slot[0]), 0, "holder fixture should keep success unit contact slot array after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_contact_slot_array_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(int(store.contact_slot[1]), -1, "holder fixture should keep waiting unit contact slot array after commit", failures)

func _test_holder_fixture_success_unit_keeps_velocity_vector_after_commit(failures: Array[String]) -> void:
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
	_assert_true(float(store.velocity_x[0]) > 0.0, "holder fixture should keep positive x velocity toward anchor after commit", failures)
	_assert_eq(float(store.velocity_y[0]), 0.0, "holder fixture should keep zero y velocity on horizontal approach", failures)

func _test_holder_fixture_waiting_unit_keeps_velocity_vector_after_commit(failures: Array[String]) -> void:
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
	_assert_eq(float(store.velocity_x[1]), 0.0, "holder fixture should keep waiting unit x velocity at zero after commit", failures)
	_assert_eq(float(store.velocity_y[1]), 0.0, "holder fixture should keep waiting unit y velocity at zero after commit", failures)

func _test_holder_fixture_success_unit_moves_closer_to_anchor_after_commit(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-1.0, 0.0)
	_prepare(store, 0, 0, before, 6.0)
	_prepare(store, 1, 0, Vector2(-3.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[0], store.position_y[0])
	_assert_true(after.distance_to(Vector2.ZERO) < before.distance_to(Vector2.ZERO), "holder fixture should move success unit closer to anchor after commit", failures)

func _test_holder_fixture_waiting_unit_stays_same_distance_from_anchor_after_commit(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-3.0, 0.0)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, before, 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[1], store.position_y[1])
	_assert_eq(after.distance_to(Vector2.ZERO), before.distance_to(Vector2.ZERO), "holder fixture should keep waiting unit at same anchor distance after commit", failures)

func _test_holder_fixture_success_unit_keeps_horizontal_motion_toward_anchor(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-1.0, 0.0)
	_prepare(store, 0, 0, before, 6.0)
	_prepare(store, 1, 0, Vector2(-3.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[0], store.position_y[0])
	_assert_true(after.x > before.x, "holder fixture success unit should move horizontally toward anchor", failures)
	_assert_eq(after.y, before.y, "holder fixture success unit should preserve horizontal path", failures)

func _test_holder_fixture_waiting_unit_keeps_horizontal_position_after_commit(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-3.0, 0.0)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, before, 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[1], store.position_y[1])
	_assert_eq(after.x, before.x, "holder fixture waiting unit should keep horizontal position after commit", failures)

func _test_holder_fixture_waiting_unit_keeps_vertical_position_after_commit(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-3.0, 0.0)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, before, 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[1], store.position_y[1])
	_assert_eq(after.y, before.y, "holder fixture waiting unit should keep vertical position after commit", failures)

func _test_holder_fixture_success_unit_preserves_target_anchor_in_report_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(assignments.get(0, {}).get("global_pos", null), Vector2.ZERO, "holder fixture success unit should preserve target anchor in report after motion", failures)

func _test_holder_fixture_waiting_unit_preserves_target_anchor_in_report_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(assignments.get(1, {}).get("global_pos", null), Vector2.ZERO, "holder fixture waiting unit should preserve target anchor in report after motion", failures)

func _test_holder_fixture_success_unit_report_status_matches_store_lock_shape(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("status", -1)), 0, "holder success report status should stay successful", failures)
	_assert_eq(int(store.locked_slot_index[0]), 0, "holder success store lock should stay concrete", failures)

func _test_holder_fixture_waiting_unit_report_status_matches_store_lock_shape(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("status", -1)), 1, "holder waiting report status should stay waiting", failures)
	_assert_eq(int(store.locked_slot_index[1]), -1, "holder waiting store lock should stay unresolved", failures)

func _test_holder_fixture_success_assignment_matches_store_target_and_slot_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("target_id", -1)), int(store.target_id[0]), "holder success assignment should match committed target id", failures)
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.locked_slot_index[0]), "holder success assignment should match committed slot index", failures)

func _test_holder_fixture_waiting_assignment_matches_store_target_and_slot_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("target_id", -1)), int(store.target_id[1]), "holder waiting assignment should match committed target id", failures)
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.locked_slot_index[1]), "holder waiting assignment should match committed slot index", failures)

func _test_holder_fixture_success_assignment_matches_store_contact_slot_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.contact_slot[0]), "holder success assignment should match committed contact slot", failures)

func _test_holder_fixture_waiting_assignment_matches_store_contact_slot_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.contact_slot[1]), "holder waiting assignment should match committed contact slot", failures)

func _test_holder_fixture_success_assignment_matches_store_locked_target_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("target_id", -1)), int(store.locked_target_id[0]), "holder success assignment should match locked target pair", failures)

func _test_holder_fixture_waiting_assignment_matches_store_locked_target_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("target_id", -1)), int(store.locked_target_id[1]), "holder waiting assignment should match locked target pair", failures)

func _test_holder_fixture_success_assignment_matches_store_locked_slot_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.locked_slot_index[0]), "holder success assignment should match locked slot pair", failures)

func _test_holder_fixture_waiting_assignment_matches_store_locked_slot_pair(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.locked_slot_index[1]), "holder waiting assignment should match locked slot pair", failures)

func _test_holder_fixture_success_assignment_matches_store_locked_target_pair_after_motion(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("target_id", -1)), int(store.locked_target_id[0]), "holder success assignment should still match locked target after motion", failures)

func _test_holder_fixture_waiting_assignment_matches_store_locked_target_pair_after_motion(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("target_id", -1)), int(store.locked_target_id[1]), "holder waiting assignment should still match locked target after motion", failures)

func _test_holder_fixture_success_assignment_matches_store_locked_slot_pair_after_motion(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.locked_slot_index[0]), "holder success assignment should still match locked slot after motion", failures)

func _test_holder_fixture_waiting_assignment_matches_store_locked_slot_pair_after_motion(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.locked_slot_index[1]), "holder waiting assignment should still match locked slot after motion", failures)

func _test_holder_fixture_success_assignment_matches_store_contact_slot_after_motion(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(0, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.contact_slot[0]), "holder success assignment should still match contact slot after motion", failures)

func _test_holder_fixture_waiting_assignment_matches_store_contact_slot_after_motion(failures: Array[String]) -> void:
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
	var assignment: Dictionary = report.get("assignments", {}).get(1, {})
	_assert_eq(int(assignment.get("assigned_slot_index", -2)), int(store.contact_slot[1]), "holder waiting assignment should still match contact slot after motion", failures)

func _test_holder_fixture_success_assignment_preserves_anchor_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(report.get("assignments", {}).get(0, {}).get("global_pos", null), Vector2.ZERO, "holder success assignment should preserve anchor after store motion", failures)

func _test_holder_fixture_waiting_assignment_preserves_anchor_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(report.get("assignments", {}).get(1, {}).get("global_pos", null), Vector2.ZERO, "holder waiting assignment should preserve anchor after store motion", failures)

func _test_holder_fixture_success_assignment_status_stays_success_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("status", -1)), 0, "holder success assignment status should stay success after store motion", failures)

func _test_holder_fixture_waiting_assignment_status_stays_waiting_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("status", -1)), 1, "holder waiting assignment status should stay waiting after store motion", failures)

func _test_holder_fixture_success_assignment_target_matches_target_array_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("target_id", -1)), int(store.target_id[0]), "holder success assignment target should match target array after store motion", failures)

func _test_holder_fixture_waiting_assignment_target_matches_target_array_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("target_id", -1)), int(store.target_id[1]), "holder waiting assignment target should match target array after store motion", failures)

func _test_holder_fixture_success_assignment_slot_matches_contact_slot_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("assigned_slot_index", -2)), int(store.contact_slot[0]), "holder success assignment slot should match contact slot after store motion", failures)

func _test_holder_fixture_waiting_assignment_slot_matches_contact_slot_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("assigned_slot_index", -2)), int(store.contact_slot[1]), "holder waiting assignment slot should match contact slot after store motion", failures)

func _test_holder_fixture_success_assignment_status_matches_contact_resolution_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("status", -1)), 0, "holder success assignment should remain successful after contact resolution", failures)

func _test_holder_fixture_waiting_assignment_status_matches_contact_resolution_after_store_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("status", -1)), 1, "holder waiting assignment should remain waiting after contact resolution", failures)

func _test_holder_fixture_success_assignment_slot_matches_locked_slot_after_contact_resolution(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("assigned_slot_index", -2)), int(store.locked_slot_index[0]), "holder success assignment slot should match locked slot after contact resolution", failures)

func _test_holder_fixture_waiting_assignment_slot_matches_locked_slot_after_contact_resolution(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("assigned_slot_index", -2)), int(store.locked_slot_index[1]), "holder waiting assignment slot should match locked slot after contact resolution", failures)

func _test_holder_fixture_success_assignment_target_matches_locked_target_after_contact_resolution(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("target_id", -1)), int(store.locked_target_id[0]), "holder success assignment target should match locked target after contact resolution", failures)

func _test_holder_fixture_waiting_assignment_target_matches_locked_target_after_contact_resolution(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("target_id", -1)), int(store.locked_target_id[1]), "holder waiting assignment target should match locked target after contact resolution", failures)

func _test_holder_fixture_success_assignment_slot_matches_contact_slot_after_contact_resolution(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("assigned_slot_index", -2)), int(store.contact_slot[0]), "holder success assignment slot should match contact slot after contact resolution", failures)

func _test_holder_fixture_waiting_assignment_slot_matches_contact_slot_after_contact_resolution(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("assigned_slot_index", -2)), int(store.contact_slot[1]), "holder waiting assignment slot should match contact slot after contact resolution", failures)

func _test_holder_fixture_success_assignment_status_matches_locked_slot_shape_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(0, {}).get("status", -1)), 0, "holder success assignment status should match concrete locked slot after motion", failures)
	_assert_true(int(store.locked_slot_index[0]) != -1, "holder success store lock should stay concrete after motion", failures)

func _test_holder_fixture_waiting_assignment_status_matches_unresolved_slot_shape_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("assignments", {}).get(1, {}).get("status", -1)), 1, "holder waiting assignment status should match unresolved locked slot after motion", failures)
	_assert_eq(int(store.locked_slot_index[1]), -1, "holder waiting store lock should stay unresolved after motion", failures)

func _test_holder_fixture_success_assignment_anchor_matches_target_position_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(report.get("assignments", {}).get(0, {}).get("global_pos", null), Vector2(store.position_x[2], store.position_y[2]), "holder success assignment anchor should match target position after motion", failures)

func _test_holder_fixture_waiting_assignment_anchor_matches_target_position_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(report.get("assignments", {}).get(1, {}).get("global_pos", null), Vector2(store.position_x[2], store.position_y[2]), "holder waiting assignment anchor should match target position after motion", failures)

func _test_holder_fixture_contention_success_rate_matches_assignment_partition_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(float(contention.get("claim_success_rate", -1.0)), 0.5, "holder fixture success rate should match one success and one waiting assignment after motion", failures)

func _test_holder_fixture_contention_waiting_count_matches_assignment_partition_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "holder fixture waiting count should match one waiting assignment after motion", failures)

func _test_holder_fixture_contention_intent_count_matches_attacker_pair_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), 2, "holder fixture intent count should stay on attacker pair after motion", failures)

func _test_holder_fixture_contention_group_count_stays_single_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("contested_groups", -1)), 1, "holder fixture contested group count should stay single after motion", failures)

func _test_holder_fixture_contention_metrics_stay_consistent_with_serialized_assignments_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), int(assignments.size()), "holder fixture contention intent count should match serialized assignment count after motion", failures)
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "holder fixture waiting count should stay aligned with serialized assignments after motion", failures)

func _test_holder_fixture_contention_metrics_stay_consistent_with_serialized_intents_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), int(intents.size()), "holder fixture contention intent count should match serialized intents after motion", failures)
	_assert_eq(int(intents.size()), 2, "holder fixture should still serialize two attacker intents after motion", failures)

func _test_holder_fixture_contention_success_rate_stays_half_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(float(contention.get("claim_success_rate", -1.0)), 0.5, "holder fixture success rate should stay half after motion", failures)

func _test_holder_fixture_contention_waiting_count_stays_one_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "holder fixture waiting count should stay one after motion", failures)

func _test_holder_fixture_contention_group_count_stays_one_after_motion_with_holder_lock(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("contested_groups", -1)), 1, "holder fixture contested group count should stay one after motion with holder lock", failures)

func _test_holder_fixture_contention_intent_count_matches_attacker_assignments_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), int(assignments.size()), "holder fixture intent count should match attacker assignment count after motion", failures)

func _test_holder_fixture_contention_waiting_count_matches_waiting_assignment_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("waiting_count", -1)), 1, "holder fixture waiting count should match waiting assignment after motion", failures)
	_assert_eq(int(assignments.get(1, {}).get("status", -1)), 1, "holder fixture should still serialize one waiting attacker assignment after motion", failures)

func _test_holder_fixture_contention_success_rate_matches_success_assignment_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(float(contention.get("claim_success_rate", -1.0)), 0.5, "holder fixture success rate should match one successful attacker assignment after motion", failures)
	_assert_eq(int(assignments.get(0, {}).get("status", -1)), 0, "holder fixture should still serialize one successful attacker assignment after motion", failures)

func _test_holder_fixture_contention_and_report_processed_count_stay_compatible(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("processed", -1)), 3, "holder fixture should still report three processed entities", failures)
	_assert_eq(int(report.get("contention", {}).get("intent_count", -1)), 2, "holder fixture contention should still report two attacker intents", failures)

func _test_holder_fixture_processed_count_stays_above_attacker_intents(failures: Array[String]) -> void:
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
	_assert_true(int(report.get("processed", -1)) > int(report.get("contention", {}).get("intent_count", -1)), "holder fixture processed count should stay above attacker intent count", failures)

func _test_holder_fixture_contention_bucket_metadata_stays_constant(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("bucket_index", -1)), 0, "holder fixture bucket index should stay constant", failures)
	_assert_eq(int(report.get("bucket_count", -1)), 1, "holder fixture bucket count should stay constant", failures)

func _test_holder_fixture_processed_count_matches_bucket_entity_count(failures: Array[String]) -> void:
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
	_assert_eq(int(report.get("processed", -1)), 3, "holder fixture processed count should match bucket entity count", failures)

func _test_holder_fixture_contention_metrics_ignore_target_side_entity_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = report.get("contention", {})
	_assert_eq(int(contention.get("intent_count", -1)), 2, "holder fixture contention should ignore target-side entity after motion", failures)
	_assert_eq(int(report.get("intents", []).size()), 2, "holder fixture serialized intents should ignore target-side entity after motion", failures)

func _test_holder_fixture_assignment_report_ignores_target_side_entity_after_motion(failures: Array[String]) -> void:
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
	_assert_true(not assignments.has(2), "holder fixture assignment report should ignore target-side entity after motion", failures)
	_assert_eq(int(assignments.size()), 2, "holder fixture assignment report should keep only attacker-side entries after motion", failures)

func _test_holder_fixture_intent_report_ignores_target_side_entity_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	_assert_eq(int(intents.size()), 2, "holder fixture intent report should ignore target-side entity after motion", failures)
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		_assert_true(int(intent.get("entity_id", -1)) != 2, "holder fixture intent report should exclude target-side entity id", failures)

func _test_holder_fixture_reported_attacker_ids_match_expected_pair_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	var assignments: Dictionary = report.get("assignments", {})
	_assert_true(assignments.has(0) and assignments.has(1), "holder fixture assignment report should keep attacker ids 0 and 1", failures)
	var seen_ids := {}
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		seen_ids[int(intent.get("entity_id", -1))] = true
	_assert_true(seen_ids.has(0) and seen_ids.has(1), "holder fixture intent report should keep attacker ids 0 and 1", failures)

func _test_holder_fixture_attacker_ids_remain_sorted_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	_assert_eq(int((intents[0] as Dictionary).get("entity_id", -1)), 0, "holder fixture should keep attacker id 0 first after motion", failures)
	_assert_eq(int((intents[1] as Dictionary).get("entity_id", -1)), 1, "holder fixture should keep attacker id 1 second after motion", failures)

func _test_holder_fixture_assignment_keys_remain_sorted_after_motion(failures: Array[String]) -> void:
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
	var keys := assignments.keys()
	keys.sort()
	_assert_eq(int(keys[0]), 0, "holder fixture should keep attacker assignment key 0 first after motion", failures)
	_assert_eq(int(keys[1]), 1, "holder fixture should keep attacker assignment key 1 second after motion", failures)

func _test_holder_fixture_intent_priority_weights_remain_descending_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	_assert_true(float((intents[0] as Dictionary).get("priority_weight", -1.0)) >= float((intents[1] as Dictionary).get("priority_weight", -1.0)), "holder fixture intent priority weights should remain descending after motion", failures)

func _test_holder_fixture_success_assignment_stays_first_by_entity_id_after_motion(failures: Array[String]) -> void:
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
	var keys := assignments.keys()
	keys.sort()
	_assert_eq(int(keys[0]), 0, "holder fixture success assignment should stay first by entity id after motion", failures)

func _test_holder_fixture_waiting_assignment_stays_second_by_entity_id_after_motion(failures: Array[String]) -> void:
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
	var keys := assignments.keys()
	keys.sort()
	_assert_eq(int(keys[1]), 1, "holder fixture waiting assignment should stay second by entity id after motion", failures)

func _test_holder_fixture_attacker_intents_keep_expected_order_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = report.get("intents", [])
	_assert_eq(int((intents[0] as Dictionary).get("entity_id", -1)), 0, "holder fixture first attacker intent should stay entity 0 after motion", failures)
	_assert_eq(int((intents[1] as Dictionary).get("entity_id", -1)), 1, "holder fixture second attacker intent should stay entity 1 after motion", failures)

func _test_holder_fixture_assignment_dictionary_keeps_two_attacker_entries_after_motion(failures: Array[String]) -> void:
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
	_assert_eq(int(assignments.size()), 2, "holder fixture assignment dictionary should keep two attacker entries after motion", failures)

func _test_holder_fixture_assignment_dictionary_excludes_target_side_entry_after_motion(failures: Array[String]) -> void:
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
	_assert_true(not assignments.has(2), "holder fixture assignment dictionary should exclude target-side entry after motion", failures)

func _test_holder_fixture_intent_dictionary_fields_stay_complete_after_motion(failures: Array[String]) -> void:
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
	var intents: Array = simulation.tick_bucket_with_report(store, 0.1, 0, 1).get("intents", [])
	_assert_true(intents.size() == 2, "holder fixture should still expose two attacker intents after motion", failures)
	for intent_variant in intents:
		var intent: Dictionary = intent_variant
		_assert_true(intent.has("entity_id") and intent.has("target_id") and intent.has("desired_slot_index") and intent.has("priority_weight") and intent.has("current_pos"), "holder fixture intent dictionaries should stay complete after motion", failures)

func _test_holder_fixture_assignment_dictionary_fields_stay_complete_after_motion(failures: Array[String]) -> void:
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
	var assignments: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1).get("assignments", {})
	_assert_eq(int(assignments.size()), 2, "holder fixture should still expose two attacker assignments after motion", failures)
	for assignment_variant in assignments.values():
		var assignment: Dictionary = assignment_variant
		_assert_true(assignment.has("target_id") and assignment.has("assigned_slot_index") and assignment.has("global_pos") and assignment.has("status"), "holder fixture assignment dictionaries should stay complete after motion", failures)

func _test_holder_fixture_contention_dictionary_fields_stay_complete_after_motion(failures: Array[String]) -> void:
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
	var contention: Dictionary = simulation.tick_bucket_with_report(store, 0.1, 0, 1).get("contention", {})
	_assert_true(contention.has("intent_count") and contention.has("contested_groups") and contention.has("waiting_count") and contention.has("claim_success_rate"), "holder fixture contention dictionary should stay complete after motion", failures)

func _test_holder_fixture_contention_rate_stays_bounded_after_motion(failures: Array[String]) -> void:
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
	var rate := float(simulation.tick_bucket_with_report(store, 0.1, 0, 1).get("contention", {}).get("claim_success_rate", -1.0))
	_assert_true(rate >= 0.0 and rate <= 1.0, "holder fixture contention rate should stay bounded after motion", failures)

func _test_holder_fixture_success_unit_motion_updates_grid_position(failures: Array[String]) -> void:
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
	_assert_eq(grid.get_cell_key(0), Vector2i(-1, 0), "holder fixture success unit should update grid cell after motion", failures)

func _test_holder_fixture_waiting_unit_does_not_touch_grid_position(failures: Array[String]) -> void:
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
	_assert_eq(grid.get_cell_key(1), null, "holder fixture waiting unit should not update grid cell", failures)

func _test_holder_fixture_success_unit_appears_in_grid_neighbors_after_motion(failures: Array[String]) -> void:
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
	_assert_true(grid.query_neighbors(Vector2.ZERO).has(0), "holder fixture success unit should appear in grid neighbors after motion", failures)

func _test_holder_fixture_waiting_unit_stays_absent_from_grid_neighbors_after_motion(failures: Array[String]) -> void:
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
	_assert_true(not grid.query_neighbors(Vector2.ZERO).has(1), "holder fixture waiting unit should stay absent from grid neighbors after motion", failures)

func _test_holder_fixture_reported_success_position_matches_store_after_motion(failures: Array[String]) -> void:
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
	_assert_true(Vector2(store.position_x[0], store.position_y[0]).distance_to(Vector2(-0.4, 0.0)) <= 0.001, "holder fixture success position should match committed store motion after tick", failures)

func _test_holder_fixture_waiting_position_stays_exact_after_motion(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var waiting_before := Vector2(-3.0, 0.0)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, waiting_before, 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	_assert_true(Vector2(store.position_x[1], store.position_y[1]).distance_to(waiting_before) <= 0.001, "holder fixture waiting position should stay exact after motion", failures)

func _test_holder_fixture_success_velocity_matches_expected_step_after_motion(failures: Array[String]) -> void:
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
	_assert_true(absf(float(store.velocity_x[0]) - 6.0) <= 0.001, "holder fixture success velocity should match expected horizontal step", failures)
	_assert_true(absf(float(store.velocity_y[0])) <= 0.001, "holder fixture success velocity should keep zero vertical step", failures)

func _test_holder_fixture_waiting_velocity_remains_zero_after_motion(failures: Array[String]) -> void:
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
	_assert_true(absf(float(store.velocity_x[1])) <= 0.001, "holder fixture waiting velocity x should remain zero after motion", failures)
	_assert_true(absf(float(store.velocity_y[1])) <= 0.001, "holder fixture waiting velocity y should remain zero after motion", failures)

func _test_holder_fixture_success_position_uses_expected_delta_step(failures: Array[String]) -> void:
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
	_assert_true(Vector2(store.position_x[0], store.position_y[0]).distance_to(Vector2(-0.4, 0.0)) <= 0.001, "holder fixture success position should use expected delta step", failures)

func _test_holder_fixture_success_position_and_velocity_stay_directionally_aligned(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-1.0, 0.0)
	_prepare(store, 0, 0, before, 6.0)
	_prepare(store, 1, 0, Vector2(-3.0, 0.0), 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[0], store.position_y[0])
	var velocity := Vector2(store.velocity_x[0], store.velocity_y[0])
	_assert_true((after - before).dot(velocity) > 0.0, "holder fixture success displacement should align with committed velocity", failures)

func _test_holder_fixture_waiting_position_and_velocity_stay_directionally_neutral(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationV4.new(grid)
	var before := Vector2(-3.0, 0.0)
	_prepare(store, 0, 0, Vector2(-1.0, 0.0), 6.0)
	_prepare(store, 1, 0, before, 6.0)
	_prepare(store, 2, 1, Vector2.ZERO, 0.0)
	store.target_id[0] = 2
	store.locked_target_id[0] = 2
	store.locked_slot_index[0] = 0
	store.contact_slot[0] = 0
	store.intent_state[0] = Types.INTENT_STATE_ATTACK
	simulation.tick_bucket_with_report(store, 0.1, 0, 1)
	var after := Vector2(store.position_x[1], store.position_y[1])
	var velocity := Vector2(store.velocity_x[1], store.velocity_y[1])
	_assert_true((after - before).dot(velocity) == 0.0, "holder fixture waiting displacement should stay neutral with zero velocity", failures)

func _test_holder_fixture_success_grid_key_tracks_committed_position(failures: Array[String]) -> void:
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
	var committed_pos := Vector2(store.position_x[0], store.position_y[0])
	_assert_eq(grid.get_cell_key(0), Vector2i(int(floor(committed_pos.x / 10.0)), int(floor(committed_pos.y / 10.0))), "success grid key should track committed position", failures)

func _test_holder_fixture_waiting_grid_key_stays_unset(failures: Array[String]) -> void:
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
	_assert_eq(grid.get_cell_key(1), null, "waiting grid key should stay unset", failures)

func _test_holder_fixture_success_grid_neighbors_include_committed_unit_after_motion(failures: Array[String]) -> void:
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
	var committed_pos := Vector2(store.position_x[0], store.position_y[0])
	_assert_true(grid.query_neighbors(committed_pos).has(0), "success grid neighbors should include committed unit after motion", failures)

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
