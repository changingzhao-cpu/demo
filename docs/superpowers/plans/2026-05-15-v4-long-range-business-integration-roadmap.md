# V4 Long-Range Business Integration Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 demo 项目建立一份覆盖后续多个阶段的长线开发总计划，以真实业务接入为唯一主线，避免后续每次只做短段式规划。

**Architecture:** 以“真实业务接入 → 基线建立 → 毛刺解释 → 降级式反馈 → 业务闭环接管”作为单一主线推进，不插入无真实压力的大规模结构整顿。每一阶段都通过现有 smoke/full runner 护栏与 unified snapshot / trace payload / business bridge 合同维持稳定演进。

**Tech Stack:** Godot 4 GDScript、battle controller、battle scene runtime、unified snapshots、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本路线图用途 |
|---|---|---|
| `scripts/battle/battle_controller.gd` | runtime controller | 业务桥接、基线缓存、后续 gate feedback 统一入口 |
| `scripts/battle/battle_scene_runtime.gd` | 真实业务 battle 入口 | 静默挂载、事件扩充、后续降级式反馈接入点 |
| `tests/test_runner.gd` | 全量测试入口 | 持续作为全量护栏 |
| `tests/battle/smoke_suite.json` | P0 smoke 套件列表 | 持续作为日常护栏 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace contract | 锁住业务路径 payload 消费面 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 锁住真实业务路径挂载存在与不破坏 scene |
| `tests/battle/test_probe_sampling_payload_contract.gd` | critical payload contract | 锁住真实业务基线与后续闭环不破坏 unified snapshot |
| `tests/battle/test_probe_critical_runtime_perturbation_contract.gd` | perturbation contract | 锁住解释毛刺与后续反馈依赖字段 |
| `docs/v4_delivery_archive.md` | 交付档案 | 沉淀每阶段业务接入里程碑 |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 维护长期 P1/P2 冻结边界 |
| `docs/v4_real_business_baseline.md` | 基线文档 | 记录真实业务观测结论 |
| `docs/v4_senior_review_consultation_text.md` | 咨询文本 | 对外征求资深工程师路线反馈 |

## Roadmap Overview

| 阶段 | 目标 | 核心验收 |
|---|---|---|
| Phase A | Silent Integration | 真实业务路径稳定产出 `business_probe_events` 与 unified snapshots |
| Phase B | Baseline Establishment | 建立第一版真实业务 threshold baseline |
| Phase C | Real-Issue Interpretation | 至少抓到 1 个真实业务毛刺，并由 V4 指标解释 |
| Phase D | Degradative Feedback | Warning/Critical 先做降级式反馈，不做粗暴阻断 |
| Phase E | Authoritative Takeover | 在验证充分后让 `takeover_ready` 或相关 gate 进入业务闭环 |

## Task 1: 固化 Phase A / Silent Integration 成果

**Files:**
- Modify: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 delivery archive 中补一段 Phase A 结论，固定“静默挂载已完成”**

```md
## Phase A / Silent Integration
- `emit_v4_probe_event` is live in the real battle path.
- `business_probe_events` now coexist with `warning_unified_snapshot` and `critical_unified_snapshot`.
- No business battle decision is modified in this phase.
```

- [ ] **Step 2: 在 backlog tiers 中明确 Phase A 已完成，下一阶段转入 baseline establishment**

```md
## Active next phase
- Phase B / Baseline Establishment
- Goal: fit the first real-business threshold baseline from silent business traces
```

- [ ] **Step 3: 在 real business baseline 文档中补一段“当前只观察、不接管”的边界说明**

```md
## Phase boundary
- Phase A only observes.
- No battle decision, AI route, or effect policy is changed by V4 in this phase.
```

- [ ] **Step 4: 运行 smoke 与 full runner，确认 Phase A 文档归档不破坏护栏**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add docs/v4_delivery_archive.md docs/v4_backlog_tiers.md docs/v4_real_business_baseline.md
git commit -m "docs: archive silent v4 business integration"
```

## Task 2: 推进 Phase B / Baseline Establishment

**Files:**
- Modify: `scripts/battle/battle_scene_runtime.gd`
- Modify: `scripts/battle/battle_controller.gd`
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Test: `tests/battle/test_battle_scene_runtime_binding.gd`

- [ ] **Step 1: 在 trace contract 中先写失败断言，锁住真实业务基线事件至少暴露 `wave/live_count/combat_event_count`**

```gdscript
var business_probe_events: Array = trace_payload.get("business_probe_events", [])
var first_event: Dictionary = business_probe_events[0] if not business_probe_events.is_empty() else {}
_assert_trace_true(first_event.has("wave"), "business probe event should expose wave", failures)
_assert_trace_true(first_event.has("live_count"), "business probe event should expose live_count", failures)
_assert_trace_true(first_event.has("combat_event_count"), "business probe event should expose combat_event_count", failures)
```

- [ ] **Step 2: 运行 smoke，确认先红且失败集中在 baseline 事件字段缺失**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: FAIL，失败点集中在 baseline 事件字段缺失

- [ ] **Step 3: 在 `battle_scene_runtime.gd` 里补齐基线字段，不改变 battle 判定**

```gdscript
if _controller.has_method("emit_v4_probe_event"):
	var report: Dictionary = _controller.call("get_last_tick_report") if _controller.has_method("get_last_tick_report") else {}
	var current_wave: Dictionary = _controller.call("get_current_wave") if _controller.has_method("get_current_wave") else {}
	_controller.call("emit_v4_probe_event", {
		"event_type": "battle_scene_runtime_tick",
		"state": _controller.call("get_state"),
		"wave": int(current_wave.get("wave", -1)),
		"live_count": int(report.get("live_count", 0)),
		"combat_event_count": int(report.get("combat_event_count", 0))
	})
