# V4 Takeover Rollforward Rules

| Rule | Meaning |
|---|---|
| Promotion precondition | Shadow recommendation and degradative feedback must remain stable on real business paths |
| Promotion scope | Promote one bounded business decision point at a time |
| Rollback trigger | Any smoke regression, full-runner regression, business instability, or unexplained authority mismatch |
| Rollback action | Immediately return to shadow/review-only mode |
| Evidence requirement | Every promotion must name the business issue, V4 signal, feedback behavior, and expected business outcome |
| Escalation order | shadow -> degradative feedback -> bounded authoritative takeover |

## Promotion checklist

| Check | Required |
|---|---|
| Smoke green | yes |
| Full runner green | yes |
| Real issue interpretation documented | yes |
| Degradative feedback behavior documented | yes |
| Rollback path documented | yes |
| Scope bounded to one decision point | yes |
