extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const OUTPUT_PATH := "user://runtime_probe.json"
const SAMPLE_TIMES := [0.0, 0.01, 0.03, 0.05, 0.1, 0.2, 0.5, 1.0, 1.1, 1.2, 1.25, 1.3, 1.4, 1.5, 1.6, 1.8, 2.0, 2.2, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 16.0, 20.0]
const INITIAL_PROBE := "user://transition_initial_probe.json"
const RUNTIME_PROBE := "user://transition_runtime_probe.json"

func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data

func _initialize() -> void:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		printerr("[PROBE] failed to load battle scene")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
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
		var controller := instance.get_node_or_null("BattleController")
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
			tracked_entities[str(tracked_id)] = {
				"controller": entity_payload,
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
					"engagement_target": int(entity_payload.get("engagement_target", -1)),
					"engagement_blocked_time": float(entity_payload.get("engagement_blocked_time", 0.0)),
					"position": entity_payload.get("position", Vector2.ZERO),
					"velocity": entity_payload.get("velocity", Vector2.ZERO),
					"view_position": entity_view_snapshot.get("global_position", Vector2.ZERO),
					"body_scale": entity_view_snapshot.get("sprite", {}).get("body_scale", Vector2.ZERO),
					"body_texture": entity_view_snapshot.get("sprite", {}).get("body_texture", "")
				})
				trajectories[trajectory_key] = points
		var recent_events_probe: Dictionary = _read_json("user://controller_recent_combat_events_probe.json")
		var pair_distance_35_to_9 = null
		var attacks_on_9: Array = []
		for event_variant in recent_events_probe.get("events", []):
			var event: Dictionary = event_variant
			if int(event.get("attacker_id", -1)) == 35 and int(event.get("target_id", -1)) == 9 and str(event.get("type", "")) == "attack":
				var attacker_position_35: Vector2 = event.get("attacker_position", Vector2.ZERO)
				var target_position_35: Vector2 = event.get("target_position", Vector2.ZERO)
				pair_distance_35_to_9 = attacker_position_35.distance_to(target_position_35)
			if int(event.get("target_id", -1)) == 9 and str(event.get("type", "")) == "attack":
				var attacker_position_9 = event.get("attacker_position", Vector2.ZERO)
				var target_position_9 = event.get("target_position", Vector2.ZERO)
				attacks_on_9.append({
					"attacker_id": int(event.get("attacker_id", -1)),
					"attacker_position": attacker_position_9,
					"target_position": target_position_9
				})
		var entity_2: Dictionary = tracked_entities.get("2", {})
		var entity_2_controller: Dictionary = entity_2.get("controller", {})
		var entity_2_target: Dictionary = entity_2.get("target", {})
		var entity_2_target_target: Dictionary = entity_2.get("target_target", {})
		samples.append({
			"time": elapsed,
			"tick_before": _read_json("user://tick_probe_before.json"),
			"payload_probe": _read_json("user://runtime_payload_probe.json"),
			"view_probe": _read_json("user://runtime_view_probe.json"),
			"combat_feedback_probe": _read_json("user://combat_feedback_probe.json"),
			"combat_pulse_probe": _read_json("user://combat_pulse_probe.json"),
			"controller_recent_combat_events_probe": recent_events_probe,
			"controller_consume_combat_events_probe": _read_json("user://controller_consume_combat_events_probe.json"),
			"unit_view_attack_pulse_probe_33": _read_json("user://unit_view_attack_pulse_probe_33.json"),
			"unit_view_sync_probe_33": _read_json("user://unit_view_sync_probe_33.json"),
			"runtime_view_probe": _read_json("user://runtime_view_probe.json"),
			"controller_recent_deaths_probe": _read_json("user://controller_recent_deaths_probe.json"),
			"tracked_entities": tracked_entities,
			"pair_distance_35_to_9": pair_distance_35_to_9,
			"attacks_on_9": attacks_on_9,
			"entity_2_focus": {
				"state_name": entity_2_controller.get("state_name", ""),
				"target_id": int(entity_2_controller.get("target_id", -1)),
				"engagement_target": int(entity_2_controller.get("engagement_target", -1)),
				"engagement_slot": int(entity_2_controller.get("engagement_slot", -1)),
				"engagement_blocked_time": float(entity_2_controller.get("engagement_blocked_time", 0.0)),
				"position": entity_2_controller.get("position", Vector2.ZERO),
				"velocity": entity_2_controller.get("velocity", Vector2.ZERO),
				"target_position": entity_2_target.get("position", Vector2.ZERO),
				"target_state_name": entity_2_target.get("state_name", ""),
				"target_target_id": int(entity_2_target.get("target_id", -1)),
				"target_target_position": entity_2_target_target.get("position", Vector2.ZERO),
				"target_target_state_name": entity_2_target_target.get("state_name", "")
			}
		})
		sample_index += 1
	var controller := instance.get_node_or_null("BattleController")
	var attack_times: Dictionary = controller.call("debug_get_first_attack_times") if controller != null and controller.has_method("debug_get_first_attack_times") else {}
	var output := {
		"samples": samples,
		"trajectories": trajectories,
		"initial_probe": FileAccess.get_file_as_string(INITIAL_PROBE),
		"runtime_probe": FileAccess.get_file_as_string(RUNTIME_PROBE),
		"tick_before": FileAccess.get_file_as_string("user://tick_probe_before.json"),
		"tick_after": FileAccess.get_file_as_string("user://tick_probe_after.json"),
		"initial_to_runtime_delta": FileAccess.get_file_as_string("user://initial_to_runtime_delta_probe.json"),
		"first_attack_times": attack_times,
		"full_attack_history_probe": _read_json("user://controller_full_attack_history_probe.json")
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("[PROBE] failed to open output file")
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print("[PROBE] wrote ", ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)
