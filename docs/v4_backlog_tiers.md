# V4 Backlog Tiers

## P1

| Item | Why it stays out of current slice |
|---|---|
| 用 V4 数据解释真实业务中的已知毛刺/拥挤点 | Baseline 已建立，下一步应进入真实问题解释 |
| 降级式 gate feedback | 当 V4 报 Warning/Critical 时，优先做特效削减、AI 精度放宽、负载节流，而不是粗暴阻断战斗逻辑 |

## P2

| Item | Why deferred |
|---|---|
| 大脚本拆分 | 当前收益低于交付收口收益 |
| runner 内部进一步重构 | 当前只修入口，不动内部 |
| Critical 精度继续提升 | 当前 contract 已可交付 |
| 20 resources / DummyTexture 尾项继续排查 | 已 accepted，不阻断交付 |

## Rule

- Closeout phase must not accept new feature logic.
- Any new work must be classified into P1 or P2 before implementation begins.