```

- [ ] **Step 4: 在 `v4_real_business_baseline.md` 里记录第一版 baseline 事件结构与拟合意图**

```md
## Baseline event shape
| Field | Meaning |
|---|---|
| `wave` | current business wave |
| `live_count` | number of alive units |
| `combat_event_count` | recent combat pressure indicator |

## Baseline fitting intent
- map real business density to unified snapshot observations
- prepare threshold baseline for later issue interpretation
```

- [ ] **Step 5: 重跑 smoke 与全量 runner**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/battle_scene_runtime.gd scripts/battle/battle_controller.gd tests/battle/test_battle_runtime_probe_trace_contract.gd tests/battle/test_battle_scene_runtime_binding.gd docs/v4_real_business_baseline.md
git commit -m "feat: establish first real business baseline fields"
```

## Task 3: 推进 Phase C / Real-Issue Interpretation

**Files:**
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`

- [ ] **Step 1: 在 payload contract 中先写失败断言，锁住用于解释业务毛刺的字段仍存在**

```gdscript
_assert_true(unified_gate_results.has("attack_rebind_escape_count"), "real issue interpretation should preserve attack_rebind_escape_count", failures)
_assert_true(unified_gate_results.has("attack_rebind_recontact_count"), "real issue interpretation should preserve attack_rebind_recontact_count", failures)
_assert_true(unified_gate_results.has("attack_midband_drift_count"), "real issue interpretation should preserve attack_midband_drift_count", failures)
```

- [ ] **Step 2: 在 perturbation contract 中补一条失败断言，锁住 `perturbation_summary` 继续存在**

```gdscript
_assert_true(payload.has("perturbation_summary"), "real issue interpretation should still preserve perturbation_summary", failures)
```

- [ ] **Step 3: 在 backlog tiers 中把下一步明确写成“解释真实毛刺”**

```md
## P1
| Item | Why it stays out of current slice |
|---|---|
| 用 V4 数据解释真实业务中的已知毛刺/拥挤点 | Baseline 已建立，下一步应进入真实问题解释 |
```

- [ ] **Step 4: 在 delivery archive 中增加一条 Interpretation milestone 预留段**

```md
## Phase C / Real-Issue Interpretation
- Goal: explain at least one known business stall, clumping point, or arbitration hotspot with V4 signals
```

- [ ] **Step 5: 运行 full runner，确认解释入口不破坏现有 contract**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 6: Commit**

```bash
git add tests/battle/test_probe_sampling_payload_contract.gd tests/battle/test_probe_critical_runtime_perturbation_contract.gd docs/v4_backlog_tiers.md docs/v4_delivery_archive.md
git commit -m "test: preserve interpretation hooks for business issues"
```

## Task 4: 推进 Phase D / Degradative Feedback

**Files:**
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 backlog tiers 中把下一阶段反馈明确成“降级式接管”**

```md
## P1
| Item | Why it stays out of current slice |
|---|---|
| 降级式 gate feedback | Warning/Critical 先作用于特效削减、AI 精度放宽、负载节流，而不是粗暴阻断战斗逻辑 |
```

- [ ] **Step 2: 在 delivery archive 中补 Gate Feedback Principle**

```md
## Gate Feedback Principle
- V4 should first behave as a silent observer.
- Feedback must be degradative before it becomes authoritative.
```

- [ ] **Step 3: 在 baseline 文档中补闭环前提说明**

```md
## Before gate activation
- first prove that V4 can explain one real business issue
- then activate degradative feedback
- do not directly switch to authoritative takeover
```

- [ ] **Step 4: 运行 smoke 与 full runner，作为长线 roadmap 当前节点最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add docs/v4_backlog_tiers.md docs/v4_delivery_archive.md docs/v4_real_business_baseline.md
git commit -m "docs: define degradative business feedback path"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 baseline establishment、issue interpretation、degradative feedback 三段长线推进主线 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 统一使用 `business_probe_events`、`wave`、`live_count`、`combat_event_count`、`takeover_ready` |
| Scope check | 明确持续真实业务接入，不插入无压力结构整顿 |
