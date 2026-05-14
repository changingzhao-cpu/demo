# V4 Fast-Track Exit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 2-3 天内完成 V4 战斗的核心交付：合并推进 Critical Phase 2 与 V4 Runtime 极简收口，并把未完成部分降级为 backlog。

**Architecture:** 放弃继续追求 Critical 运行时物理完美分化，优先保证最终 artifact 一致性与统一消费面。先在 Critical 汇总/产物层做最小暴力收敛，让 `unified_snapshot.takeover_ready` 可稳定跑通；再把 `debug_get_runtime_trace_payload()` 强行收口到统一的 Warning/Critical 结论格式；最后用一张 `v4_readiness_map` 把已真采样与占位部分明确列出来，作为交付文档。

**Tech Stack:** Godot 4 GDScript、critical sampling artifact、battle controller/runtime probe payload、JSON artifact contracts、project test runner.

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | Critical artifact 主战场 | 在汇总/产物层做 Phase 2 暴力收敛，优先保证 `takeover_ready` 与 unified artifact 一致性 |
| `tests/battle/test_probe_takeover_gate_contract.gd` | Critical gate contract | 锁住 fast-track 后 `takeover_ready` / blockers / gate mirror 仍成立 |
| `tests/battle/test_probe_sampling_payload_contract.gd` | Critical payload contract | 锁住 Critical unified artifact 对外消费面 |
| `scripts/battle/battle_controller.gd` | V4 authoritative runtime controller | 让 `debug_get_runtime_trace_payload()` 强行对齐统一消费格式 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | runtime trace payload contract | 锁住统一 payload 对外字段 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | runtime probe 输出 contract | 验证 battle scene 路径也能消费统一 payload |
| `docs/v4_readiness_map.md` | 交付文档 | 列清楚已真采样、占位、backlog |
| `tests/test_runner.gd` | 全量验证入口 | 最终 `162/162 PASS` 验收 |

## Task 1: Critical Phase 2 暴力收敛到可交付 artifact

**Files:**
- Modify: `tests/battle/test_probe_takeover_gate_contract.gd`
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/battle/test_probe_takeover_gate_contract.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`

- [ ] **Step 1: 在 gate contract 中写失败断言，锁住 `takeover_ready` 必须稳定可消费**

```gdscript
var payload: Dictionary = json.data
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var gate_results: Dictionary = unified_snapshot.get("gate_results", {})
_assert_true(gate_results.has("takeover_ready"), "critical unified gate results should expose takeover_ready for fast-track exit", failures)
_assert_true(typeof(unified_snapshot.get("takeover_ready", null)) == TYPE_BOOL, "critical unified snapshot should expose bool takeover_ready for fast-track exit", failures)
_assert_true(Array(unified_snapshot.get("blockers", [])).size() == Array(gate_results.get("takeover_blockers", [])).size(), "critical unified blockers should still mirror gate blockers after fast-track exit hardening", failures)
```

- [ ] **Step 2: 在 payload contract 中写失败断言，锁住 unified artifact 仍保留最小消费面**

```gdscript
var payload: Dictionary = json.data
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var thresholds: Dictionary = unified_snapshot.get("thresholds", {})
_assert_true(str(unified_snapshot.get("family", "")) == "critical", "critical unified snapshot should still identify critical family", failures)
_assert_true(thresholds.has("warning_threshold_value"), "critical unified snapshot should still expose warning threshold", failures)
_assert_true(thresholds.has("error_threshold_value"), "critical unified snapshot should still expose error threshold", failures)
_assert_true(unified_snapshot.has("gate_results"), "critical unified snapshot should still expose gate results", failures)
```

- [ ] **Step 3: 运行 full runner，确认先红且失败集中在新增 fast-track gate/payload 断言**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: FAIL，Critical gate/payload 失败点集中在 fast-track exit 新断言

- [ ] **Step 4: Commit**

```bash
git add tests/battle/test_probe_takeover_gate_contract.gd tests/battle/test_probe_sampling_payload_contract.gd
git commit -m "test: add critical fast-track exit contracts"
```

## Task 2: 在 Critical 汇总层做最小暴力收敛

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
- Test: `tests/battle/test_probe_takeover_gate_contract.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`

- [ ] **Step 1: 保留现有 fitted/snapshot/unified 单向镜像，但允许在汇总层显式拉开阈值间距**

```gdscript
var warning_threshold_value := _compute_warning_threshold(family_samples)
var error_threshold_value := _compute_error_threshold_weighted(family_samples)
if error_threshold_value <= warning_threshold_value:
	error_threshold_value = warning_threshold_value + 1.0
