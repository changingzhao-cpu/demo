# Oscillation Baseline Snapshot Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 oscillation 单样本定义稳定的 baseline_snapshot 契约，让落盘结果既可人读，也可结构化比对，为后续 contention-first 判读准备基线。

**Architecture:** 仅围绕 `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` 的 fixture 落盘与对应 contract test 展开。通过先收紧 contract test，再用最小实现补齐 `baseline_snapshot` 结构，保证 `v4_probe_fingerprint`、`v4_probe_baseline`、`v4_probe_baseline_source` 继续稳定，同时新增一个更高层的 `baseline_snapshot` 包装层，不触碰 `_check_anomaly`、全局阈值或多样本聚合逻辑。

**Tech Stack:** Godot 4.6 GDScript、现有 `tests/test_runner.gd`、JSON fixture 落盘、静态 contract tests

---

## File Structure

| 文件 | 角色 |
|---|---|
| `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | 唯一实现文件；负责生成 oscillation fixture、落盘 `baseline_snapshot`、读回并校验 payload 对齐 |
| `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd` | 静态 contract test；锁定 fixture 中 `baseline_snapshot` 结构、baseline/fingerprint/source 的保留方式与字段顺序 |
| `tests/test_runner.gd` | 已包含 oscillation contract suite；本阶段不新增 suite，只依赖现有 runner 回归 |

## Target Structure

本阶段新增并锁定的 `baseline_snapshot` 结构：

```gdscript
{
	"sample_name": "oscillation",
	"snapshot_version": 1,
	"baseline_text": v4_probe_baseline,
	"fingerprint": v4_probe_fingerprint,
	"baseline_source": v4_probe_fingerprint,
	"capture_context": {
		"fixture": "runtime_probe_test_fixture",
		"backend": "v4"
	}
}
```

约束：

| 字段 | 约束 |
|---|---|
| `sample_name` | 固定为 `oscillation` |
| `snapshot_version` | 固定为 `1` |
| `baseline_text` | 必须沿用现有 canonical 序列：`claim_success_rate -> contention_index -> late_commit_deviation -> assignment_count` |
| `fingerprint` | 必须继续保留四字段结构化快照 |
| `baseline_source` | 当前阶段与 `fingerprint` 一致，作为 baseline 文本的结构化来源 |
| `capture_context` | 只保留最小上下文，不扩张到时间戳、阈值、聚合器等额外信息 |

## Task 1: Lock the baseline_snapshot contract

**Files:**
- Modify: `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd`
- Test: `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd`

- [ ] **Step 1: Write the failing test**

在 `run()` 中追加最小 contract 断言，锁定 `baseline_snapshot` 必须存在，且至少包含 `sample_name`、`snapshot_version`、`baseline_text`、`fingerprint`、`baseline_source`、`capture_context` 这些字面量：

```gdscript
_assert_true(source.contains('"baseline_snapshot"'), "oscillation fixture should persist baseline_snapshot", failures)
_assert_true(source.contains('"sample_name": "oscillation"'), "oscillation fixture should fix baseline snapshot sample name", failures)
_assert_true(source.contains('"snapshot_version": 1'), "oscillation fixture should fix baseline snapshot version", failures)
_assert_true(source.contains('"baseline_text": v4_probe_baseline'), "oscillation fixture should map baseline snapshot text to v4_probe_baseline", failures)
_assert_true(source.contains('"fingerprint": v4_probe_fingerprint'), "oscillation fixture should map baseline snapshot fingerprint to v4_probe_fingerprint", failures)
_assert_true(source.contains('"baseline_source": v4_probe_fingerprint'), "oscillation fixture should map baseline snapshot source to v4_probe_fingerprint", failures)
_assert_true(source.contains('"capture_context"'), "oscillation fixture should persist baseline snapshot capture context", failures)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1" -s res://tests/test_runner.gd > "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_red.txt" 2>&1; printf "EXIT=%s\n" "$?" >> "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_red.txt"
```

Expected: `battle/test_runtime_probe_oscillation_fingerprint_contract` 因缺少 `baseline_snapshot` 相关断言而失败。

- [ ] **Step 3: Write minimal implementation**

在落盘 JSON 中新增最小 `baseline_snapshot` 包装层，不改变现有 `v4_probe_fingerprint` / `v4_probe_baseline` / `v4_probe_baseline_source` 顶层字段：

```gdscript
"baseline_snapshot": {
	"sample_name": "oscillation",
	"snapshot_version": 1,
	"baseline_text": v4_probe_baseline,
	"fingerprint": v4_probe_fingerprint,
	"baseline_source": v4_probe_fingerprint,
	"capture_context": {
		"fixture": "runtime_probe_test_fixture",
		"backend": "v4"
	}
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1" -s res://tests/test_runner.gd > "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_green.txt" 2>&1; printf "EXIT=%s\n" "$?" >> "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_green.txt"
```

Expected: `[TEST] All 120 test suite(s) passed.` and `EXIT=0`.

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "test: add oscillation baseline snapshot contract"
```

## Task 2: Validate payload readback against baseline_snapshot

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
- Test: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`

- [ ] **Step 1: Write the failing test**

在 payload 读回断言区追加最小行为测试，直接校验 `baseline_snapshot` 读回存在且与已有字段一致：

```gdscript
_assert_true(payload is Dictionary and payload.has("baseline_snapshot"), "runtime probe fixture output should persist baseline snapshot", failures)
_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("sample_name", "") == "oscillation", "runtime probe fixture output should persist oscillation sample name", failures)
_assert_true(payload is Dictionary and int(payload.get("baseline_snapshot", {}).get("snapshot_version", -1)) == 1, "runtime probe fixture output should persist baseline snapshot version", failures)
_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("baseline_text", "") == payload.get("v4_probe_baseline", ""), "runtime probe fixture output should align baseline snapshot text with v4 probe baseline", failures)
_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("fingerprint", {}) == payload.get("v4_probe_fingerprint", {}), "runtime probe fixture output should align baseline snapshot fingerprint with v4 probe fingerprint", failures)
_assert_true(payload is Dictionary and payload.get("baseline_snapshot", {}).get("baseline_source", {}) == payload.get("v4_probe_baseline_source", {}), "runtime probe fixture output should align baseline snapshot source with v4 probe baseline source", failures)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1" -s res://tests/test_runner.gd > "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_payload_red.txt" 2>&1; printf "EXIT=%s\n" "$?" >> "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_payload_red.txt"
```

Expected: `test_battle_runtime_probe_contact_oscillation` 因 payload 中缺少 `baseline_snapshot` 或字段未对齐而失败。

- [ ] **Step 3: Write minimal implementation**

在 payload 落盘 JSON 中补完 `baseline_snapshot` 后，不新增新的派生逻辑；只在现有 payload 读回区读取并对照：

```gdscript
var baseline_snapshot: Dictionary = payload.get("baseline_snapshot", {})
```

随后复用现有断言模式，对 `baseline_text` / `fingerprint` / `baseline_source` 做等值比较，不做额外容错层。

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
"C:/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1" -s res://tests/test_runner.gd > "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_payload_green.txt" 2>&1; printf "EXIT=%s\n" "$?" >> "C:/Users/admin/Documents/demo/.worktrees/battle-runtime-rebuild-phase1/.claude_baseline_snapshot_payload_green.txt"
```

