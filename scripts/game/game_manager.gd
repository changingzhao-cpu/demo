extends RefCounted
class_name GameManager

const GameStateMachineScript = preload("res://scripts/game/game_state_machine.gd")
const WaveControllerScript = preload("res://scripts/battle/wave_controller.gd")

var _state_machine
var _wave_controller

func _init(wave_defs_path: String) -> void:
	_state_machine = GameStateMachineScript.new()
	_wave_controller = WaveControllerScript.new(wave_defs_path)

func start_run() -> Dictionary:
	_state_machine.start_run()
	return _wave_controller.start_run()

func handle_wave_clear() -> void:
	_wave_controller.complete_current_wave(true)
	_state_machine.on_wave_cleared()

func claim_reward_and_advance() -> Dictionary:
	var next_wave: Dictionary = _wave_controller.advance_after_reward()
	_state_machine.finish_reward()
	return next_wave

func handle_run_failed() -> void:
	_wave_controller.complete_current_wave(false)
	_state_machine.on_run_failed()

func get_state() -> String:
	return _state_machine.get_state()
