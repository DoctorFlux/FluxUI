# Client and reference validation — 29 October 2026

This record began as a local installation/source audit. Era now has a native vendor attribution capture and five alternating background getter pairs; full visual/security and whole-vendor after acceptance remain pending. [Native evidence](TIER_COUNT_WORK.md). [CLIENT_MATRIX.csv](CLIENT_MATRIX.csv) records installed executable versions separately from `_FluxUI.toc` interface declarations, reference-source versions, and test status. [REFERENCE_MANIFEST.csv](REFERENCE_MANIFEST.csv) pins inspected metadata/license files; its hashes identify those files, not entire upstream packages.

## Installed roster and evidence limits

The requested Era, Anniversary, MoP, Retail, and Forever executables are accessible. Their Windows PE FileVersion values are respectively `1.15.9.70576`, `2.5.6.70577`, `5.5.4.70631`, `12.1.5.70575`, and `1.60.1.70685`. These values are installation facts, not executed `GetBuildInfo()` results or evidence of successful addon loading. Era runtime GetBuildInfo confirms 1.15.9 / 70576 / interface 11509. Its numeric project ID was not recorded; other runtime build/interface values remain pending.

The supplied spec calls Retail 12.1.0. The installed executable is 12.1.5.70575 and Flux's advertised interface remains 120100. All five named local Blizzard source trees are older than the corresponding installed executable. Do not silently relabel their builds or use them to certify current native callback contracts. They have no `.git` directory; upstream commit IDs are unpinned.

Modern Wrath and retained Cata remain separate rows with no matching installed executable found in the inspected immediate client directories. `_Ascension/Wow.exe` and `Ascension.exe` report `3, 3, 5, 12340`; this is a custom original-3.3.5 installation, not modern Wrath Classic. The supplied original Wrath UI tree has a descriptive README but no pinned build/commit. Current project-constant branches and filtered files do not establish original-3.3.5 support. Keep that row unsupported/unverified pending an explicit adapter and native validation; do not copy the addon to that client as part of this audit.

Other executables observed, outside the primary acceptance roster: `_beta_/WowB.exe` 12.0.1.66220, `_ptr_/WowT.exe` 12.1.7.70493, `_classic_era_ptr_/WowClassicT.exe` 2.5.6.70006, and `TurtleWoW/WoW.exe` 1.12.1.5875. Folder labels alone are insufficient to classify a client. No new deployment was made to any installation.

## Optional providers and local references

Retail's active AddOns root contains no top-level Syndicator, Baganator, Details, or Questie folder. Read-only reference availability is different from enabled-addon state: `__AddonsForRef/Syndicator` is version 267. Current Syndicator 288, Baganator 839, Details `#Details.20261015.15339.172`, and Questie 12.3.1 are present under both Era and Anniversary. AddOns.txt and private character settings were not used to infer an enabled load list. Record the actual loaded list in each native run.

Syndicator 288 source exposes `API.IsReady`, `GetCurrentCharacter`, `GetCharacter`, `GetWarband`, and the `Ready`, `BagCacheUpdate`, `CurrencyCacheUpdate`, and `WarbandCurrencyCacheUpdate` callbacks used by Flux. Its callbacks publish current-character identity and dirty bag maps in the expected source shapes. This verifies inspected API spelling/shapes only. Flux's adapter retains built-in facts while waiting, changes `Inv.source` to `syndicator` on `Ready`, proxies the account store, and avoids duplicate location tooltip lines. Baganator readiness is separate: its deferred bridge waits for `Baganator.API` and installs categories, gear protection, and bank controls.

The currency handoff audit found that four built-in currency event callbacks remain registered after `Store.SetUsesSyndicator(true)`. Before the fix, `PLAYER_MONEY` can still write the shared currency snapshot and the other callbacks schedule unnecessary inventory work. The modernization change addresses this narrowly; the root work log/performance ledger records its regression and before/after results. Native confirmation is still required. This does not claim all built-in provider resources have been retired; other region callbacks, timers and permanent mail hooks need their own lifecycle checks.

The continuation fixes two more deferred ownership paths: mail/auction scans now
cancel on their next callback after handoff, and pending send/return completion
discards builtin attribution before resolving a provider-owned character table.
See [provider lifecycle evidence](PROVIDER_HANDOFF_LIFECYCLE.md). Its desktop checks
do not change native acceptance status. Add queued/partial scans, forced final
inbox scan/retries, known-alt send/return success/failure and late Ready between
capture and completion to native scenarios where naturally reproducible. Preserve
standalone mailbox-open behavior and all existing interaction timing. Auction/guild/
void event ownership still needs separate evidence.

