# Work log

## 2026-10-29 — audit baseline and first provider fix

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

## 2026-10-29 continuation — deferred scans and mail completion

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

## 2026-10-29 continuation — Windows enable/disable (user excludes provider queries)

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

## 2026-10-29 — repository editorial cleanup

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

## 2026-10-29 — queued merchant purchase identity

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
