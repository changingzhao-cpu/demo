# 战斗背景恢复实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 恢复战斗场景中的完整 arena 背景表现，同时保持当前已验收通过的角色可读性与前后层级遮挡效果。

**Architecture:** 直接在 `battle_scene.tscn` 中恢复当前被隐藏的 arena 场景节点，不新增新的背景系统，也不把背景显示逻辑转移到 runtime 脚本。通过测试先锁定“背景节点存在且默认可见”，再最小化修改场景节点的 `visible` 与弱化参数，确保背景在单位层下方显示且不影响现有单位层级排序。

**Tech Stack:** Godot 4.6、GDScript、`.tscn` 场景资源、自定义 headless 测试运行器

---

## 文件结构

- 修改：`scenes/battle/battle_scene.tscn`
  - 恢复 arena 相关节点的可见状态。
  - 必要时微调现有弱化参数，例如 `color`、`default_color`、透明度或轻微位置/尺寸参数。
- 修改：`tests/battle/test_battle_scene_side_angle_readability.gd`
  - 增加 arena 节点默认可见性的断言。
- 可选修改：`tests/battle/test_battle_scene_visual_bootstrap.gd`
  - 如果现有测试没有覆盖“背景出现但不抢戏”，则补充最小断言。
- 验证：`scripts/battle/battle_scene_runtime.gd`
  - 只用于确认无需新增背景切换逻辑；本计划不应修改它，除非发现真实阻塞问题。

---

### 任务 1：为 arena 背景默认可见写失败测试

**Files:**
- Modify: `tests/battle/test_battle_scene_side_angle_readability.gd`
- Test: `tests/battle/test_battle_scene_side_angle_readability.gd`

- [ ] **步骤 1：编写失败测试**

```gdscript
func _test_scene_conveys_side_angle_arena_readability(failures: Array[String]) -> void:
	var instance = BattleScene.instantiate()
	var arena_shadow = instance.get_node_or_null("ArenaShadow")
	var arena_floor = instance.get_node_or_null("ArenaFloor")
	var arena_rim = instance.get_node_or_null("ArenaRim")
	_assert_true(arena_shadow is CanvasItem and arena_shadow.visible, "ArenaShadow 应默认可见以提供场地纵深", failures)
	_assert_true(arena_floor is CanvasItem and arena_floor.visible, "ArenaFloor 应默认可见以提供战斗地板", failures)
	_assert_true(arena_rim is CanvasItem and arena_rim.visible, "ArenaRim 应默认可见以提供场地边界", failures)
	instance.free()
```

- [ ] **步骤 2：运行测试并确认失败**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- `battle/test_battle_scene_side_angle_readability` 失败
- 失败原因是 `ArenaShadow` / `ArenaFloor` / `ArenaRim` 当前为 `visible = false`

- [ ] **步骤 3：提交测试代码**

```bash
git add tests/battle/test_battle_scene_side_angle_readability.gd
git commit -m "test: require visible arena background"
```

---

### 任务 2：最小化恢复 arena 背景节点显示

**Files:**
- Modify: `scenes/battle/battle_scene.tscn:399-430`
- Test: `tests/battle/test_battle_scene_side_angle_readability.gd`

- [ ] **步骤 1：最小实现，只改场景节点可见性与弱化参数**

将以下节点从隐藏改为显示，并保持弱化视觉：

```tscn
[node name="ArenaShadow" type="Polygon2D" parent="."]
visible = true
position = Vector2(644, 476)
color = Color(0.22, 0.12, 0.08, 0.12)
z_index = -3

[node name="ArenaFloor" type="Polygon2D" parent="."]
visible = true
position = Vector2(640, 422)
texture = ExtResource("4_arena_floor")
color = Color(1, 1, 1, 0.72)
z_index = -2

[node name="ArenaRim" type="Line2D" parent="."]
visible = true
position = Vector2(640, 422)
default_color = Color(0.51, 0.24, 0.16, 0.28)
z_index = -1
```