The baseline documentation contained several discrepancies corrected in this batch. `29-integrations.md` and `90-reference-inspirations.md` listed external companions in TOC OptionalDeps, but the actual TOC declares only Blizzard_UnitFrame and Blizzard_CompactRaidFrames. `21-inventory-foundation.md` and `29-integrations.md` described a Syndicator timeout/session fallback; the current adapter performs Ready-driven handoff. `29-integrations.md` described global Baganator item-identity wrappers, while current `BaganatorCompat/Loader.lua` leaves Blizzard item identity APIs intact, as `24-baganator-compat.md` already documented. Related stale architecture/command descriptions in `07-runtime-architecture.md` and `31-commands-and-bindings.md` are reconciled with the loaded source. The preserved baseline and supplied specifications retain the prior wording as evidence; these corrections do not restore obsolete runtime behavior.

Reference copies were inspected read-only. MoveAny, EllesmereUI, the local Bartender4 variant, Scrap, Syndicator, and Baganator contain reserved-rights notices. Clicked includes GPLv3. ButtonForge, Buffet, Restocker, and TrinketMenu did not supply a verified root-level reuse grant in the inspected files; bundled-library licenses do not license their host addons. ThreatClassic2 2.67 declares MIT in its TOC, but it is not assumed to be the requested `classicthreat`. ItemRack and a package named `classicthreat` were not found in the inspected reference/primary addon locations. No new code or assets were copied.

## Desktop checks actually executed

On 29 October 2026, from this checkout:

```powershell
lua tests/late_inventory.lua
lua tests/optional_startup.lua
lua Inventory/_tmp_inventorylag_smoke.lua
```

All exited 0 on Lua 5.4.6. The adapter test passed absent/pending/ready/repeated-readiness cases; optional startup passed BigDebuffs late initialization/idempotency/combat deferral; the inventory harness reported 1,732 checks across mocked Retail, Forever, Mists, Cata, Era, Anniversary and Wrath, for built-in and Syndicator pipelines. These particular harnesses do not load `Inventory/Builtin/Currency.lua` and do not cover the new currency regression. Their unchanged source inputs are in the recovered baseline; the final validation report identifies the candidate corpus and whole-suite result. They do not execute the installed provider addons or certify native WoW behavior.

Historical native captures remain under `docs/validation/`, including Retail and Forever CPU/presentation samples. They describe earlier trees/configurations and do not become before/after evidence for this change. Keep their original timestamps, build values and limitations. No current FPS, frame-time, taint, secret-value or pixel-parity result is claimed.

## Native acceptance procedure

Use one `_FluxUI` identity and the same saved profile for baseline/candidate, sequentially. Keep the recovery archive outside Interface/AddOns. Before any sequential source swap, close WoW, preserve the current working tree and relevant WTF data, and select only the recorded addon revision without resetting user changes. Do not enable a second addon copy. Initial baseline is commit `7436820453d2248c84c99fff71507553efc47c19` plus the recovered actual-file manifest; obtain the candidate identity from `STATUS.md` and the result ledger.

