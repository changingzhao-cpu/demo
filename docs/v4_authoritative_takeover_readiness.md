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
| Business behavior | keep authority changes bounded to one explicit trial gate only |
| Validation | smoke and full runner remain green |
| Exit | only after this bounded milestone may broader authoritative control be considered |

## Current bounded trial status

| Item | Status |
|---|---|
| Trial scope | one single decision point |
| Trial promotion | `trial_gate` -> `authoritative_trial` -> `authoritative_takeover` |
| Visibility | `takeover_trial_applied` remains visible in `business_probe_events` |
| Guardrail | regression returns to shadow/review-only mode |
| Verification | full runner green (`All 163 test suite(s) passed.`) |

## Next implementation slice

- expose takeover review state in debug/runtime payload
- wire a shadow-mode business-facing field
- keep business authority unchanged in the first slice
- validate with smoke and full runner before any stronger coupling
- follow `docs/v4_takeover_rollforward_rules.md` before any bounded authoritative promotion

## Rollforward reference

- See `docs/v4_takeover_rollforward_rules.md`
- Promotion must remain bounded to one business decision point at a time
- Rollback returns immediately to shadow/review-only mode
