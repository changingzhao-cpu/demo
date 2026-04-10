extends RefCounted
class_name EffectPool

const ObjectPoolScript = preload("res://scripts/battle/object_pool.gd")
const ENEMY_CORPSE_TINT := Color(0.95, 0.4, 0.4, 0.45)
const ALLY_CORPSE_TINT := Color(0.45, 0.85, 1.0, 0.4)
const DEFAULT_TINT := Color.WHITE
const ENEMY_CORPSE_SCALE := Vector2(0.85, 0.85)
const ALLY_CORPSE_SCALE := Vector2(1.1, 1.1)
const DEFAULT_SCALE := Vector2.ONE

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
			effect.reset_count += 1
			_reset_visual_payload(effect),
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
	_apply_visual_payload(corpse, Vector2.ZERO, "enemy", "enemy_corpse", false)
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
	_apply_visual_payload(corpse, Vector2.ZERO, "ally", "ally_corpse", true)
	_active_ally_corpses.append(corpse)
	return corpse

func spawn_visual_event(effect_key: String, world_position: Vector2, team: String, ttl: float = 1.0):
	var effect = spawn_ally_corpse() if team == "ally" else spawn_enemy_corpse(ttl)
	if effect == null:
		return null
	effect.ttl = -1.0 if team == "ally" else ttl
	effect.team = team
	_apply_visual_payload(effect, world_position, team, effect_key, team == "ally")
	return effect

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

func get_active_effects() -> Array:
	var active_effects: Array = []
	active_effects.append_array(_active_enemy_corpses)
	active_effects.append_array(_active_ally_corpses)
	return active_effects

func available_count() -> int:
	return _pool.available_count()

func on_enemy_unit_died(ttl: float = 1.0):
	return spawn_enemy_corpse(ttl)

func on_ally_unit_died():
	return spawn_ally_corpse()

func _apply_visual_payload(effect, world_position: Vector2, team: String, visual_kind: String, persistent: bool) -> void:
	_set_effect_property_if_present(effect, "position", world_position)
	_set_effect_property_if_present(effect, "visual_kind", visual_kind)
	_set_effect_property_if_present(effect, "persistent", persistent)
	if team == "ally":
		_set_effect_property_if_present(effect, "tint", ALLY_CORPSE_TINT)
		_set_effect_property_if_present(effect, "scale", ALLY_CORPSE_SCALE)
	else:
		_set_effect_property_if_present(effect, "tint", ENEMY_CORPSE_TINT)
		_set_effect_property_if_present(effect, "scale", ENEMY_CORPSE_SCALE)

func _reset_visual_payload(effect) -> void:
	_set_effect_property_if_present(effect, "position", Vector2.ZERO)
	_set_effect_property_if_present(effect, "tint", DEFAULT_TINT)
	_set_effect_property_if_present(effect, "scale", DEFAULT_SCALE)
	_set_effect_property_if_present(effect, "visual_kind", "")
	_set_effect_property_if_present(effect, "persistent", false)

func _set_effect_property_if_present(effect, property_name: String, value) -> void:
	if effect == null:
		return
	if effect is Dictionary:
		effect[property_name] = value
		return
	for property in effect.get_property_list():
		if str(property.get("name", "")) == property_name:
			effect.set(property_name, value)
			return

func _remove_active_reference(effect) -> void:
	var enemy_index := _active_enemy_corpses.find(effect)
	if enemy_index != -1:
		_active_enemy_corpses.remove_at(enemy_index)
	var ally_index := _active_ally_corpses.find(effect)
	if ally_index != -1:
		_active_ally_corpses.remove_at(ally_index)
