# Critical Truth-Hardening Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Critical 的 `fitted_thresholds -> probe_contract_snapshot -> unified_snapshot` 形成严格单向镜像链，并通过更强 contract 验证。

**Architecture:** 这一阶段不扩大 Critical runtime family 行为面，只强化 artifact truth-hardening。先补 content/payload 红测锁住单向派生关系，再把 `warning_threshold_value`、`error_threshold_value`、`gate_results`、`takeover_blockers`、`old_escape_true_count` 都改成从上游单向镜像，禁止独立重算。

**Tech Stack:** Godot 4 GDScript、critical sampling artifact、JSON payload contracts、project test runner.

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | Critical artifact 生成主战场 | 统一 `fitted_thresholds -> probe_contract_snapshot -> unified_snapshot` 单向派生链 |
| `tests/battle/test_probe_fitted_threshold_contract.gd` | Critical fitted threshold contract | 加强 `fitted_thresholds` 与 snapshot/unified 镜像验证 |
| `tests/battle/test_probe_takeover_gate_contract.gd` | Critical gate contract | 加强 `gate_results` / blockers / takeover_ready 的单向来源验证 |
| `tests/battle/test_probe_sampling_payload_contract.gd` | Critical payload contract | 加强 `probe_contract_snapshot` / `unified_snapshot` 的 payload truth-hardening |
| `tests/test_runner.gd` | full runner | 最终 `162/162 PASS` 验证 |

## Task 1: 先给 Critical content/payload contract 增加单向镜像红测

**Files:**
- Modify: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Modify: `tests/battle/test_probe_takeover_gate_contract.gd`
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Test: `tests/battle/test_probe_takeover_gate_contract.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`

- [ ] **Step 1: 在 fitted threshold contract 中写失败断言，锁住 snapshot 必须镜像 fitted 值**

```gdscript
var payload: Dictionary = json.data
var fitted_thresholds: Dictionary = payload.get("fitted_thresholds", {})
var probe_contract_snapshot: Dictionary = payload.get("probe_contract_snapshot", {})
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var unified_thresholds: Dictionary = unified_snapshot.get("thresholds", {})

_assert_true(float(probe_contract_snapshot.get("warning_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_threshold_value", 0.0)), "critical snapshot warning threshold should mirror fitted warning threshold", failures)
_assert_true(float(probe_contract_snapshot.get("error_threshold_value", 0.0)) == float(fitted_thresholds.get("error_threshold_value", 0.0)), "critical snapshot error threshold should mirror fitted error threshold", failures)
_assert_true(float(unified_thresholds.get("warning_threshold_value", 0.0)) == float(probe_contract_snapshot.get("warning_threshold_value", 0.0)), "critical unified warning threshold should mirror probe contract snapshot", failures)
_assert_true(float(unified_thresholds.get("error_threshold_value", 0.0)) == float(probe_contract_snapshot.get("error_threshold_value", 0.0)), "critical unified error threshold should mirror probe contract snapshot", failures)
```

- [ ] **Step 2: 在 gate contract 中写失败断言，锁住 unified gate/blockers 必须镜像 snapshot gate**

```gdscript
var payload: Dictionary = json.data
var probe_contract_snapshot: Dictionary = payload.get("probe_contract_snapshot", {})
var snapshot_gate_results: Dictionary = probe_contract_snapshot.get("gate_results", {})
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var unified_gate_results: Dictionary = unified_snapshot.get("gate_results", {})

_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(snapshot_gate_results.get("takeover_ready", false)), "critical unified takeover flag should mirror snapshot gate takeover flag", failures)
_assert_true(Array(unified_snapshot.get("blockers", [])).size() == Array(snapshot_gate_results.get("takeover_blockers", [])).size(), "critical unified blockers should mirror snapshot gate blockers", failures)
_assert_true(bool(unified_gate_results.get("gate_c_no_false_positive_records", false)) == bool(snapshot_gate_results.get("gate_c_no_false_positive_records", false)), "critical unified gate results should mirror snapshot gate results", failures)
```

- [ ] **Step 3: 在 payload contract 中写失败断言，锁住 support_counts 必须镜像 old_escape_true_count**

```gdscript
var payload: Dictionary = json.data
var probe_contract_snapshot: Dictionary = payload.get("probe_contract_snapshot", {})
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var support_counts: Dictionary = unified_snapshot.get("support_counts", {})

_assert_true(int(support_counts.get("old_escape_true_count", -1)) == int(probe_contract_snapshot.get("old_escape_true_count", -2)), "critical unified support count should mirror probe contract snapshot old_escape count", failures)
_assert_true(int(unified_snapshot.get("sample_count", -1)) == int(probe_contract_snapshot.get("fitted_from_sample_count", -2)), "critical unified sample count should mirror probe contract snapshot sample count", failures)
```

