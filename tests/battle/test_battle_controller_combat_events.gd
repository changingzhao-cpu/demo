extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

class RecordingCombatView:
	extends RefCounted

	var attack_pulses := 0
	var hit_pulses := 0

	func bind_entity(_entity_id: int) -> void:
		pass

	func trigger_attack_pulse() -> void:
		attack_pulses += 1

	func trigger_hit_pulse() -> void:
		hit_pulses += 1

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_controller_exposes_recent_combat_event_api(failures)
	_test_controller_acquires_targets_and_moves_before_contact(failures)
	_test_attack_events_drive_bound_view_pulses(failures)
	return failures

func _test_controller_exposes_recent_combat_event_api(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("get_recent_combat_events"), "battle controller should expose recent combat events", failures)
	_assert_true(controller.has_method("consume_recent_combat_events"), "battle controller should expose a consuming combat event API", failures)
	if controller.has_method("get_recent_combat_events"):
		var events: Array = controller.call("get_recent_combat_events")
		_assert_true(events is Array, "recent combat events API should return an Array", failures)
	if controller.has_method("consume_recent_combat_events"):
		var consumed: Array = controller.call("consume_recent_combat_events")
		_assert_true(consumed is Array, "consume_recent_combat_events should return an Array", failures)
	controller.free()

func _test_controller_acquires_targets_and_moves_before_contact(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("get_entity_store"), "battle controller should expose the runtime store for target-acquisition diagnostics", failures)
	_assert_true(controller.has_method("get_live_entity_ids"), "battle controller should expose live entity ids for target-acquisition diagnostics", failures)
	if not controller.has_method("get_entity_store") or not controller.has_method("get_live_entity_ids"):
		controller.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	var saw_target_acquired := false
	var saw_movement_signal := false
	var saw_contact_signal := false
	var moved_signal_frames := 0
	var saw_advancing_runtime := false
	for _step in range(210):
		controller.call("tick_combat", 0.016)
		var report: Dictionary = controller.call("get_last_tick_report")
		if int(report.get("moved", 0)) > 0:
			saw_movement_signal = true
			moved_signal_frames += 1
		if int(report.get("advancing_count", 0)) > 0:
			saw_advancing_runtime = true
		if int(report.get("in_range", 0)) > 0 or int(report.get("combat_event_count", 0)) > 0 or int(report.get("attacked", 0)) > 0:
			saw_contact_signal = true
		if saw_target_acquired and moved_signal_frames >= 8 and (saw_contact_signal or saw_advancing_runtime):
			break
		for entity_id_variant in live_entity_ids:
			var entity_id := int(entity_id_variant)
			if int(store.target_id[entity_id]) != -1:
				saw_target_acquired = true
				break
		if saw_target_acquired and saw_movement_signal and saw_contact_signal:
			break
	_assert_true(saw_target_acquired, "battle controller should acquire at least one enemy target instead of leaving all units idle", failures)
	_assert_true(saw_movement_signal, "battle controller should produce movement signals before contact instead of remaining fully static", failures)
	_assert_true(moved_signal_frames >= 2 or saw_contact_signal, "battle controller should either show some pursuit or reach contact quickly instead of stalling", failures)
	_assert_true(saw_advancing_runtime or saw_contact_signal, "battle controller should advance toward battle after acquiring targets instead of stalling in place", failures)
	_assert_true(saw_movement_signal and saw_target_acquired, "battle controller should demonstrate real pursuit after target acquisition", failures)
	controller.free()

func _test_attack_events_drive_bound_view_pulses(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("get_live_entity_ids"), "battle controller should expose live entity ids for view pulse checks", failures)
	_assert_true(controller.has_method("register_unit_view"), "battle controller should allow binding runtime views for pulse checks", failures)
	if not controller.has_method("get_live_entity_ids") or not controller.has_method("register_unit_view"):
		controller.free()
		return
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	var views_by_entity: Dictionary = {}
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		var view := RecordingCombatView.new()
		views_by_entity[entity_id] = view
		controller.call("register_unit_view", entity_id, view)
	var saw_attack_event := false
	var saw_attack_pulse := false
	for _step in range(240):
		controller.call("tick_combat", 0.016)
		var events: Array = controller.call("get_recent_combat_events") if controller.has_method("get_recent_combat_events") else []
		if not events.is_empty():
			saw_attack_event = true
		for view in views_by_entity.values():
			if int(view.attack_pulses) > 0:
				saw_attack_pulse = true
				break
		if saw_attack_event and saw_attack_pulse:
			break
	_assert_true(saw_attack_event, "battle controller should eventually produce attack events for bound view pulse checks", failures)
	_assert_true(saw_attack_pulse, "attack events should drive at least one bound attacker pulse without relying on scene-level event consumption", failures)
	controller.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)
