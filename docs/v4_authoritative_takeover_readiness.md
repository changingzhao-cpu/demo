# V4 Authoritative Takeover Readiness

## Readiness review

| Check | Requirement | Current status |
|---|---|---|
| Silent integration | `business_probe_events` stable in real battle path | pass |
| Baseline establishment | baseline fields `wave/live_count/combat_event_count` stable | pass |
| Real issue interpretation | at least one business issue explained by V4 signals | pass |
| Degradative feedback | low-risk feedback path defined before authority shift | pass |
| Regression guard | smoke and full runner remain green | pass |

## Entry criteria

| Item | Rule |
|---|---|
| `takeover_ready` review | must not enter business decision loop before degradative feedback proves stable |
| Feedback order | degradative first, authoritative later |
| Guardrails | smoke and full runner must stay green |

## Initial decision

| Item | Decision |
|---|---|
| Immediate authoritative takeover | not yet |
| Next action | keep readiness review explicit and require a separate gate-activation decision |

## Activation boundary

| Item | Rule |
|---|---|
| First rollout mode | advisory-only or shadow mode first |
| Allowed effect | annotate or tag business decisions before modifying them |
| Forbidden first step | direct hard switch of battle authority |
| Promotion condition | degradative feedback stays stable and contracts remain green |
| Rollback condition | any smoke/full runner regression or business instability immediately returns to non-authoritative mode |

## First activation milestone

| Item | Target |
|---|---|
| Gate exposure | expose takeover review result to business layer |
| Business behavior | do not yet alter battle authority |
| Validation | smoke and full runner remain green |
| Exit | only after this milestone may authoritative control be considered |

## Next implementation slice

- expose takeover review state in debug/runtime payload
- wire a shadow-mode business-facing field
- keep business authority unchanged in the first slice
- validate with smoke and full runner before any stronger coupling
