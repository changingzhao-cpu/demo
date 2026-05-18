# V4 Progress and Long-Range Plan

## 当前开发进度

| 领域 | 当前状态 | 说明 |
|---|---|---|
| Warning truth-hardening | 完成 | Phase 1-3 已完成，warning unified snapshot 稳定可消费 |
| Critical truth-hardening | 完成 | Phase 1 已完成，critical payload / thresholds / mirrors 稳定 |
| Fast-track exit | 完成 | runtime trace 已稳定暴露 warning/critical unified snapshots |
| Critical perturbation hardening | 完成 | `anomaly_scan` / `perturbation_summary` / gate mirrors 已落地 |
| 收口基础设施 | 完成 | smoke suite、runner conventions、delivery archive、backlog tiers 已建立 |
| 真实业务静默接入 | 完成 | `emit_v4_probe_event` + `business_probe_events` 已挂到真实 battle scene 路径 |
| 真实业务 baseline | 已完成第一版 | 业务事件已带 `wave/live_count/combat_event_count` |
| 真实业务毛刺解释入口 | 完成 | 解释毛刺所需 evidence fields、模板、里程碑、边界已固化 |
| 降级式反馈边界 | 完成 | feedback principle / entry condition 已写入文档 |
| authoritative takeover | 未开始 | 仍处于后续阶段 |
| smoke 回归 | 通过 | `All 6 test suite(s) passed.` |
| full runner | 通过 | `All 163 test suite(s) passed.` |
| Godot 资源尾项 | accepted | 不作为当前交付阻断项 |

## 当前架构结论

| 项目 | 结论 |
|---|---|
| 主线 | 坚定走真实业务接入 |
| 当前禁止事项 | 无业务压力下的大规模结构整顿 |
| 当前允许事项 | baseline 拟合、毛刺解释、降级式反馈、闭环接管 |
| 当前架构形态 | 已从“实验性探针体系”进入“可在真实业务路径持续演进的观测与反馈框架” |

## 长线开发阶段

| 阶段 | 目标 | 当前状态 | 成功标准 |
|---|---|---|---|
| Phase A | Silent Integration | 完成 | 真实 battle 路径稳定暴露 `business_probe_events` 与 unified snapshots |
| Phase B | Baseline Establishment | 完成第一版 | 产出第一版真实业务 threshold baseline |
| Phase C | Real-Issue Interpretation | 入口完成，案例未落地 | 至少解释 1 个真实业务毛刺/拥挤点 |
| Phase D | Degradative Feedback | 仅边界完成 | Warning/Critical 先以降级方式影响业务层 |
| Phase E | Authoritative Takeover | 未开始 | `takeover_ready` 或同级 gate 进入业务闭环 |

## 长线优先级

| 优先级 | 项目 | 处理方式 |
|---|---|---|
| P1 | 拿到首个“真实业务毛刺 -> V4 指标解释”案例 | 当前最优先 |
| P1 | 基于解释案例设计降级式 gate feedback | 次优先 |
| P1 | 验证 feedback 是否能缓解真实业务问题 | 在解释成功后推进 |
| P2 | 大脚本拆分 | 冻结 |
| P2 | runner 深度重构 | 冻结 |
| P2 | Critical 精度继续优化 | 冻结 |
| P2 | Godot 资源尾项排查 | 冻结 |

## 未来 3 个迭代建议

| 迭代 | 目标 | 交付物 |
|---|---|---|
| Iteration 1 | 拿到首个真实业务毛刺解释案例 | 问题描述、指标映射、解释记录 |
| Iteration 2 | 设计并验证降级式反馈 | 最小反馈策略、回归验证结果 |
| Iteration 3 | 决定是否进入 authoritative takeover | 接管前提检查、闭环准入条件 |

## 执行原则

| 原则 | 含义 |
|---|---|
| Business-first | 业务接入优先，结构优化服从真实痛点 |
| Evidence-first | 先采真实数据，再调参、再反馈、再接管 |
| Freeze refactor | 不做无压力结构整顿 |
| Guardrails stay green | smoke 与 full runner 必须持续绿 |
