# 单位战斗逻辑重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把当前单位索敌、移动、攻击整链路重构为一套轻量、可控、适合微信小游戏手机端的行为系统，并优先解决原地抖动、鬼畜横跳和拥挤不出手问题。

**Architecture:** 保留 `battle_controller.gd` 作为总控，保留 `battle_simulation.gd` 作为主行为文件，但将其内部重排为明确的状态步骤：目标校验、目标获取、攻击位分配、朝攻击位移动、攻击判定与攻击执行。第一阶段不拆成大量新脚本，而是在现有文件中引入轻量状态机与 4 攻击位机制，删除高随机性扰动和高频位置修正。

**Tech Stack:** Godot 4.6、GDScript、自定义 headless 测试运行器、实体存储数组结构、空间网格邻域查询

---

## 文件结构

- 修改：`scripts/battle/battle_simulation.gd`
  - 引入轻量状态机步骤。
  - 删除 `lane_bias` 和 `nudge` 驱动的非稳定运动。
  - 加入攻击位分配、位点移动与位点释放。
- 修改：`scripts/battle/entity_store.gd`
  - 为目标锁定状态、攻击位索引、位点归属等数据提供最小存储字段。
- 修改：`scripts/battle/battle_controller.gd`
  - 保持总控不变，仅补充必要的 report 字段或调试输出。
- 修改：`tests/battle/test_battle_simulation_targeting.gd`
  - 强化锁敌稳定性测试。
- 修改：`tests/battle/test_battle_simulation_attacks.gd`
  - 增加强制到位后进入攻击的测试。
- 创建：`tests/battle/test_battle_simulation_engagement_slots.gd`
  - 测试攻击位分配与拥挤下的稳定出手。
- 创建：`tests/battle/test_battle_simulation_anti_jitter.gd`
  - 测试连续 tick 下不应横跳/抖动。

---

### Task 1: 锁定当前目标稳定性

**Files:**
- Modify: `tests/battle/test_battle_simulation_targeting.gd`
- Test: `tests/battle/test_battle_simulation_targeting.gd`

- [ ] **Step 1: 写失败测试，要求有效目标不因更近敌人瞬时出现而切换**

```gdscript
func _test_valid_target_lock_is_kept_even_when_a_closer_enemy_appears(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var locked_target: int = store.allocate()
	var closer_target: int = store.allocate()
	store.team_id[attacker] = 0
	store.team_id[locked_target] = 1
	store.team_id[closer_target] = 1
	store.position_x[attacker] = 0.0
	store.position_y[attacker] = 0.0
	store.position_x[locked_target] = 6.0
	store.position_y[locked_target] = 0.0
	store.position_x[closer_target] = 2.0
	store.position_y[closer_target] = 0.0
	store.target_id[attacker] = locked_target
	store.move_speed[attacker] = 4.0
	grid.upsert(attacker, Vector2(0.0, 0.0))
	grid.upsert(locked_target, Vector2(6.0, 0.0))
	grid.upsert(closer_target, Vector2(2.0, 0.0))
	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.target_id[attacker], locked_target, "valid target lock should be kept until a hard invalidation happens", failures)
```

- [ ] **Step 2: 运行测试，确认失败原因正确**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- `battle/test_battle_simulation_targeting` 失败
- 失败原因是当前有效目标锁不够稳定

- [ ] **Step 3: 在 `battle_simulation.gd` 中实现最小锁敌判定重构**

```gdscript
func _update_target_state(store, entity_id: int) -> int:
	var current_target := int(store.target_id[entity_id])
	if _is_target_valid(store, entity_id, current_target):
		return current_target
	return _acquire_target(store, entity_id)

func _acquire_target(store, entity_id: int) -> int:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	var best_target := -1
	var best_distance_sq := INF
	for candidate in _grid.query_neighbors(origin):
		if not _is_enemy_candidate(store, entity_id, candidate):
			continue
		var distance_sq := origin.distance_squared_to(Vector2(store.position_x[candidate], store.position_y[candidate]))
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = candidate
	return best_target
```

- [ ] **Step 4: 运行测试确认通过**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 新锁敌测试通过
- 现有 targeting 测试继续通过

- [ ] **Step 5: 提交**

```bash
git add tests/battle/test_battle_simulation_targeting.gd scripts/battle/battle_simulation.gd
git commit -m "feat: stabilize target locking"
```

