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
