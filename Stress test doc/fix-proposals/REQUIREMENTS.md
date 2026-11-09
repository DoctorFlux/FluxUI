# Fix proposals before application — 7 November 2026

User: "lets find fixes before we apply them". Current focus is recurring USER-001
and its related ALPHA-01..06 and GEO-01/02 findings. This phase prepares and tests
reviewable candidates without applying them. Earlier Respec/service/performance
backlog remains in the original audit and is not silently marked fixed.

| ID | Requirement | Evidence needed |
|---|---|---|
| FP-01 | No live-addon runtime changes | Fresh frozen external baseline, candidate directories outside AddOns, final original-source comparison |
| FP-02 | Cast fade avoids restricted alpha read | Exact candidate hunk; old failure/new pass; unchanged public start1, holds, durations and completion |
| FP-03 | Swing fade preserves its intended alpha | No getter; public0/0.4/1, restarts at current painted midpoint, explicit writes/cancellation and completion; no new recurring driver |
| FP-04 | Redundant swing priority alpha read removed | Active-cast behavior unchanged; all inactive returns remain false; no opaque read |
| FP-05 | Alpha comparisons use permitted owned facts | Per-owner policy, exact public behavior and explicit unknown-state handling; no blanket0/hide/force1 |
| FP-06 | Glow recolor and retry state remain coherent | Own texture alpha write/animation inventory; preserve colors/fades/restarts; successful state commit and library license/ownership |
| FP-07 | Heal prediction uses public/native geometry safely | Preserve visible absorb amounts/geometry without secret comparisons or unauthorized opaque SetWidth |
| FP-08 | Tiled art remains visually equivalent | Public and unreadable geometry policy; preserve stripe scale/coverage; reject a candidate if parity cannot be established |
| FP-09 | Source contracts stay client-specific | Four requested client pins; native secret/protected/pixel acceptance remains distinct and pending |
| FP-10 | Candidates are concrete and reviewable | Diffs, before/after identities, failing baselines, passing cases, public-behavior controls and residual limits |

Existing user testing choice remains simulation only. No game, foreground,
keyboard, mouse, clipboard, profiler, settings, sync, branch, commit or push work.
No UI design change is intended. No approval is required for these isolated
research candidates; applying any candidate to the addon is outside this phase.

Candidate code is stored externally at paths in `workspace.json`. Only reports,
diffs, `.lua.txt` harnesses and metadata belong in this folder. Do not load any
candidate into a running game or invoke the existing mirror on it. A passing
mock demonstrates its supplied cases, not removal of native taint in the user's
unknown frame. Keep cast/swing attribution unconfirmed until actual evidence.

## Reconciliation

| Requirement | Result |
|---|---|
| FP-01 | External975-file snapshot; nine candidate files external; original live files still match at packet verification |
| FP-02/04 | Minimal staged cast endpoint/dead-read fix tested; native caller/taint acceptance pending |
| FP-03 | Broader Swing ownership prototype tested including restart/zero-elapsed/stale-completion cases; intentional behavior changes explicit; held for native acceptance |
| FP-05 | Concrete guarded-reader candidates tested; getter-call denial and exact unreadable-alpha appearance remain application gates |
| FP-06 | Candidate preserves tested public glow phases/recolor/pool reuse; winning-library ownership and coupled cache change remain gates |
| FP-07 | Native-anchor experiment rejected by snapshot mismatch; public-owner-width direction held; no geometric change selected |
| FP-08 | GEO-02 unchanged and held; no falsely claimed stripe-art parity |
| FP-09 | Four branch pins unchanged on recheck; needed current native contracts verified; native results not inferred |
| FP-10 | Staged diffs/source hashes, focused rejection/control tests and full222/222 baseline/prototype comparison retained; no actual application |
