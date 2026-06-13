# First Real Business Issue Interpretation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地首个“真实业务毛刺 -> V4 指标解释”案例，证明 V4 不只是会采样，而且能解释真实业务问题。

**Architecture:** 不新增功能主线，不回头做结构整顿。先锁住解释案例所需的 trace / payload / perturbation 证据字段，然后在业务基线文档中建立正式案例结构，再把首个真实问题的描述、触发条件、V4 信号和解释链固化到文档与档案里，最后保持 smoke 与 full runner 全绿。

**Tech Stack:** Godot 4 GDScript、battle scene runtime、trace payload、critical unified snapshot、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace payload contract | 锁住解释案例依赖的业务事件字段存在 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 锁住真实业务路径会持续暴露 baseline 解释字段 |
| `tests/battle/test_probe_sampling_payload_contract.gd` | critical payload contract | 锁住 unified gate 中解释毛刺所需字段持续存在 |
| `tests/battle/test_probe_critical_runtime_perturbation_contract.gd` | perturbation contract | 锁住 `perturbation_summary` 及 escape/drift 字段持续存在 |
| `docs/v4_real_business_baseline.md` | 真实业务基线文档 | 填入首个解释案例模板与实际案例 |
| `docs/v4_delivery_archive.md` | 交付档案 | 记录 Stage 2 案例完成里程碑 |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 把下一阶段主线更新为降级式 feedback |

## Task 1: 锁住解释案例所需证据字段

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 trace contract 中先写失败断言，锁住业务事件字段不会被后续改动删掉**

```gdscript
var business_probe_events: Array = trace_payload.get("business_probe_events", [])
var first_event: Dictionary = business_probe_events[0] if not business_probe_events.is_empty() else {}
_assert_trace_true(first_event.has("event_type"), "business probe event should expose event_type for issue interpretation", failures)
_assert_trace_true(first_event.has("state"), "business probe event should expose state for issue interpretation", failures)
_assert_trace_true(first_event.has("wave"), "business probe event should expose wave for issue interpretation", failures)
_assert_trace_true(first_event.has("live_count"), "business probe event should expose live_count for issue interpretation", failures)
_assert_trace_true(first_event.has("combat_event_count"), "business probe event should expose combat_event_count for issue interpretation", failures)
```

- [ ] **Step 2: 在 scene binding contract 中先写失败断言，锁住真实业务路径也会暴露这些字段**

```gdscript
var events: Array = payload.get("business_probe_events", [])
var first_event: Dictionary = events[0] if not events.is_empty() else {}
_assert_true(first_event.has("wave"), "battle scene controller runtime trace payload should expose wave for issue interpretation", failures)
_assert_true(first_event.has("live_count"), "battle scene controller runtime trace payload should expose live_count for issue interpretation", failures)
_assert_true(first_event.has("combat_event_count"), "battle scene controller runtime trace payload should expose combat_event_count for issue interpretation", failures)
```

- [ ] **Step 3: 在 payload 与 perturbation contract 中先写失败断言，锁住解释问题必需的 V4 指标仍存在**

```gdscript
_assert_true(unified_gate_results.has("attack_rebind_escape_count"), "real issue interpretation should preserve attack_rebind_escape_count", failures)
_assert_true(unified_gate_results.has("attack_rebind_recontact_count"), "real issue interpretation should preserve attack_rebind_recontact_count", failures)
_assert_true(unified_gate_results.has("attack_midband_drift_count"), "real issue interpretation should preserve attack_midband_drift_count", failures)
_assert_true(unified_gate_results.has("critical_hit_rate"), "real issue interpretation should preserve critical_hit_rate", failures)
_assert_true(unified_gate_results.has("fast_false_positive_rate"), "real issue interpretation should preserve fast_false_positive_rate", failures)
```