---

### Task 2: 引入 4 攻击位数据与最小占位规则

**Files:**
- Modify: `scripts/battle/entity_store.gd`
- Modify: `scripts/battle/battle_simulation.gd`
- Create: `tests/battle/test_battle_simulation_engagement_slots.gd`
- Test: `tests/battle/test_battle_simulation_engagement_slots.gd`

- [ ] **Step 1: 写失败测试，要求两个近战单位围同一目标时占不同攻击位**

```gdscript
func _test_attackers_claim_different_slots_around_the_same_target(failures: Array[String]) -> void:
	var store = EntityStore.new(3)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker_a: int = store.allocate()
	var attacker_b: int = store.allocate()
	var target: int = store.allocate()
	store.team_id[attacker_a] = 0
	store.team_id[attacker_b] = 0
	store.team_id[target] = 1
	store.position_x[attacker_a] = -3.0
	store.position_y[attacker_a] = 0.0
	store.position_x[attacker_b] = -3.0
	store.position_y[attacker_b] = 1.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.move_speed[attacker_a] = 4.0
	store.move_speed[attacker_b] = 4.0
	grid.upsert(attacker_a, Vector2(-3.0, 0.0))
	grid.upsert(attacker_b, Vector2(-3.0, 1.0))
	grid.upsert(target, Vector2(0.0, 0.0))
	simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_true(store.engagement_slot[attacker_a] != store.engagement_slot[attacker_b], "attackers should claim different engagement slots", failures)
```

- [ ] **Step 2: 运行测试，确认失败**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 新建 `battle/test_battle_simulation_engagement_slots` 失败
- 失败原因是当前没有攻击位机制

- [ ] **Step 3: 在 `entity_store.gd` 增加最小字段**

```gdscript
var engagement_slot: PackedInt32Array
var engagement_target: PackedInt32Array
var engagement_blocked_time: PackedFloat32Array
```

在初始化中分配默认值：

```gdscript
engagement_slot = PackedInt32Array()
engagement_slot.resize(capacity)
engagement_target = PackedInt32Array()
engagement_target.resize(capacity)
engagement_blocked_time = PackedFloat32Array()
engagement_blocked_time.resize(capacity)
for i in range(capacity):
	engagement_slot[i] = -1
	engagement_target[i] = -1
	engagement_blocked_time[i] = 0.0
```

- [ ] **Step 4: 在 `battle_simulation.gd` 中增加 4 攻击位分配**

```gdscript
const ENGAGEMENT_SLOT_OFFSETS := [
	Vector2(-1.2, 0.0),
	Vector2(1.2, 0.0),
	Vector2(0.0, -1.0),
	Vector2(0.0, 1.0)
]

func _resolve_engagement_slot(store, entity_id: int, target_id: int) -> int:
	if store.engagement_target[entity_id] == target_id and store.engagement_slot[entity_id] >= 0:
		return store.engagement_slot[entity_id]
	for slot_index in range(ENGAGEMENT_SLOT_OFFSETS.size()):
		if _is_engagement_slot_free(store, entity_id, target_id, slot_index):
			store.engagement_target[entity_id] = target_id
			store.engagement_slot[entity_id] = slot_index
			return slot_index
	store.engagement_target[entity_id] = target_id
	store.engagement_slot[entity_id] = -1
	return -1
```

- [ ] **Step 5: 运行测试确认通过**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- engagement slot 测试通过
- 现有 targeting 测试继续通过

- [ ] **Step 6: 提交**

```bash
git add scripts/battle/entity_store.gd scripts/battle/battle_simulation.gd tests/battle/test_battle_simulation_engagement_slots.gd
git commit -m "feat: add engagement slot allocation"
```

---

### Task 3: 用攻击位替代中心点追击

**Files:**
- Modify: `scripts/battle/battle_simulation.gd`
- Modify: `tests/battle/test_battle_simulation_attacks.gd`
- Test: `tests/battle/test_battle_simulation_attacks.gd`

- [ ] **Step 1: 写失败测试，要求单位接近攻击位后进入攻击态**

