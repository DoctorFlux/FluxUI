# Deferred inventory provider ownership

BUG-002 / PERF-002, 29 October 2026. Builtin mail and owned-auction scans can start
before Syndicator becomes ready and continue over several frames. Their scheduling
entrypoints checked provider ownership, but their queued StepScan callbacks did not.
After Ready installed Syndicator snapshots, the old scans still read native data,
overwrote those snapshots and notified consumers. An unchanged provider mail refresh
then returned early because its fingerprint was unchanged, leaving the overwritten
snapshot in place. This reproduces a snapshot contract failure; a particular visible
tooltip or gameplay symptom was not established.

The fix checks ownership at the start of each StepScan, before its due-time check.
If ownership transferred, it clears queued/partial scan data and removes OnUpdate;
mail also clears its retry count. Mailbox/auction open state remains unchanged.
This matters because `Inv.IsMailboxOpen()` can use `Mail.IsOpen()` to defer heavy
inventory work. No display, settings, binding or secure-action code changed.

## Source and scenario identity

- Baseline commit `201bc8382f9fa6b5d9906200e3331a4ad90c2f13`, tree
  `6976189ef0843924e081d89cd47c83001f8d150f`. Actual files/settings/history were
  checkpointed at 09:32 UTC; see [RECOVERY.md](RECOVERY.md).
- Candidate runtime commit `05e9f79160ac641f842f5aba8eabd21f1fe0c1fe`, tree
  `6e612fa6b27282f5e535b361f5cf93ac17d250ba`.
- Nonloaded baseline fixtures preserve the original Mail/Auctions bytes. Raw hashes,
  exact commands and all repetitions are in the
  [comparison JSON](validation/deferred-inventory-comparison-2026-10-29.json).
- The [baseline identity check](validation/deferred-inventory-baseline-identity-2026-10-29.json)
  verified all 723 previously tested Lua hashes still matched; the earlier complete
  82-test result was reused instead of rerunning unchanged code. The new regression
  was captured before runtime editing: [210 checks, 42 failures](validation/deferred-inventory-baseline-2026-10-29.txt).

The regression runs production Store, Mail, Auctions and Syndicator readiness/list
builders, with native APIs, frames and other regions mocked. It tests queued and
partially completed scans, empty/populated providers, legacy/modern auction paths,
early-before-due cancellation, forced final inbox scans after close and incomplete
mail retries. Standalone and pending-provider debounce/publication, saved ledgers,
already-ready startup, duplicate readiness, and subsequent provider updates remain
covered. Provider callback timing is not certified by this mock.

## Measured desktop outcomes

Five alternating baseline/candidate process pairs ran the same 12 measured cases.
Each case used a fresh harness, 8 native mails or 70 owned listings; the partial
case ran one scan frame before Ready. Counters reset after the real Ready callback,
then the test drains at most 20 synthetic frames. Profiling is off. Per-case count
ranges were zero across all five repetitions. Startup/standalone/retry checks are
correctness controls, not measured startup or steady-state speedups.

| Work after handoff, per case | Baseline | Candidate |
|---|---:|---:|
| Mail API reads, queued / partial | 105 / 56 | 0 / 0 |
| Legacy or modern auction API reads, queued / partial | 71 / 38 | 0 / 0 |
| Stale snapshot generation increments | 1 | 0 |
| Stale notifications | 1 | 0 |
| Active scan callbacks after the first post-handoff callback | 1 | 0 |

Candidate passes all **210 checks** in every invocation. Existing inventory pipeline
test passes **1,732 checks** across its seven capability fixtures. The complete
[candidate suite](validation/deferred-inventory-full-2026-10-29.json) passes
**83 scripts and 724 Lua syntax files**, with zero failures. Independent source/test
review found no actionable defect. The old frames remain reusable; this fix removes
their active OnUpdate script rather than allocating a replacement.

Environment remains desktop Lua/luac 5.4.6, Python 3.10.6, Windows 10.0.26200,
Intel i7-12700F/20 logical processors. Native addon lists/settings, GPU/RAM, CPU,
attributed allocation, native operation latency and frame-time/FPS are unavailable.
Whole-process elapsed times in the raw record include interpreter/harness setup;
they do not establish a speedup. No WoW process was running at checkpoint capture.

```powershell
lua tests/deferred_inventory_handoff.lua --mail-source tests/fixtures/mail_scan_provider_before.txt --auction-source tests/fixtures/auction_scan_provider_before.txt --measure
lua tests/deferred_inventory_handoff.lua
lua Inventory/_tmp_inventorylag_smoke.lua
```

