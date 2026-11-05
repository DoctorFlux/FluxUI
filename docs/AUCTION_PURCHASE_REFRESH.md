# Auction purchase refresh investigation

Follow-up: [metadata fan-out reproduction and fix](AUCTION_METADATA_WORK.md)
removes unnecessary shared callback work; native Buy acceptance remains pending.

The user reports a large spike immediately at Buy across clients, especially
Retail/Forever, with Syndicator enabled. Both providers must work. This request
opens the auction purchase path; guild-bank and void-storage callbacks remain
excluded. This batch removes a reproduced traversal cost. The reported native
Buy spike remains **unresolved pending capture**.

## Findings and change

Both AlreadyKnown variants built `{ScrollTarget:GetChildren()}` on every modern
auction result refresh. ScrollTarget retains released pool rows alongside the
active view. Blizzard TableBuilder clears released rowData, so these rows usually
do not trigger classification; they still cost traversal and a temporary children
table. The replacement uses `ScrollBox:ForEachFrame` with one persistent local
painter. Classification, unknown-item rechecks, pet links, colors, monochrome,
highlight alpha and update timing remain intact. No negative cache, timer, event,
hook, secure action, settings root or dependency was added. The legacy auction UI
keeps its existing fixed-size loop.

The replay labels both providers but does not load external Syndicator. These are
controls for the shared UI path, not proof of native provider integration. Five
client labels load the two real source variants; legacy fallback is also checked.

Read-only Syndicator289 (All Rights Reserved) inspection shows modern purchases
publish mail through MailCacheUpdate. FluxUI coalesces that snapshot. Neither bag
arrival nor owned-listing scanning is established as the cause. PLAYER_MONEY also
refreshes the gold bar, and currency publication can refresh it again. Gold-ledger
rows on disk number only1-5 per client: a large-ledger synthetic benchmark would
not explain this user's spike. These leads remain unmeasured; external addon
code/settings were not changed or copied.

## Evidence and recovery

Baseline commit `24cffd22c3e347d55c1c22a3bae820ba9850e09b`.
[Raw pairs, candidate runtime SHA256 identities and reference hashes](validation/auction-active-row-comparison-2026-11-05.json).
[Full validation](validation/auction-active-rows-2026-11-05.json).
External recovery `Auction-buy-20261105T075700Z`:1,432 actual files, verified Git
bundle and123 available on-disk settings files. Source ZIP SHA256:
`c2cb3fac9930ab479dbbc7f387c191d4a9cfe7496f8c6278ff08afb416b7365a`.
Archives remain outside AddOns. No settings/profiler preferences changed.

Five alternating fresh-process baseline/candidate pairs execute20 result updates
with3 active rows and1,000 released rows per scenario. Across5 client labels and
2 provider labels: baseline200,600 traversal visits versus candidate600, with200
classifications in both. These synthetic pool sizes were not observed in the user
session. Operation counts have zero variation. Baseline20 failures of116 checks;
candidate0. Two mutations (no refresh; wrong monochrome) are rejected. Known,
unknown, recycled, newly-known, disabled and legacy behavior pass. Full suite:
126 scripts/781 Lua syntax files pass. Lua5.4.6 desktop APIs/frames are mocked;
warm-up0, one scenario per process. Wall times include startup/assertions and are
not a native latency benchmark. No CPU/FPS/leak/taint or pixel acceptance follows.

Local Blizzard live, forever, classic_era, classic_anniversary and classic mirrors
provide iterator/pool/TableBuilder ownership evidence. Paths/hashes are recorded
in the comparison. Online branch-pin queries were unavailable; mirrors establish
inspected source only. No reference code/assets or license changes. Fresh executable
metadata: Retail12.1.5.70783, Forever1.60.1.70790, Era1.15.9.70576,
Anniversary2.5.6.70577 and MoP5.5.4.70631. Runtime GetBuildInfo is unobserved this
session; retained Wrath/Cata targets are not newly certified.

## Native checks still needed

No visible WoW process or connected runtime tool was available. Leave the PC and
WoW in the background; do not take foreground/input/clipboard for captures.
Test Retail and Forever first, then Era, Anniversary and MoP. Repeat with builtin
inventory, Syndicator, and Syndicator+Baganator if installed. Preserve/restore
enabled addons and diagnostics. No purchase is needed merely to test highlighting.

1. Save profiler/debug preferences and diagnostic roots. Record GetBuildInfo,
   hardware, graphics, resolution/UI scale, profile, complete addon list and loaded
   auction UI. Match baseline/candidate and record exact source identities.
2. Warm up30s. Use `/fluxperf capture 20` then `/fluxperf last` for idle at the
   same AH, one Buy, and a separate repeated-Buy burst. Record quantities, item
   class, timestamps and delivery state. At least5 alternating matched runs per
   variant; distinguish startup, steady-state and burst work.
3. For listeners: `/fluxinvdebug on`, `/fluxinvdebug quiet`, `/fluxinvdebug reset`,
   repeat the operation, then `/fluxinvdebug report` and `/fluxinvdebug listeners`.
   CPU rankings require scriptProfile; if enabling it, save its prior value,
   reload/warm up and restore it afterwards. These diagnostics do not time every
   AH/gold callback. Preserve previous diagnostic roots rather than discarding them.
4. Compare active/retained pool counts, allocation/memory, frame time and operation
   latency. Compare highlighting enabled/disabled through its existing option.
   Do not sum overlapping inclusive CPU or equate lower addon CPU with higher FPS.
   Isolate money/status refresh and Syndicator mail publication if spikes remain;
   keep results separate for each provider.
5. Match screenshots after search, scroll, Buy, selection and row reuse, including
   known/unknown/pet items. Verify tint/alpha, disabled highlighting, secure actions,
   errors/taint, and inventory/mail/consumable counts after delivery and depletion.
   Restore preferences and addons.

Native results: pending on every client/provider combination. No purchase was
made and no native profiler overhead introduced. The reported spike is not yet
attributed or accepted as fixed.
