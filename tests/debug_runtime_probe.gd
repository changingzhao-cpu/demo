extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const OUTPUT_PATH := "user://runtime_probe.json"
const SAMPLE_TIMES := [0.03, 0.5, 1.0]

func _initialize() -> void:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		printerr("[PROBE] failed to load battle scene")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	await process_frame
	var runtime: Node = instance
	var samples: Array = []
	var elapsed := 0.0
	var sample_index := 0
	while sample_index < SAMPLE_TIMES.size():
		var step := 0.01
		runtime.call("_process", step)
		await process_frame
		elapsed += step
		if elapsed + 0.0001 < float(SAMPLE_TIMES[sample_index]):
			continue
		var snapshot: Dictionary = runtime.call("debug_get_runtime_view_snapshot")
		var visible_entities: Array = []
		for item in snapshot.get("views", []):
			if bool(item.get("visible", false)) and int(item.get("entity_id", -1)) != -1:
				visible_entities.append({
					"entity_id": int(item.get("entity_id", -1)),
					"position": item.get("position", Vector2.ZERO),
					"global_position": item.get("global_position", Vector2.ZERO),
					"sprite": item.get("sprite", {})
				})
		samples.append({
			"time": elapsed,
			"snapshot": snapshot,
			"visible_entities": visible_entities
		})
		sample_index += 1
	var output := {
		"samples": samples
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
