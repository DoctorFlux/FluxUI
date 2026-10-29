# Decisions

## 2026-10-29

- Modernize the existing `_FluxUI` and repository in place. User's current request
  supersedes fresh-project/no-old-code/separate-repository/rename instructions in
  older specs. Product requirements remain inputs; conflicting current behavior
  is recorded, not silently removed or redesigned.
- Use the current change branch; leave `main` untouched until explicitly
  authorized. Keep the same TOC, public commands, saved roots and profiles. No push
  or merge is part of the first batch.
- Preserve all actual files and Git history outside AddOns before changes, including
  original untracked package/log and ignored local work. Relevant private settings
  remain outside Git. Exact hashes and recovery procedure are in `RECOVERY.md`.
- Reuse the existing source/reference collector, Lua validation runner, performance
  diagnostics and service architecture. Append ledgers, not a competing framework.
  Refresh generated indexes because the baseline references were stale; their larger
  diff is an audit correction, not thousands of runtime changes.
- Select BUG-001 before general lifecycle restructuring: production Currency/Store/
  Adapter replay proves stale builtin snapshot writes after external Ready. Four
  execution-time guards use the existing authoritative provider flag. Keep four
  shared-bus subscriptions inert after handoff; full provider retirement is separate.
- Preserve standalone startup, immediate money updates, token/warband cadence,
  saved ledger and provider callbacks. No appearance/secure-input code changes.
  Deliberate correction: provider-owned money must not be overwritten by a stale
  builtin event; the regression checks this exact failure.
- Runtime fix/test/fixture are a separate commit from requirements/audit/generated
  references. The supplied package is retained verbatim; no user log or settings is
  staged. Commit-only author configuration follows existing repository attribution.
- Desktop deterministic counters are valid operation evidence, not native CPU,
  memory or FPS. Requests are not executed scheduler passes. Historical native
  samples retain original context and cannot certify this candidate.
- PE versions and source version files are recorded separately from native
  GetBuildInfo. Retain original Wrath, modern Wrath and Cata as distinct rows;
  unavailable or unsupported cases are explicit. No TOC compatibility changes yet.
- Correct documentation when direct source evidence resolves it (`OptionalDeps`,
  Ready handoff, native item identity APIs, `/fluxui bliz`). Preserve unresolved
  product differences/defaults until a focused decision or reproduced defect.

## 2026-10-29 continuation — deferred provider work

- Followed the next-step event audit rather than assuming a historical finding was
  an active gameplay bug. Production dispatch reproduces skipped callbacks during
  removal, but the only active removal owner is Context.DisarmEvents and no current
  production call to its unsubscribe path was found. Keep this latent API defect
  documented in `EVENT_DISPATCH_AUDIT.md`; defer a hot-path redesign until a concrete
  consumer or lifecycle migration requires it.
- Prioritize BUG-002: queued/partial builtin mail and auction scans can outlive
  Syndicator readiness and overwrite the provider snapshot. Execution-time ownership
  checks belong at the beginning of each existing StepScan, before debounce/time
  checks. Cancel its data and OnUpdate work, preserving mailbox/auction open state,
  standalone scan budgets, close behavior and incomplete-data retries.
- Keep mail-send/return completion and auction/guild query ownership as separately
  tracked follow-ups. This scan fix does not claim complete builtin-provider teardown.
- Reuse the earlier complete 82-test/723-file baseline only after verifying every
  tested Lua hash matches current bytes. Capture the new focused failure before
  runtime edits and run full candidate validation after the change.
- The next controlled replay proved BUG-003 for both SendMail and ReturnInboxItem:
  completion after Ready mutates the exact character table returned by Syndicator.
  Treat loss of ownership like existing failure cleanup before resolving the
  recipient; clear the pending operation and its subscriptions. Keep this separate
  from scan cancellation, with its own checkpoint, baseline and regression.

## 2026-10-29 continuation — disabled Windows lifecycle

