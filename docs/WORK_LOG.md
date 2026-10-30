# Work log

## 2026-10-30 — unit power visibility

Read the continuity/specification records; verified clean main
`058efb8192b537d73e7e1e7f1a7e6afe2fbde575`, the dated external
source/history/settings checkpoint and present on-disk Retail settings before
runtime edits. Inspected Gethe's `live` UI source and local client contracts.
Flux-owned main and raid frames now hide known zero-maximum power bars and let
health fill the inner region; power returns on capacity changes. After user
feedback that Live/Forever health still looked split, verified source annotations
and placed full-height health behind a power layer with native secret-safe alpha.
Raid combat reanchoring waits for regeneration. Existing
health-only satellites require no change. [Details](UNIT_POWER_VISIBILITY.md).
Follow-up: health text now follows full-height HP for absent/restricted power;
known positive power keeps the split-area text anchor. The Flux separator starts
transparent and follows max-power alpha. Verified the existing dated external
source/history/settings checkpoint still exists; Retail on-disk `Config.wtf`
changed outside this work and was not opened for writing.

Focused models pass. Full desktop validation passes 96 scripts / 737 Lua files.
Native checks across clients, secure combat, restricted values and pixels remain
pending. WoW remained in the background; no settings/profiler/diagnostic or
other addon state changed. Main contains uncommitted source, test and records.

## 2026-10-29 — teleport counts and interrupted casts

User confirms Retail interrupted teleport/portal lag and unwanted reagent-free
count. Read continuity/travel requirements, inspected clean main b45eb5e and
verified fresh external source/history/on-disk Retail settings before edits.
BUG-012/PERF-011 uses native count text, clears reagent-free legacy digits, stops
fabricating runes from opaque text, skips reagent construction for eligibility
and restores the host without popup/key rebuild. No settings/default/cadence or
other flyout-owner changes. [Exact identities/limits](TELEPORT_CAST_WORK.md).

527 assertions: baseline 14 failures, candidate zero. Three rejected mutations.
Five alternating desktop pairs: per 100 integrated casts, tooltip calls 2,000 -> 0
and popup rebuild boundaries 100 -> 0, zero variation. Full 95 scripts / 736 Lua
files pass. Native reported-hitch resolution/combat/taint/pixels and general
custom flyouts pending. WoW/profile/diagnostic/settings untouched; no foreground
input, sync job, commit or push. Existing history preserved.

## 2026-10-29 â€” audit baseline and first provider fix

Inspected actual main `7436820`, remote, manifests, tests, diagnostics, documentation
and supplied Word/Markdown plans/templates/specifications. Initial tracked tree was
clean; `new docs/` and sync log were untracked. No root/ancestor instructions existed.
Merged durable rules without modifying supplied documents. Read-only audits
covered all supplied specs, lifecycle ownership and installed clients/references.

Before repository edits, created and verified source ZIP (1,177 files), Git history
bundle and private settings ZIP (403 files), while no WoW process was running. See
`RECOVERY.md`. Created the current change branch; main was preserved.

Ran `python tests/run_validation.py --output docs/validation/modernization-baseline-2026-10-29.json`:
81 tests passed; 722 Lua syntax files, zero failures. Lua/luac 5.4.6, Python 3.10.6.
Existing historical P0 fixes remain regression controls, not reimplemented work.

Reproduced BUG-001 in real Store/Currency/Syndicator adapter code with native APIs
and unrelated regions mocked. Before editing runtime, added a focused test and
captured `lua tests/currency_provider_handoff.lua --measure` output: 150 checks,
50 failures. A 400-event burst after Ready reads builtin money 100 times, requests
300/400 redundant refreshes and overwrites provider money 999 with 654. Saved
standalone ledger was already protected by Store; the shared snapshot was not.

Added four provider guards and an ownership comment in Currency.lua. Preserved
the baseline source as a nonloaded `.txt` fixture with matching checkpoint hash.
Targeted candidate and existing late-inventory regression passed. Five alternating
baseline/candidate process pairs each exercised five capability models and five
400-event repetitions. Candidate passed 150 checks every invocation; all stale
read/request/generation counts became zero with zero range. Four shared-bus callbacks
remain subscribed; external update and standalone timing checks pass. Raw samples
and identities are in `validation/currency-provider-comparison-2026-10-29.json`.

Ran `python tests/run_validation.py --output docs/validation/modernization-candidate-2026-10-29.json --sync-docs`:
82 tests passed; 723 syntax files, zero failures. Independent diff review found no
actionable correctness defect and confirmed limits of the mocked evidence.
Runtime/test/fixture committed separately as `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`,
tree `86ed71c06dc9bc2117fb60e30d5417976506912a`. Initial commit attempt found no Git
author configuration; retry used this repository's existing DoctorFlux name/noreply
address through command-only settings, without changing global/local config.

Created feature/options/default/command/integration inventory (1,384 rows, all 26
specs, 17 discrepancies), client/reference matrix, ownership/dependency/API maps,
prioritized implementation plan and performance protocol/results. Refreshed existing
generated references with `python -B docs/tools/build_reference.py`: 756 Lua/XML
sources, 577 reachable, 361 option definitions, 519 defaults. Corrected stale prose
about load order, OptionalDeps, provider timeout/global item wrappers and `/fluxui bliz`.
The generated diff includes previously stale references, not additional runtime work.

`python -B docs/tools/validate_docs.py` passed: 756 classified sources, 577 reachable,
361 setting definitions, 23 saved roots and 12,649 valid local links. All six CSV
ledger row shapes passed. All 723 current Lua files match the candidate manifest;
the 42 original supplied-package/log files match the recovery hashes byte-for-byte.
`git diff --check` passed. Generated/explanatory reference refresh is committed
separately from the new audit, continuity and preserved requirements package.
The later full staged check flags the supplied specs' intentional Markdown
two-space line breaks and their verbatim CSV copies. They are preserved; the
staged check passes with end-of-line whitespace excluded. No source normalization
was applied to the user's package to silence those warnings.

No native clients launched, no settings mutated, no reference addon copied or edited,
and no deploy/sync to another installation. Native visual/input/secure/taint/secret,
CPU, allocations, latency and frame-time/FPS acceptance remains pending. Larger
architecture/lifecycle migration is unfinished. Next investigation is event-dispatch
mutation and its actual consumers, with a separate baseline before any fix.

