extends RefCounted
class_name AttackResolver

func resolve_basic_attack(store, attacker_id: int, target_id: int, damage: float) -> bool:
	if attacker_id == target_id:
		return false
	if not store.alive[attacker_id]:
		return false
	if not store.alive[target_id]:
		store.target_id[attacker_id] = -1
		return false
	if store.attack_cd[attacker_id] > 0.0:
		return false

	_apply_damage(store, target_id, damage)
	store.attack_cd[attacker_id] = max(0.0, store.attack_interval[attacker_id])
	if store.alive[target_id]:
		return true

	store.target_id[attacker_id] = -1
	return true

func resolve_cleave_attack(store, attacker_id: int, target_id: int, damage: float, secondary_targets: Array, cleave_chance: float, max_secondary_targets: int, secondary_damage_scale: float) -> Dictionary:
	var result: Dictionary = {
		"hit": false,
		"secondary_hits": 0
	}
	var primary_team: int = store.team_id[target_id]
	var primary_hit: bool = resolve_basic_attack(store, attacker_id, target_id, damage)
	result["hit"] = primary_hit
	if not primary_hit:
		return result
	if cleave_chance <= 0.0 or max_secondary_targets <= 0:
		return result

	var secondary_hits: int = 0
	for candidate in secondary_targets:
		if secondary_hits >= max_secondary_targets:
			break
		var secondary_id: int = int(candidate)
		if secondary_id == attacker_id or secondary_id == target_id:
			continue
		if secondary_id < 0 or secondary_id >= store.capacity:
			continue
		if not store.alive[secondary_id]:
			continue
		if store.team_id[secondary_id] != primary_team:
			continue
		_apply_damage(store, secondary_id, damage * secondary_damage_scale)
		secondary_hits += 1

	result["secondary_hits"] = secondary_hits
	return result

func resolve_support_pulse(store, support_id: int, candidate_targets: Array, heal_amount: float, max_targets: int) -> Dictionary:
	var result: Dictionary = {
		"triggered": false,
		"affected": 0
	}
	if support_id < 0 or support_id >= store.capacity:
		return result
	if not store.alive[support_id]:
		return result
	if store.attack_cd[support_id] > 0.0:
		return result

	var affected: int = 0
	var support_team: int = store.team_id[support_id]
	for candidate in candidate_targets:
		if affected >= max_targets:
			break
		var target_id: int = int(candidate)
		if target_id < 0 or target_id >= store.capacity:
			continue
		if not store.alive[target_id]:
			continue
		if store.team_id[target_id] != support_team:
			continue
		store.hp[target_id] = min(store.max_hp[target_id], store.hp[target_id] + heal_amount)
		affected += 1

	store.attack_cd[support_id] = max(0.0, store.attack_interval[support_id])
	result["triggered"] = true
	result["affected"] = affected
	return result

func _apply_damage(store, target_id: int, damage: float) -> void:
	store.hp[target_id] = max(0.0, store.hp[target_id] - damage)
	if store.hp[target_id] > 0.0:
		return

	store.hp[target_id] = 0.0
	store.alive[target_id] = 0
	store.target_id[target_id] = -1
	store.state[target_id] = 4
	store.velocity_x[target_id] = 0.0
	store.velocity_y[target_id] = 0.0
	store.move_speed[target_id] = 0.0
	store.attack_cd[target_id] = 0.0
	store.grid_id[target_id] = -1
	store.bucket_id[target_id] = -1
	store.active_count = max(0, store.active_count - 1)
	if target_id not in store._free_ids:
		store._free_ids.push_front(target_id)
