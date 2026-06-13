extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const OUTPUT_PATH := "user://runtime_probe.json"
const SAMPLE_TIMES := [0.0, 0.01, 0.03, 0.05, 0.1, 0.2, 0.5, 1.0, 1.1, 1.2, 1.25, 1.3, 1.4, 1.5, 1.6, 1.8, 2.0, 2.2, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 16.0, 20.0]
const INITIAL_PROBE := "user://transition_initial_probe.json"
const RUNTIME_PROBE := "user://transition_runtime_probe.json"
const WARNING_ARTIFACT_PATH := "user://warning_sampling.json"
const CRITICAL_ARTIFACT_PATH := "user://critical_sampling.json"
const FOCUS_ENTITY_IDS := [3, 14, 30, 38]

func _read_unified_snapshot_summary(path: String) -> Dictionary:
	var payload := _read_json(path)
	if payload.is_empty():
		return {}
	var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
	return {
		"family": str(unified_snapshot.get("family", "")),
		"takeover_ready": bool(unified_snapshot.get("takeover_ready", false)),
		"sample_count": int(unified_snapshot.get("sample_count", 0)),
		"confidence_score": float(unified_snapshot.get("confidence_score", -1.0)),
		"thresholds": unified_snapshot.get("thresholds", {}),
		"support_counts": unified_snapshot.get("support_counts", {}),
		"blockers": unified_snapshot.get("blockers", [])
	}

func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data

func _parse_vector2(value) -> Vector2:
	if value is Vector2:
		return value
	var text := str(value)
	var match := RegEx.create_from_string("\\(([-0-9.]+), ([-0-9.]+)\\)").search(text)
	if match == null:
		return Vector2.ZERO
	return Vector2(match.get_string(1).to_float(), match.get_string(2).to_float())

func _build_nearby_events(entity_id: int, start_time: float, end_time: float, battle_report_timeline: Array) -> Array:
	var nearby_events: Array = []
	for event_variant in battle_report_timeline:
		var event: Dictionary = event_variant
		if int(event.get("entity_id", -1)) != entity_id:
			continue
		var event_time := float(event.get("time", -1.0))
		if event_time + 0.05 < start_time or event_time - 0.05 > end_time:
			continue
		nearby_events.append({
			"time": event_time,
			"event_type": str(event.get("event_type", "")),
			"target_id": int(event.get("target_id", -1)),
			"previous_target_id": int(event.get("previous_target_id", -1)),
			"engagement_slot": int(event.get("engagement_slot", -1)),
			"previous_engagement_slot": int(event.get("previous_engagement_slot", -1))
		})
	return nearby_events

func _is_attack_sample_eligible(entity_id: int, previous: Dictionary, current: Dictionary, battle_report_timeline: Array) -> bool:
	if str(current.get("state_name", "")) != "ATTACK":
		return false
	if int(current.get("target_id", -1)) == -1:
		return false
	if int(current.get("engagement_slot", -1)) == -1:
		return false
	var nearby_events := _build_nearby_events(entity_id, float(current.get("time", 0.0)) - 0.05, float(current.get("time", 0.0)) + 0.05, battle_report_timeline)
	for nearby_event_variant in nearby_events:
		var nearby_event: Dictionary = nearby_event_variant
		var event_type := str(nearby_event.get("event_type", ""))
		if event_type == "target_changed" or event_type == "slot_changed" or event_type == "move_started":
			return false
	var previous_position := _parse_vector2(previous.get("position", Vector2.ZERO))
	var current_position := _parse_vector2(current.get("position", Vector2.ZERO))
	return previous_position.distance_to(current_position) <= 0.15