## 2026-10-29 continuation â€” deferred scans and mail completion

Resumed on `201bc83`; tracked tree was clean and only the original sync log was
untracked. Read instructions, status, decisions, ownership/performance records and
relevant inventory specs. Preserved verified checkpoints at 09:32 and 09:41 UTC
outside AddOns, including actual files, Git history and private WTF while WoW was
closed. Main stayed at `7436820` throughout.

Production event-dispatch replay confirmed skipped handlers under removal and
inconsistent same-event additions. Traced the real Ev alias through Context:
DisarmEvents is called only from Unsubscribe, with no production caller found.
Recorded the latent API issue and six reproducible sequences in
`EVENT_DISPATCH_AUDIT.md`; no shared dispatcher changes were justified for this batch.

Prioritized BUG-002 after reproducing real Store/Mail/Auctions/Adapter handoff:
queued/partial builtin scans overwrite external snapshots after Ready. Unchanged
provider mail fingerprints can leave that corruption in place. Verified all 723
previously tested Lua hashes before reusing the existing full baseline, captured
new focused baseline (210 checks/42 failures), then added execution-time ownership
checks and cancellation in the two StepScan callbacks. Mailbox/open state, retry
and standalone close behavior remain. Five alternating pairs report zero variation:
queued/partial mail reads 105/56 to zero, auctions 71/38 to zero, stale publication
one to zero. Existing inventory pipeline passes 1,732 checks; full candidate passes
83 scripts/724 syntax files. Runtime/test/fixtures committed as `05e9f79`.

Separately reproduced BUG-003 for SendMail and ReturnInboxItem using controlled
post-hooks/events and actual local Syndicator 288 API/Main.lua returned references.
Completion after Ready appended directly to provider-owned alt mail. Portable tests
model that verified contract without adding an external fixture dependency. The
next baseline verifies all 724 tested Lua hashes and preserves the current Mail
fixture. Focused baseline: 410 checks/8 failures. A single ownership condition now
routes stale completion through existing failure cleanup before destination lookup.
Five alternating pairs pass all 410 candidate checks; four success cases change
one provider lookup/foreign row append to zero. Each action's 100 standalone cycles
retain one frame, zero subscriptions and 50 valid credits before/after. Independent
reviews found no actionable issue. Committed separately as `ab4e658`.

Commands/results:

- `lua tests/deferred_inventory_handoff.lua`: 210 checks pass; baseline `--measure`
  with both retained fixture arguments reports 42 expected failures.
- `lua tests/pending_mail_provider_handoff.lua`: 410 checks pass; baseline with
  `--source tests/fixtures/pending_mail_provider_before.txt --measure` reports 8 failures.
- `lua Inventory/_tmp_inventorylag_smoke.lua`: 1,732 checks pass across seven models.
- `python tests/run_validation.py --output docs/validation/deferred-inventory-full-2026-10-29.json --sync-docs`:
  83 scripts and 724 syntax files pass, before BUG-003.
- `python tests/run_validation.py --output docs/validation/pending-mail-full-2026-10-29.json --sync-docs`:
  final 84 scripts and 725 syntax files pass. All final Lua bytes match its manifest.
- Matched samples and exact commands/source hashes are preserved in the deferred
  inventory and pending mail comparison JSONs; continuation-identities pins both
  commit/trees and final normalized corpus. Process durations are not native CPU/FPS.

Updated parity, ownership/API/dependency, client, plan, performance, continuity and
recovery records. No new abstraction, native API replacement, settings migration,
client deployment, push or merge. Original user package/log remains preserved.
Native visual/input/secure/taint/performance results remain pending. Next source
investigation is auction/guild/Void query/request work after Ready; it is currently
an unmeasured finding rather than a claimed fixed defect.

Final reference regeneration reports 758 classified sources/577 reachable;
`python -B docs/tools/validate_docs.py` passes with 361 settings, 23 saved roots and
12,685 valid local links. All six CSV ledgers have valid row shapes and all 725 Lua
hashes match final validation. The 41 supplied package files match the original
archive. The sync log grew to 142,774 bytes before this continuation (09:30:44 UTC);
it matches both new checkpoints and was left untouched/untracked. This explains the
initial final-preservation check's mismatch against the older 111,922-byte log;
no rollback or overwrite was performed. Whitespace checks pass with intentional
verbatim Markdown line breaks retained.

## 2026-10-29 continuation â€” Windows enable/disable (user excludes provider queries)

Resumed on `f1a3bc7`, same modernization branch, with only the original sync log
untracked. Read durable records, lifecycle/feature/API/client/performance records,
Windows requirements/options, actual Catalog/Engine/Init, existing tests and runner.
The user explicitly excluded auction, guild-bank and void callback investigation;
no runtime edits were made in those domains.

Before edits, created and hash-verified a fresh external checkpoint at 10:07:52 UTC:
1,219 actual source files, all Git refs/history, and 403 private settings files with
WoW closed. Rechecked all 725 Lua hashes against the previous passing full report
before reusing that baseline. Main remains `7436820`; no push/merge/deployment.

Production mover/options replay reproduced BUG-004/PERF-003: disabled startup still
runs catalog discovery and native attachment, Player Spells keeps polling, and the
public SetEnabled(false) leaves a scaling driver able to change saved scale.
Captured 220 checks/108 failures before editing. The two-file runtime diff gates
Scan by existing settings, hides/shows the panel watcher through Refresh and calls
Refresh for both public enable outcomes. Existing options setter already uses it.
No saved data migration, new framework or native API replacement.

Commands and evidence:

- `lua tests/window_mover_disabled.lua --baseline --measure`: 108 expected failures
  in 220 checks using retained pre-fix source fixtures. Initial baseline was captured
  from unchanged runtime before applying the fix. Measure mode deliberately exits 0.
- `lua tests/window_mover_disabled.lua`: 220 checks pass, including real options and
  module startup, event/delayed discovery, 100 enable/disable cycles, scale persistence,
  public disable during scaling and combat-deferred Apply.