说明：
- `ArenaFloor` 恢复贴图和较弱透明度。
- `ArenaShadow` 与 `ArenaRim` 只作为辅助层，透明度保持较低。
- 不调整 `UnitLayer.z_index = 2`，保证 arena 始终在单位层下方。

- [ ] **步骤 2：运行单套测试确认转绿**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- `battle/test_battle_scene_side_angle_readability` 通过
- 不出现新的场景解析错误

- [ ] **步骤 3：提交最小实现**

```bash
git add scenes/battle/battle_scene.tscn tests/battle/test_battle_scene_side_angle_readability.gd
git commit -m "feat: restore arena background visibility"
```

---

### 任务 3：补充“背景出现但不抢戏”的回归断言

**Files:**
- Modify: `tests/battle/test_battle_scene_visual_bootstrap.gd`
- Test: `tests/battle/test_battle_scene_visual_bootstrap.gd`

- [ ] **步骤 1：为背景弱化状态写失败测试**

如果该文件已有场景可读性断言，则追加最小检查：

```gdscript
func _test_background_exists_without_overpowering_units(failures: Array[String]) -> void:
	var instance = BattleScene.instantiate()
	var arena_floor = instance.get_node_or_null("ArenaFloor")
	var arena_shadow = instance.get_node_or_null("ArenaShadow")
	_assert_true(arena_floor is CanvasItem and arena_floor.visible, "ArenaFloor 应保持可见", failures)
	_assert_true(arena_shadow is CanvasItem and arena_shadow.visible, "ArenaShadow 应保持可见", failures)
	if arena_floor is Polygon2D:
		_assert_true(arena_floor.color.a <= 0.8, "ArenaFloor 应弱化显示，避免压过角色", failures)
	if arena_shadow is Polygon2D:
		_assert_true(arena_shadow.color.a <= 0.2, "ArenaShadow 应保持轻量，不应抢戏", failures)
	instance.free()
```

- [ ] **步骤 2：运行测试并确认失败或新增断言生效**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 如果参数还没调整到位，此测试先失败
- 失败信息明确指向 arena 透明度或可见性

- [ ] **步骤 3：按测试结果微调场景参数到最小满足值**

如果断言失败，仅微调 `battle_scene.tscn` 中现有 arena 参数，例如：

```tscn
color = Color(1, 1, 1, 0.68)
default_color = Color(0.51, 0.24, 0.16, 0.24)
```

原则：
- 只调现有参数
- 不增加新节点
- 不改 runtime 逻辑

- [ ] **步骤 4：运行测试确认通过**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- `battle/test_battle_scene_visual_bootstrap` 通过
- 其他 battle scene 测试继续通过

- [ ] **步骤 5：提交回归保护**

```bash
git add scenes/battle/battle_scene.tscn tests/battle/test_battle_scene_visual_bootstrap.gd
git commit -m "test: guard arena background readability"
```

---

### 任务 4：完整验证并准备视觉验收

**Files:**
- Verify: `scenes/battle/battle_scene.tscn`
- Verify: `scripts/battle/battle_scene_runtime.gd`

- [ ] **步骤 1：运行完整测试**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" -s res://tests/test_runner.gd
```

预期：
- 所有测试通过
- 不出现新的脚本解析错误

- [ ] **步骤 2：运行项目启动验证**

运行：
```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo" --quit
```

预期：
- 项目可启动
- 不出现 arena 资源加载错误

- [ ] **步骤 3：提交最终实现**

```bash
git add scenes/battle/battle_scene.tscn tests/battle/test_battle_scene_side_angle_readability.gd tests/battle/test_battle_scene_visual_bootstrap.gd
git commit -m "feat: restore battle arena presentation"
```

- [ ] **步骤 4：推送并请求用户做视觉验收**

```bash
git push
```

预期：
- 远端包含最新背景恢复改动
- 然后请用户录制或截图弹窗画面，确认背景恢复后角色仍然清晰、层级仍然正确