- User explicitly deferred auction, guild-bank and void-storage callback audits.
  Redirected independent inspection to the documented WindowMover disable behavior.
- Production Catalog/Engine/Init/options replay reproduced disabled attachment and
  polling, plus public SetEnabled(false) retaining an active scale gesture that
  changes saved scale. Fix BUG-004/PERF-003 using the existing Scan and Refresh.
- Gate discovery before native hook setup; hide/show the existing panel watcher
  through Refresh; call Refresh on both public enable outcomes. Keep enabled
  cadence, frame reuse, native protection guards and saved positions/scales.
- Retain existing permanent guarded hooks, startup proxy/driver, two discovery
  event subscriptions and two bounded startup callbacks. Their disabled Scan now
  returns before catalog access. Do not claim complete module teardown.
- Reused the 84-script full baseline only after verifying all 725 Lua source hashes.
  Captured a new verified external source/history/private settings checkpoint before
  edits. Matched desktop counters establish removed work; native input/pixels/taint/
  performance remain pending.

## 2026-10-29 — editorial maintenance

- Use conventional contribution guidelines and development tasks instead of editor
  workflow files. Archive original prompts/templates, planning Word file, old handoffs,
  local backup trees and sync log outside the addon before removing active copies.
- Rewrite conversational comments as technical explanations. Preserve every executable
  Lua token/string, native restriction invariant, license and third-party attribution.
- Retain technical specifications, tests, measurement values and revision identities.
  Use factual descriptions of the recorded procedure. Preserve
  original records in the verified checkpoint and omit optional branch metadata.
- Do not rewrite Git history or alter main as part of a working-tree cleanup.

## 2026-10-29 — queued merchant purchase identity

- BUG-005 is an active queue correctness issue: production replay buys a replacement
  merchant item or submits an empty slot after listings change. Index refresh alone
  cannot repair retained task references. Protect the operation, not just index build.
- Reuse ResolveMerchantSlotItemID in RunBuyPass's invalid-task condition. Discard a
  missing/mismatched listing before quantity calculation, purchase, wallet debit or
  reporting. Continue valid tasks at the original eight-call budget and cadence.
- Do not relocate stale tasks or restart the session automatically: a fresh normal
  request uses current index/remaining counts. This avoids resubmitting earlier
  purchases while inventory acknowledgements may still be settling.
- Record the extra identity lookup per valid purchase as correctness overhead.
  No native performance improvement is claimed. Unchanged-ID price/stock changes
  and purchase acknowledgement are separate unmeasured candidates.

## 2026-10-29 — finite merchant stock budget

- BUG-006 reproduces two related capacity defects: zero availability was uncapped,
  and repeated tasks reused the same finite snapshot count. Treat zero as a cap and
  reserve submitted quantities on the existing shared index entry.
- The shared remaining value is a reservation budget until index refresh, not proof
  of native acceptance. Do not introduce another transaction service or live polling.
  Unrelated rejections, external stock changes and acknowledgement remain separate.
- Preserve unlimited/nil helper semantics, gold/alternate-cost math, eight-call pass
  budget, UI/defaults/settings and normal refresh/new-request recovery. Extend the
  existing merchant harness with focused stock/identity groups rather than duplicate it.
- Exact read-only Blizzard source hashes support API shape/zero-stock interpretation;
  the 12.1.0.69283 snapshot predates installed clients and does not advance native rows.

## 2026-10-29 — vendor-open availability work

- Prioritize the user's idle vendor-open hitch, reported only on Era so far. Do not
  assume first-open/repeated-open behavior or automation settings, and do not claim
  native resolution from a desktop reduction.
- BUG-007/PERF-004 reproduces repeated fallback bag walks in the real availability
  path. Cache its exact boolean result under the existing junk owner using reliable
  bag generation and existing rule/item/list/slot invalidation. A classified count
  of zero alone is insufficient for cold gray-item data. Retain native-positive
  precedence, live retry when unready/unreliable, and all callback timing.