- `lua WindowMover/_tmp_charactercombatsmoke.lua`: passes existing modeled Forever
  mouse/gamepad hook isolation and combat recovery controls.
- Five alternating fresh-process pairs: disabled-start discovery 24 to zero,
  resolution calls 2,546 to zero, hooks seven to zero. After enabled startup, 20
  disabled event scans/2,120 resolves and 100 polls in ten modeled seconds become
  zero. Public disable stops post-disable saved scale change and both update loops.
  Count ranges are zero; 100 cycles retain seven fixture frames/hooks and scale 1.2.
- `python tests/run_validation.py --output docs/validation/window-mover-full-2026-10-29.json --sync-docs`:
  85 scripts/726 syntax files, zero failures. These are desktop mocks, not native
  UI/secure/taint/secret/FPS acceptance. Process durations are advisory only.

Runtime/test/fixtures committed separately as `19c40a0c84212b24fdf221a9653a4116d32f9020`,
tree `92973edadfdd5ebfc5935621bc2b77f1e0655066`. Review of the small runtime diff
confirmed enabled geometry paths/restriction guards are unchanged.  Evidence/native steps are in
`WINDOW_MOVER_LIFECYCLE.md`; current baseline/candidate hashes and matched outputs
are pinned in `validation/window-mover-comparison-2026-10-29.json`.

Latest documentation validation passes: 759 classified sources, 577 reachable,
361 setting definitions, 23 SavedVariables roots and 12,704 local links. All six
CSV ledgers have valid row shapes (1,384 parity, 35 ownership, 18 API contracts,
eight client, 77 reference and 109 performance rows). All 726 current Lua hashes
match full validation; all 42 supplied package/log files match the fresh checkpoint.
Generated references were refreshed with the existing tools. Whitespace checks pass
with intentional verbatim Markdown hard breaks retained.

## 2026-10-29 â€” repository editorial cleanup

Baseline f57fc79; main unchanged. Before edits, verified a fresh external source,
history and private settings checkpoint at 10:19 UTC with WoW closed. Retired editor
plans, prompts/templates, original Word plan, old handoffs, ignored local backups
and sync log into that checkpoint. Replaced useful rules/tasks with conventional
contribution and development documentation. Retained all 26 specifications and the
Markdown implementation plan; three terminology edits preserve gameplay requirements.

Rewrote conversational comments in 39 Lua files across bars, binding, window/map,
extra buttons, inventory/restock, layout, menu, minimap, other helpers, Respec and
unit frames. Existing lexer comparison against recovered sources proves identical
non-comment tokens and exact string bytes for every changed Lua file. Data, licenses,
assets, saved roots, manifests and runtime behavior are preserved. Historical capture
numbers remain unchanged; only process descriptions/optional branch metadata changed.

Evidence: validation/comment-cleanup-tokens-2026-10-29.json. No new runtime benchmark
is needed for identical executable code; native acceptance remains at its prior status.

Final checks use `python tests/run_validation.py --output docs/validation/editorial-cleanup-full-2026-10-29.json --sync-docs`, the existing
reference builder and documentation validator. The final source manifest supersedes
intermediate reports made before the last inline comment edit. Libraries/assets/
manifests (318 files) and historical measurement values were byte/value checked;
38 retired original files match the external checkpoint. All six CSV ledgers retain
valid row shapes. Explicit development-tool markers are absent from actual addon
files outside Git; legitimate game labels/item names/local variables are retained.

Editorial validation completed: 85 desktop tests and 726 Lua syntax checks pass;
all current Lua hashes match the final report. Documentation validation passes
with 759 classified sources, 577 reachable files, 361 setting definitions,
23 SavedVariables roots and 12,709 local links. All six CSV ledgers are valid.
The final scope scan covers 1,195 actual files and finds zero development-tool
markers outside Git. Native acceptance retains its prior pending status.

## 2026-10-29 â€” queued merchant purchase identity

Resumed on 07b11ce with a clean working tree, same branch and main 7436820. Read
contribution/status/development/decision records, vendor ownership/performance
records, supplied vendor requirements, production seller/classifier/buyer and tests.
The auction, guild-bank and void-storage callback audits remain deferred.

Before edits, verified a fresh external checkpoint at 10:40:48 UTC: 1,195 source
files, Git history/refs and 403 private settings files while WoW was closed. Verified
all 726 previous Lua hashes before reusing the 85-script full baseline.

BUG-005 reproduction executes production FluxVendorBuy through public restock and
merchant event handlers. After the initial eight purchases, replacing slot 9 and
removing slot 10 causes wrong/empty purchases on the next bag pulse, even after the
index rebuild. Baseline: 660 checks/36 failures. Added one execution-time identity
condition using the existing resolver; no new service or settings change. Invalid
tasks leave the queue before purchase/accounting while valid trailing tasks continue.

Validation:

- `lua tests/vendor_slot_identity.lua --source tests/fixtures/vendor_buy_slot_before.txt --measure`:
  retained baseline records 36 expected failures; measure mode deliberately exits 0.
- `lua tests/vendor_slot_identity.lua`: all 660 checks pass. Four merchant API/identity
  models, manual/tier targets, pulses before/after index rebuild, same-pass changes,
  fresh request recovery, merchant close and stable 40-target queues are covered.
- `lua Inventory/Restock/Junk/_tmp_junksmoke.lua`: existing sale/protection/visual
  regression passes; no seller code changes.
- Five alternating process pairs: all 20 metric cases have zero count variation.
  Each changed tail goes from one wrong + one empty purchase to zero; valid trailing
  purchases remain two. Stable 40-item queues retain five passes/eight-call budget
  and one event frame; each valid purchase adds one ID or link identity read.
- `python tests/run_validation.py --output docs/validation/vendor-slot-full-2026-10-29.json --sync-docs`:
  86 scripts/727 syntax files, zero failures. Native screenshots/input/taint/security,
  resource costs, latency and FPS remain pending; fixture money is simulated.

Runtime/test/fixture committed as cdd752abd060588bc1602e880d997a60dd0b34a9, tree
d18478f458e670f18931c070a00d53a708387fee. Source review confirms only the invalid-task
condition/comment changed; purchase math/UI/defaults/restriction guards are preserved.
Evidence and exact native steps are in VENDOR_PURCHASE_IDENTITY.md. No new native
client run, settings mutation, deployment, push or main change.