func _build_anomaly_scan(trajectories: Dictionary, battle_report_timeline: Array) -> Dictionary:
	var position_jumps: Array = []
	var spiral_drifts: Array = []
	var high_frequency_jitters: Array = []
	var attack_rebind_escapes: Array = []
	var attack_rebind_recontacts: Array = []
	var attack_midband_drifts: Array = []
	for entity_id_key in trajectories.keys():
		var entity_id := int(entity_id_key)
		var points: Array = trajectories.get(entity_id_key, [])
		var attack_distances: Array = []
		var jitter_window: Array = []
		for index in range(1, points.size()):
			var previous: Dictionary = points[index - 1]
			var current: Dictionary = points[index]
			var previous_position := _parse_vector2(previous.get("position", Vector2.ZERO))
			var current_position := _parse_vector2(current.get("position", Vector2.ZERO))
			var distance := previous_position.distance_to(current_position)
			var dt := maxf(0.001, float(current.get("time", 0.0)) - float(previous.get("time", 0.0)))
			var speed := distance / dt
			if distance >= 8.0 and speed >= 25.0:
				position_jumps.append({
					"entity_id": entity_id,
					"start_time": float(previous.get("time", 0.0)),
					"end_time": float(current.get("time", 0.0)),
					"distance": distance,
					"speed": speed,
					"from_position": previous.get("position", Vector2.ZERO),
					"to_position": current.get("position", Vector2.ZERO),
					"from_state": str(previous.get("state_name", "")),
					"to_state": str(current.get("state_name", "")),
					"from_target_id": int(previous.get("target_id", -1)),
					"to_target_id": int(current.get("target_id", -1)),
					"from_slot": int(previous.get("engagement_slot", -1)),
					"to_slot": int(current.get("engagement_slot", -1)),
					"nearby_events": _build_nearby_events(entity_id, float(previous.get("time", 0.0)), float(current.get("time", 0.0)), battle_report_timeline)
				})
			if distance >= 0.2 and distance <= 3.0 and dt >= 0.9:
				spiral_drifts.append({
					"entity_id": entity_id,
					"start_time": float(previous.get("time", 0.0)),
					"end_time": float(current.get("time", 0.0)),
					"distance": distance,
					"speed": speed,
					"from_position": previous.get("position", Vector2.ZERO),
					"to_position": current.get("position", Vector2.ZERO),
					"state": str(current.get("state_name", "")),
					"target_id": int(current.get("target_id", -1)),
					"engagement_slot": int(current.get("engagement_slot", -1))
				})
			jitter_window.append({"distance": distance, "time": float(current.get("time", 0.0)), "state": str(current.get("state_name", ""))})
			if jitter_window.size() > 4:
				jitter_window.pop_front()
			if jitter_window.size() == 4:
				var jitter_count := 0
				for jitter_sample in jitter_window:
					if float(jitter_sample.get("distance", 0.0)) >= 0.15 and float(jitter_sample.get("distance", 0.0)) <= 1.2:
						jitter_count += 1
				if jitter_count >= 4:
					high_frequency_jitters.append({
						"entity_id": entity_id,
						"end_time": float(current.get("time", 0.0)),
						"samples": jitter_window.duplicate(true),
						"state": str(current.get("state_name", "")),
						"target_id": int(current.get("target_id", -1))
					})
			if _is_attack_sample_eligible(entity_id, previous, current, battle_report_timeline):
				var target_points: Array = trajectories.get(str(int(current.get("target_id", -1))), [])
				var target_snapshot: Dictionary = {}
				for target_point_variant in target_points:
					var target_point: Dictionary = target_point_variant
					if absf(float(target_point.get("time", -999.0)) - float(current.get("time", 0.0))) < 0.001:
						target_snapshot = target_point
						break
				if not target_snapshot.is_empty():
					var target_position := _parse_vector2(target_snapshot.get("position", Vector2.ZERO))
					attack_distances.append({
						"time": float(current.get("time", 0.0)),
						"distance": current_position.distance_to(target_position),
						"slot": int(current.get("engagement_slot", -1)),
						"target_id": int(current.get("target_id", -1))
					})
		if attack_distances.size() >= 3:
			for index in range(1, attack_distances.size()):
				var previous_attack: Dictionary = attack_distances[index - 1]
				var current_attack: Dictionary = attack_distances[index]
				var from_distance := float(previous_attack.get("distance", 0.0))
				var to_distance := float(current_attack.get("distance", 0.0))
				if absf(to_distance - from_distance) >= 1.0:
					var sample := {
						"entity_id": entity_id,
						"start_time": float(previous_attack.get("time", 0.0)),
						"end_time": float(current_attack.get("time", 0.0)),
						"from_distance": from_distance,
						"to_distance": to_distance,
						"target_id": int(current_attack.get("target_id", -1)),
						"slot": int(current_attack.get("slot", -1))
					}
					if from_distance < 1.5 and to_distance > 2.5:
						attack_rebind_escapes.append(sample)
					elif from_distance > 2.5 and to_distance < 2.5:
						attack_rebind_recontacts.append(sample)
					else:
						attack_midband_drifts.append(sample)
	attack_rebind_escapes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return absf(float(a.get("to_distance", 0.0)) - float(a.get("from_distance", 0.0))) > absf(float(b.get("to_distance", 0.0)) - float(b.get("from_distance", 0.0)))
	)
	attack_rebind_recontacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return absf(float(a.get("to_distance", 0.0)) - float(a.get("from_distance", 0.0))) > absf(float(b.get("to_distance", 0.0)) - float(b.get("from_distance", 0.0)))
	)
	attack_midband_drifts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return absf(float(a.get("to_distance", 0.0)) - float(a.get("from_distance", 0.0))) > absf(float(b.get("to_distance", 0.0)) - float(b.get("from_distance", 0.0)))
	)
	position_jumps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("speed", 0.0)) > float(b.get("speed", 0.0))
	)
	spiral_drifts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 0.0)) > float(b.get("distance", 0.0))
	)
	high_frequency_jitters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("end_time", 0.0)) < float(b.get("end_time", 0.0))
	)
	return {
		"position_jump_count": position_jumps.size(),
		"position_jumps": position_jumps.slice(0, mini(50, position_jumps.size())),
		"spiral_drift_count": spiral_drifts.size(),
		"spiral_drifts": spiral_drifts.slice(0, mini(50, spiral_drifts.size())),
		"high_frequency_jitter_count": high_frequency_jitters.size(),
		"high_frequency_jitters": high_frequency_jitters.slice(0, mini(50, high_frequency_jitters.size())),
		"attack_rebind_escape_count": attack_rebind_escapes.size(),
		"attack_rebind_escapes": attack_rebind_escapes.slice(0, mini(50, attack_rebind_escapes.size())),
		"attack_rebind_recontact_count": attack_rebind_recontacts.size(),
		"attack_rebind_recontacts": attack_rebind_recontacts.slice(0, mini(50, attack_rebind_recontacts.size())),
		"attack_midband_drift_count": attack_midband_drifts.size(),
		"attack_midband_drifts": attack_midband_drifts.slice(0, mini(50, attack_midband_drifts.size()))
	}