1. For each available primary client, record `/dump GetBuildInfo()` and `/dump WOW_PROJECT_ID`, hardware/driver/OS, loaded addons with versions, character/class/spec, zone/camera, keyboard or gamepad mode, resolution, render/UI scale, graphics settings, fonts, Flux options/profile, and profiling settings. Treat unavailable API outputs as unavailable rather than inventing a value.
2. Capture baseline screenshots at the same UI state: full idle HUD; Flux Window Map/Meter/Options; native and Flux unit-frame modes; bags/bank; currency/gold strip and tooltips. Repeat equivalent candidate screenshots and compare pixels and frame geometry. Keep mouse position, selected target, combat state, buffs, animation phase and scroll positions matched; document masks for unavoidable dynamic regions. Check option defaults/scopes, input edges, hover timing, held modifiers, menus, binds, slash commands and reload persistence.
3. Validate standalone inventory with Syndicator/Baganator disabled through the normal addon UI, then reload. `/fluxinv` should report `source=builtin` and eventual readiness. Observe gold and token changes, bank deposits/withdrawals where supported, item counts and location tooltips. Close/reopen bags and bank and traverse a loading screen. Restore the original addon selection after this scenario.
4. Enable the installed external Syndicator normally and reload with the same profile. `/fluxinv` should eventually report `source=syndicator`, `ready=yes`, and `syndicator=yes` in the store line. With `/fluxstartup on` followed by `/reload`, the startup report can expose the provider-ready milestone. A naturally fast Ready event may not exercise delayed handoff: mark that case unobserved rather than forcing provider globals or manipulating protected game APIs.
5. For the currency fix, after confirmed Syndicator ownership, earn/spend a recorded small amount of money through ordinary gameplay and open/close the bank; exercise a token update where available. Verify Flux gold/currency displays and tooltips follow provider updates once and do not regress to a stale built-in snapshot. In the standalone scenario verify those same native events still update immediately. Duplicate callback counts require a narrowly scoped diagnostic/native trace; visual correctness alone does not measure eliminated work.
6. Add Baganator and repeat bank/restock, gear-set shields and protection, junk/consumable categories, live versus cached-bank checks and profile reload. Repeat late native frame loads and combat entry/exit. Check existing Questie tracker/map ownership and Details meter behavior with their recorded versions; absent dependencies must retain supported standalone behavior. Do not execute destructive junk sales or equipment changes merely to populate a benchmark; use controlled items and reversible operations appropriate to the scenario.
7. Measure startup, steady idle and burst scenarios separately. For CPU captures, use `/console scriptProfile 1`, `/reload`, 30 seconds warm-up, then `/fluxperf capture 30` and `/fluxperf last`. Run at least five matched baseline/candidate pairs, alternating order, preserving each raw capture before the next overwrites the last-result slot. Record `/fluxstartup` separately and disable it with `/fluxstartup off` when done. Repeat unprofiled runs using `/console scriptProfile 0` and `/reload`; restore original profiling preferences afterward. If the client lacks a capture API, record that result explicitly.
8. Preserve raw samples and report variation, resource counts, CPU attribution, available memory deltas and operation latency. The capture's one-second FPS samples and recent profiler averages do not supply a frame-time distribution or reliable tails. Use a separately documented native frame-time trace where available; otherwise those fields remain pending. Never sum overlapping inclusive timings or equate reduced addon CPU with improved FPS.
9. Check Lua errors, blocked actions and taint attribution while exercising secure bindings, vehicle/possess/form transitions and combat-deferred operations. If collecting taint logs, record prior logging state and restore it afterward. Retail/Forever secret-value behavior must be observed through supported display APIs, without replacing globals or hiding illegal calls. Record each client/scenario as passed, failed, inconclusive, unavailable or pending with artifacts.

Reproduction of the read-only installation metadata:

```powershell
Get-Item 'F:\World of Warcraft\_retail_\Wow.exe' | ForEach-Object { $_.VersionInfo.FileVersion }
Get-Content '..\__AddonsForRef\wow-ui-source-live\version.txt'
Get-FileHash '..\__AddonsForRef\wow-ui-source-live\version.txt' -Algorithm SHA256
```

Use the corresponding verified path in the CSV for other clients/references. No native row can move to passed solely because these commands or desktop mocks pass.

## Windows lifecycle continuation — native checks pending

BUG-004/PERF-003 changes only mover discovery/watcher/disable lifecycle. The desktop
suite passes 85 scripts/726 syntax files and its focused production-code replay
passes 220 checks, including 100 toggle cycles. These do not advance any native
client row. Follow [Windows native steps](WINDOW_MOVER_LIFECYCLE.md): disabled reload,
late panel discovery, options/public API disable and re-enable, gesture cancellation,
saved geometry/scopes, protected combat Apply and matched screenshots/input. Capture
matched native startup/idle/burst performance with profiling overhead accounted for.
Auction/guild-bank/void callback audits are currently deferred by user direction.

## Queued merchant identity — native acceptance pending

BUG-005 uses the existing item-ID/link resolver before a queued purchase. The desktop
replay passes 660 checks and the full suite 86 scripts/727 syntax files; no native
client row advances. Follow [merchant identity native checks](VENDOR_PURCHASE_IDENTITY.md):
stable manual/automatic restock, naturally changed/missing listings before/after
index refresh, normal fresh-request recovery, quantities, money, tier/alternate-cost
behavior, close/reopen, input/combat/taint and matched screenshots/performance. No
native API replacement or forced live-data manipulation is part of the procedure.

## Finite merchant stock — native acceptance pending

BUG-006 caps zero availability and reserves finite submitted quantities on shared
merchant index entries. Desktop stock/identity replay passes 837 checks, with the
full 86-script/727-syntax suite passing. No native client row advances. Follow
[stock native checks](VENDOR_STOCK_BUDGET.md) for sold-out/limited/unlimited merchants,
partial funds and alternate costs, cross-pass/shared targets, replenishment/new
requests, real acceptance/error totals, screenshots/input/combat/taint and matched
startup/idle/purchase profiling. Reservations do not certify native acknowledgement.

## Vendor-open hitch — native attribution recorded; after acceptance pending