```gdscript
_assert_true(payload.has("perturbation_summary"), "real issue interpretation should still preserve perturbation_summary", failures)
_assert_true(payload.get("perturbation_summary", {}).has("attack_rebind_escape_count"), "real issue interpretation should preserve perturbation escape count in perturbation_summary", failures)
```

- [ ] **Step 4: 运行 full runner，确认解释证据护栏绿灯**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_trace_contract.gd tests/battle/test_battle_scene_runtime_binding.gd tests/battle/test_probe_sampling_payload_contract.gd tests/battle/test_probe_critical_runtime_perturbation_contract.gd
git commit -m "test: lock evidence fields for first business issue interpretation"
```

## Task 2: 固化首个解释案例模板

**Files:**
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 baseline 文档中写正式案例模板**

```md
## First Interpretation Case

| Item | Current status |
|---|---|
| Business issue name | pending real case |
| Observable symptom | pending real case |
| Triggering scene/wave | pending real case |
| V4 signal(s) | pending real case |
| Why the signal explains the issue | pending real case |
| Follow-up action | pending real case |
```

- [ ] **Step 2: 在模板前补一段案例填写规则，防止后续写成流水账**

```md
## Case writing rule
- Describe the business symptom first.
- Then record the triggering scene or wave.
- Then list the exact V4 signal(s).
- Then explain why the signal is sufficient to explain the issue.
- Do not jump to feedback or takeover decisions in this section.
```

- [ ] **Step 3: 运行 smoke，确认文档更新不影响护栏**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_real_business_baseline.md
git commit -m "docs: add first business issue interpretation template"
```

## Task 3: 记录 Stage 2 里程碑与下一阶段交接边界

**Files:**
- Modify: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_backlog_tiers.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 delivery archive 中增加 Stage 2 里程碑段**

```md
## Phase C / Real-Issue Interpretation
- Goal: explain at least one known business stall, clumping point, or arbitration hotspot with V4 signals.
- Current requirement: keep all interpretation evidence fields stable under smoke and full runner.
```

- [ ] **Step 2: 在 backlog tiers 中把“首个解释案例”写成当前主目标**

```md
## Active next phase
- Phase C / Real-Issue Interpretation
- Goal: land the first business issue explanation case with V4 signals
```

- [ ] **Step 3: 在 backlog tiers 中写清楚完成解释案例之后才进入降级式 feedback**

```md
## Rule
- Degradative feedback may begin only after at least one real business issue has been explained by V4 signals.
```

- [ ] **Step 4: 运行 smoke 与 full runner，确认 Stage 2 交接文档不破坏护栏**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add docs/v4_delivery_archive.md docs/v4_backlog_tiers.md
git commit -m "docs: promote real issue interpretation milestone"
```

## Task 4: 为 Stage 3 / Degradative Feedback 预留最小接入边界

**Files:**
- Modify: `docs/v4_real_business_baseline.md`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 baseline 文档中增加反馈前顺序规则**

```md
## Progression rule
- Silent baseline first
- Real issue interpretation second
- Degradative feedback third
```

- [ ] **Step 2: 在 delivery archive 中补反馈前提条件**

```md
## Feedback Entry Condition
- first prove one real issue explanation case
- then activate degradative feedback
- do not jump directly to authoritative takeover
```

- [ ] **Step 3: 运行 smoke 与 full runner，作为本计划最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_real_business_baseline.md docs/v4_delivery_archive.md
git commit -m "docs: define interpretation to feedback transition"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖解释证据护栏、案例模板、Stage 2 里程碑、向 Stage 3 的过渡边界 |
| Placeholder scan | 首个案例位置明确使用 `pending real case`，其余无 TBD/TODO 占位 |
| Type consistency | 统一使用 `attack_rebind_escape_count`、`attack_rebind_recontact_count`、`attack_midband_drift_count`、`critical_hit_rate`、`fast_false_positive_rate` |
| Scope check | 聚焦首个真实业务毛刺解释案例，不回头做结构整顿 |