Expected: `[TEST] All 120 test suite(s) passed.` and `EXIT=0`.

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "test: verify oscillation baseline snapshot payload"
```

## Acceptance Criteria

| 类别 | 标准 |
|---|---|
| 结构 | payload 顶层新增 `baseline_snapshot`，且不移除 `v4_probe_fingerprint` / `v4_probe_baseline` / `v4_probe_baseline_source` |
| 可读性 | `baseline_snapshot.baseline_text` 与现有 canonical baseline 文本一致 |
| 可比性 | `baseline_snapshot.fingerprint`、`baseline_snapshot.baseline_source` 与现有顶层结构完全一致 |
| 范围控制 | 只改 oscillation 样本 fixture 与其 contract test |
| 非目标 | 不修改 `_check_anomaly`、不新增阈值、不扩到多样本 |

## Verification Matrix

| 验证项 | 命令 | 期望 |
|---|---|---|
| contract 红测 | `... > .claude_baseline_snapshot_red.txt` | 出现 `baseline_snapshot` 缺失相关失败 |
| payload 红测 | `... > .claude_baseline_snapshot_payload_red.txt` | 出现 payload 对齐失败 |
| 全量绿测 | `... > .claude_baseline_snapshot_green.txt` 或 `...payload_green.txt` | `All 120 test suite(s) passed.` / `EXIT=0` |

## Self-Review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖目标结构、最小测试顺序、最小实现范围、验收标准 |
| Placeholder scan | 无 TBD/TODO/“后续实现”类占位 |
| Type consistency | 全程统一使用 `baseline_snapshot` / `baseline_text` / `fingerprint` / `baseline_source` / `capture_context` 这些字段名 |