The user reports a spike on every Era vendor reopening. A clean four-reopen capture
now confirms a 333 ms maximum UI interval on 1.15.9.70576 with automation off and
profiling=1. [PERF-006](TIER_COUNT_WORK.md) records attribution and native getter
comparisons; whole-vendor after acceptance remains pending.
BUG-007/PERF-004 removes a desktop-reproduced redundant junk scan contributor. Seven
API fixtures pass 265 checks and the full suite 87 scripts/728 syntax files. This
advances no native client row. Original Wrath 3.3.5 is not covered by the modern
Wrath fixture. Follow [vendor-open native procedure](VENDOR_OPEN_WORK.md): Era first,
matched first/repeated opens without actions, recorded settings/addons and raw
frame-time evidence, cold data/protection/Useful controls, standalone/external
provider readiness, then each available client. Compare pixels/input/cadence and
profiling overhead. Do not deploy to another installation without authorization.

## Quick Join SetPoint cycle — native recheck pending

The user's stack names the social callback and a Channels frame on FluxCCPChatColumn;
no affected client/build was specified. BUG-008 reproduces and fixes that reversed
anchor dependency in production-backed Live/Forever Quick Join fixtures on both
sides. Existing five-branch column controls remain; the full 87-script/728-syntax
suite passes. No native row advances. Follow [chat native steps](CHAT_QUICKJOIN_ANCHOR.md)
for reload, native alerts, tab/side changes, Social/Channels visibility, Edit Mode,
combat/regen, matched screenshots/geometry, input/taint and profiling. Clients with
only FriendsMicroButton retain their separate path. Original Wrath is unverified.

## Repeated Era vendor spike — prior PERF-005 scope

User confirms every same-vendor reopening spikes. Prior junk/buyer/chat sources
matched the Era install before this batch; no sync was performed. Saved Config.wtf
has scriptProfile=1; runtime state was unobserved in that prior batch. [PERF-005](VENDOR_TIER_WORK.md)
reduces repeated usability work in legacy/modern API fixtures: 340 checks, five
matched pairs and full 88 scripts/729 syntax pass. No native row advances. Prioritize
matched repeated-open profiling on/off runs, retaining the original preference;
record actual build/profile/addons and raw hitch evidence. Check reference discovery,
levels/skills, cold rejected items, thresholds, ties, pixels/input/combat/taint.

## Era native count comparison — partial pass

Actual runtime 1.15.9.70576 / interface 11509, level 60 Mage, built-in inventory,
recorded addon list/hardware/settings. Five alternating background baseline/local
candidate pairs preserve all getter results and reduce measured CPU. [PERF-006
protocol and raw samples](TIER_COUNT_WORK.md). Personal-bank outputs are all zero;
positive bank and warband quantities are desktop-only. User's normal sync delivered
candidate source; original automation flags and profiler=1 restored. WoW stays in
the background without further foreground access.

Only Era's matrix row gains this partial native result. Full repeated-open after,
matched screenshots/input, cold work, unprofiled FPS, security/taint, external
providers and other clients remain pending. Original Wrath remains unverified.

## Retail native idle and resource audit — partial evidence

Retail is now observed running 12.1.5.70575, interface120105, project1, level81 Mage
in Stormwind. Five background profile1 idle captures and ten GC/frame censuses
record actual addons/settings/hardware. Frame/public-cache sizes stay stable while
requested diagnostics retain memory; [audit](RETAIL_PERFORMANCE_AUDIT.md) separates
that observation from a normal HUD leak claim. Source fixes reuse loot waiters and
release full capture snapshots. Original profiler=0 is restored after measurement;
no game activation or public/native API replacement. Complete foreground FPS,
visual/input/taint/secrets, combat/loot, long sessions, external providers and other
clients remain pending. This partial row does not certify all Retail features.

## Shared chat column follow-up

Retail BUG-011 native partial pass: Social gap8 UI units, untouched post-reload screenshot inspected before chat/tab input, and seven General/Global/Combat Log selections with identical visible coordinates. Profiler0 restored; temporary exports removed. [Evidence](CHAT_COLUMN_ALIGNMENT.md). Custom-tab desktop checks do not certify other native clients or combat/taint.

## Countdown native follow-up

PERF-009 Retail 12.1.5.70575 / interface 120105 / project 1: five alternating
real-widget pairs retain identical owned-widget geometry, alpha and hide/reuse,
with zero recorded errors. Median elapsed time per 2,000 updates is 33.371 ->
31.712 ms; one candidate pair is slower. Full-addon scene changes make its separate
before/after capture inconclusive. Profile 0 stays unchanged and diagnostics are
removed by normal reload. [Exact evidence and remaining steps](NAMEPLATE_COUNTDOWN_WORK.md).
Other clients have desktop controls only for this batch; actual plate-aura pixels,
secret values, combat/taint, foreground FPS and long-session acceptance remain pending.