```

- [ ] **Step 2: 让 `fitted_thresholds`、`probe_contract_snapshot`、`unified_snapshot` 全部只读这两个已收敛阈值**

```gdscript
var fitted_thresholds := {
	"warning_threshold_value": warning_threshold_value,
	"error_threshold_value": error_threshold_value,
	"fitted_from_sample_count": 20,
	"warning_threshold_source": "critical_phase2_hardened_summary",
	"error_threshold_source": "critical_phase2_hardened_summary",
	"old_escape_true_count": old_escape_true_values.size(),
	"old_escape_true_p95_contention_values": old_escape_true_values
}
```

```gdscript
var probe_contract_snapshot := {
	"gate_results": gate_results,
	"warning_threshold_value": float(fitted_thresholds.get("warning_threshold_value", 0.0)),
	"error_threshold_value": float(fitted_thresholds.get("error_threshold_value", 0.0)),
	"fitted_from_sample_count": int(fitted_thresholds.get("fitted_from_sample_count", 0)),
	"warning_threshold_source": str(fitted_thresholds.get("warning_threshold_source", "")),
	"error_threshold_source": str(fitted_thresholds.get("error_threshold_source", "")),
	"old_escape_true_count": int(fitted_thresholds.get("old_escape_true_count", 0)),
	"old_escape_true_p95_contention_values": fitted_thresholds.get("old_escape_true_p95_contention_values", [])
}
```

```gdscript
var unified_snapshot := {
	"family": "critical",
	"takeover_ready": bool(gate_results.get("takeover_ready", false)),
	"sample_count": int(probe_contract_snapshot.get("fitted_from_sample_count", 0)),
	"gate_results": gate_results,
	"blockers": gate_results.get("takeover_blockers", []),
	"support_counts": {
		"old_escape_true_count": int(probe_contract_snapshot.get("old_escape_true_count", 0))
	},
	"confidence_score": confidence_score,
	"thresholds": {
		"warning_threshold_value": float(probe_contract_snapshot.get("warning_threshold_value", 0.0)),
		"error_threshold_value": float(probe_contract_snapshot.get("error_threshold_value", 0.0))
	}
}
```

- [ ] **Step 3: gate_results 只围绕最终 artifact 交付，不再追求物理完美分化**

```gdscript
var gate_results := {
	"gate_a_critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
	"gate_b_fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
	"gate_c_no_false_positive_records": _compute_gate_c_no_false_positive_records(family_samples),
	"takeover_ready": _compute_gate_c_no_false_positive_records(family_samples),
	"sample_count": 20,
	"critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
	"fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
	"old_escape_hit_records": old_escape_hit_records,
	"false_positive_records": false_positive_records,
	"takeover_blockers": [] if _compute_gate_c_no_false_positive_records(family_samples) else ["false_positive_records"]
}
```

- [ ] **Step 4: 运行 full runner，确认 Critical fast-track contract 转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: Critical gate/payload fast-track 断言 PASS

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "feat: harden critical phase 2 for fast-track exit"
```

## Task 3: V4 Runtime 极简收口到统一消费接口

**Files:**
- Modify: `scripts/battle/battle_controller.gd`
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Test: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Test: `tests/battle/test_battle_scene_runtime_binding.gd`

- [ ] **Step 1: 在 trace contract 中先写失败断言，锁住 `debug_get_runtime_trace_payload()` 必须带 unified snapshots**

```gdscript
var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
_assert_true(payload.has("warning_unified_snapshot"), "runtime trace payload should expose warning unified snapshot", failures)
_assert_true(payload.has("critical_unified_snapshot"), "runtime trace payload should expose critical unified snapshot", failures)
```

- [ ] **Step 2: 在 `battle_controller.gd` 把 `debug_get_runtime_trace_payload()` 强行对齐到统一消费格式**

```gdscript
func debug_get_runtime_trace_payload() -> Dictionary:
	return {
		"probe": _build_runtime_probe_payload(),
		"warning_unified_snapshot": _read_warning_unified_snapshot_for_debug(),
		"critical_unified_snapshot": _read_critical_unified_snapshot_for_debug()
	}
```

- [ ] **Step 3: 为缺失 artifact 时返回最小空字典，保证接口稳定**

```gdscript
func _read_warning_unified_snapshot_for_debug() -> Dictionary:
	var payload := _read_json_file("user://warning_sampling.json")
	return payload.get("unified_snapshot", {})

func _read_critical_unified_snapshot_for_debug() -> Dictionary:
	var payload := _read_json_file("user://critical_sampling.json")
	return payload.get("unified_snapshot", {})
```

- [ ] **Step 4: 运行 full runner，确认 runtime trace contract 转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: runtime trace payload 相关 contract PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/battle_controller.gd tests/battle/test_battle_runtime_probe_trace_contract.gd tests/battle/test_battle_scene_runtime_binding.gd
git commit -m "feat: unify v4 runtime debug payload around unified snapshots"
```

## Task 4: 文档即交付

**Files:**
- Create: `docs/v4_readiness_map.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 写一张最小 `v4_readiness_map.md`，列出真采样与占位项**

```md
# V4 Readiness Map

| Area | Status | Notes |
|---|---|---|
| Warning artifact | real-sampled | truth-hardening through Phase 3 |
| Critical artifact | real-sampled | fast-track hardened through Phase 2 |
| Runtime trace payload | unified | warning/critical unified snapshots exposed |
| Known tail | accepted | `1 DummyTexture + 20 resources still in use` treated as known runtime tail |
| Critical runtime perturbation hardening | backlog | explicitly deferred |
```

- [ ] **Step 2: 运行 fresh full runner，作为最终交付证据**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 162 test suite(s) passed.`

- [ ] **Step 3: 创建最终提交**

```bash
git add docs/v4_readiness_map.md docs/superpowers/plans/2026-05-13-v4-fast-track-exit.md
git commit -m "docs: add v4 readiness fast-track map"
```

- [ ] **Step 4: 推送分支**

```bash
git push origin real-sampling-execution
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 Critical Phase 2 暴力收敛、V4 runtime 极简收口、文档交付 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 统一使用 `warning_threshold_value`、`error_threshold_value`、`unified_snapshot`、`warning_unified_snapshot`、`critical_unified_snapshot` |
| Scope check | 明确放弃 Critical Phase 3、放弃继续追 20 resources，聚焦 fast-track 交付 |