Baseline `--measure` intentionally exits zero while printing the 42 failed checks;
normal candidate execution must exit successfully with zero failures.

## Mail completion ownership

BUG-003 is a separate correction after the scan commit. A SendMail or ReturnInboxItem
post-hook captured attachments for a known alt while the builtin provider was active.
If Syndicator became ready before the success event, `Store.GetCharacter` then
returned the external provider's character record. The pending builtin callback
appended its payload directly to that record, without the provider owning the update.
It could also create a missing `mail` table. The old Flux ledger stayed unchanged.

Read-only replay verified this direct-reference contract against local Syndicator
288 `API/Main.lua` (SHA-256
`892f6607d05953dc22504b33fd8294b2908ca45f77157d3ef24767d8e76de393`). Its GetCharacter
alias returns the stored character table. The portable regression models that API
shape and introduces no new dependency on the external installation. The test uses
synthetic character records; no real player/provider saved data was mutated.

The callback now treats provider ownership like its existing failure cleanup:
clear the pending payload and all three possible completion subscriptions before
resolving the recipient. Normal builtin success/failure behavior, attachment counts,
expiration/quality and known-alt attribution remain covered.

- Baseline: scan-fix commit `05e9f79160ac641f842f5aba8eabd21f1fe0c1fe`, tree
  `6e612fa6b27282f5e535b361f5cf93ac17d250ba`; all 724 tested Lua hashes were verified
  unchanged before editing. The 09:41 checkpoint includes the actual dirty audit files.
- Candidate: `ab4e658a98a7ce3ee6688ac6170e7e0991325af0`, tree
  `67b4890083fe13e242ffbc47c36ff6037a172f82`.
- [Focused baseline](validation/pending-mail-baseline-2026-10-29.txt): 410 checks,
  8 failed assertions across four successful send/return plus existing/missing-mail
  handoff cases. Candidate: 410 checks, zero failures.
- [Five alternating pairs](validation/pending-mail-comparison-2026-10-29.json): each
  stale successful completion performs **1 to 0 provider lookups and 1 to 0 foreign
  row appends**, payload quantity **3 to 0**. Failure controls remain zero. Counts
  have zero range across repetitions; these are modeled operations, not native timing.
- Each action also runs 100 alternating standalone success/failure cycles per
  invocation: exactly 50 valid credits, one reused frame and zero retained completion
  events, both before and after. Permanent post-hooks remain installed and gated.
- The final [full suite](validation/pending-mail-full-2026-10-29.json) passes
  **84 scripts and 725 Lua syntax files**, including BUG-001 and BUG-002 regressions.
  Independent review found no actionable defect in the completion correction.

Counters start after the real Ready transition in a fresh fixture. Eight handoff
outcome cases and 200 standalone cycles run per invocation, with profiling off.
Environment/measurement limitations are the same as the scan replay above. This is
a correctness repair; no startup/idle/native CPU, allocation, latency or FPS benefit
is claimed.

```powershell
lua tests/pending_mail_provider_handoff.lua --source tests/fixtures/pending_mail_provider_before.txt --measure
lua tests/pending_mail_provider_handoff.lua
```

The completion baseline deliberately reports eight failures with `--measure`;
candidate execution must have zero failures. Native validation should additionally
observe known-alt sends/returns, failure, reload persistence and a naturally late
Ready between capture/completion where reproducible. Do not inject or replace
provider globals in live play. A native case not observed remains pending.

## Scope and native acceptance

All relevant native rows remain pending. Apply the matched-build/settings/profile/
foreground and screenshot protocol in [PERFORMANCE_PROTOCOL.md](PERFORMANCE_PROTOCOL.md).
Use the same addon identity sequentially, with five matched CPU and separate
unprofiled pairs. Record exact build and external Syndicator version. Test standalone
mail and AH open/close, taking/returning messages, changing owned auctions, incomplete
attachment data, and provider readiness before/between scan frames where naturally
reproducible. Check retained mailbox-open deferral and unchanged close/retry timing.
Do not force provider globals or inject fake readiness into live saved data; a late
Ready case that cannot be observed remains pending. Match screenshots of relevant
inventory presentation and interaction states, and retain sanitized raw evidence.

These corrections do not retire all builtin-provider resources. Auction SHOW
callbacks and guild/void events still need separate ownership checks/reproduction.
Permanent hooks and shared services are still present. The event-dispatch audit is documented separately
as a [latent API defect](EVENT_DISPATCH_AUDIT.md), with no current in-repository
gameplay trigger established. No dispatcher/runtime framework change was made.
