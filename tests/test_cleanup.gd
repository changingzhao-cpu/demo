extends RefCounted
class_name TestCleanup

static func release_tree_instance(main_loop: SceneTree, instance: Node) -> void:
	if main_loop == null or instance == null:
		return
	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
	instance.queue_free()
	await main_loop.process_frame
	await main_loop.process_frame
