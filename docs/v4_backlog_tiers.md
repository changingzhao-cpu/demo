# V4 Backlog Tiers

## Active next phase
- Phase E / Authoritative Takeover
- Goal: verify whether takeover_ready can safely enter business decision loops

## P1

| Item | Why it stays out of current slice |
|---|---|
| authoritative takeover 准入检查 | 需要先验证 takeover_ready 是否适合进入真实业务决策回路，具体检查项见 `docs/v4_authoritative_takeover_readiness.md` 与 `docs/v4_takeover_rollforward_rules.md` |
| 降级式 gate feedback | 已有方向，但仍需继续观察其对真实业务的缓解效果 |

## P2

| Item | Why deferred |
|---|---|
| 大脚本拆分 | 当前收益低于交付收口收益 |
| runner 内部进一步重构 | 当前只修入口，不动内部 |
| Critical 精度继续提升 | 当前 contract 已可交付 |
| 20 resources / DummyTexture 尾项继续排查 | 已 accepted，不阻断交付 |

## Rule
- Degradative feedback may begin only after at least one real business issue has been explained by V4 signals.
- Authoritative takeover may begin only after degradative feedback has proven stable on real business paths.
- Closeout phase must not accept new feature logic.
- Any new work must be classified into P1 or P2 before implementation begins.