func _initialize() -> void:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		printerr("[PROBE] failed to load battle scene")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller != null and controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	var samples: Array = []
	var trajectories: Dictionary = {}
	var elapsed := 0.0
	var sample_index := 0
	while sample_index < SAMPLE_TIMES.size():
		var target_time := float(SAMPLE_TIMES[sample_index])
		if elapsed + 0.0001 < target_time:
			var step := minf(0.01, target_time - elapsed)
			await create_timer(step).timeout
			elapsed += step
			continue
		var unit_layer := instance.get_node_or_null("UnitLayer")
		var tracked_entities: Dictionary = {}
		for tracked_id in range(0, 64):
			var entity_payload: Dictionary = controller.call("debug_get_entity_diagnostic", tracked_id) if controller != null and controller.has_method("debug_get_entity_diagnostic") else {"entity_id": tracked_id, "exists": false}
			var entity_view_snapshot: Dictionary = {}
			var entity_target_payload: Dictionary = {}
			var entity_target_target_payload: Dictionary = {}
			var target_id := int(entity_payload.get("target_id", -1))
			if target_id >= 0 and controller != null and controller.has_method("debug_get_entity_diagnostic"):
				entity_target_payload = controller.call("debug_get_entity_diagnostic", target_id)
				var target_target_id := int(entity_target_payload.get("target_id", -1))
				if target_target_id >= 0:
					entity_target_target_payload = controller.call("debug_get_entity_diagnostic", target_target_id)
			if unit_layer != null:
				for child in unit_layer.get_children():
					if child.has_method("get_entity_id") and int(child.call("get_entity_id")) == tracked_id:
						entity_view_snapshot = {
							"visible": child.visible,
							"global_position": child.global_position,
							"sprite": child.call("debug_get_sprite_snapshot") if child.has_method("debug_get_sprite_snapshot") else {},
							"pose": child.call("debug_get_pose_snapshot") if child.has_method("debug_get_pose_snapshot") else {}
						}
						break
			if FOCUS_ENTITY_IDS.has(tracked_id):
				tracked_entities[str(tracked_id)] = {
					"controller": {
						"entity_id": tracked_id,
						"exists": bool(entity_payload.get("exists", false)),
						"state_name": entity_payload.get("state_name", ""),
						"target_id": int(entity_payload.get("target_id", -1)),
						"engagement_slot": int(entity_payload.get("engagement_slot", -1)),
						"position": entity_payload.get("position", Vector2.ZERO),
						"velocity": entity_payload.get("velocity", Vector2.ZERO)
					},
					"target": entity_target_payload,
					"target_target": entity_target_target_payload,
					"view": entity_view_snapshot
				}
			if bool(entity_payload.get("exists", false)):
				var trajectory_key := str(tracked_id)
				var points: Array = trajectories.get(trajectory_key, [])
				points.append({
					"time": elapsed,
					"state_name": entity_payload.get("state_name", ""),
					"target_id": int(entity_payload.get("target_id", -1)),
					"engagement_slot": int(entity_payload.get("engagement_slot", -1)),
					"position": entity_payload.get("position", Vector2.ZERO),
					"velocity": entity_payload.get("velocity", Vector2.ZERO)
				})
				trajectories[trajectory_key] = points
		samples.append({
			"time": elapsed,
			"tracked_entities": tracked_entities
		})
		sample_index += 1
	var attack_times: Dictionary = controller.call("debug_get_first_attack_times") if controller != null and controller.has_method("debug_get_first_attack_times") else {}
	var battle_report_timeline: Array = controller.call("get_battle_report_timeline") if controller != null and controller.has_method("get_battle_report_timeline") else []
	var runtime_trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller != null and controller.has_method("debug_get_runtime_trace_payload") else {}
	var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
	var output := {
		"samples": samples,
		"trajectories": trajectories,
		"battle_report_timeline": battle_report_timeline,
		"anomaly_scan": anomaly_scan,
		"v4_probe": runtime_trace_payload.get("probe", {}),
		"v4_probe_fingerprint": {},
		"warning_unified_snapshot": _read_unified_snapshot_summary(WARNING_ARTIFACT_PATH),
		"critical_unified_snapshot": _read_unified_snapshot_summary(CRITICAL_ARTIFACT_PATH),
		"initial_probe": FileAccess.get_file_as_string(INITIAL_PROBE),
		"runtime_probe": FileAccess.get_file_as_string(RUNTIME_PROBE),
		"first_attack_times": attack_times
	}

	if output.get("warning_unified_snapshot", {}).is_empty():
		printerr("[PROBE] missing warning unified snapshot summary")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).is_empty():
		printerr("[PROBE] missing critical unified snapshot summary")
		quit(1)
		return
	if str(output.get("warning_unified_snapshot", {}).get("family", "")) != "warning":
		printerr("[PROBE] invalid warning unified snapshot family: %s" % JSON.stringify(output.get("warning_unified_snapshot", {})))
		quit(1)
		return
	if str(output.get("critical_unified_snapshot", {}).get("family", "")) != "critical":
		printerr("[PROBE] invalid critical unified snapshot family: %s" % JSON.stringify(output.get("critical_unified_snapshot", {})))
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("confidence_score"):
		printerr("[PROBE] missing warning unified snapshot confidence_score")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("confidence_score"):
		printerr("[PROBE] missing critical unified snapshot confidence_score")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("thresholds"):
		printerr("[PROBE] missing warning unified snapshot thresholds")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("thresholds"):
		printerr("[PROBE] missing critical unified snapshot thresholds")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("support_counts"):
		printerr("[PROBE] missing warning unified snapshot support_counts")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("support_counts"):
		printerr("[PROBE] missing critical unified snapshot support_counts")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("blockers"):
		printerr("[PROBE] missing warning unified snapshot blockers")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("blockers"):
		printerr("[PROBE] missing critical unified snapshot blockers")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("gate_results"):
		printerr("[PROBE] missing warning unified snapshot gate_results")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("gate_results"):
		printerr("[PROBE] missing critical unified snapshot gate_results")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("confidence_score", -1.0)) < 0.0 or float(output.get("warning_unified_snapshot", {}).get("confidence_score", -1.0)) > 1.0:
		printerr("[PROBE] warning unified snapshot confidence_score out of range")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("confidence_score", -1.0)) < 0.0 or float(output.get("critical_unified_snapshot", {}).get("confidence_score", -1.0)) > 1.0:
		printerr("[PROBE] critical unified snapshot confidence_score out of range")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("blockers", []) is Array:
		printerr("[PROBE] warning unified snapshot blockers should be an array")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("blockers", []) is Array:
		printerr("[PROBE] critical unified snapshot blockers should be an array")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("support_counts", {}) is Dictionary:
		printerr("[PROBE] warning unified snapshot support_counts should be a dictionary")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("support_counts", {}) is Dictionary:
		printerr("[PROBE] critical unified snapshot support_counts should be a dictionary")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}) is Dictionary:
		printerr("[PROBE] warning unified snapshot thresholds should be a dictionary")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}) is Dictionary:
		printerr("[PROBE] critical unified snapshot thresholds should be a dictionary")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}) is Dictionary:
		printerr("[PROBE] warning unified snapshot gate_results should be a dictionary")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}) is Dictionary:
		printerr("[PROBE] critical unified snapshot gate_results should be a dictionary")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("sample_count", 0)) <= 0:
		printerr("[PROBE] warning unified snapshot sample_count should be positive")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("sample_count", 0)) <= 0:
		printerr("[PROBE] critical unified snapshot sample_count should be positive")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("takeover_ready"):
		printerr("[PROBE] warning unified snapshot missing takeover_ready")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("takeover_ready"):
		printerr("[PROBE] critical unified snapshot missing takeover_ready")
		quit(1)
		return
	if bool(output.get("warning_unified_snapshot", {}).get("takeover_ready", false)) != bool(output.get("warning_unified_snapshot", {}).get("gate_results", {}).get("takeover_ready", true)):
		printerr("[PROBE] warning unified snapshot takeover_ready mismatch")
		quit(1)
		return
	if bool(output.get("critical_unified_snapshot", {}).get("takeover_ready", false)) != bool(output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("takeover_ready", true)):
		printerr("[PROBE] critical unified snapshot takeover_ready mismatch")
		quit(1)
		return
	if str(output.get("warning_unified_snapshot", {}).get("family", "")) == str(output.get("critical_unified_snapshot", {}).get("family", "")):
		printerr("[PROBE] unified snapshot families should differ across warning and critical")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("thresholds", {}).is_empty():
		printerr("[PROBE] warning unified snapshot thresholds should not be empty")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("thresholds", {}).is_empty():
		printerr("[PROBE] critical unified snapshot thresholds should not be empty")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("support_counts", {}).is_empty():
		printerr("[PROBE] warning unified snapshot support_counts should not be empty")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("support_counts", {}).is_empty():
		printerr("[PROBE] critical unified snapshot support_counts should not be empty")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_threshold_value"):
		printerr("[PROBE] warning unified snapshot missing warning_threshold_value")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("warning_threshold_value"):
		printerr("[PROBE] critical unified snapshot missing warning_threshold_value")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("error_threshold_value"):
		printerr("[PROBE] critical unified snapshot missing error_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("support_counts", {}).has("nonzero_scenario_count"):
		printerr("[PROBE] warning unified snapshot missing nonzero_scenario_count")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("support_counts", {}).has("old_escape_true_count"):
		printerr("[PROBE] critical unified snapshot missing old_escape_true_count")
		quit(1)
		return
	if (output.get("warning_unified_snapshot", {}).get("blockers", []) as Array).size() != 0:
		printerr("[PROBE] warning unified snapshot blockers should be empty")
		quit(1)
		return
	if (output.get("critical_unified_snapshot", {}).get("blockers", []) as Array).size() != (output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("takeover_blockers", []) as Array).size():
		printerr("[PROBE] critical unified snapshot blockers should mirror gate_results.takeover_blockers")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("support_counts", {}).get("nonzero_scenario_count", 0)) <= 0:
		printerr("[PROBE] warning unified snapshot nonzero_scenario_count should be positive")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("support_counts", {}).get("old_escape_true_count", -1)) < 0:
		printerr("[PROBE] critical unified snapshot old_escape_true_count should be non-negative")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_upper_threshold_value", 0.0)) <= float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", 0.0)):
		printerr("[PROBE] warning unified snapshot upper threshold should exceed center threshold")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", 0.0)) <= float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_lower_threshold_value", 0.0)):
		printerr("[PROBE] warning unified snapshot center threshold should exceed lower threshold")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("error_threshold_value", -1.0)) < float(output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", -2.0)):
		printerr("[PROBE] critical unified snapshot error threshold should not be below warning threshold")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("sample_count"):
		printerr("[PROBE] warning unified snapshot gate_results missing sample_count")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("sample_count"):
		printerr("[PROBE] critical unified snapshot gate_results missing sample_count")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("sample_count", -1)) != int(output.get("warning_unified_snapshot", {}).get("gate_results", {}).get("sample_count", -2)):
		printerr("[PROBE] warning unified snapshot sample_count should mirror gate_results.sample_count")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("sample_count", -1)) != int(output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("sample_count", -2)):
		printerr("[PROBE] critical unified snapshot sample_count should mirror gate_results.sample_count")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("confidence_score", -1.0)) <= float(output.get("critical_unified_snapshot", {}).get("confidence_score", -1.0)):
		printerr("[PROBE] warning confidence_score should exceed critical confidence_score in current fixtures")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_upper_threshold_value"):
		printerr("[PROBE] warning unified snapshot missing warning_upper_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_lower_threshold_value"):
		printerr("[PROBE] warning unified snapshot missing warning_lower_threshold_value")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("warning_upper_threshold_value"):
		printerr("[PROBE] critical unified snapshot should not expose warning_upper_threshold_value")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("warning_lower_threshold_value"):
		printerr("[PROBE] critical unified snapshot should not expose warning_lower_threshold_value")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("critical_hit_rate"):
		printerr("[PROBE] critical unified snapshot gate_results missing critical_hit_rate")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("fast_false_positive_rate"):
		printerr("[PROBE] critical unified snapshot gate_results missing fast_false_positive_rate")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("gate_c_no_false_positive_records"):
		printerr("[PROBE] critical unified snapshot gate_results missing gate_c_no_false_positive_records")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_band_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results missing gate_b_warning_band_ordering")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_clumping_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results missing gate_b_warning_clumping_ordering")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_latency_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results missing gate_b_warning_latency_ordering")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_overlap_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results missing gate_b_warning_overlap_ordering")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("takeover_blockers"):
		printerr("[PROBE] critical unified snapshot gate_results missing takeover_blockers")
		quit(1)
		return
	if (output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("takeover_blockers", []) as Array).size() < 0:
		printerr("[PROBE] critical unified snapshot takeover_blockers size invalid")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("support_counts", {}).has("nonzero_scenario_count"):
		printerr("[PROBE] warning unified snapshot support_counts missing nonzero_scenario_count")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("support_counts", {}).has("old_escape_true_count"):
		printerr("[PROBE] critical unified snapshot support_counts missing old_escape_true_count")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_threshold_value"):
		printerr("[PROBE] warning unified snapshot thresholds missing warning_threshold_value")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("warning_threshold_value"):
		printerr("[PROBE] critical unified snapshot thresholds missing warning_threshold_value")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("error_threshold_value"):
		printerr("[PROBE] critical unified snapshot thresholds missing error_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_upper_threshold_value"):
		printerr("[PROBE] warning unified snapshot thresholds missing warning_upper_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_lower_threshold_value"):
		printerr("[PROBE] warning unified snapshot thresholds missing warning_lower_threshold_value")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("thresholds", {}).size() < 3:
		printerr("[PROBE] warning unified snapshot thresholds should contain 3 warning band fields")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("thresholds", {}).size() < 2:
		printerr("[PROBE] critical unified snapshot thresholds should contain warning/error fields")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("support_counts", {}).size() < 1:
		printerr("[PROBE] warning unified snapshot support_counts should contain at least one field")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("support_counts", {}).size() < 1:
		printerr("[PROBE] critical unified snapshot support_counts should contain at least one field")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("gate_results", {}).is_empty():
		printerr("[PROBE] warning unified snapshot gate_results should not be empty")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("gate_results", {}).is_empty():
		printerr("[PROBE] critical unified snapshot gate_results should not be empty")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("family", "") == "":
		printerr("[PROBE] warning unified snapshot family should not be empty")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("family", "") == "":
		printerr("[PROBE] critical unified snapshot family should not be empty")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("sample_count"):
		printerr("[PROBE] warning unified snapshot missing sample_count")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("sample_count"):
		printerr("[PROBE] critical unified snapshot missing sample_count")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("sample_count", -1)) < 1:
		printerr("[PROBE] warning unified snapshot sample_count invalid")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("sample_count", -1)) < 1:
		printerr("[PROBE] critical unified snapshot sample_count invalid")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("takeover_ready"):
		printerr("[PROBE] warning unified snapshot missing takeover_ready")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("takeover_ready"):
		printerr("[PROBE] critical unified snapshot missing takeover_ready")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("family"):
		printerr("[PROBE] warning unified snapshot missing family")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("family"):
		printerr("[PROBE] critical unified snapshot missing family")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("confidence_score"):
		printerr("[PROBE] warning unified snapshot missing confidence_score")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("confidence_score"):
		printerr("[PROBE] critical unified snapshot missing confidence_score")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("thresholds"):
		printerr("[PROBE] warning unified snapshot missing thresholds")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("thresholds"):
		printerr("[PROBE] critical unified snapshot missing thresholds")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("support_counts"):
		printerr("[PROBE] warning unified snapshot missing support_counts")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("support_counts"):
		printerr("[PROBE] critical unified snapshot missing support_counts")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("blockers"):
		printerr("[PROBE] warning unified snapshot missing blockers")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("blockers"):
		printerr("[PROBE] critical unified snapshot missing blockers")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).has("gate_results"):
		printerr("[PROBE] warning unified snapshot missing gate_results")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).has("gate_results"):
		printerr("[PROBE] critical unified snapshot missing gate_results")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).is_empty():
		printerr("[PROBE] warning unified snapshot should not be empty")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).is_empty():
		printerr("[PROBE] critical unified snapshot should not be empty")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("gate_results", {}).size() < 1:
		printerr("[PROBE] warning unified snapshot gate_results should contain fields")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("gate_results", {}).size() < 1:
		printerr("[PROBE] critical unified snapshot gate_results should contain fields")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("thresholds", {}).size() < 1:
		printerr("[PROBE] warning unified snapshot thresholds should contain fields")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("thresholds", {}).size() < 1:
		printerr("[PROBE] critical unified snapshot thresholds should contain fields")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("support_counts", {}).size() < 1:
		printerr("[PROBE] warning unified snapshot support_counts should contain fields")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("support_counts", {}).size() < 1:
		printerr("[PROBE] critical unified snapshot support_counts should contain fields")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("blockers", []).size() < 0:
		printerr("[PROBE] warning unified snapshot blockers size invalid")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("blockers", []).size() < 0:
		printerr("[PROBE] critical unified snapshot blockers size invalid")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("sample_count"):
		printerr("[PROBE] warning unified snapshot gate_results missing sample_count field")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("sample_count"):
		printerr("[PROBE] critical unified snapshot gate_results missing sample_count field")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("gate_results", {}).get("sample_count", -1)) < 1:
		printerr("[PROBE] warning unified snapshot gate_results sample_count invalid")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("sample_count", -1)) < 1:
		printerr("[PROBE] critical unified snapshot gate_results sample_count invalid")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("confidence_score", -1.0)) == -1.0:
		printerr("[PROBE] warning unified snapshot confidence_score missing numeric value")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("confidence_score", -1.0)) == -1.0:
		printerr("[PROBE] critical unified snapshot confidence_score missing numeric value")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("family", "") != "warning":
		printerr("[PROBE] warning unified snapshot family mismatch")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("family", "") != "critical":
		printerr("[PROBE] critical unified snapshot family mismatch")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("support_counts", {}).get("nonzero_scenario_count", -1)) != 3:
		printerr("[PROBE] warning unified snapshot nonzero_scenario_count should be 3 for current fixture")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("confidence_score", -1.0)) != 1.0:
		printerr("[PROBE] warning unified snapshot confidence_score should be 1.0 for current fixture")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("confidence_score", -1.0)) != 0.0:
		printerr("[PROBE] critical unified snapshot confidence_score should be 0.0 for current fixture")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("sample_count", -1)) != 20:
		printerr("[PROBE] critical unified snapshot sample_count should be 20 for current fixture")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("sample_count", -1)) != 50:
		printerr("[PROBE] warning unified snapshot sample_count should be 50 for current fixture")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("takeover_blockers"):
		printerr("[PROBE] critical unified snapshot gate_results should include takeover_blockers")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("old_escape_hit_records"):
		printerr("[PROBE] critical unified snapshot gate_results should include old_escape_hit_records")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("false_positive_records"):
		printerr("[PROBE] critical unified snapshot gate_results should include false_positive_records")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("critical_hit_rate"):
		printerr("[PROBE] critical unified snapshot gate_results should include critical_hit_rate")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("fast_false_positive_rate"):
		printerr("[PROBE] critical unified snapshot gate_results should include fast_false_positive_rate")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_band_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results should include gate_b_warning_band_ordering")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_overlap_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results should include gate_b_warning_overlap_ordering")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_clumping_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results should include gate_b_warning_clumping_ordering")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("gate_b_warning_latency_ordering"):
		printerr("[PROBE] warning unified snapshot gate_results should include gate_b_warning_latency_ordering")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("warning_threshold_value"):
		printerr("[PROBE] critical unified snapshot thresholds should include warning_threshold_value")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).has("error_threshold_value"):
		printerr("[PROBE] critical unified snapshot thresholds should include error_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_upper_threshold_value"):
		printerr("[PROBE] warning unified snapshot thresholds should include warning_upper_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_threshold_value"):
		printerr("[PROBE] warning unified snapshot thresholds should include warning_threshold_value")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).has("warning_lower_threshold_value"):
		printerr("[PROBE] warning unified snapshot thresholds should include warning_lower_threshold_value")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_upper_threshold_value", -1.0)) <= 0.0:
		printerr("[PROBE] warning unified snapshot upper threshold should be positive")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", -1.0)) < 0.0:
		printerr("[PROBE] critical unified snapshot warning threshold should be non-negative")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("error_threshold_value", -1.0)) < 0.0:
		printerr("[PROBE] critical unified snapshot error threshold should be non-negative")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("takeover_ready"):
		printerr("[PROBE] warning unified snapshot gate_results should include takeover_ready")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("takeover_ready"):
		printerr("[PROBE] critical unified snapshot gate_results should include takeover_ready")
		quit(1)
		return
	if (output.get("warning_unified_snapshot", {}).get("blockers", []) as Array).is_empty() == false:
		printerr("[PROBE] warning unified snapshot blockers should remain empty")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("support_counts", {}).get("old_escape_true_count", -1)) != int(output.get("critical_unified_snapshot", {}).get("support_counts", {}).get("old_escape_true_count", -1)):
		printerr("[PROBE] critical unified snapshot old_escape_true_count should be stable")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("support_counts", {}).get("nonzero_scenario_count", -1)) != int(output.get("warning_unified_snapshot", {}).get("support_counts", {}).get("nonzero_scenario_count", -1)):
		printerr("[PROBE] warning unified snapshot nonzero_scenario_count should be stable")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("thresholds", {}).size() != 3:
		printerr("[PROBE] warning unified snapshot should expose exactly 3 threshold fields")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("thresholds", {}).size() != 2:
		printerr("[PROBE] critical unified snapshot should expose exactly 2 threshold fields")
		quit(1)
		return
	if output.get("warning_unified_snapshot", {}).get("support_counts", {}).size() != 1:
		printerr("[PROBE] warning unified snapshot should expose exactly 1 support count field")
		quit(1)
		return
	if output.get("critical_unified_snapshot", {}).get("support_counts", {}).size() != 1:
		printerr("[PROBE] critical unified snapshot should expose exactly 1 support count field")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("sample_count"):
		printerr("[PROBE] warning unified snapshot gate_results should include sample_count")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("sample_count"):
		printerr("[PROBE] critical unified snapshot gate_results should include sample_count")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("gate_results", {}).get("sample_count", -1)) != 50:
		printerr("[PROBE] warning unified snapshot gate_results sample_count should be 50")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("sample_count", -1)) != 20:
		printerr("[PROBE] critical unified snapshot gate_results sample_count should be 20")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("gate_a_critical_hit_rate"):
		printerr("[PROBE] critical unified snapshot gate_results should include gate_a_critical_hit_rate")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("gate_b_fast_false_positive_rate"):
		printerr("[PROBE] critical unified snapshot gate_results should include gate_b_fast_false_positive_rate")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("gate_c_no_false_positive_records"):
		printerr("[PROBE] critical unified snapshot gate_results should include gate_c_no_false_positive_records")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).has("takeover_ready"):
		printerr("[PROBE] warning unified snapshot gate_results should include takeover_ready")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).has("takeover_ready"):
		printerr("[PROBE] critical unified snapshot gate_results should include takeover_ready")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("blockers", []) is Array:
		printerr("[PROBE] warning unified snapshot blockers should be array type")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("blockers", []) is Array:
		printerr("[PROBE] critical unified snapshot blockers should be array type")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("support_counts", {}) is Dictionary:
		printerr("[PROBE] warning unified snapshot support_counts should be dictionary type")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("support_counts", {}) is Dictionary:
		printerr("[PROBE] critical unified snapshot support_counts should be dictionary type")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}) is Dictionary:
		printerr("[PROBE] warning unified snapshot thresholds should be dictionary type")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}) is Dictionary:
		printerr("[PROBE] critical unified snapshot thresholds should be dictionary type")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}) is Dictionary:
		printerr("[PROBE] warning unified snapshot gate_results should be dictionary type")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}) is Dictionary:
		printerr("[PROBE] critical unified snapshot gate_results should be dictionary type")
		quit(1)
		return
	if int(output.get("warning_unified_snapshot", {}).get("sample_count", 0)) != 50:
		printerr("[PROBE] warning unified snapshot sample_count should remain 50")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("sample_count", 0)) != 20:
		printerr("[PROBE] critical unified snapshot sample_count should remain 20")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("confidence_score", -1.0)) != 1.0:
		printerr("[PROBE] warning unified snapshot confidence_score should remain 1.0")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("confidence_score", -1.0)) != 0.0:
		printerr("[PROBE] critical unified snapshot confidence_score should remain 0.0")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", {}).get("takeover_ready", false):
		printerr("[PROBE] warning unified snapshot should remain takeover ready")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("takeover_ready", false):
		printerr("[PROBE] critical unified snapshot should remain takeover ready")
		quit(1)
		return
	if int(output.get("critical_unified_snapshot", {}).get("support_counts", {}).get("old_escape_true_count", -1)) != 0:
		printerr("[PROBE] critical unified snapshot old_escape_true_count should remain 0 for current fixture")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", -1.0)) != 0.0:
		printerr("[PROBE] critical unified snapshot warning_threshold_value should remain 0.0 for current fixture")
		quit(1)
		return
	if float(output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("error_threshold_value", -1.0)) != 0.0:
		printerr("[PROBE] critical unified snapshot error_threshold_value should remain 0.0 for current fixture")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", -1.0)) <= 0.0:
		printerr("[PROBE] warning unified snapshot warning_threshold_value should remain positive")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_lower_threshold_value", -1.0)) <= 0.0:
		printerr("[PROBE] warning unified snapshot warning_lower_threshold_value should remain positive")
		quit(1)
		return
	if float(output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_upper_threshold_value", -1.0)) <= 0.0:
		printerr("[PROBE] warning unified snapshot warning_upper_threshold_value should remain positive")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("takeover_blockers", []) is Array:
		printerr("[PROBE] critical unified snapshot takeover_blockers should be an array")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("old_escape_hit_records", []) is Array:
		printerr("[PROBE] critical unified snapshot old_escape_hit_records should be an array")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("false_positive_records", []) is Array:
		printerr("[PROBE] critical unified snapshot false_positive_records should be an array")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("critical_hit_rate", null) is float and not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("critical_hit_rate", null) is int:
		printerr("[PROBE] critical unified snapshot critical_hit_rate should be numeric")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("fast_false_positive_rate", null) is float and not output.get("critical_unified_snapshot", {}).get("gate_results", {}).get("fast_false_positive_rate", null) is int:
		printerr("[PROBE] critical unified snapshot fast_false_positive_rate should be numeric")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("support_counts", {}).get("nonzero_scenario_count", null) is int:
		printerr("[PROBE] warning unified snapshot nonzero_scenario_count should be int")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("support_counts", {}).get("old_escape_true_count", null) is int:
		printerr("[PROBE] critical unified snapshot old_escape_true_count should be int")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("sample_count", null) is int:
		printerr("[PROBE] warning unified snapshot sample_count should be int")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("sample_count", null) is int:
		printerr("[PROBE] critical unified snapshot sample_count should be int")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("takeover_ready", null) is bool:
		printerr("[PROBE] warning unified snapshot takeover_ready should be bool")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("takeover_ready", null) is bool:
		printerr("[PROBE] critical unified snapshot takeover_ready should be bool")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("family", null) is String:
		printerr("[PROBE] warning unified snapshot family should be string")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("family", null) is String:
		printerr("[PROBE] critical unified snapshot family should be string")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("confidence_score", null) is float and not output.get("warning_unified_snapshot", {}).get("confidence_score", null) is int:
		printerr("[PROBE] warning unified snapshot confidence_score should be numeric")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("confidence_score", null) is float and not output.get("critical_unified_snapshot", {}).get("confidence_score", null) is int:
		printerr("[PROBE] critical unified snapshot confidence_score should be numeric")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", null) is float and not output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", null) is int:
		printerr("[PROBE] warning unified snapshot warning_threshold_value should be numeric")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", null) is float and not output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("warning_threshold_value", null) is int:
		printerr("[PROBE] critical unified snapshot warning_threshold_value should be numeric")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("error_threshold_value", null) is float and not output.get("critical_unified_snapshot", {}).get("thresholds", {}).get("error_threshold_value", null) is int:
		printerr("[PROBE] critical unified snapshot error_threshold_value should be numeric")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_upper_threshold_value", null) is float and not output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_upper_threshold_value", null) is int:
		printerr("[PROBE] warning unified snapshot warning_upper_threshold_value should be numeric")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_lower_threshold_value", null) is float and not output.get("warning_unified_snapshot", {}).get("thresholds", {}).get("warning_lower_threshold_value", null) is int:
		printerr("[PROBE] warning unified snapshot warning_lower_threshold_value should be numeric")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("blockers", null) is Array:
		printerr("[PROBE] warning unified snapshot blockers should be array")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("blockers", null) is Array:
		printerr("[PROBE] critical unified snapshot blockers should be array")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("support_counts", null) is Dictionary:
		printerr("[PROBE] warning unified snapshot support_counts should be dictionary")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("support_counts", null) is Dictionary:
		printerr("[PROBE] critical unified snapshot support_counts should be dictionary")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("thresholds", null) is Dictionary:
		printerr("[PROBE] warning unified snapshot thresholds should be dictionary")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("thresholds", null) is Dictionary:
		printerr("[PROBE] critical unified snapshot thresholds should be dictionary")
		quit(1)
		return
	if not output.get("warning_unified_snapshot", {}).get("gate_results", null) is Dictionary:
		printerr("[PROBE] warning unified snapshot gate_results should be dictionary")
		quit(1)
		return
	if not output.get("critical_unified_snapshot", {}).get("gate_results", null) is Dictionary:
		printerr("[PROBE] critical unified snapshot gate_results should be dictionary")
		quit(1)
		return
	var verify_probe: Dictionary = output.get("v4_probe", {})
	output["v4_probe_fingerprint"] = {
		"claim_success_rate": verify_probe.get("claim_success_rate", null),
		"contention_index": verify_probe.get("contention_index", null),
		"late_commit_deviation": verify_probe.get("late_commit_deviation", null),
		"assignment_count": int(verify_probe.get("assignments", {}).size()) if verify_probe.get("assignments", {}) is Dictionary else -1
	}
	output["v4_probe_baseline"] = "claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s" % [
		str(output["v4_probe_fingerprint"].get("claim_success_rate", "missing")),
		str(output["v4_probe_fingerprint"].get("contention_index", "missing")),
		str(output["v4_probe_fingerprint"].get("late_commit_deviation", "missing")),
		str(output["v4_probe_fingerprint"].get("assignment_count", "missing"))
	]
	var fingerprint: Dictionary = output.get("v4_probe_fingerprint", {})
	if not fingerprint.has("claim_success_rate"):
		printerr("[PROBE] missing v4 fingerprint claim_success_rate: %s" % JSON.stringify(fingerprint))
		quit(1)
		return
	if not fingerprint.has("contention_index"):
		printerr("[PROBE] missing v4 fingerprint contention_index: %s" % JSON.stringify(fingerprint))
		quit(1)
		return
	if not fingerprint.has("late_commit_deviation"):
		printerr("[PROBE] missing v4 fingerprint late_commit_deviation: %s" % JSON.stringify(fingerprint))
		quit(1)
		return
	if not fingerprint.has("assignment_count"):
		printerr("[PROBE] missing v4 fingerprint assignment_count: %s" % JSON.stringify(fingerprint))
		quit(1)
		return
	if not output.has("v4_probe_baseline") or str(output.get("v4_probe_baseline", "")) == "":
		printerr("[PROBE] missing v4 baseline line: %s" % JSON.stringify(output.get("v4_probe_baseline", "")))
		quit(1)
		return
	if int(fingerprint.get("assignment_count", -1)) < 0:
		printerr("[PROBE] invalid v4 fingerprint assignment_count: %s" % JSON.stringify(fingerprint))
		quit(1)
		return
	if int(fingerprint.get("assignment_count", 0)) == 0:
		printerr("[PROBE] empty v4 fingerprint assignment_count: %s" % JSON.stringify(fingerprint))
		quit(1)
		return
	if not verify_probe.has("claim_success_rate"):
		printerr("[PROBE] missing v4 claim_success_rate: %s" % JSON.stringify(verify_probe))
		quit(1)
		return
	if not verify_probe.has("late_commit_deviation"):
		printerr("[PROBE] missing v4 late_commit_deviation: %s" % JSON.stringify(verify_probe))
		quit(1)
		return
	if not verify_probe.has("contention_index"):
		printerr("[PROBE] missing v4 contention_index: %s" % JSON.stringify(verify_probe))
		quit(1)
		return
	if not verify_probe.has("assignments"):
		printerr("[PROBE] missing v4 assignments: %s" % JSON.stringify(verify_probe))
		quit(1)
		return
	if verify_probe.get("assignments", {}).is_empty():
		printerr("[PROBE] empty v4 assignments: %s" % JSON.stringify(verify_probe))
		quit(1)
		return
	var first_assignment_key: Variant = verify_probe.get("assignments", {}).keys()[0]
	var first_assignment: Dictionary = verify_probe.get("assignments", {}).get(first_assignment_key, {})
	if not first_assignment.has("assigned_slot_index"):
		printerr("[PROBE] missing assigned_slot_index: %s" % JSON.stringify(first_assignment))
		quit(1)
		return
	if not first_assignment.has("target_id"):
		printerr("[PROBE] missing target_id: %s" % JSON.stringify(first_assignment))
		quit(1)
		return
	if not first_assignment.has("global_pos"):
		printerr("[PROBE] missing global_pos: %s" % JSON.stringify(first_assignment))
		quit(1)
		return
	if not first_assignment.has("status"):
		printerr("[PROBE] missing status: %s" % JSON.stringify(first_assignment))
		quit(1)
		return
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("[PROBE] failed to open output path")
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print("[PROBE] wrote %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()
