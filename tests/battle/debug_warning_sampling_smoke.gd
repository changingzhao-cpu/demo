extends SceneTree

const BattleWarningSamplerFactory = preload("res://tests/battle/battle_warning_sampler_factory.gd")
const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func _initialize() -> void:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		quit(1)
		return
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		quit(1)
		return
	if controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	for _i in range(24):
		if controller.has_method("tick_combat"):
			controller.call("tick_combat", 0.016)
	var runtime_trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller.has_method("debug_get_runtime_trace_payload") else {}
	var probe: Dictionary = runtime_trace_payload.get("probe", {})
	var sampler_core = BattleWarningSamplerFactory.create_core("corridor", 0)
	var sample: Dictionary = sampler_core.sample(probe)
	var file := FileAccess.open("user://warning_sampling_smoke.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(sample, "\t"))
		file.close()
	instance.queue_free()
	await process_frame
	quit(0 if str(sample.get("error", "")) == "" else 1)
	return

func _deferred_force_backend(instance: Node) -> void:
	if instance == null:
		return
	var controller = instance.get_node_or_null("BattleController")
	if controller != null and controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
