# V4 Delivery Archive

## Milestone Timeline

| Phase | Status | Notes |
|---|---|---|
| Warning truth-hardening Phase 1-3 | done | warning unified snapshot stabilized |
| Critical truth-hardening Phase 1 | done | fitted thresholds / payload mirrors stabilized |
| Fast-track exit | done | runtime trace unified snapshots exposed |
| Critical runtime perturbation hardening | done | anomaly_scan and perturbation_summary mirrored into critical gate results |

## Artifact Contract Map

| Surface | Required fields |
|---|---|
| Warning unified snapshot | `family`, `confidence_score`, `thresholds`, `support_counts`, `blockers`, `gate_results` |
| Critical unified snapshot | `family`, `confidence_score`, `thresholds`, `support_counts`, `blockers`, `gate_results`, `attack_rebind_escape_count` mirrors |
| Runtime trace payload | `probe`, `warning_unified_snapshot`, `critical_unified_snapshot` |

## Metric Physics

| Metric | Physical meaning |
|---|---|
| `contention_index` | 接敌/分配阶段的拥挤与冲突压力近似量 |
| `claim_success_rate` | 单位稳定占据预期接敌/分配结果的成功率 |
| `late_commit_deviation` | 后提交造成的状态偏差，用于识别“结果晚到”不稳定 |
| `old_escape_hit` | 历史 escape 异常是否在新采样中重现 |
| `attack_rebind_escape_count` | 攻击态重绑后再次逃出稳定接敌窗口的次数 |
| `attack_rebind_recontact_count` | 逃出后重新回到稳定接敌窗口的次数 |
| `attack_midband_drift_count` | 攻击中带内的不合理漂移次数 |

## Acceptance Boundary

| Area | Acceptance |
|---|---|
| Warning artifact | unified snapshot 可消费且 contract 保持绿 |
| Critical artifact | perturbation mirrors / takeover gate / payload contracts 保持绿 |
| Runtime trace payload | warning/critical unified snapshots 持续可消费 |
| Full runner | `All 163 test suite(s) passed.` |

## Known Tail

| Item | Status | Policy |
|---|---|---|
| `DummyTexture/ObjectDB/resources still in use` | accepted | 不再作为当前 V4 交付阻断项 |
