extends RefCounted
class_name BattleWarningSamplerFactory

const BattleWarningSamplerCore = preload("res://tests/battle/battle_warning_sampler_core.gd")

static func create_core(scenario: String, run_id: int):
	return BattleWarningSamplerCore.new(scenario, run_id)
