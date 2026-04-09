extends RefCounted
class_name GameStateMachine

const STATE_INIT := "init"
const STATE_WAIT := "wait"
const STATE_COMBAT := "combat"
const STATE_REWARD := "reward"
const STATE_SETTLE := "settle"

var _state: String = STATE_INIT

func get_state() -> String:
	return _state

func start_run() -> void:
	_state = STATE_COMBAT

func on_wave_cleared() -> void:
	if _state != STATE_COMBAT:
		return
	_state = STATE_REWARD

func finish_reward() -> void:
	if _state != STATE_REWARD:
		return
	_state = STATE_COMBAT

func on_run_failed() -> void:
	_state = STATE_SETTLE

func reset_to_wait() -> void:
	_state = STATE_WAIT