Merchant identity documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,733 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 19 API,
eight client, 77 reference and 118 performance rows). All 727 Lua hashes match
the full report. Requirements/libraries/assets/manifests (346 files) match the fresh
checkpoint, and the development-tool marker scan remains clear outside Git.

## 2026-10-29 â€” finite merchant stock budget

Resumed on 0d05acc with a clean working tree, same branch and main 7436820. Read
contribution/development/status/decisions, vendor requirements/ownership/performance
records, production quantity/queue code and existing tests. Read-only local Blizzard
12.1.0.69283 merchant source and existing bulk-buy code confirm separate zero-stock
handling; no reference code/assets were copied. Deferred callback scope is unchanged.

Before edits, verified an external source/history/private-settings checkpoint at
10:54:48 UTC while WoW was closed. All 727 Lua hashes matched the prior 86-script
full report before baseline reuse. Extended the existing merchant harness instead
of creating another fixture framework; retained the pre-edit runtime as a nonloaded
source fixture. Baseline stock replay: 177 checks, 39 failures.

Changed ComputeRestockPurchaseQty to cap zero stock. RunBuyPass now reserves finite
submitted quantities on the existing shared index entry, preventing reuse within
and across passes/duplicate entries. The reservation is not native acknowledgement.
Settings, UI, cadence, unlimited/nil helper semantics and other affordability math
remain. Normal index refresh/new request can buy replenished stock.

Commands/results:

- `lua tests/vendor_slot_identity.lua --stock-only --source tests/fixtures/vendor_stock_before.txt --measure`:
  39 expected baseline failures; measure mode deliberately exits zero.
- `lua tests/vendor_slot_identity.lua --stock-only`: 177 checks pass.
- `lua tests/vendor_slot_identity.lua --identity-only`: original 660 checks pass.
- Default execution: 837 checks pass. Existing junk smoke passes.
- Five alternating fresh-process pairs: all 20 metric cases have zero count range.
  Zero-stock rejection calls 5 to zero; finite stock 3/max stack 2 rejections 4 to zero,
  actual units 2 to 3 and accounted/actual copper 50/10 to 15/15. Across-pass stock
  rejection calls 2 to zero; unlimited 40 purchases/five passes and one event frame
  remain. No extra merchant-info reads. Money values are simulated, not native losses.
- `python tests/run_validation.py --output docs/validation/vendor-stock-full-2026-10-29.json --sync-docs`:
  86 scripts/727 syntax files, zero failures. Native screenshots/input/taint/security,
  CPU/resources/latency/frame times/FPS remain pending; no speedup is claimed.

Runtime/test/fixture committed as b505bb880aeefbab414d957d8d7fbee6820c20a8, tree
cc067974b724c82188d52f24a9800ad485ca261e. Small runtime diff reviewed for ownership,
negative/nil sentinels and shared-entry capacity. Evidence/native steps are in
VENDOR_STOCK_BUDGET.md. No settings mutation, client deployment, push or main change.

Finite-stock documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,750 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 20 API,
eight client, 77 reference and 129 performance rows). All 727 current Lua hashes
match the full report; requirements/libraries/assets/manifests (346 files) match
the checkpoint. The development-tool marker scan remains clear outside Git.

## 2026-10-29 â€” vendor-open junk availability

User reports lag simply opening a vendor on Classic Era and requests all-client
coverage. First/repeated-open behavior and automation settings are unknown. Kept
main and the deferred auction/guild-bank/void-storage callback scope unchanged.
Inspected current contribution/status/decision records and actual merchant/junk/
inventory source before editing. Preserved the clean 9e17e28 baseline at 11:14:06 UTC
in a verified external source/history/private-settings checkpoint with WoW closed.
All prior 727 Lua hashes matched the 86-script full report before baseline reuse.

Production availability calls repeatedly walked unchanged non-junk bags. BUG-007/
PERF-004 adds two scalar values to the existing junk owner, keyed by reliable bag
generation and cleared by existing rule/item/list/slot invalidation. Native-positive
precedence, cold gray fallback, unready retries, UI cadence and automation remain.
No new frames/hooks/timers/subscriptions/settings. The native hitch is not certified
fixed; other open-path work remains unmeasured.

Commands/results:

- `lua tests/vendor_open_work.lua --source tests/fixtures/vendor_open_junk_before.txt --measure`:
  265 checks, seven expected baseline failures; measure mode exits zero.
- `lua tests/vendor_open_work.lua`: all 265 checks pass across Era, Anniversary,
  modern Wrath Classic, Cata, Mists, Retail and Forever fixtures. Real buyer events,
  inventory/junk modules and extracted production UI availability callbacks run;
  rendering/layout/restock data/other integrations are modeled or excluded.
- Five alternating fresh-process pairs, all automation off: each legacy fixture's
  first-open slot reads 300 to 200; 25 unchanged reopens 5,000 to zero. Retail/Forever
  360 to 240 and 6,000 to zero. All counts have zero trial range. Buyer event frame
  remains one, native junk-count queries remain 182 on modern fixtures/zero legacy.
- Existing junk seller smoke passes; merchant stock/identity controls retain 837
  checks. `python tests/run_validation.py --output docs/validation/vendor-open-full-2026-10-29.json --sync-docs`:
  87 scripts/728 syntax files, no failures. Every current Lua hash matches the report.
- Native builds/settings/addon list, screenshots/input/combat/taint/secrets, CPU/
  memory/latency/frame times/FPS remain pending. Process timings include fixture
  startup and do not measure native vendor-open latency.

Runtime/test/nonloaded fixture: `e02139ab1c6b8099b02fb4506ff150a50d6555ef`, tree
`0a23a38a04809c0a087089586cb5842496fb5c64`. Focused evidence and exact native steps:
[VENDOR_OPEN_WORK.md](VENDOR_OPEN_WORK.md). No settings reset, deployment or push.

