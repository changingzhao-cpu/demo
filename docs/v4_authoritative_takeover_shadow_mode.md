# V4 Authoritative Takeover Shadow Mode

## Intent

| Item | Meaning |
|---|---|
| `takeover_shadow_mode` | 当前仅处于 review-only / shadow-mode，不进入真实接管 |
| `takeover_shadow_ready` | 表示是否满足影子态准入前提 |
| `takeover_shadow_recommendation` | 给业务层的建议动作，默认 `hold` |
| `takeover_shadow_reason` | 解释当前为什么还不能进入真实接管 |

## Current rollout policy

| Stage | Policy |
|---|---|
| Shadow | expose recommendation only |
| Degradative feedback | may reduce load or relax precision |
| Authoritative takeover | forbidden until shadow and degradative stages stay stable |

## Initial default

| Field | Value |
|---|---|
| `takeover_shadow_mode` | `review_only` |
| `takeover_shadow_ready` | `false` |
| `takeover_shadow_recommendation` | `hold` |
| `takeover_shadow_reason` | `awaiting_stable_feedback` |

## Shadow review event shape

| Field | Meaning |
|---|---|
| `event_type` | `takeover_shadow_review` |
| `recommendation` | current shadow recommendation |
| `reason` | why the recommendation is produced |
| `feedback_mode` | current feedback mode when recommendation is produced |
| `takeover_shadow_mode` | current shadow gate mode |
| `takeover_shadow_ready` | whether shadow gate thinks the case is reviewable |
| `attack_midband_drift_count` | drift evidence carried into review |
| `attack_rebind_escape_count` | escape evidence carried into review |

## Current policy
- expose recommendation only
- do not alter battle authority
- use shadow review output for business-side advisory consumption next

## Bounded trial status

| Field | Current bounded meaning |
|---|---|
| `review_only` | 仅做影子评审与建议输出 |
| `trial_gate` | 单一决策点已满足受控试运行前提，但尚未进入 live authority |
| `authoritative_trial` | 单一决策点已进入受控 live trial |
| `authoritative_takeover` | 当前 trial 的 live recommendation，仍不意味着全局多点 authority 扩张 |

## Business-side consumption rule
- 业务层可以消费 `review_only` / `trial_gate` / `authoritative_trial` 状态做显示、标记、日志或 timeline 记录。
- 除已批准的单一决策点外，不得把这些状态扩展成第二个真实 authority 改写点。
- `takeover_trial_applied` 必须持续可见，作为 bounded live trial 已发生的证据。
- `battle_report_timeline` 应保持可读，用于承接 advisory 与 trial 的业务解释链。

## Current boundary
- bounded trial 已完成验证，但当前仍只允许一个显式决策点进入 authoritative trial。
- 下一步先加强业务侧消费与证据稳定，不直接新增第二个 takeover 点。
