extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const OUTPUT_PATH := "user://runtime_probe.json"
const SAMPLE_TIMES := [0.0, 0.01, 0.03, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 3.0, 4.0]
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
	var elapsed := 0.0
	var sample_index := 0
	while sample_index < SAMPLE_TIMES.size():
		var target_time := float(SAMPLE_TIMES[sample_index])
		if elapsed + 0.0001 < target_time:
			var step := minf(0.01, target_time - elapsed)
			await create_timer(step).timeout
			elapsed += step
			continue
		samples.append({
			"time": elapsed,
			"tick_before": _read_json("user://tick_probe_before.json"),
			"payload_probe": _read_json("user://runtime_payload_probe.json"),
			"view_probe": _read_json("user://runtime_view_probe.json"),
			"combat_feedback_probe": _read_json("user://combat_feedback_probe.json"),
			"combat_pulse_probe": _read_json("user://combat_pulse_probe.json"),
			"controller_recent_combat_events_probe": _read_json("user://controller_recent_combat_events_probe.json"),
			"controller_consume_combat_events_probe": _read_json("user://controller_consume_combat_events_probe.json"),
			"unit_view_attack_pulse_probe_33": _read_json("user://unit_view_attack_pulse_probe_33.json"),
			"unit_view_sync_probe_33": _read_json("user://unit_view_sync_probe_33.json"),
			"runtime_view_probe": _read_json("user://runtime_view_probe.json"),
			"controller_recent_deaths_probe": _read_json("user://controller_recent_deaths_probe.json")
		})
		sample_index += 1
	var controller := instance.get_node_or_null("BattleController")
	var attack_times: Dictionary = controller.call("debug_get_first_attack_times") if controller != null and controller.has_method("debug_get_first_attack_times") else {}
	var output := {
		"samples": samples,
		"initial_probe": FileAccess.get_file_as_string(INITIAL_PROBE),
		"runtime_probe": FileAccess.get_file_as_string(RUNTIME_PROBE),
		"tick_before": FileAccess.get_file_as_string("user://tick_probe_before.json"),
		"tick_after": FileAccess.get_file_as_string("user://tick_probe_after.json"),
		"initial_to_runtime_delta": FileAccess.get_file_as_string("user://initial_to_runtime_delta_probe.json"),
		"first_attack_times": attack_times
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