Vendor-open documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,769 local links. All
six ledgers have valid row shapes (1,384 parity, 35 ownership, 21 API, eight client,
77 reference and 157 performance rows). All 728 Lua hashes match the full report.
The checkpoint comparison finds no missing files and preserves 348 specification/
library/asset/manifest files byte-for-byte. Explicit development-tool markers remain
absent across 1,218 actual files outside Git. Legacy fixture labels share one API
route; Retail/Forever share another, rather than proving seven native contracts.

## 2026-10-29 — Quick Join anchor cycle

User supplied the native QuickJoinToastButton:SetPoint cycle at FluxChatFrame.lua
line 1248; client/build unspecified. Current branch was clean; main remained
7436820453d2248c84c99fff71507553efc47c19. Read current rules/records, chat options/
specification, both layout owners and existing tests. A fresh verified external
checkpoint at 11:47:07 UTC (12:47 Copenhagen) covers all 1,218 files, Git history
and 403 private settings files with WoW closed. All 728 baseline Lua hashes match
the previous full 87-script report.

The column anchors Channels below Quick Join. Its older social callback reverses
that dependency, reproducing the supplied failure. BUG-008 adds a six-line owner
guard when either button belongs to the column; the surrounding normal layout
still reconciles it. Native fallback, defaults/settings, dimensions, click scripts
and 0/0.1/1-second retry deadlines remain. No runtime hooks/timers/frames added.

Extended the existing column test with a cycle-aware parent/anchor graph and
bottom-point geometry, executing actual social and retry callbacks with the column.
Baseline passes the original 1,311 checks, then fails 448 of 508 ownership checks.
Candidate passes all 1,819, including four existing rejected mutations. Other chat
layout/startup/retry controls pass. Five alternating fresh-process pairs across
Live/Forever, both sides: cycle failures per three queued callbacks 3 to zero;
retry callbacks 3 to 3; burst frames zero to zero. Candidate reaches/reuses the
existing combat waiter that baseline exceptions prevent from being queued.

Commands: `lua tests/chat_column_layout.lua --source tests/fixtures/chat_quickjoin_before.txt --measure`,
`lua tests/chat_column_layout.lua`, `lua tests/idle_layout_retries.lua`,
`lua tests/chat_layout.lua`, `lua tests/chat_startup.lua`.
`python tests/run_validation.py --output docs/validation/chat-quickjoin-full-2026-10-29.json --sync-docs`:
87 scripts/728 syntax files pass. Measure mode deliberately exits zero for the
known failing baseline. Native rendering/input/security/CPU/resources/latency/frame
times/FPS remain pending; preventing an exception is not measured native speedup.

Runtime/test/nonloaded fixture: `5198ded001dde5bbc3fc5d6011239652cbe79dac`, tree
`ffeca6fce85ff9606c7dab3f38b065bdbfdfeb70`. [Evidence and native steps](CHAT_QUICKJOIN_ANCHOR.md).
No client sync/deployment, settings reset, main update or push. Vendor-open native
hitch confirmation remains pending; deferred callbacks remain outside this batch.

Chat-anchor documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,788 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 22 API, eight
client, 77 reference and 173 performance rows). All 728 Lua hashes match the full
report. The fresh checkpoint comparison finds no missing files or unexpected
changes and preserves 348 specification/library/asset/manifest files byte-for-byte.
Explicit development-tool markers remain absent across 1,225 actual files outside
Git. Main remains unchanged; native acceptance remains pending.

## 2026-10-29 — repeated vendor tier work

Continued on the clean existing branch; main and deferred callback scope unchanged.
User clarified that the Era spike occurs on every same-vendor reopening. Read-only
Era hashes matched the earlier junk/buyer/chat fixes. Era Config.wtf saves
scriptProfile=1; active runtime state was not observed and no preference was changed.
Fresh verified external checkpoint at 12:04:44 UTC / 13:04 Copenhagen includes all
1,225 files, history and 403 private settings files with WoW closed. Verified all
728 baseline Lua hashes against the prior 87-script suite.

A blanket index skip would suppress consumable reference seeding. Instead, PERF-005
moves live usability after classification in two vendor tier loops, retaining
reference discovery, level/skill checks on matching contenders, thresholds, ties,
Well Fed/food-water rules, retries and UI timing. No new resources or caches.
Classification before level rejection can shift cold work; native cost remains
pending.

`lua tests/vendor_tier_work.lua --baseline --measure`: 340 checks, 12 expected
baseline failures; measure mode exits zero. Candidate passes 340. Actual production
buyer/index/post-index seed and Score/tier modules run with classification/native
facts modeled. Five alternating pairs cover legacy/modern APIs and 20/200 listings.
Large-vendor initial seed info/ownership lookups 1,000 to 10 each; separate status
2,000 to 20 each. After the cadence clarification, added 25 same-vendor reopens with
retained food/water refs and three unoffered families: 15,000 info and ownership
lookups each to zero (small vendor 1,500 each to zero). Classification counts remain;
all count ranges zero, buyer frame one and purchases zero. These are service calls,
not native CPU/cache misses or FPS.

Bag-tier controls pass 16,527 checks; merchant identity/stock 837 and junk availability
265. Final `python tests/run_validation.py --output docs/validation/vendor-tier-full-2026-10-29.json --sync-docs`:
88 scripts/729 syntax files pass. The final full run includes the repeated-open
extension. Native pixels/input/taint/security/CPU/memory/latency/frame times/FPS remain
pending. No sync/deployment/settings reset/push or main update.

Runtime `17628269f0e3b7fbeb1b8c2d7f9c7196829e67f3`, tree `0c681c46987fc5b136274bba59e5e5bb3dd90990`.
Repeated-open test carrier `e7ec46a4070c132ff8bf6033d6bef5e2c92f90aa`, tree
`4507ccd1456e42f9acdea0e2be4aaad073ff72ae`. [Evidence/native procedure](VENDOR_TIER_WORK.md).

Vendor-tier documentation validation passes: 762 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,807 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 23 API, eight
client, 77 reference and 217 performance rows). All 729 current Lua hashes match
the full report. The fresh checkpoint comparison preserves 348 specification/
library/asset/manifest files byte-for-byte, with no missing files or unexpected
changes. Explicit development-tool markers remain absent across 1,234 actual files
outside Git. Main remains unchanged; native repeated-open acceptance is pending.

## 2026-10-29 — native Era vendor tier counts

