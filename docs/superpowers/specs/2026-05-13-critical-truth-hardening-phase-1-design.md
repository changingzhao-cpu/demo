# Critical Truth-Hardening Phase 1 Design

## Goal

让 Critical 侧最终 artifact 也具备更强的 truth-hardening：`fitted_thresholds`、`probe_contract_snapshot`、`gate_results`、`unified_snapshot` 之间保持单向镜像与可解释的一致性。

## Problem statement

当前 Critical 侧虽然已经产出 `critical_sampling.json`、`probe_contract_snapshot` 与 `unified_snapshot`，但它的 artifact 纪律还没有像 Warning Phase 2/3 那样被系统性锁严。

当前链路核心片段在 `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`：

| 层级 | 当前状态 |
|---|---|
| `fitted_thresholds` | 已生成，但部分字段仍独立计算 |
| `probe_contract_snapshot` | 已存在，但同时重算 gate / threshold 值 |
| `unified_snapshot` | 已存在，但主要是镜像，不足以证明上游链条严格单向 |
| content contracts | 有 coverage，但 truth-hardening 约束仍弱于 Warning |

因此 Phase 1 不追求像 Warning 一样扩大 runtime 扰动，而先把 **单向派生一致性** 锁住。

## Scope

| 类型 | 包含 |
|---|---|
| 包含 | `fitted_thresholds -> probe_contract_snapshot -> unified_snapshot` 的单向镜像约束 |
| 包含 | `gate_results` 与 `takeover_blockers` 的 artifact truth-hardening |
| 包含 | Critical content contract / payload contract 加强 |
| 不包含 | Warning 逻辑 |
| 不包含 | tail 继续追查 |
| 不包含 | Critical runtime family 重新设计 |

## Design

### 1. 先锁单向派生链

Critical Phase 1 要求：

| 链路 | 规则 |
|---|---|
| `fitted_thresholds.warning_threshold_value` | 作为 `probe_contract_snapshot.warning_threshold_value` 的唯一来源 |
| `fitted_thresholds.error_threshold_value` | 作为 `probe_contract_snapshot.error_threshold_value` 的唯一来源 |
| `probe_contract_snapshot.gate_results` | 作为 `unified_snapshot.gate_results` 的唯一来源 |
| `probe_contract_snapshot.old_escape_true_count` | 作为 `unified_snapshot.support_counts.old_escape_true_count` 的唯一来源 |
| `probe_contract_snapshot.takeover blockers/gate flags` | 作为 `unified_snapshot.blockers/takeover_ready` 的唯一来源 |

### 2. 强化 content contract

需要新增或加强的约束：

| 约束 | 目的 |
|---|---|
| `probe_contract_snapshot.warning_threshold_value == fitted_thresholds.warning_threshold_value` | 禁止 snapshot 独立重算 warning threshold |
| `probe_contract_snapshot.error_threshold_value == fitted_thresholds.error_threshold_value` | 禁止 snapshot 独立重算 error threshold |
| `unified_snapshot.thresholds.* == probe_contract_snapshot.*` | 禁止 unified 自己派生新值 |
| `unified_snapshot.gate_results == probe_contract_snapshot.gate_results` | 统一 gate 结论来源 |
| `unified_snapshot.blockers == gate_results.takeover_blockers` | 统一 blockers 入口 |

### 3. Phase 1 不扩大行为面

这一阶段只做 artifact truth-hardening，不做：

| 不做事项 | 原因 |
|---|---|
| 调整 Critical sample family 分布 | 先锁 artifact 纪律 |
| 重写 threshold formula | 当前目标不是算法升级 |
| 引入新的 snapshot 层 | 现有 `probe_contract_snapshot` + `unified_snapshot` 已足够 |

## Success criteria

| 条件 | 必须满足 |
|---|---|
| fresh full runner | `162/162 PASS` |
| Critical artifact chain | `fitted_thresholds -> probe_contract_snapshot -> unified_snapshot` 单向一致 |
| gate/blockers | `probe_contract_snapshot` 与 `unified_snapshot` 不再各自独立表达 |
| Warning 主线 | 不受影响 |