```gdscript
func _test_attacker_enters_attack_state_after_reaching_engagement_slot(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	store.team_id[attacker] = 0
	store.team_id[target] = 1
	store.position_x[attacker] = -1.4
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.move_speed[attacker] = 4.0
	store.attack_range_sq[attacker] = 0.25
	grid.upsert(attacker, Vector2(-1.4, 0.0))
	grid.upsert(target, Vector2(0.0, 0.0))
	for _step in range(6):
		simulation.tick_bucket(store, 0.1, 0, 1)
	_assert_eq(store.state[attacker], 1, "attacker should enter attack state after reaching its engagement slot", failures)
```

- [ ] **Step 2: 运行测试并确认失败**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- attack reachability 测试失败
- 失败原因是当前移动目标不是攻击位

- [ ] **Step 3: 最小实现：移动目标改为攻击位坐标**

```gdscript
func _resolve_engagement_slot_position(store, target_id: int, slot_index: int) -> Vector2:
	var target_position := Vector2(store.position_x[target_id], store.position_y[target_id])
	return target_position + ENGAGEMENT_SLOT_OFFSETS[slot_index]

func _move_to_engagement_slot(store, entity_id: int, target_id: int, delta: float) -> void:
	var slot_index := _resolve_engagement_slot(store, entity_id, target_id)
	if slot_index == -1:
		return
	var slot_position := _resolve_engagement_slot_position(store, target_id, slot_index)
	_move_toward_position(store, entity_id, slot_position, delta)
```

- [ ] **Step 4: 删除当前高风险扰动**

把以下逻辑删除或停用：

```gdscript
var lane_bias := sin(float(entity_id) * 1.37) * FORMATION_LANE_STRENGTH
var move_vector := (forward + lateral * lane_bias).normalized()
```

改成：

```gdscript
var move_vector := forward
```

并删除卡住后的：

```gdscript
if before_move.distance_to(Vector2(store.position_x[entity_id], store.position_y[entity_id])) <= 0.001:
	var nudge := signf(target.x - before_move.x)
	...
```

- [ ] **Step 5: 运行测试确认通过**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 新攻击位到位测试通过
- 现有移动、攻击测试继续通过

- [ ] **Step 6: 提交**

```bash
git add scripts/battle/battle_simulation.gd tests/battle/test_battle_simulation_attacks.gd
git commit -m "feat: move units toward engagement slots"
```

---

### Task 4: 防抖动回归保护

**Files:**
- Create: `tests/battle/test_battle_simulation_anti_jitter.gd`
- Modify: `scripts/battle/battle_simulation.gd`
- Test: `tests/battle/test_battle_simulation_anti_jitter.gd`

- [ ] **Step 1: 写失败测试，要求连续 tick 下不能横向来回震荡**

```gdscript
func _test_attacker_does_not_ping_pong_horizontally_while_chasing(failures: Array[String]) -> void:
	var store = EntityStore.new(2)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var attacker: int = store.allocate()
	var target: int = store.allocate()
	store.team_id[attacker] = 0
	store.team_id[target] = 1
	store.position_x[attacker] = -4.0
	store.position_y[attacker] = 0.0
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	store.move_speed[attacker] = 4.0
	grid.upsert(attacker, Vector2(-4.0, 0.0))
	grid.upsert(target, Vector2(0.0, 0.0))
	var xs: Array[float] = []
	for _step in range(6):
		simulation.tick_bucket(store, 0.1, 0, 1)
		xs.append(store.position_x[attacker])
	_assert_true(xs[1] >= xs[0] and xs[2] >= xs[1] and xs[3] >= xs[2], "attacker x movement should remain monotonic while approaching a target slot", failures)
```

- [ ] **Step 2: 运行测试并确认失败**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- anti-jitter 测试失败
- 失败原因是旧扰动逻辑导致位置不单调

- [ ] **Step 3: 最小实现：把局部修正降级为从属修正**

```gdscript
func _apply_same_team_spacing(store, entity_id: int) -> void:
	var origin := Vector2(store.position_x[entity_id], store.position_y[entity_id])
	for candidate in _grid.query_neighbors(origin):
		if candidate == entity_id:
			continue
		if not store.alive[candidate]:
			continue
		if store.team_id[candidate] != store.team_id[entity_id]:
			continue
		var candidate_position := Vector2(store.position_x[candidate], store.position_y[candidate])
		if origin.distance_to(candidate_position) < 0.6:
			var offset := (origin - candidate_position).normalized()
			store.position_x[entity_id] += offset.x * 0.04
			store.position_y[entity_id] += offset.y * 0.04
```