Continued on the existing clean branch at d3bce5b; main stayed
7436820453d2248c84c99fff71507553efc47c19. Read current contribution rules,
requirements, diagnostics and affected tier sources/tests. Fresh verified external
checkpoint at 12:35:23.862522 UTC covers 1,234 actual files, history and 403 private
WTF files. Both clients were running: on-disk settings only, not a quiescent state.
Verified all 729 baseline Lua hashes against the prior complete report.

User authorized native vendor commands, then requested ordinary PC use with WoW
in the background. Clean foreground Era 1.15.9.70576 capture with four reopenings,
three automations temporarily off and profile=1 reproduces a 333 ms maximum UI
interval. GetRestockTargetItems: four calls / 1,281.123 inclusive ms; GetTierCount:
20 / 707.280 ms; cached-bank getter: 20 / 457.873 ms. 5,250 tooltip calls expose
unrelated live usability checks in those count loops. Earlier interrupted captures
are excluded; this one pilot is attribution, not five full-window matched pairs.

PERF-006 moves tier membership ahead of live usability in the existing two count
functions. Retains matching live gates, caches, quantities, inferior protection,
strict/loose bank semantics, vendor-first deduplication and live fallback. No new
runtime resources/settings; no auction, guild-bank or void callback edits.
Runtime/test/nonloaded fixture commit `013bf40db1d5b57c238ac3ac377e8ced98446fd1`,
tree `4f0d827bb26bba3ee8b20e21de891596fad0e98b`.

`lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure`:
1,710 checks with ten expected baseline performance failures. Candidate passes all
1,710; five alternating fresh-process pairs reduce initial/repeated legacy live
checks 1,350/33,750 to 17/425; modern 1,500/37,500 to 18/450. Bank-store reads remain.
Existing tiers 16,527 checks, vendor tiers 340, stock/identity 837 and junk 265 pass.
Full `python tests/run_validation.py --output docs/validation/tier-count-full-2026-10-29.json --sync-docs`:
89 scripts, 730 syntax files, zero failures.

Native comparison continued without activating Era: original loaded references
versus exact source-derived local candidate count functions, one warm pass, query
cache invalidation and five alternating pairs. Median CPU per five kinds:
bags 132.199 -> 15.237 ms; cached bank 118.897 -> 22.517 ms. Tooltip calls 455 -> 5
and 450 -> 5. Quantities identical in every pair; personal-bank results all zero.
Native positive-bank/warband acceptance remains pending. Net memory deltas include
harness and GC and are not allocation measurements. No native API replaced.

Original three automation flags restored true, profiler preference remains 1;
temporary sampler/namespaces cleared by reload and diagnostic SavedVariable exports
removed. User's existing sync delivered candidate source, verified before reload.
WoW remains in the background; no further focus/input access. Full vendor after
latency, matched pixels/input, unprofiled FPS, cold work, taint/security and other
clients remain pending. [Evidence and exact steps](TIER_COUNT_WORK.md).

Tier-count documentation validation passes: 763 classified sources, 577 reachable,
361 setting definitions, 519 literal defaults, 23 saved roots and 12,824 local links.
Six ledgers have valid shapes: 1,384 parity, 35 ownership, 24 API, eight client,
77 reference, 242 performance. All 730 normalized Lua hashes match the full report;
raw/normalized candidate hashes match committed source and the native probe hash
matches the exported source-derived chunk. Checkpoint comparison preserves 361
specification/library/asset/manifest/XML files byte-for-byte, with no missing or
unexpected changes. Explicit development-tool markers remain absent across 1,244
actual files outside Git. Main unchanged; native after whole-vendor acceptance
remains pending. No additional foreground/game input used during final file work.


## 2026-10-29 — objective tracker first-module scroll gap

User screenshot shows Campaign below an empty gap while fully scrolled up; requested
Retail and Forever coverage. Baseline HEAD e1132d0948906acef72be9e4c28dff60a5736931
was clean. Verified external source/history checkpoint
`tracker-checkpoint-20261029T141542Z` preserves 1,244 actual files and all Git refs.
No settings modified; WoW remained in the background. Existing sync was left alone.

The supplied Retail native XML reserves topModulePadding=38; its OnLoad callback
captures Frame.Update before Flux hooks and directly invokes ContainerMixin.Update.
The previous container after-hook was Forever-only, so Retail restored the blank
header gap and bypassed scroll sync. Both clients now share that after-hook, with
a combat early return. Deferred sync repairs the first module before its unchanged-
height shortcut. Native padding/providers remain untouched. SizeScrollContent also
restores zero after a child-rectangle refresh, removing the positive-offset-only gate.

New tests/objective_tracker_scroll.lua replays the supplied native Retail/Forever
container and frame code, including the callback captured before hooks. Original
source: 11 failures among 40 checks; candidate: all 40 pass. Covers Campaign/Quests,
equal-height section replacement, overwritten anchors, wheel targets, preserved
scroll offsets, shortened lists, zero restoration and Questie ownership. Existing
combat and Questie smoke checks pass. Full validation: 90 scripts, 731 Lua syntax
files, zero failures in validation/objective-tracker-scroll-2026-10-29.json.
These are desktop dispatch/geometry results using reference trees; installed-client
rendering, secure execution and taint remain pending. No native performance claim.

## 2026-10-29 — whole-addon Retail performance and resource audit

Preserved the pre-existing uncommitted tracker correction/test/docs in a verified
external actual-file checkpoint at 14:39:06 UTC (15:39 Copenhagen): 1,246 files,
all Git history, 403 private on-disk WTF files while Retail ran. Verified all 731
baseline Lua hashes against the 90-script tracker report. Main unchanged.

Whole-addon ownership/recurring map covers 577 reachable files and 26 source
folders. Native Retail 12.1.5.70575/interface120105/project1, level81 Mage in
Stormwind, built-in inventory, three loaded addons, original profiler0. Five
20-second background profile1 captures after 30-second warm-up: median addon CPU
30.772 ms/s (30.107-37.046). All ten endpoints retain 14,742 total frames, 1,449
Flux-source frames, 458 visible, 212 registered OnUpdates and one shared subscriber;
eight sampled public cache sizes unchanged. Requested-capture memory grows after
GC; ordinary gameplay leak rate is not inferred. Nameplate/assistant CPU remains
for separate matched timing-preserving work. No foreground/mouse/clipboard control.

