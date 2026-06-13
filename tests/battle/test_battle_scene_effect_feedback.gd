extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_enemy_death_spawns_effect_feedback_in_effect_layer(failures)
	_test_effect_layer_node_count_recovers_after_combat_feedback(failures)
	_test_degradative_feedback_state_stays_observe_only_without_stress_signal(failures)
	_test_degradative_feedback_becomes_active_under_shadow_recommendation(failures)
	_test_authoritative_trial_takeover_promotes_review_signal_to_live_gate(failures)
	return failures

func _test_enemy_death_spawns_effect_feedback_in_effect_layer(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var effect_layer = instance.get_node_or_null("EffectLayer")
	if controller == null or effect_layer == null:
		failures.append("battle scene should expose controller and effect layer before effect feedback checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.queue_free()
		await main_loop.process_frame
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 1:
			store.alive[entity_id] = 0
			break
	controller.call("sync_unit_views")
	await main_loop.process_frame
	_assert_true(effect_layer.get_child_count() > 0, "battle scene should add visible effect feedback after an enemy death", failures)
	if effect_layer.get_child_count() > 0:
		var effect_node = effect_layer.get_child(0)
		_assert_true(effect_node is Node2D, "effect feedback should create a node inside EffectLayer", failures)
		_assert_true(effect_node.has_meta("team"), "effect feedback node should record which team died", failures)
		if effect_node.has_meta("team"):
			_assert_eq(str(effect_node.get_meta("team")), "enemy", "enemy death feedback should be tagged as enemy", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_effect_layer_node_count_recovers_after_combat_feedback(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var effect_layer = instance.get_node_or_null("EffectLayer")
	if controller == null or effect_layer == null:
		failures.append("battle scene should expose controller and effect layer before effect churn checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.queue_free()
		await main_loop.process_frame
		return
	controller.call("advance_debug_frames", 180, 0.016)
	for _step in range(24):
		await main_loop.process_frame
	var peak_child_count := effect_layer.get_child_count()
	for _step in range(60):
		await main_loop.process_frame
	var settled_child_count := effect_layer.get_child_count()
	_assert_true(peak_child_count > 0, "effect layer should create nodes during combat feedback", failures)
	_assert_true(settled_child_count <= peak_child_count, "effect layer node count should stabilize instead of growing forever", failures)
	_assert_true(settled_child_count <= 12, "effect layer should stay within a bounded node count after effects settle", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_degradative_feedback_state_stays_observe_only_without_stress_signal(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		failures.append("battle scene should expose controller before degradative feedback state checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.queue_free()
		await main_loop.process_frame
		return
	var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
	_assert_true(str(payload.get("feedback_mode", "")) == "observe_only", "feedback mode should default to observe_only before stress handling", failures)
	_assert_true(bool(payload.get("feedback_active", true)) == false, "feedback should stay inactive before stress handling", failures)
	_assert_true(str(payload.get("takeover_shadow_mode", "")) == "review_only", "takeover shadow mode should default to review_only", failures)
	_assert_true(bool(payload.get("takeover_shadow_ready", true)) == false, "takeover shadow should stay not ready before stress handling", failures)
	_assert_true(str(payload.get("takeover_shadow_recommendation", "")) == "hold", "takeover shadow recommendation should default to hold", failures)
	_assert_true(str(payload.get("takeover_shadow_reason", "")) == "awaiting_stable_feedback", "takeover shadow reason should default to awaiting_stable_feedback", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_degradative_feedback_becomes_active_under_shadow_recommendation(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		failures.append("battle scene should expose controller before degradative activation checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.queue_free()
		await main_loop.process_frame
		return
	controller.set("_v4_feedback_mode", "degradative")
	controller.set("_v4_feedback_active", true)
	controller.set("_v4_takeover_shadow_mode", "review_only")
	controller.set("_v4_takeover_shadow_ready", true)
	controller.set("_v4_takeover_shadow_recommendation", "degrade_only")
	controller.set("_v4_takeover_shadow_reason", "high_density_jitter_detected")
	var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
	_assert_true(str(payload.get("feedback_mode", "")) == "degradative", "feedback mode should switch to degradative during stress handling", failures)
	_assert_true(bool(payload.get("feedback_active", false)) == true, "feedback should become active under stress handling", failures)
	_assert_true(str(payload.get("takeover_shadow_recommendation", "")) == "degrade_only", "takeover shadow recommendation should promote degrade_only under stress handling", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_authoritative_trial_takeover_promotes_review_signal_to_live_gate(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		failures.append("battle scene should expose controller before authoritative trial takeover checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.queue_free()
		await main_loop.process_frame
		return
	controller.set("_v4_feedback_mode", "degradative")
	controller.set("_v4_feedback_active", true)
	controller.set("_v4_takeover_shadow_mode", "trial_gate")
	controller.set("_v4_takeover_shadow_ready", true)
	controller.set("_v4_takeover_shadow_recommendation", "trial_takeover")
	controller.set("_v4_takeover_shadow_reason", "single_decision_point_approved")
	instance.call("_process", 0.016)
	var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
	_assert_true(str(payload.get("takeover_shadow_mode", "")) == "authoritative_trial", "authoritative trial should promote takeover mode from trial_gate to authoritative_trial", failures)
	_assert_true(str(payload.get("takeover_shadow_recommendation", "")) == "authoritative_takeover", "authoritative trial should promote recommendation from trial_takeover to authoritative_takeover", failures)
	_assert_true(str(payload.get("takeover_shadow_reason", "")) == "single_decision_point_live", "authoritative trial should mark the live single decision point reason", failures)
	var battle_report_timeline: Array = controller.call("get_battle_report_timeline")
	_assert_true(battle_report_timeline.size() > 0, "authoritative trial should keep battle_report_timeline available for business-side advisory consumption", failures)
	if battle_report_timeline.size() > 0:
		var first_timeline_event: Dictionary = battle_report_timeline[0]
		_assert_true(first_timeline_event.has("event_type"), "battle_report_timeline entries should expose event_type during authoritative trial", failures)
	var events: Array = payload.get("business_probe_events", [])
	var found_live_takeover := false
	for event_variant in events:
		var event: Dictionary = event_variant
		if str(event.get("event_type", "")) == "takeover_trial_applied":
			found_live_takeover = str(event.get("takeover_shadow_mode", "")) == "authoritative_trial" and str(event.get("recommendation", "")) == "authoritative_takeover"
			break
	_assert_true(found_live_takeover, "authoritative trial should emit takeover_trial_applied when the live gate is entered", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