说明：
- 第一阶段只保留极小的防重叠修正
- 不再允许修正量超过主运动方向

- [ ] **Step 4: 运行测试确认通过**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- anti-jitter 测试通过
- 现有 movement / attack 测试不回退

- [ ] **Step 5: 提交**

```bash
git add scripts/battle/battle_simulation.gd tests/battle/test_battle_simulation_anti_jitter.gd
git commit -m "test: guard against combat jitter"
```

---

### Task 5: 拥挤场景下的稳定出手

**Files:**
- Modify: `tests/battle/test_battle_simulation_attacks.gd`
- Modify: `scripts/battle/battle_simulation.gd`
- Test: `tests/battle/test_battle_simulation_attacks.gd`

- [ ] **Step 1: 写失败测试，要求多个单位围一个目标时至少有单位稳定出手**

```gdscript
func _test_crowded_attackers_do_not_all_stall_without_attacking(failures: Array[String]) -> void:
	var store = EntityStore.new(5)
	var grid = SpatialGrid.new(10.0)
	var simulation = BattleSimulationScript.new(grid)
	var target: int = store.allocate()
	store.team_id[target] = 1
	store.position_x[target] = 0.0
	store.position_y[target] = 0.0
	grid.upsert(target, Vector2.ZERO)
	var attackers: Array[int] = []
	for index in range(4):
		var attacker: int = store.allocate()
		attackers.append(attacker)
		store.team_id[attacker] = 0
		store.position_x[attacker] = -3.0 - float(index) * 0.2
		store.position_y[attacker] = float(index) * 0.4
		store.move_speed[attacker] = 4.0
		store.attack_range_sq[attacker] = 0.25
		grid.upsert(attacker, Vector2(store.position_x[attacker], store.position_y[attacker]))
	for _step in range(12):
		simulation.tick_bucket(store, 0.1, 0, 1)
	var attackers_in_attack := 0
	for attacker in attackers:
		if store.state[attacker] == 1:
			attackers_in_attack += 1
	_assert_true(attackers_in_attack >= 1, "crowded attackers should not all stall without entering attack", failures)
```

- [ ] **Step 2: 运行测试并确认失败**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 拥挤场景测试失败
- 失败原因是当前多人围攻时存在一起卡住的问题

- [ ] **Step 3: 最小实现：攻击位不可达时先换位，不立即乱修正位置**

```gdscript
func _update_engagement_blocked_time(store, entity_id: int, moved_distance: float, delta: float) -> void:
	if moved_distance <= 0.01:
		store.engagement_blocked_time[entity_id] += delta
	else:
		store.engagement_blocked_time[entity_id] = 0.0
	if store.engagement_blocked_time[entity_id] >= 0.35:
		store.engagement_slot[entity_id] = -1
		store.engagement_blocked_time[entity_id] = 0.0
```

- [ ] **Step 4: 运行测试确认通过**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 拥挤出手测试通过
- 不引入新的抖动回归

- [ ] **Step 5: 提交**

```bash
git add scripts/battle/battle_simulation.gd tests/battle/test_battle_simulation_attacks.gd
git commit -m "feat: keep crowded units attacking"
```

---

### Task 6: 完整验证与收尾

**Files:**
- Verify: `scripts/battle/battle_simulation.gd`
- Verify: `scripts/battle/entity_store.gd`
- Verify: `scripts/battle/battle_controller.gd`
- Verify: `tests/battle/*.gd`

- [ ] **Step 1: 运行完整测试**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 所有测试通过
- 不出现新的脚本解析错误

- [ ] **Step 2: 运行项目启动验证**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" --quit
```

预期：
- 项目可启动
- 不出现资源或脚本加载错误

- [ ] **Step 3: 提交最终整合结果**

```bash
git add scripts/battle/battle_simulation.gd scripts/battle/entity_store.gd scripts/battle/battle_controller.gd tests/battle/test_battle_simulation_targeting.gd tests/battle/test_battle_simulation_attacks.gd tests/battle/test_battle_simulation_engagement_slots.gd tests/battle/test_battle_simulation_anti_jitter.gd
git commit -m "feat: refactor combat control flow"
```

- [ ] **Step 4: 推送并进入视觉验收**

```bash
git push
```

预期：
- 远端包含新的可控战斗逻辑
- 随后通过弹窗录屏或截图验收单位索敌、接敌和攻击表现