- Reuse the junk-smoke boot fixture and production buyer events plus unmodified UI
  availability sections. Document excluded rendering/layout/integrations. Seven API
  fixtures are regression coverage, not native client certification or original
  Wrath support. Keep cold and repeated-open counts separate.
- Retain the buyer frame and native count-query controls; add no timers/subscriptions,
  settings or generic cache service. Native query overhead, CPU/frame times and the
  remaining classification/index/Already Known/layout candidates need live evidence.

## 2026-10-29 — Quick Join anchor ownership

- Prioritize the user's concrete native SetPoint error. The column already anchors
  Channels to Quick Join; the old social callback reverses that edge. Existing
  isolated column/retry fixtures did not run the two owners together.
- BUG-008 returns before the fallback reanchor while either button belongs to the
  Flux column. Check both to survive a native reparent of either one. The enclosing
  callback still reconciles through PlaceColumnButtons; unmanaged fallback remains.
- Add parent/anchor cycle detection and correct bottom-point geometry to the existing
  column fixture, then execute real social/hook/retry callbacks there. Retain its
  five-branch controls. No competing owner, global API replacement or broad runtime
  error suppression is needed; preserve column geometry and the three deadlines.
- The baseline combat exception never reaches its existing waiter. The candidate
  reaches that deferral and reuses one waiter; it does not add a new runtime frame
  service. Native geometry, input/taint and performance remain pending.

## 2026-10-29 — repeated vendor tier candidates

- User confirms Era spikes on every same-vendor reopening. Read-only hashes showed
  the preceding junk/buyer/chat fixes already installed; do not assume a stale copy.
  Saved scriptProfile=1 is an observation requiring matched unprofiled validation,
  not proof of causality or permission to change the user's preference.
- Preserve merchant discovery/reference seeding. A blanket lazy-index skip can
  suppress that feature. PERF-005 instead filters actual tier matches before live
  usability in best selection and status; non-improving best contenders also skip
  the gate. Matching contenders retain fresh level/skill checks without a new cache.
- Reuse the existing buyer fixture and actual Score/Match/Vendor modules. Extend
  measurement to 25 reopenings with retained food/water refs and unoffered families
  after the user's cadence clarification; retain the source fix and test extension
  as separate reviewable commits.
- Ready-classification calls remain equal in measured runs. Classification now
  precedes level rejection, so cold tooltip cost can differ and needs native checks.
  Service call reductions are not native cache-miss, CPU, latency or FPS results.

## 2026-10-29 — native tier count attribution

- The clean Era 1.15.9.70576 four-reopen pilot reproduces a 333 ms UI interval;
  GetRestockTargetItems spends about 320 ms per call. Inclusive bag/bank count and
  tooltip rows identify a measured target; do not sum overlapping timings.
- PERF-006 filters tier membership before live usability in existing bag and cached
  personal/warband count owners. Keep live gates on matches, accounting, caches,
  fallback and protections. No new lifecycle resources or generic service.
- Five alternating native background getter pairs return identical quantities;
  median CPU is 132.199 to 15.237 ms for five bag kinds, 118.897 to 22.517 ms for
  cached-bank kinds. Bank outputs are zero on this character; positive/warband
  parity is desktop-only. Candidate bodies ran as source-derived local functions;
  no public/native API replaced. This is not full-window after acceptance.
- Honor the user's background PC use: no further game activation. Background local
  slash diagnostics preserved focus; original automation values and profiler=1
  restored, temporary exports removed and sampler/namespaces cleared by reload.
  The user's normal sync delivered source; no separate addon or sync job created.
- Native foreground repeated opens, unprofiled FPS, matched pixels, cold work,
  security/taint and other clients remain pending. Keep auction, guild-bank and
  void-storage callbacks deferred. [Evidence](TIER_COUNT_WORK.md).

## 2026-10-29 — whole-addon Retail resource audit

