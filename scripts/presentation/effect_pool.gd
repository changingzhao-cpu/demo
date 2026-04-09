extends RefCounted
class_name EffectPool

const ObjectPoolScript = preload("res://scripts/battle/object_pool.gd")

var _pool
var _active_enemy_corpses: Array = []
var _active_ally_corpses: Array = []
var _ally_corpse_limit: int = 8

func _init(factory: Callable, prewarm_count: int, ally_corpse_limit: int = 8) -> void:
	_ally_corpse_limit = ally_corpse_limit
	_pool = ObjectPoolScript.new(
		factory,
		prewarm_count,
		func(effect) -> void:
			effect.active = false
			effect.reset_count += 1,
		func(effect) -> void:
			effect.active = true
	)

func play_effect(effect_key: String):
	var effect = _pool.borrow()
	if effect == null:
		return null
	effect.last_key = effect_key
	effect.play_count += 1
	return effect

func release_effect(effect) -> void:
	if effect == null:
		return
	_remove_active_reference(effect)
	_pool.release(effect)

func spawn_enemy_corpse(ttl: float):
	var corpse = play_effect("enemy_corpse")
	if corpse == null:
		return null
	corpse.ttl = ttl
	corpse.team = "enemy"
	_active_enemy_corpses.append(corpse)
	return corpse

func spawn_ally_corpse():
	var retired = null
	if _active_ally_corpses.size() >= _ally_corpse_limit:
		retired = _active_ally_corpses.pop_front()
		if _pool.available_count() == 0:
			release_effect(retired)

	var corpse = play_effect("ally_corpse")
	if corpse == null:
		return null

	if retired != null and retired != corpse and retired.active:
		release_effect(retired)

	corpse.ttl = -1.0
	corpse.team = "ally"
	_active_ally_corpses.append(corpse)
	return corpse

func tick_corpses(delta: float) -> void:
	var survivors: Array = []
	for corpse in _active_enemy_corpses:
		corpse.ttl -= delta
		if corpse.ttl > 0.0:
			survivors.append(corpse)
			continue
		release_effect(corpse)
	_active_enemy_corpses = survivors

	var active_allies: Array = []
	for corpse in _active_ally_corpses:
		if corpse.active:
			active_allies.append(corpse)
	_active_ally_corpses = active_allies

func available_count() -> int:
	return _pool.available_count()

func _remove_active_reference(effect) -> void:
	var enemy_index := _active_enemy_corpses.find(effect)
	if enemy_index != -1:
		_active_enemy_corpses.remove_at(enemy_index)
	var ally_index := _active_ally_corpses.find(effect)
	if ally_index != -1:
		_active_ally_corpses.remove_at(ally_index)
