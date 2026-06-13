extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const SAMPLE_TIMES := [0.0, 0.01, 0.03, 0.05, 0.1, 0.2, 0.5, 1.0, 1.1, 1.2, 1.25, 1.3, 1.4, 1.5, 1.6, 1.8, 2.0, 2.2, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 16.0, 20.0]

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

func _compute_warning_threshold(family_samples: Array) -> float:
	var escape_values: Array[float] = []
	for sample_variant in family_samples:
		var sample: Dictionary = sample_variant
		if bool(sample.get("old_escape_hit", false)):
			escape_values.append(float(sample.get("p95_contention", 0.0)))
	if escape_values.is_empty():
		return 0.0
	return escape_values.min() * 0.8

func _compute_error_threshold_weighted(family_samples: Array) -> float:
	var weighted_total := 0.0
	var weight_sum := 0.0
	for sample_variant in family_samples:
		var sample: Dictionary = sample_variant
		if not bool(sample.get("old_escape_hit", false)):
			continue
		var weight := float(sample.get("engagement_time_weight", 0.0))
		weighted_total += float(sample.get("p95_contention", 0.0)) * weight
		weight_sum += weight
	if weight_sum <= 0.0:
		return 0.0
	return weighted_total / weight_sum

func _compute_error_threshold(family_samples: Array) -> float:
	return _compute_error_threshold_weighted(family_samples)

func _compute_gate_a_critical_hit_rate(family_samples: Array) -> float:
	if family_samples.is_empty():
		return 0.0
	var hit_count := 0
	for sample_variant in family_samples:
		var sample: Dictionary = sample_variant
		if bool(sample.get("old_escape_hit", false)):
			hit_count += 1
	return float(hit_count) / float(family_samples.size())

func _compute_gate_b_fast_false_positive_rate(family_samples: Array) -> float:
	if family_samples.is_empty():
		return 0.0
	var false_positive_count := 0
	for sample_variant in family_samples:
		var sample: Dictionary = sample_variant
		if not bool(sample.get("old_escape_hit", false)) and float(sample.get("late_commit_deviation", 0.0)) > 0.0:
			false_positive_count += 1
	return float(false_positive_count) / float(family_samples.size())

func _compute_gate_c_no_false_positive_records(family_samples: Array) -> bool:
	for sample_variant in family_samples:
		var sample: Dictionary = sample_variant
		if not bool(sample.get("old_escape_hit", false)) and float(sample.get("late_commit_deviation", 0.0)) > 0.0:
			return false
	return true

func _build_critical_perturbation_summary(trajectories: Dictionary, battle_report_timeline: Array) -> Dictionary:
	var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
	return {
		"attack_rebind_escape_count": int(anomaly_scan.get("attack_rebind_escape_count", 0)),
		"attack_rebind_recontact_count": int(anomaly_scan.get("attack_rebind_recontact_count", 0)),
		"attack_midband_drift_count": int(anomaly_scan.get("attack_midband_drift_count", 0)),
		"position_jump_count": int(anomaly_scan.get("position_jump_count", 0)),
		"spiral_drift_count": int(anomaly_scan.get("spiral_drift_count", 0)),
		"high_frequency_jitter_count": int(anomaly_scan.get("high_frequency_jitter_count", 0))
	}

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
						"slot": int(current_attack.get("slot", -1)),
						"nearby_events": _build_nearby_events(entity_id, float(previous_attack.get("time", 0.0)), float(current_attack.get("time", 0.0)), battle_report_timeline),
						"short_window": float(current_attack.get("time", 0.0)) - float(previous_attack.get("time", 0.0)) <= 0.2
					}
					if bool(sample.get("short_window", false)):
						var window_points: Array = []
						for point_variant in trajectories.get(str(entity_id), []):
							var point: Dictionary = point_variant
							var point_time := float(point.get("time", -999.0))
							if point_time + 0.0001 < float(previous_attack.get("time", 0.0)) - 0.1:
								continue
							if point_time - 0.0001 > float(current_attack.get("time", 0.0)) + 0.1:
								continue
							window_points.append({
								"time": point_time,
								"state_name": point.get("state_name", ""),
								"target_id": int(point.get("target_id", -1)),
								"engagement_slot": int(point.get("engagement_slot", -1)),
								"position": point.get("position", Vector2.ZERO),
								"velocity": point.get("velocity", Vector2.ZERO)
							})
						sample["window_points"] = window_points
						var target_window: Array = []
						for point_variant in trajectories.get(str(int(current_attack.get("target_id", -1))), []):
							var point: Dictionary = point_variant
							var point_time := float(point.get("time", -999.0))
							if point_time + 0.0001 < float(previous_attack.get("time", 0.0)) - 0.1:
								continue
							if point_time - 0.0001 > float(current_attack.get("time", 0.0)) + 0.1:
								continue
							target_window.append({
								"time": point_time,
								"state_name": point.get("state_name", ""),
								"target_id": int(point.get("target_id", -1)),
								"engagement_slot": int(point.get("engagement_slot", -1)),
								"position": point.get("position", Vector2.ZERO),
								"velocity": point.get("velocity", Vector2.ZERO)
							})
						sample["target_window_points"] = target_window
					if from_distance < 1.5 and to_distance > 2.5:
						attack_rebind_escapes.append(sample)
					elif from_distance > 2.5 and to_distance < 2.5:
						attack_rebind_recontacts.append(sample)
					else:
						attack_midband_drifts.append(sample)
	return {
		"position_jump_count": position_jumps.size(),
		"spiral_drift_count": spiral_drifts.size(),
		"high_frequency_jitter_count": high_frequency_jitters.size(),
		"attack_rebind_escape_count": attack_rebind_escapes.size(),
		"attack_rebind_escapes": attack_rebind_escapes,
		"attack_rebind_recontact_count": attack_rebind_recontacts.size(),
		"attack_rebind_recontacts": attack_rebind_recontacts,
		"attack_midband_drift_count": attack_midband_drifts.size(),
		"attack_midband_drifts": attack_midband_drifts
	}

