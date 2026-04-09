extends Node
class_name BattleController

const GameStateMachineScript = preload("res://scripts/game/game_state_machine.gd")
const WaveControllerScript = preload("res://scripts/battle/wave_controller.gd")

@export var wave_defs_path: String = "res://data/wave_defs.json"

var _state_machine
var _wave_controller
var _current_wave: Dictionary = {}

func _init(wave_defs_path_value: String = "res://data/wave_defs.json") -> void:
	wave_defs_path = wave_defs_path_value
	_ensure_dependencies()

func _ready() -> void:
	_ensure_dependencies()
	if _current_wave.is_empty():
		start_run()

func start_run() -> Dictionary:
	_ensure_dependencies()
	_state_machine.start_run()
	_wave_controller = WaveControllerScript.new(wave_defs_path)
	_current_wave = _wave_controller.start_run()
	return _current_wave

func handle_wave_clear() -> void:
	_ensure_dependencies()
	_wave_controller.complete_current_wave(true)
	_current_wave = _wave_controller.get_current_wave()
	_state_machine.on_wave_cleared()

func claim_reward_and_advance() -> Dictionary:
	_ensure_dependencies()
	_current_wave = _wave_controller.advance_after_reward()
	_state_machine.finish_reward()
	return _current_wave

func handle_run_failed() -> void:
	_ensure_dependencies()
	_wave_controller.complete_current_wave(false)
	_state_machine.on_run_failed()

func get_state() -> String:
	_ensure_dependencies()
	return _state_machine.get_state()

func get_current_wave() -> Dictionary:
	return _current_wave

func _ensure_dependencies() -> void:
	if _state_machine == null:
		_state_machine = GameStateMachineScript.new()
	if _wave_controller == null:
		_wave_controller = WaveControllerScript.new(wave_defs_path)
