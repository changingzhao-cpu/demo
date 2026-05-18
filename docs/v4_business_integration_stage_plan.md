# V4 Business Integration Stage Plan

## Stage 1: Baseline Consolidation

| 项目 | 内容 |
|---|---|
| 目标 | 稳定真实业务 baseline 口径 |
| 输入 | `business_probe_events`、`warning_unified_snapshot`、`critical_unified_snapshot` |
| 输出 | 第一版稳定 baseline 文档与采样口径 |
| 验收 | smoke 绿、full runner 绿、baseline 文档可解释 |

## Stage 2: Real-Issue Interpretation

| 项目 | 内容 |
|---|---|
| 目标 | 用 V4 指标解释真实业务毛刺 |
| 输入 | baseline 数据 + 真实业务已知卡点 |
| 输出 | 至少 1 个“毛刺 -> 指标解释”案例 |
| 核心指标 | `contention_index`、`late_commit_deviation`、`attack_rebind_escape_count` |
| 验收 | 团队认可 V4 对真实问题有解释力 |

## Stage 3: Degradative Feedback

| 项目 | 内容 |
|---|---|
| 目标 | 让 V4 开始以低风险方式反馈业务层 |
| 反馈形式 | 特效削减、AI 精度放宽、负载节流 |
| 禁止 | 直接阻断战斗流程 |
| 验收 | 反馈存在且不破坏战斗体验 |

## Stage 4: Authoritative Takeover

| 项目 | 内容 |
|---|---|
| 目标 | 让 `takeover_ready` 或同级 gate 成为业务闭环的一部分 |
| 前提 | baseline 成立、毛刺解释成功、降级式反馈稳定 |
| 验收 | gate 能安全影响业务决策 |

## 当前建议优先级

| 优先级 | 内容 |
|---|---|
| P1 | Stage 2 / Real-Issue Interpretation |
| P1 | Stage 3 / Degradative Feedback 预案 |
| P2 | 大脚本拆分 |
| P2 | runner 深度重构 |
| P2 | Critical 精度继续优化 |
| P2 | Godot resource 尾项继续排查 |