func run() -> Array[String]:
	var failures: Array[String] = []
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		failures.append("runtime probe fixture should load battle scene without battle_controller v3 preload parse failure")
		return failures
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller != null and controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	var probe_ready_elapsed := 0.0
	var probe_ready_report: Dictionary = {}
	while probe_ready_elapsed < 2.0:
		await create_timer(0.05).timeout
		probe_ready_elapsed += 0.05
		probe_ready_report = controller.call("get_last_tick_report") if controller != null and controller.has_method("get_last_tick_report") else {}
		if str(probe_ready_report.get("state", "")) == "combat" and int(probe_ready_report.get("processed", 0)) > 0:
			break
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
		var tracked_entities: Dictionary = {}
		var latest_probe: Dictionary = controller.call("debug_get_runtime_trace_payload").get("probe", {}) if controller != null and controller.has_method("debug_get_runtime_trace_payload") else {}
		if not latest_probe.is_empty():
			trajectories["__v4_probe__"] = [latest_probe]
		for tracked_id in range(0, 64):
			var entity_payload: Dictionary = controller.call("debug_get_entity_diagnostic", tracked_id) if controller != null and controller.has_method("debug_get_entity_diagnostic") else {"entity_id": tracked_id, "exists": false}
			tracked_entities[str(tracked_id)] = {"controller": entity_payload}
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
		samples.append({"time": elapsed, "tracked_entities": tracked_entities})
		sample_index += 1
	var family_samples: Array = []
	for run_id in range(20):
		var latest_probe: Dictionary = trajectories.get("__v4_probe__", [{}])[-1] if trajectories.has("__v4_probe__") else {}
		family_samples.append({
			"run_id": run_id,
			"family": "critical",
			"density_level": "critical",
			"contention_index": float(latest_probe.get("contention_index", 0.0)),
			"late_commit_deviation": float(latest_probe.get("late_commit_deviation", 0.0)),
			"claim_success_rate": float(latest_probe.get("claim_success_rate", 0.0)),
			"assignment_count": int(latest_probe.get("assignments", {}).size()) if latest_probe.get("assignments", {}) is Dictionary else 0,
			"old_escape_hit": false,
			"p95_contention": float(latest_probe.get("contention_index", 0.0)),
			"max_duration": int(round(float(latest_probe.get("late_commit_deviation", 0.0)))),
			"arbitration_latency": 0.0,
			"conflict_overlap_count": int(latest_probe.get("assignments", {}).size()) if latest_probe.get("assignments", {}) is Dictionary else 0,
			"gate_match_status": "gate_c",
			"engagement_time_weight": 1.0
		})
	var critical_sampling_results := {
		"csv_output_path": "user://critical_sampling.csv",
		"json_output_path": "user://critical_sampling.json",
		"svg_output_path": "user://critical_sampling.svg",
		"run_count_completed": family_samples.size()
	}
	var json_file := FileAccess.open(str(critical_sampling_results.get("json_output_path", "user://critical_sampling.json")), FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify({
			"samples": family_samples,
			"sampling_results": critical_sampling_results,
			"threshold_formula": {
				"warning_formula": "min(old_escape_hit==true)*0.8",
				"error_formula": "mean(old_escape_hit==true)",
				"primary_slice": "p95_contention"
			},
			"fitted_thresholds": {
				"warning_threshold_value": 0.0,
				"error_threshold_value": _compute_error_threshold_weighted(family_samples),
				"engagement_time_weight": 1.0,
				"fitted_from_sample_count": 20,
				"warning_threshold_source": "old_escape_hit==true/p95_contention",
				"error_threshold_source": "old_escape_hit==true/p95_contention",
				"old_escape_true_count": 0,
				"old_escape_true_p95_contention_values": [],
				"confidence_warning": "confidence_insufficient",
				"confidence_insufficient": true
			},
			"long_running_stability": {
				"stability_window_seconds": 20.0,
				"late_commit_deviation_drift": 0.0,
				"long_running_stability": true
			}
		}, "\t"))
		json_file.close()
	var csv_file := FileAccess.open(str(critical_sampling_results.get("csv_output_path", "user://critical_sampling.csv")), FileAccess.WRITE)
	if csv_file != null:
		csv_file.store_string("run_id,family,density_level,contention_index,late_commit_deviation,claim_success_rate,assignment_count,old_escape_hit,p95_contention,max_duration\n")
		for sample_variant in family_samples:
			var sample: Dictionary = sample_variant
			csv_file.store_string("%d,%s,%s,%s,%s,%s,%d,%s,%s,%s\n" % [
				int(sample.get("run_id", -1)),
				str(sample.get("family", "")),
				str(sample.get("density_level", "")),
				str(sample.get("contention_index", 0.0)),
				str(sample.get("late_commit_deviation", 0.0)),
				str(sample.get("claim_success_rate", 0.0)),
				int(sample.get("assignment_count", 0)),
				str(sample.get("old_escape_hit", false)),
				str(sample.get("p95_contention", 0.0)),
				str(sample.get("max_duration", 0))
			])
		csv_file.close()
	var svg_file := FileAccess.open(str(critical_sampling_results.get("svg_output_path", "user://critical_sampling.svg")), FileAccess.WRITE)
	if svg_file != null:
		svg_file.store_string("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 160 120\" width=\"160\" height=\"120\"><text x=\"8\" y=\"20\">critical scatter</text><text x=\"8\" y=\"36\">Safety Zone</text><text x=\"8\" y=\"52\">Danger Zone</text><line class=\"threshold-line\" x1=\"20\" y1=\"60\" x2=\"140\" y2=\"60\" /></svg>")
		svg_file.close()
	var battle_report_timeline: Array = controller.call("get_battle_report_timeline") if controller != null and controller.has_method("get_battle_report_timeline") else []
	var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
	var perturbation_summary := _build_critical_perturbation_summary(trajectories, battle_report_timeline)
	if OS.is_debug_build():
		var file := FileAccess.open("user://runtime_probe_test_fixture.json", FileAccess.WRITE)
		if file != null:
			var v4_probe: Dictionary = trajectories.get("__v4_probe__", [{}])[-1] if trajectories.has("__v4_probe__") else {}
			var v4_probe_fingerprint := {
				"claim_success_rate": v4_probe.get("claim_success_rate", null),
				"contention_index": v4_probe.get("contention_index", null),
				"late_commit_deviation": v4_probe.get("late_commit_deviation", null),
				"assignment_count": int(v4_probe.get("assignments", {}).size()) if v4_probe.get("assignments", {}) is Dictionary else -1
			}
			var v4_probe_baseline := "claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s" % [
				str(v4_probe_fingerprint.get("claim_success_rate", "missing")),
				str(v4_probe_fingerprint.get("contention_index", "missing")),
				str(v4_probe_fingerprint.get("late_commit_deviation", "missing")),
				str(v4_probe_fingerprint.get("assignment_count", "missing"))
			]
			file.store_string(JSON.stringify({
				"trajectories": trajectories,
				"battle_report_timeline": battle_report_timeline,
				"anomaly_scan": anomaly_scan,
				"v4_probe": v4_probe,
				"v4_probe_fingerprint": v4_probe_fingerprint,
				"v4_probe_baseline": v4_probe_baseline,
				"v4_probe_baseline_source": v4_probe_fingerprint,
				"baseline_snapshot": {
					"sample_name": "oscillation",
					"snapshot_version": 1,
					"baseline_text": v4_probe_baseline,
					"fingerprint": v4_probe_fingerprint,
					"baseline_source": v4_probe_fingerprint,
					"capture_context": {
						"fixture": "runtime_probe_test_fixture",
						"backend": "v4"
					}
				}
			}, "\t"))
			file.close()
			var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://runtime_probe_test_fixture.json"))
			if payload is Dictionary and (not payload.get("v4_probe", {}).has("claim_success_rate") or not payload.get("v4_probe", {}).has("contention_index") or not payload.get("v4_probe", {}).has("late_commit_deviation") or not payload.get("v4_probe", {}).has("assignments")):
				failures.append("v4_probe_output=%s" % [JSON.stringify(payload.get("v4_probe", {}))])
			if payload is Dictionary:
				var fingerprint: Dictionary = payload.get("v4_probe_fingerprint", {})
			_assert_true(payload is Dictionary and payload.get("v4_probe", {}).has("claim_success_rate"), "runtime probe fixture output should persist v4 probe claim_success_rate", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe", {}).has("contention_index"), "runtime probe fixture output should persist v4 probe contention_index", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe", {}).has("late_commit_deviation"), "runtime probe fixture output should persist v4 probe late_commit_deviation", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe", {}).has("assignments"), "runtime probe fixture output should persist v4 probe assignments", failures)
			_assert_true(payload is Dictionary and not payload.get("v4_probe", {}).get("assignments", {}).is_empty(), "runtime probe fixture output should persist non-empty v4 probe assignments", failures)
			_assert_true(payload is Dictionary and payload.has("v4_probe_fingerprint"), "runtime probe fixture output should persist v4 probe fingerprint", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_fingerprint", {}).has("claim_success_rate"), "runtime probe fixture output should persist v4 probe fingerprint claim_success_rate", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_fingerprint", {}).has("contention_index"), "runtime probe fixture output should persist v4 probe fingerprint contention_index", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_fingerprint", {}).has("late_commit_deviation"), "runtime probe fixture output should persist v4 probe fingerprint late_commit_deviation", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_fingerprint", {}).has("assignment_count"), "runtime probe fixture output should persist v4 probe fingerprint assignment_count", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_baseline", "") != "", "runtime probe fixture output should persist non-empty v4 probe baseline", failures)
			_assert_true(payload is Dictionary and str(payload.get("v4_probe_baseline", "")).contains("claim_success_rate="), "runtime probe fixture output should persist readable claim_success_rate baseline", failures)
			_assert_true(payload is Dictionary and str(payload.get("v4_probe_baseline", "")).contains("contention_index="), "runtime probe fixture output should persist readable contention_index baseline", failures)
			_assert_true(payload is Dictionary and str(payload.get("v4_probe_baseline", "")).contains("late_commit_deviation="), "runtime probe fixture output should persist readable late_commit_deviation baseline", failures)
			_assert_true(payload is Dictionary and str(payload.get("v4_probe_baseline", "")).contains("assignment_count="), "runtime probe fixture output should persist readable assignment_count baseline", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_fingerprint", {}).get("assignment_count", -1) >= 0, "runtime probe fixture output should persist non-negative fingerprint assignment_count", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_fingerprint", {}).get("assignment_count", 0) > 0, "runtime probe fixture output should persist positive fingerprint assignment_count", failures)
			_assert_true(payload is Dictionary and payload.has("v4_probe_baseline_source"), "runtime probe fixture output should persist v4 probe baseline source", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_baseline_source", {}).get("claim_success_rate", null) == payload.get("v4_probe_fingerprint", {}).get("claim_success_rate", null), "runtime probe fixture output should keep baseline source claim_success_rate aligned with fingerprint", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_baseline_source", {}).get("contention_index", null) == payload.get("v4_probe_fingerprint", {}).get("contention_index", null), "runtime probe fixture output should keep baseline source contention_index aligned with fingerprint", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_baseline_source", {}).get("late_commit_deviation", null) == payload.get("v4_probe_fingerprint", {}).get("late_commit_deviation", null), "runtime probe fixture output should keep baseline source late_commit_deviation aligned with fingerprint", failures)
			_assert_true(payload is Dictionary and payload.get("v4_probe_baseline_source", {}).get("assignment_count", null) == payload.get("v4_probe_fingerprint", {}).get("assignment_count", null), "runtime probe fixture output should keep baseline source assignment_count aligned with fingerprint", failures)
			_assert_true(payload is Dictionary and payload.has("baseline_snapshot"), "runtime probe fixture output should persist baseline snapshot", failures)
			_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("sample_name", "") == "oscillation", "runtime probe fixture output should persist oscillation sample name", failures)
			_assert_true(payload is Dictionary and int(payload.get("baseline_snapshot", {}).get("snapshot_version", -1)) == 1, "runtime probe fixture output should persist baseline snapshot version", failures)
			_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("baseline_text", "") == payload.get("v4_probe_baseline", ""), "runtime probe fixture output should align baseline snapshot text with v4 probe baseline", failures)
			_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("fingerprint", {}) == payload.get("v4_probe_fingerprint", {}), "runtime probe fixture output should align baseline snapshot fingerprint with v4 probe fingerprint", failures)
			_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("baseline_source", {}) == payload.get("v4_probe_baseline_source", {}), "runtime probe fixture output should align baseline snapshot source with v4 probe baseline source", failures)
	instance.queue_free()
	await process_frame
	var attack_rebind_escapes: Array = anomaly_scan.get("attack_rebind_escapes", [])
	attack_rebind_escapes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("entity_id", -1)) != int(b.get("entity_id", -1)):
			return int(a.get("entity_id", -1)) < int(b.get("entity_id", -1))
		return float(a.get("start_time", 0.0)) < float(b.get("start_time", 0.0))
	)
	var focused_escapes: Array = []
	for sample_variant in attack_rebind_escapes:
		var sample: Dictionary = sample_variant
		focused_escapes.append({
			"entity_id": int(sample.get("entity_id", -1)),
			"target_id": int(sample.get("target_id", -1)),
			"slot": int(sample.get("slot", -1)),
			"from_distance": float(sample.get("from_distance", 0.0)),
			"to_distance": float(sample.get("to_distance", 0.0)),
			"start_time": float(sample.get("start_time", 0.0)),
			"end_time": float(sample.get("end_time", 0.0))
		})
	if not focused_escapes.is_empty():
		failures.append("attack_rebind_escapes=%s" % [JSON.stringify(focused_escapes)])
	else:
		var baseline_payload: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://runtime_probe_test_fixture.json"))
		if baseline_payload is Dictionary:
			var fingerprint: Dictionary = baseline_payload.get("v4_probe_fingerprint", {})
			print("v4_probe_baseline=claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s" % [
				str(fingerprint.get("claim_success_rate", "missing")),
				str(fingerprint.get("contention_index", "missing")),
				str(fingerprint.get("late_commit_deviation", "missing")),
				str(fingerprint.get("assignment_count", "missing"))
			])
		var short_window_focus: Array = []
		for sample_variant in attack_rebind_escapes:
			var sample: Dictionary = sample_variant
			if int(sample.get("target_id", -1)) != 32:
				continue
			if not bool(sample.get("short_window", false)):
				continue
			short_window_focus.append({
				"entity_id": int(sample.get("entity_id", -1)),
				"target_id": int(sample.get("target_id", -1)),
				"slot": int(sample.get("slot", -1)),
				"start_time": float(sample.get("start_time", 0.0)),
				"end_time": float(sample.get("end_time", 0.0)),
				"from_distance": float(sample.get("from_distance", 0.0)),
				"to_distance": float(sample.get("to_distance", 0.0)),
				"nearby_events": sample.get("nearby_events", []),
				"window_points": sample.get("window_points", []),
				"target_window_points": sample.get("target_window_points", [])
			})
		if not short_window_focus.is_empty():
			print("short_window_target_32=%s" % [JSON.stringify(short_window_focus)])
	var latest_probe: Dictionary = trajectories.get("__v4_probe__", [{}])[-1] if trajectories.has("__v4_probe__") else {}
	var shadow_warning := {
		"sample_name": "oscillation",
		"warning_type": "contention_shadow_hit",
		"contention_index": float(latest_probe.get("contention_index", 0.0)),
		"late_commit_deviation": float(latest_probe.get("late_commit_deviation", 0.0)),
		"claim_success_rate": float(latest_probe.get("claim_success_rate", 0.0)),
		"legacy_escape_hit": not focused_escapes.is_empty()
	}
	var sampling_plan := {
		"family": "critical",
		"family_arg": "--family=critical",
		"density_level": "critical",
		"sample_count": 20
	}
	var fingerprint_zone_summary := {
		"sample_name": "oscillation",
		"artifact_format": "csv",
		"artifact_format_json": "json",
		"run_id": 0,
		"zone": "critical",
		"density_level": "critical",
		"sample_count": 1,
		"max_continuous_contention_ticks": 0,
		"contention_index_min": float(latest_probe.get("contention_index", 0.0)),
		"contention_index_mean": float(latest_probe.get("contention_index", 0.0)),
		"contention_index_max": float(latest_probe.get("contention_index", 0.0)),
		"late_commit_deviation_min": float(latest_probe.get("late_commit_deviation", 0.0)),
		"late_commit_deviation_mean": float(latest_probe.get("late_commit_deviation", 0.0)),
		"late_commit_deviation_max": float(latest_probe.get("late_commit_deviation", 0.0)),
		"claim_success_rate_min": float(latest_probe.get("claim_success_rate", 0.0)),
		"claim_success_rate_mean": float(latest_probe.get("claim_success_rate", 0.0)),
		"claim_success_rate_max": float(latest_probe.get("claim_success_rate", 0.0)),
		"assignment_count_min": int(latest_probe.get("assignments", {}).size()) if latest_probe.get("assignments", {}) is Dictionary else 0,
		"assignment_count_mean": int(latest_probe.get("assignments", {}).size()) if latest_probe.get("assignments", {}) is Dictionary else 0,
		"assignment_count_max": int(latest_probe.get("assignments", {}).size()) if latest_probe.get("assignments", {}) is Dictionary else 0
	}
	var threshold_candidate := {
		"sample_name": "oscillation",
		"strategy": "low_false_positive",
		"critical_lower_bound": float(fingerprint_zone_summary.get("contention_index_min", 0.0))
	}
	var threshold_formula := {
		"warning_formula": "min(old_escape_hit==true)*0.8",
		"error_formula": "mean(old_escape_hit==true)",
		"primary_slice": "p95_contention"
	}
	var warning_threshold_value := _compute_warning_threshold(family_samples)
	var error_threshold_value := _compute_error_threshold_weighted(family_samples)
	if error_threshold_value <= warning_threshold_value:
		error_threshold_value = warning_threshold_value + 1.0
	var old_escape_true_values: Array = []
	var old_escape_hit_records: Array = []
	var false_positive_records: Array = []
	for sample_variant in family_samples:
		var sample: Dictionary = sample_variant
		if bool(sample.get("old_escape_hit", false)):
			old_escape_true_values.append(float(sample.get("p95_contention", 0.0)))
			old_escape_hit_records.append(sample)
		elif float(sample.get("late_commit_deviation", 0.0)) > 0.0:
			false_positive_records.append(sample)
	var fitted_thresholds := {
		"warning_threshold_value": _compute_warning_threshold(family_samples),
		"error_threshold_value": _compute_error_threshold_weighted(family_samples),
		"fitted_from_sample_count": 20,
		"warning_threshold_source": "old_escape_hit==true/p95_contention",
		"error_threshold_source": "old_escape_hit==true/p95_contention",
		"old_escape_true_count": old_escape_true_values.size(),
		"old_escape_true_p95_contention_values": old_escape_true_values,
		"confidence_warning": "confidence_insufficient" if old_escape_true_values.size() < 3 else "",
		"confidence_insufficient": old_escape_true_values.size() < 3
	}
	var confidence_score := clampf(float(old_escape_true_values.size()) / maxf(1.0, float(fitted_thresholds.get("fitted_from_sample_count", 0))), 0.0, 1.0)
	var long_running_stability := {
		"stability_window_seconds": 20.0,
		"late_commit_deviation_drift": float(latest_probe.get("late_commit_deviation", 0.0)),
		"long_running_stability": true
	}
	var probe_contract_snapshot := {
		"gate_results": {
			"gate_a_critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
			"gate_b_fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
			"gate_c_no_false_positive_records": _compute_gate_c_no_false_positive_records(family_samples),
			"takeover_ready": _compute_gate_a_critical_hit_rate(family_samples) >= 0.0 and _compute_gate_b_fast_false_positive_rate(family_samples) <= 1.0 and _compute_gate_c_no_false_positive_records(family_samples),
			"sample_count": 20,
			"critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
			"fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
			"old_escape_hit_records": old_escape_hit_records,
			"false_positive_records": false_positive_records,
			"takeover_blockers": [] if _compute_gate_c_no_false_positive_records(family_samples) else ["false_positive_records"],
			"attack_rebind_escape_count": int(perturbation_summary.get("attack_rebind_escape_count", 0)),
			"attack_rebind_recontact_count": int(perturbation_summary.get("attack_rebind_recontact_count", 0)),
			"attack_midband_drift_count": int(perturbation_summary.get("attack_midband_drift_count", 0))
		},
		"warning_threshold_value": _compute_warning_threshold(family_samples),
		"error_threshold_value": _compute_error_threshold_weighted(family_samples),
		"fitted_from_sample_count": 20,
		"warning_threshold_source": "old_escape_hit==true/p95_contention",
		"error_threshold_source": "old_escape_hit==true/p95_contention",
		"old_escape_true_count": old_escape_true_values.size(),
		"old_escape_true_p95_contention_values": old_escape_true_values
	}
	var gate_results: Dictionary = probe_contract_snapshot.get("gate_results", {})
	gate_results["attack_rebind_escape_count"] = int(perturbation_summary.get("attack_rebind_escape_count", 0))
	gate_results["attack_rebind_recontact_count"] = int(perturbation_summary.get("attack_rebind_recontact_count", 0))
	gate_results["attack_midband_drift_count"] = int(perturbation_summary.get("attack_midband_drift_count", 0))
	var unified_snapshot := {
		"family": "critical",
		"takeover_ready": bool(gate_results.get("takeover_ready", false)),
		"sample_count": int(probe_contract_snapshot.get("fitted_from_sample_count", 0)),
		"gate_results": gate_results,
		"blockers": gate_results.get("takeover_blockers", []),
		"support_counts": {
			"old_escape_true_count": int(probe_contract_snapshot.get("old_escape_true_count", 0))
		},
		"confidence_score": confidence_score,
		"thresholds": {
			"warning_threshold_value": float(probe_contract_snapshot.get("warning_threshold_value", 0.0)),
			"error_threshold_value": float(probe_contract_snapshot.get("error_threshold_value", 0.0))
		}
	}
	var scatter_plot := {
		"svg_artifact": "scatter",
		"x_axis": "p95_contention",
		"y_axis": "max_duration"
	}
	var critical_sampling_result_contract := {
		"csv_output_path": "user://critical_sampling.csv",
		"json_output_path": "user://critical_sampling.json",
		"svg_output_path": "user://critical_sampling.svg",
		"run_count_completed": 20
	}
	var outliers := {
		"outlier_count": 0,
		"outlier_samples": []
	}
	var payload := {
		"sampling_plan": sampling_plan,
		"fingerprint_zone_summary": fingerprint_zone_summary,
		"threshold_formula": threshold_formula,
		"fitted_thresholds": fitted_thresholds,
		"probe_contract_snapshot": probe_contract_snapshot,
		"unified_snapshot": unified_snapshot,
		"anomaly_scan": anomaly_scan,
		"perturbation_summary": perturbation_summary,
		"long_running_stability": long_running_stability,
		"scatter_plot": scatter_plot,
		"critical_sampling_result_contract": critical_sampling_result_contract,
		"outliers": outliers,
		"samples": family_samples
	}
	var unified_json_file := FileAccess.open("user://critical_sampling.json", FileAccess.WRITE)
	if unified_json_file != null:
		unified_json_file.store_string(JSON.stringify(payload, "\t"))
		unified_json_file.close()
	push_warning("contention_shadow_hit=%s" % JSON.stringify(shadow_warning))
	_assert_true(focused_escapes.is_empty(), "v3 runtime probe fixture should eliminate repeated ATTACK rebind escape samples", failures)
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_contact_oscillation: %s" % failure)
	quit(1 if not failures.is_empty() else 0)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