BUG-009/PERF-007 replay reproduces repeated readiness/combat frame allocations.
Runtime/test/fixture `6ac4389` reuses owners; five alternating desktop pairs reduce
203 frames to 3 with one hook/101 geometry writes unchanged. 2,050 checks pass,
20 baseline failures. Cleared requests disarm regen. Same timeout and six-pixel
anchor; native loot/combat trigger remains pending.

BUG-010/PERF-008 runtime/test/fixture `3046478` clears completed/cancelled full
capture snapshot and timer references. Five alternating desktop pairs retain
20 -> 0 full snapshots / 10,000 -> 0 frame rows per model; 400 checks after 200
baseline failures. Existing capture 383 checks/12 rejected mutations pass. The
full current actual-file suite passes 92 scripts/733 syntax files, including the
preserved pending tracker test. New runtime commits exclude that separate work.

Source checks find existing mirror-timer installation guards; corrected stale QoL
prose, with no duration runtime change. Binding/macro/spell/visual cache controls
retained; older inspect GUID TTL without eviction remains an unmeasured candidate.
Incomplete long-upload private native comparison was discarded after truncation;
no missing candidate result invented. Follow-up uses direct file-loaded capture
calls. Native foreground FPS/pixels/input/taint, long-session/private-cache churn,
other clients and full interaction acceptance remain pending. Excluded callbacks
untouched. [Detailed evidence](RETAIL_PERFORMANCE_AUDIT.md).

Native direct follow-up completed five actual file-loaded20-second profile1
captures. Post-GC addon memory24,105->24,928 KiB across retained reports versus
24,115->64,565 KiB before; median capture-associated delta186 versus7,860 KiB.
Endpoint gaps90-235sec versus22sec and changed camera/frame totals(14,588 versus
14,742) prevent strict gameplay/CPU/FPS causal acceptance. After CPU21.315 ms/s
median is context, not a claimed speedup. A later failed scripted export was also
discarded. Original profiler0 restored and temporary SavedVariable/namespaces
cleared by normal reload. WoW remains open in the background; no native API replaced.
Public raw samples and commands contain no private settings/account names.

## 2026-10-29 — shared Social offset, reload and all-tab geometry

User supplied cropped alignment reference, requested a slight downward adjustment,
then reported reload/tab-only recovery and Combat Log displacement. Fresh verified
15:32 UTC checkpoint includes1,263 actual files, history and403 on-disk WTF files
while Retail ran. All prior tracker/audit work preserved; main unchanged.

Final shared inset8 UI units uses existing primary tab-height service in column
owner coordinates. Relative height survives a provisional chat rectangle moving
later at login without another tab selection. All holder placement now anchors to
ChatFrame1 instead of selected Combat Log/Global/custom window geometry. Selected
Copy target, buttons/actions/art, settings, native ownership, scales, overflow,
combat waiter and three retry deadlines remain. No new runtime resource/framework.
Commits78fe4e7 and7f13000; exact identities/raw results in CHAT_COLUMN_ALIGNMENT.md.

Expanded actual column/social fixture:1,311 original plus508 ownership plus190 new
checks=2,009 passing; frozen baseline fails100 new assertions. Five alternating
pairs have zero count variation;100 layouts add no frames, same point writes;
shared tab-height reads are explicit correctness overhead. Existing chat layout165,
startup478 and retries5,869 controls pass. Final whole actual-file suite92 scripts/
733 syntax files passes, including the preserved pending tracker test.

Native Retail12.1.5.70575/interface120105/profile0 geometry has Social8 units below
menu/tab top (was33); measured surrounding rectangles unchanged. A private untouched
post-reload image was inspected before chat/tab input. Seven native out-of-combat
General1/Global3/CombatLog2 selections sample identical visible Social left57.600/
top361.059 after2seconds without further chat input; original observed tab restored.
No OS activation/mouse/clipboard/native API replacement. Temporary geometry/tab
exports removed by normal reload; original profile0 retained. Other native clients,
combat/taint and full-screen pixel/FPS acceptance remain pending.

Final combined verification:92 scripts/733 normalized Lua hashes pass. Source
inventory766, reachable577, setting definitions361, literal defaults519, saved
roots23, local links12,868. Ledger shapes valid:1,384 parity/35 ownership/28 API/
eight clients/77 references/308 performance/26 audit-domain rows. Protected361
files remain byte-identical; tracker source/test preserved. Explicit development-
tool markers absent across1,271 actual files outside Git. Main unchanged. Native
temporary data removed; original profile0 retained. Generated records remain with
the user's separate pending tracker work; focused runtime/evidence commits exclude it.

## 2026-10-29 - PERF-009 and original-plan continuation

Reviewed actual branch/main/dirty tree, contribution/status/decision/work records,
supplied original plan and relevant nameplate/action-bar specifications. Confirmed
all26 specification requirement ledgers remain available; added explicit original
stage-gate tracking and restored root continuity files as the user requested.
Verified external actual-file/history/settings recovery before runtime edits.
Preserved the unrelated pending objective-tracker source/test/docs.

Reproduced duplicate countdown discovery and temporary per-aura level tables in
real Core/Countdown replay. Runtime `efca305` reuses the current poll's discovered
region and unrolls the same guarded three level reads; no cross-poll cache or new
resource. Five alternating desktop pairs retain same text/anchor/level/frame counts
while discovery halves and measured transient desktop heap falls.1,160 checks,
100 remove/re-add cycles and5 mutation controls pass. The first full run exposed an
existing source guard tied to the exact two-argument helper spelling; adjusted it
to accept optional arguments while retaining label-before-fade ordering. Full
rerun passes93 scripts/734 syntax files; no unexplained runtime failure remains.

