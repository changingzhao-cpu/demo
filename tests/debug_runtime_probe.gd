extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const OUTPUT_PATH := "user://runtime_probe.json"
const SAMPLE_TIMES := [0.0, 0.01, 0.03, 0.05, 0.1, 0.2, 0.5, 1.0, 1.1, 1.2, 1.25, 1.3, 1.4, 1.5, 1.6, 1.8, 2.0, 2.2, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 16.0, 20.0]
const INITIAL_PROBE := "user://transition_initial_probe.json"
const RUNTIME_PROBE := "user://transition_runtime_probe.json"
const FOCUS_ENTITY_IDS := [3, 30, 38]

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
		controller.call("debug_force_simulation_backend", "v2")
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
					"target": {
						"entity_id": int(entity_target_payload.get("entity_id", -1)),
						"state_name": entity_target_payload.get("state_name", ""),
						"target_id": int(entity_target_payload.get("target_id", -1)),
						"engagement_slot": int(entity_target_payload.get("engagement_slot", -1)),
						"position": entity_target_payload.get("position", Vector2.ZERO),
						"velocity": entity_target_payload.get("velocity", Vector2.ZERO)
					},
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
	var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
	var output := {
		"samples": samples,
		"trajectories": trajectories,
		"battle_report_timeline": battle_report_timeline,
		"anomaly_scan": anomaly_scan,
		"initial_probe": FileAccess.get_file_as_string(INITIAL_PROBE),
		"runtime_probe": FileAccess.get_file_as_string(RUNTIME_PROBE),
		"first_attack_times": attack_times
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("[PROBE] failed to open output path")
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print("[PROBE] wrote %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()
