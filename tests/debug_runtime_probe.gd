extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const OUTPUT_PATH := "user://runtime_probe.json"
const SAMPLE_TIMES := [0.03, 0.5, 1.0, 2.0, 3.0, 4.0]
const INITIAL_PROBE := "user://transition_initial_probe.json"
const RUNTIME_PROBE := "user://transition_runtime_probe.json"

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
	var runtime: Node = instance
	var samples: Array = []
	var elapsed := 0.0
	var sample_index := 0
	while sample_index < SAMPLE_TIMES.size():
		var step := 0.01
		await create_timer(step).timeout
		elapsed += step
		if elapsed + 0.0001 < float(SAMPLE_TIMES[sample_index]):
			continue
		var runtime_probe_text := FileAccess.get_file_as_string(RUNTIME_PROBE)
		if runtime_probe_text == "":
			printerr("[PROBE] missing runtime transition probe at ", ProjectSettings.globalize_path(RUNTIME_PROBE))
			quit(1)
			return
		var runtime_json := JSON.new()
		if runtime_json.parse(runtime_probe_text) != OK:
			printerr("[PROBE] failed to parse runtime transition probe")
			quit(1)
			return
		var runtime_snapshot: Dictionary = runtime_json.data
		var visible_entities: Array = []
		for item in runtime_snapshot.get("entries", []):
			if bool(item.get("visible", false)) and int(item.get("entity_id", -1)) != -1:
				visible_entities.append({
					"entity_id": int(item.get("entity_id", -1)),
					"position": item.get("position", Vector2.ZERO),
					"global_position": item.get("global_position", Vector2.ZERO)
				})
		var tick_before_text := FileAccess.get_file_as_string("user://tick_probe_before.json")
		var tick_before_json := JSON.new()
		var tick_before_snapshot: Dictionary = {}
		if tick_before_text != "" and tick_before_json.parse(tick_before_text) == OK:
			tick_before_snapshot = tick_before_json.data
		samples.append({
			"time": elapsed,
			"snapshot": tick_before_snapshot,
			"visible_entities": visible_entities
		})
		sample_index += 1
	var initial_probe := FileAccess.get_file_as_string(INITIAL_PROBE)
	var runtime_probe := FileAccess.get_file_as_string(RUNTIME_PROBE)
	var tick_before := FileAccess.get_file_as_string("user://tick_probe_before.json")
	var tick_after := FileAccess.get_file_as_string("user://tick_probe_after.json")
	var controller := instance.get_node_or_null("BattleController")
	var attack_times: Dictionary = controller.call("debug_get_first_attack_times") if controller != null and controller.has_method("debug_get_first_attack_times") else {}
	var output := {
		"samples": samples,
		"initial_probe": initial_probe,
		"runtime_probe": runtime_probe,
		"tick_before": tick_before,
		"tick_after": tick_after,
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
