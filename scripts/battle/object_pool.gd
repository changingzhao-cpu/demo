extends RefCounted
class_name ObjectPool

var capacity: int = 0

var _factory: Callable
var _on_release: Callable
var _on_borrow: Callable
var _available: Array[Variant] = []
var _in_use: Dictionary = {}

func _init(factory: Callable, prewarm_count: int, on_release: Callable = Callable(), on_borrow: Callable = Callable()) -> void:
	_factory = factory
	_on_release = on_release
	_on_borrow = on_borrow
	capacity = max(0, prewarm_count)
	for _i in range(capacity):
		_available.append(_factory.call())

func borrow():
	if _available.is_empty():
		return null

	var item: Variant = _available.pop_back()
	_in_use[item] = true
	if _on_borrow.is_valid():
		_on_borrow.call(item)
	return item

func release(item: Variant) -> void:
	if item == null:
		return
	if not _in_use.has(item):
		return

	_in_use.erase(item)
	if _on_release.is_valid():
		_on_release.call(item)
	_available.append(item)

func available_count() -> int:
	return _available.size()