- Cover all 26 loaded source domains through current ownership/recurring-driver
  maps. Native idle execution does not exercise every lifecycle or prove leak-free
  operation; keep pending interaction/client scenarios explicit.
- BUG-009/PERF-007 reuses loot combat/readiness frames after production replay proves
  203 allocations across repeated world/combat cycles. Keep 50-update timeout,
  six-pixel anchor, native show hook and no protected writes in combat.
- BUG-010/PERF-008 explicitly releases full requested-capture snapshots and handle
  cycles. Retained-callback replay proves 20 -> 0 snapshots and 10,000 -> 0 frame
  rows per model. Retain the compact report, schema, deadlines and dormant behavior.
- Native Retail baseline has stable frame/public-cache counts but memory increases
  during diagnostics. Attribute requested capture retention before accusing the
  normal HUD. Native CPU ranks nameplates and assisted painting; do not disable
  features or slow update cadence without matched evidence.
- Discard the incomplete long-upload native comparison; no result for its missing
  candidate. Use normal file-loaded API calls for follow-up. Original profiler=0
  must be restored; no game activation, global API replacement or restriction bypass.
- Preserve the existing uncommitted tracker source/test/docs. Keep its changes out
  of the new runtime commits and record actual-file identities separately from HEAD.
  Main and excluded auction/guild-bank/void callbacks remain untouched.

## 2026-10-29 — common Social offset and dock ownership

- User-authorized intentional position correction: one eight-unit inset from the
  tab/menu top across client paths, preserving other layout/feature behavior.
- Use existing tab height as a relative offset. An absolute future top against a
  provisional login chat rectangle goes stale after the final pin; no timer/hook
  is needed to follow that movement.
- Anchor the column to primary ChatFrame1 on all tabs. Combat Log/custom native
  rectangles may differ; selected-tab identity remains solely for Copy/action data.
- Preserve Classic ownership/overflow handling, other menu-position fallback,
  scale conversion, combat restrictions and current retry deadlines. No framework.
- Native seven-selection Retail pass plus untouched reload image supports this
  scope. Five desktop branch models are not other-client native certification.

## 2026-10-29 - original stage tracking and countdown work

- Continue the supplied original plan through explicit stage gates; inventories
  and passing desktop checks do not complete all native acceptance.
- PERF-009 keeps the existing NamePlates owner/driver/cadence and removes repeated
  FontString discovery plus per-aura level tables. Reuse only within one poll;
  changing/opaque labels and native digit fallback remain fresh.
- Keep real unprotected native-widget results separate from actual combat aura
  rendering/taint/FPS. Background whole-addon scene changed, so that comparison
  is inconclusive even though errors remain0 and per-window frame counts stable.
- The user again explicitly requested root working rules and next-session records;
  restore those concise files alongside existing contribution/development docs.
  Do not restore retired prompt templates, narrated comments or private artifacts.
- Preserve the separate tracker work and current branch; main and excluded
  callback audits remain untouched. Keep WoW in the background and profile0.

## 2026-10-29 - action batch facts and native player auras

- Sample activation once within an existing bar paint batch. Pass explicit false;
  retain fresh standalone queries and the API helper's independent guard. No
  cross-frame cache, generic framework, animation suppression or slower cadence.
- Keep top-right player aura data/handlers/styles native. Short-idle measurements
  do not justify a competing aura painter or prove dense/restricted churn safe.
- Treat source-derived real-painter matched runs separately from complete-addon
  CPU/FPS. Both native clients use inactive highlight settings; real active combat
  input still requires acceptance. Preserve failed/inconclusive scope honestly.
- The user authorizes normal reconnect/warning dismissal and named character
  selection for testing. Same-account sessions displace each other: run serially,
  validate each executable/window and preserve foreground PC use. No credentials.
- Leave the user-owned mirror job unchanged. Verify each source transition; when
  delayed, copy only the known test file into the existing authorized client.
  Restore each original profiling preference and prior diagnostic report.