- [ ] **Step 4: 运行 full runner，确认先红且失败集中在新增镜像断言**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: FAIL，Critical 失败点集中在新增的 snapshot/unified mirror assertions

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_probe_fitted_threshold_contract.gd tests/battle/test_probe_takeover_gate_contract.gd tests/battle/test_probe_sampling_payload_contract.gd
git commit -m "test: add critical artifact truth-hardening contracts"
```

## Task 2: 让 probe_contract_snapshot 直接镜像 fitted_thresholds 和 gate_results

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
- Test: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Test: `tests/battle/test_probe_takeover_gate_contract.gd`

- [ ] **Step 1: 先提取单独的 `gate_results` 变量，避免在 snapshot 内独立重算**

```gdscript
var gate_results := {
	"gate_a_critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
	"gate_b_fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
	"gate_c_no_false_positive_records": _compute_gate_c_no_false_positive_records(family_samples),
	"takeover_ready": _compute_gate_a_critical_hit_rate(family_samples) >= 0.0 and _compute_gate_b_fast_false_positive_rate(family_samples) <= 1.0 and _compute_gate_c_no_false_positive_records(family_samples),
	"sample_count": 20,
	"critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
	"fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
	"old_escape_hit_records": old_escape_hit_records,
	"false_positive_records": false_positive_records,
	"takeover_blockers": [] if _compute_gate_c_no_false_positive_records(family_samples) else ["false_positive_records"]
}
```

- [ ] **Step 2: 让 `probe_contract_snapshot` 的 threshold 字段直接镜像 `fitted_thresholds`**

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

- [ ] **Step 3: 运行 full runner，确认 fitted/gate 相关 Critical contract 转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `test_probe_fitted_threshold_contract` 与 `test_probe_takeover_gate_contract` 相关新增断言 PASS

- [ ] **Step 4: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "feat: mirror critical snapshot from fitted thresholds"
```

## Task 3: 让 unified_snapshot 只镜像 probe_contract_snapshot

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`

- [ ] **Step 1: 让 `unified_snapshot.thresholds` 只读取 `probe_contract_snapshot`**

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

- [ ] **Step 2: 让 `unified_snapshot.gate_results` / `blockers` / `sample_count` 保持 snapshot 唯一来源**

```gdscript
var snapshot_gate_results: Dictionary = probe_contract_snapshot.get("gate_results", {})
var unified_snapshot := {
	"family": "critical",
	"takeover_ready": bool(snapshot_gate_results.get("takeover_ready", false)),
	"sample_count": int(probe_contract_snapshot.get("fitted_from_sample_count", 0)),
	"gate_results": snapshot_gate_results,
	"blockers": snapshot_gate_results.get("takeover_blockers", []),
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

- [ ] **Step 3: 运行 full runner，确认 payload contract 转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `test_probe_sampling_payload_contract` 新增断言 PASS

- [ ] **Step 4: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "feat: mirror critical unified snapshot from probe contract snapshot"
```

## Task 4: fresh full runner 验收并推送

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
- Modify: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Modify: `tests/battle/test_probe_takeover_gate_contract.gd`
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 运行 fresh full runner**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 162 test suite(s) passed.`

- [ ] **Step 2: 逐项核对 Critical 链路是否单向一致**

```text
fitted_thresholds.warning_threshold_value == probe_contract_snapshot.warning_threshold_value
fitted_thresholds.error_threshold_value == probe_contract_snapshot.error_threshold_value
probe_contract_snapshot.gate_results == unified_snapshot.gate_results
probe_contract_snapshot.old_escape_true_count == unified_snapshot.support_counts.old_escape_true_count
probe_contract_snapshot.gate_results.takeover_blockers == unified_snapshot.blockers
```

- [ ] **Step 3: 创建阶段提交**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd tests/battle/test_probe_fitted_threshold_contract.gd tests/battle/test_probe_takeover_gate_contract.gd tests/battle/test_probe_sampling_payload_contract.gd
git commit -m "feat: finish critical truth hardening phase 1"
```

- [ ] **Step 4: 推送分支**

```bash
git push origin real-sampling-execution
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 `fitted_thresholds -> probe_contract_snapshot -> unified_snapshot` 单向镜像链与 gate/blockers/support_count 一致性 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 统一使用 `warning_threshold_value`、`error_threshold_value`、`gate_results`、`takeover_blockers`、`old_escape_true_count` |
| Scope check | 只做 Critical artifact truth-hardening，不混入 Warning 或 tail 主线 |
