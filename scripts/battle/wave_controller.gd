extends RefCounted
class_name WaveController

var _wave_defs_path: String
var _waves: Array = []
var _current_wave_index: int = -1
var _reward_pending: bool = false
var _finished: bool = false

func _init(wave_defs_path: String) -> void:
	_wave_defs_path = wave_defs_path
	_waves = _load_waves()

func start_run() -> Dictionary:
	_finished = _waves.is_empty()
	_reward_pending = false
	_current_wave_index = 0 if not _finished else -1
	return get_current_wave()

func get_current_wave() -> Dictionary:
	if _current_wave_index < 0 or _current_wave_index >= _waves.size():
		return {}
	var wave: Variant = _waves[_current_wave_index]
	if wave is Dictionary:
		return wave
	return {}

func complete_current_wave(victory: bool) -> void:
	if _finished or _current_wave_index == -1:
		return
	if not victory:
		_finished = true
		_reward_pending = false
		return
	if _current_wave_index >= _waves.size() - 1:
		_finished = true
		_reward_pending = false
		return
	_reward_pending = true

func advance_after_reward() -> Dictionary:
	if not _reward_pending:
		return get_current_wave()
	_reward_pending = false
	_current_wave_index += 1
	return get_current_wave()

func current_wave_index() -> int:
	return _current_wave_index

func is_reward_pending() -> bool:
	return _reward_pending

func is_finished() -> bool:
	return _finished

func has_next_wave() -> bool:
	return _current_wave_index >= 0 and _current_wave_index < _waves.size() - 1

func _load_waves() -> Array:
	if not FileAccess.file_exists(_wave_defs_path):
		return []
	var file := FileAccess.open(_wave_defs_path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed
	return []
