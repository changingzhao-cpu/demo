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