At the user's reminder, executed background Retail12.1.5.70575 real-widget native
checks and full-addon20s before/after windows after30s scheduled warm-up. Frozen
baseline file loaded by normal reload; candidate restored in normal folder and
loaded by normal reload. Source transport changed header comment punctuation only;
exported source executable lines/literals and full ASCII diagnostic probe verified.
Five alternating2,000-update native widget pairs: medians33.371 ->31.712ms; all raw
samples/ranges retained, one candidate slower. Geometry/font/alpha/hide-reuse match;
BugTabs counts0 before, after fixture and after candidate window. Private baseline/
candidate screenshots retained outside Git. Camera/mount/plate density changed,
so full-addon performance/pixel comparison is inconclusive. Legacy CPU is
unavailable with profile0; do not interpret its zero as no addon work.

Native diagnostics/root/globals/temporary frames removed by normal reload; original
profile0 unchanged and WoW stays open in background. No mouse/clipboard/activation,
API replacement, settings reset, new addon/repo, deferred callback audit or main
change. Actual protected aura rendering/security/FPS, long sessions and other
clients remain pending. Updated stage/evidence/client/parity/performance/API records.

## 2026-10-29 - PERF-010, action bars and player auras

Inspected current branch/main/dirty work, root rules/continuity, original action/
unit/minimap requirements, manifests, current paint/watch/API/auras and existing
regressions. Verified fresh external recovery of1,284 actual files/history and404
on-disk settings files with both clients/sync running. Preserved pending tracker
source/test/records. Read the supplied sync script as context; did not execute or
modify it. Actual timeout1s despite60s text remains external measurement load.

PERF-010 `677d85c` shares one activation boolean within existing highlight/Flush
batches. False is explicit, direct callers stay fresh and next-spell helper keeps
its guard. No cache/resource/framework/cadence change. Real-source regression1420
checks covers100 toggles per branch, state/identity, minirow construction, cleanup,
geometry and combat effects. Frozen baseline20 work failures; five alternating
fresh-process pairs have identical operation/resource budgets except activation
5800 ->100 disabled/5900 ->200 enabled. Five mutations rejected. Full94 scripts/
735 syntax files pass. Native aura smoke, player ownership and17454 bar-refresh
checks/19 mutations retain their scope.

Logged in requested Retail/Era characters using observed normal warning dismissal,
Reconnect and Enter World controls; same-account sessions conflict, so tests ran
serially. No OS activation/mouse/foreground keyboard/clipboard, credentials,
restriction bypass or API/script replacement. Retail12.1.5.70575/project1 and
Era1.15.9.70576/project2(SoD) each pass five alternating real57-button inactive-
highlight pairs. Exact received ASCII source/probe strings verify;5800 ->100 calls
per100 passes, medians5.303 ->2.728ms Retail/8.568 ->3.079ms Era. All57 button
shapes and native aura root anchors/scales/visibility match; matched-run errors0.
Root native OnEvent references stable during baseline observations. Separate20s
complete-addon windows after30s warm-up remain inconclusive for overall CPU/FPS.
Native player aura inclusive idle cost is small; no aura rewrite justified.

Verified577 potentially reachable source files equal on Era baseline. Existing
mirror lagged the temporary version; copied only verified Paint.lua between the
known versions and restored candidate in normal source/Era, byte-equal. No second
addon/repo or extra mirror job. Restored Retail profile0/root nil and Era profile1/
pre-existing diagnostic report, deep-equal after reload. Temporary namespaces and
closures cleared; both processes left open, Era in world, Retail warning dismissed.
Updated ownership/client/parity/API/performance/original-plan records. Actual active
combat/secure input, dense/restricted aura and long-session acceptance stays pending.

## 2026-10-29 - complete GitHub publication preparation

User requested uploading the complete current addon, then explicitly authorized
main. Inspected working tree/rules/continuity/remotes and preserved a fresh external
checkpoint including dirty/untracked files/history and404 on-disk settings files.
Checked/fetched GitHub main at7436820; existing development history descends from
it. Audited outgoing files/history for private credentials/account paths/archives;
no findings. No force push, game interaction, settings change or new sync job.

Included the formerly pending tracker source/test/chapter/API row and historical
focused report in73ca9d2. Focused40 checks pass; the prior complete report's735 Lua
hashes match the actual combined source. Rerun the full publication suite, reconcile
generated references and validate docs before pushing both main/development refs.
Private recoveries/settings/captures and ignored helper files remain local. Current
native limitations and remaining optimization gates are not promoted to complete
by this upload. Git ref verification establishes publication outcome.

Publication outcome: atomic push advanced GitHub main from7436820 to421c05a and
created the retained development branch at the same payload. Remote refs read
back exact; local main clean and0 ahead/behind. All735 runtime/test Lua hashes
still match the passing94-script report. This completion receipt adds docs only;
no game interaction or source/settings change during upload.

## 2026-10-29 - main-only current local snapshot

User requested main only, then clarified that the actual local files must all be
uploaded. Found newer uncommitted teleport source/test/docs, preserved them in a
verified external recovery covering1,302 actual files/history and404 on-disk
settings files. Both branch refs equaled b45eb5e; deleted the fully merged branch
locally/remotely. Main retains every published commit.

Inspected the local teleport delta and existing evidence. Its full95-script/
736-Lua report exactly matches current code; focused527 checks pass again. Include
this local fix and all current records, run the fresh local-snapshot suite, refresh
references and publish only main. No older checkout, runtime rewrite, force push,
new branch, private data upload, game input/settings or sync-job change.

## 2026-10-30 - unit power separator and text follow-up

User observed a middle border after target/ToT changes, misplaced text on
resource units, and a missing ToT split border. Retained the existing full-height
health layer. Reapplied separator alpha after partition and border-color paint,
kept restricted-max health text in the upper health area, and removed a Lua
truthiness test of a secret maximum. Expanded the focused desktop model with a
separator repaint and ToT zero/positive/secret transitions. Full validation:
96 scripts, 737 Lua syntax files, zero failures. Native all-client geometry,
secret and combat checks remain pending. No game or settings changes.

Follow-up: user specified that HP text should be vertically centered when
there is no resource, with the prior placement when resource returns, and asked
to repair ToT's HP/resource split. Player/target known-zero transitions now
refresh text anchors, including on `UNIT_MAXPOWER`. ToT's UIParent separator
container follows the raised ToT button level in side-by-side placement and
returns to its original level in stacked placement. Focused power and idle
geometry checks pass; full validation again passes 96 scripts and 737 Lua
syntax files. Native pixels remain pending.
