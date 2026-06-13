# Stage 3 Degradative Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 基于已解释的真实业务毛刺案例，落地第一版低风险降级式反馈路径，让 V4 在不阻断战斗逻辑的前提下先做节流与降载。

**Architecture:** 保持 V4 仍以观察者为主，但允许在达到 Warning/Critical 条件时触发轻量反馈。反馈只作用于特效、AI 精度或负载节流，不直接修改 battle 主判定。先锁住反馈字段和入口，再引入最小反馈策略，最后验证 smoke/full runner 继续稳定。

**Tech Stack:** Godot 4 GDScript、battle scene runtime、battle controller、effect feedback、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `scripts/battle/battle_controller.gd` | runtime controller | 暴露最小 gate feedback 状态或策略读取接口 |
| `scripts/battle/battle_scene_runtime.gd` | 真实业务 battle 入口 | 按 V4 信号触发降级式反馈 |
| `tests/battle/test_battle_scene_effect_feedback.gd` | effect feedback contract | 锁住反馈存在且不粗暴阻断战斗 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 锁住业务路径能暴露 feedback 相关状态 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace contract | 锁住 feedback 前后 trace payload 仍稳定 |
| `docs/v4_delivery_archive.md` | 交付档案 | 记录 Stage 3 / Degradative Feedback 里程碑 |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 把下一阶段更新为 authoritative takeover 准备 |
| `docs/v4_real_business_baseline.md` | 基线文档 | 记录由解释案例导出的第一版反馈策略 |

## Task 1: 锁住反馈入口与状态字段

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Modify: `scripts/battle/battle_controller.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 trace contract 中先写失败断言，锁住 payload 必须暴露 feedback 状态字段**

```gdscript
_assert_trace_true(trace_payload.has("feedback_mode"), "runtime trace payload should expose feedback_mode", failures)
_assert_trace_true(trace_payload.has("feedback_active"), "runtime trace payload should expose feedback_active", failures)
```

- [ ] **Step 2: 在 scene binding contract 中先写失败断言，锁住真实 scene 路径也能读到 feedback 状态**

```gdscript
var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
_assert_true(payload.has("feedback_mode"), "battle scene runtime trace payload should expose feedback_mode", failures)
_assert_true(payload.has("feedback_active"), "battle scene runtime trace payload should expose feedback_active", failures)
```

- [ ] **Step 3: 在 `battle_controller.gd` 写最小反馈状态输出，不接业务判定**

```gdscript
var _v4_feedback_mode := "observe_only"
var _v4_feedback_active := false

func debug_get_runtime_trace_payload() -> Dictionary:
	var probe_payload := _build_runtime_trace_payload()
	var nested_probe: Dictionary = probe_payload.get("probe", {})
	var output := probe_payload.duplicate(true)
	output["probe"] = nested_probe.duplicate(true)
	output["business_probe_events"] = _v4_business_probe_events.duplicate(true)
	output["feedback_mode"] = _v4_feedback_mode
	output["feedback_active"] = _v4_feedback_active
	output["warning_unified_snapshot"] = _read_warning_unified_snapshot_for_debug()
	output["critical_unified_snapshot"] = _read_critical_unified_snapshot_for_debug()
	for key in nested_probe.keys():
		output[key] = nested_probe[key]
	return output
```

- [ ] **Step 4: 运行 smoke 与 full runner**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/battle_controller.gd tests/battle/test_battle_runtime_probe_trace_contract.gd tests/battle/test_battle_scene_runtime_binding.gd
git commit -m "feat: expose degradative feedback state"
```

## Task 2: 落地最小降级式反馈策略

**Files:**
- Modify: `scripts/battle/battle_scene_runtime.gd`
- Modify: `tests/battle/test_battle_scene_effect_feedback.gd`
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/battle/test_battle_scene_effect_feedback.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 effect feedback contract 中先写失败断言，锁住反馈不是粗暴阻断，而是轻量降载**

```gdscript
_assert_true(runtime_trace_payload.get("feedback_mode", "") == "degradative", "feedback mode should switch to degradative during stress handling", failures)
_assert_true(bool(runtime_trace_payload.get("feedback_active", false)) == true, "feedback should become active under stress handling", failures)
```

- [ ] **Step 2: 在 `battle_scene_runtime.gd` 中加入最小反馈逻辑，只在高密度解释案例对应信号下切换模式**

```gdscript
func _refresh_v4_degradative_feedback() -> void:
	if _controller == null:
		return
	var payload: Dictionary = _controller.call("debug_get_runtime_trace_payload")
	var critical_snapshot: Dictionary = payload.get("critical_unified_snapshot", {})
	var gate_results: Dictionary = critical_snapshot.get("gate_results", {})
	var should_degrade := int(gate_results.get("attack_midband_drift_count", 0)) > 0 or int(gate_results.get("attack_rebind_escape_count", 0)) > 0
	_controller.set("_v4_feedback_mode", "degradative" if should_degrade else "observe_only")
	_controller.set("_v4_feedback_active", should_degrade)
```

- [ ] **Step 3: 把反馈策略写进 baseline 文档**

```md
## First degradative feedback policy

| Signal | Feedback |
|---|---|
| `attack_midband_drift_count > 0` | reduce non-core battle effects |
| `attack_rebind_escape_count > 0` | relax AI precision before altering battle authority |
```

- [ ] **Step 4: 运行 smoke 与 full runner**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/battle_scene_runtime.gd tests/battle/test_battle_scene_effect_feedback.gd docs/v4_real_business_baseline.md
git commit -m "feat: add first degradative business feedback"
```

## Task 3: 固化 Stage 3 里程碑与下一阶段入口

**Files:**
- Modify: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_backlog_tiers.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 delivery archive 中增加 Stage 3 里程碑段**

```md
## Phase D / Degradative Feedback
- Goal: apply low-risk throttling feedback before any authoritative takeover.
- Current policy: reduce non-core effects and relax AI precision before changing battle authority.
```

- [ ] **Step 2: 在 backlog tiers 中把 Active next phase 更新为 authoritative takeover 准备**

```md
## Active next phase
- Phase E / Authoritative Takeover
- Goal: verify whether takeover_ready can safely enter business decision loops
```

- [ ] **Step 3: 运行 smoke 与 full runner**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_delivery_archive.md docs/v4_backlog_tiers.md
git commit -m "docs: mark degradative feedback milestone"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖反馈状态字段、最小降级策略、Stage 3 里程碑与下一阶段入口 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 统一使用 `feedback_mode`、`feedback_active`、`degradative`、`observe_only` |
| Scope check | 聚焦低风险反馈，不提前进入 authoritative takeover |
