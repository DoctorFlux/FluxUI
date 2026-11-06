# Next session

Consumable Well Fed native check pending: on Retail, Forever and other
available clients, test real configured food above/at/below its refresh
threshold in the button and config, then reload and check combat behavior.
Capture food/aura IDs, client build and errors. Desktop fixture passes 35
timer checks and 30 weapon-target checks; these do not prove native parity.
[Case](docs/CONSUMABLE_REFRESH_TIMER.md#well-fed-follow-up--6-november-2026).

Forever glow priority: the latest candidate directly paints action bars and
Extra Buttons on SAO's screen/button callbacks in combat and uses pre-acquired
Retail proc art when available. The user has been asked to `/reload` and test
Missile Barrage combat show and proc clear. If it fails, request the single
in-combat `/run print(FluxEffectGlow.Diagnostics())` line; its counters separate
missing SAO signal, bar match, and modern frame draw. Earlier Classic candidate
failed live after reload. See [full record](docs/FOREVER_SAO_GLOW.md).

Latest signal evidence: `screen=0/0 notify=128 modern=158/0/0 failed=0
classic=0` during visible Missile Barrage. The new candidate samples SAO's
global screen-frame list on UNIT_AURA and next frame, and reveals the retained
Retail glow by alpha/animation without combat Show. If live test fails, get
the new diagnostic line including `aura` and `frame` counters.

The user did retest: still post-combat-only; `aura=7/1 frame=334` but
`modernShow=0`. Await live `/run` read of SAO overlay keys, Want(5143), and
Bars.Effects counters before further code changes.

The read returned `want5143=0` and an empty SAO overlay list. The latest
candidate observes Forever native screen overlay show/hide events (which the
installed SAO addon also registers) and fixes an empty SAO-list override.
Await fresh `/reload` Missile Barrage show/clear and diagnostics including
`native=` event counts/last ID if it still fails.

Native-event retest and private SAO AuraContainer lookup both failed;
`container=0/0/0`. Latest candidate finds the static 400589 filter through
Blizzard's global AuraContainer slot registry and hooks mapped AuraButtons
OOC. Await reload/combat acceptance; if dark, read `container=` hook/show/hide
counts and `modern=` show count.

Forever action bar button glow: the user confirmed SAO's Missile Barrage
screen overlay appears in combat while Flux buttons remain dark. The new
candidate follows SAO's private-table screen show/hide for that missing button association,
accepts unreadable combat icon state for a known spell ID, and retains the
Classic Era LibButtonGlow art and generic SAO/native paths. The user retested
the prior global-hook candidate and saw glow only after combat; SAO's cached
private-table method missed that hook, and standalone EBS lacked a glow-change
subscription. The corrected candidate has focused glow 46 and EBS refresh 8
checks passing. The user retested it and still saw glow only after combat;
the glow then stayed after the proc. The newest candidate adds global low-level
SAO screen show/termination hooks independent of private capture and checks
SAO's live overlay/fade state. Focused glow 48, low-level signal 5 and EBS
refresh 8 checks pass. The user retested that candidate and combat glow was
still absent. Flux now prepares and retains the Classic LBG frame OOC on each
secure button, then plays existing animations in combat; focused glow 53 checks
pass. Combined desktop suite 164 scripts/821 Lua syntax.
After a normal background reload, verify Missile Barrage plus a
second SAO-supported proc on action bars, Extra Buttons and badges in combat;
check show/hide, matching art, paging, secure input, taint and frame time. Keep
WoW in the background and preserve profiler/settings/diagnostic roots. See
[combat record](docs/FOREVER_SAO_GLOW.md#combat-button-glow-correction).

Forever glow follow-up: the user confirmed the earlier renderer-only fix did
not show a glow. The installed SAO Forever Missile Barrage effect omits the
Arcane Missiles button association; Flux now checks aura 400589 for that spell
and its ranks, with changed-state `UNIT_AURA` refresh and secret native guards.
Generic SAO/native support still covers other registered button glows. Focused
41-check fixture and 162-script/819-file desktop suite pass, but native behavior
is unverified. With Forever running in the background, reload once and trigger
Missile Barrage plus another SAO-supported button proc on bar, Extra Button and
badge; check show/hide, art, paging, icon changes, taint and frame time. Then
check Era/Anniversary separately. Keep settings and diagnostic roots intact.
[Evidence](docs/FOREVER_SAO_GLOW.md).

Current meter scope is accepted: preserve every native feature and leave
automatic Current blocked. METER-DEFAULT-CURRENT-01 remains OPEN; freeze its
implementation. Do not add a custom renderer, native/private writer, reset,
automatic setting or manual-setup completion. Reopen only with new user direction
and supported evidence. Keep native controls, sessions/history and current UI.
[Decision and limits](docs/METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap).

Successful user inventory returned all eight documented DamageMeter methods
and only enable/show-UI plus new-instance-reset CVars (`FXCV DONE`). The original
nil-help concatenation diagnostic was corrected and retested successfully; its
12:27:14 RunScript error is separate from native 11:45:22/11:45:26 taint errors.
Do not rerun the broken macro or infer clean native state from the inventory.
No explicit loaded-source fingerprint or clean-error/combat acceptance followed
the reload request. Native cleanup remains pending. The 30-second background
attempt at 11:25:15 UTC was refused before any posted message/typed character.
Keep background guards and preferences; do not take foreground control.

Independent header/Threat, native combat/secret/taint, pixel and performance
checks remain pending at their recorded scopes. No runtime change in this batch;
preserve concurrent glow work and diagnostic roots. Earlier desktop passes are
source-specific evidence, not a native cleanup or automatic-Current success.

Historical meter links: [METER_STANDALONE.md#installed-wow-interface-art-references](docs/METER_STANDALONE.md#installed-wow-interface-art-references), [meter-theme-consistency-2026-11-05.json](docs/validation/meter-theme-consistency-2026-11-05.json), [METER_STANDALONE.md#one-line-names-and-shared-meter-appearance](docs/METER_STANDALONE.md#one-line-names-and-shared-meter-appearance), [native-meter-background-checks-2026-11-05.json](docs/validation/native-meter-background-checks-2026-11-05.json), [METER_STANDALONE.md](docs/METER_STANDALONE.md), [meter-standalone-2026-11-05.json](docs/validation/meter-standalone-2026-11-05.json), [METER_COMBAT_VISIBILITY.md](docs/METER_COMBAT_VISIBILITY.md), [meter-combat-visibility-2026-11-05.json](docs/validation/meter-combat-visibility-2026-11-05.json).

Forever SAO priority: after a normal background reload, trigger real
SpellActivationOverlay 2.8.9 procs on the action bar, Extra Button and badge;
check LibButtonGlow art, hide, SHIFT/CTRL paging, macro/icon changes, taint and
frame time. Then verify Era/Anniversary glow regression separately. Source fix
and focused desktop checks are recorded in [FOREVER_SAO_GLOW](docs/FOREVER_SAO_GLOW.md).
The current combined full suite passes 162/162 scripts and 819/819 Lua syntax
files; the earlier SAO-stage meter assertion failures are resolved.
Preserve current WoW settings, profiler and diagnostic roots.

Raid-frame priority: after a normal reload, reproduce party/raid and Edit Mode
hide/restore with Flux raid frames enabled and disabled. Check BugTabs for the
07:08:57 secret mouse comparison and any new taint, then verify native/Flux
click, hover and wheel hit testing, combat roster changes and group ordering.
The 6 November `Hide.lua` fix is desktop-validated only; initially secret native
switches are left untouched to preserve their unknown policy. See
[the raid input record](docs/49-native-mouse-suppression.md#raid-secret-mouse-follow-up).
Keep WoW background, profiler preferences and diagnostic roots intact.

Wand swing theme native follow-up: [record](docs/SWING_WAND_CAST_THEME.md).
Era, Anniversary and Forever desktop models pass 13,942 focused checks; the
full suite passes, but Fire/Frost wand pixels, cast-slot handoff, combat taint,
localization and frame time are pending on real clients. Verify exact loaded
source/build, keep WoW in the background and preserve existing settings and
profiler preferences. Test each client sequentially because sessions displace
one another. Keep the separate meter and threat work below in scope.

Priority: load and accept the minimap mail lifecycle fix. Read
[the lifecycle record](docs/MINIMAP_MAIL_LIFECYCLE.md) and
[Retail tooltip readiness](docs/AUCTION_COLD_TOOLTIP.md). Baseline `c1a5f90`;
external Mail-auction-publication-20261105T194013Z preserves 1,529 actual files,
122 settings and all-ref history, source SHA256
`a6fb41fd4042442bd9d9c6d5c70320fe9001feadd068312e3b328d0dfb694449`.
Combined validation passes 153 scripts / 808 Lua syntax files with an unchanged
808-file source drift guard.
[Full report](docs/validation/minimap-mail-lifecycle-2026-11-05.json). Reproduce with
`lua tests/minimap_mail_lifecycle.lua` and `lua tests/auction_cold_tooltip.lua`.
Minimap 504 checks, five alternating pairs and five mutants pass; tooltip 48 checks,
five pairs and four mutants pass. Raw comparison reports accompany the full run.

A normal reload after source sync is required: retained WoW frames/listeners
from the old lookup survive disk edits. Leave WoW in the background while the
user uses the PC; no new foreground permission is inferred from old checks.
Read-only checks around 19:45 UTC found both runtime candidates already identical
in all five client folders and Forever PID39984 still running; no reload occurred.
Verify loaded file identity and build before measuring. Separately check mailbox
open/close, item/money loot, second-last/final Open All, Buy-to-mail, cancel,
post and buyer-sale bursts, minimap mail visibility/tooltip and normal/embedded
geometry. Repeat on every installed client with/without external Syndicator and
Baganator where available. Match resolution, scale, profile and game state.
Preserve profile0, settings and BugTabs history. Native freeze/flicker removal,
CPU, memory bytes, frame times, pixels and taint remain pending. The earlier
19:15 Forever reload predates these fixes. External Syndicator's private proposal
is deferred and uninstalled; do not apply it without authorization or discard
known inventory facts. Guild-bank and void callbacks remain excluded.

Provider row-reuse slice: read
[scope and exact identities](docs/PROVIDER_SNAPSHOT_ROW_REUSE.md). Preserve newer
consumable work through `e2c6464`, and external recovery
Mail-auction-publication-20261105T183839Z (1,520 files, 122 settings, all-ref history;
source SHA256 `b3a39827bbd2e50cc271fce7c5930ea80b1174e3215bc42105b380d36523f55f`).
Focused 700 checks, five alternating pairs and five mutants pass; full 151 scripts
/ 806 syntax files pass with the whole-source drift guard unchanged. Reports:
`docs/validation/provider-snapshot-row-reuse-comparison-2026-11-05.json` and
`docs/validation/provider-snapshot-row-reuse-2026-11-05.json`.
Reproduce with `lua tests/provider_snapshot_row_reuse.lua`.

Native acceptance for the new adapter is entirely pending: the approved 19:15
Forever reload and later source Syndicator/profile0/all-three-loaded checks
precede this slice and observed empty caches, not transaction performance.
The logger error confirmed at 19:18:25 came from the wrong diagnostic API probe;
preserve it and do not classify it as a runtime regression. Verify loaded candidate
identity before any later authorized Buy-to-mail, sale/cancel, collection and
10/100/500-operation curves. Keep all real facts; source visits still grow with
full-list validation and temporary maps remain. Do not claim progressive lag is
fully fixed. Keep WoW in the background, settings and profile0 unchanged.
The separate private Syndicator patch is under review outside Git; installed
references remain unmodified. Applying it requires explicit authorization under
the read-only reference rule. Guild-bank/void callbacks remain excluded.

Consumables timer native follow-up: on Retail, Forever, Era, Anniversary,
and supported progression, verify a buff shows `remaining − threshold` on
the main button, wisp lock, and config cell, and the buff timer clears at
the threshold while normal item cooldowns still display. Check a live
threshold change, reload, combat, secret aura, and pixels. Desktop 150/805
passes; see docs/CONSUMABLE_REFRESH_TIMER.md.

Earlier combined Lua source matched all 804 hashes in
`docs/validation/restock-charge-bank-iterator-2026-11-05.json` (149 passes).
Preserve the newer consumable commits through main `2c0e7b8`; they arrived during
this audit. Recovery Mail-auction-publication-20261105T183217Z covers all 1,519
actual files, 122 on-disk settings and full history, including uncommitted work;
source SHA256 `eb8e2855cc54ad55cfa43a670b4b4d1957f0ffa6c3d6c424c8dbef3ba10d3557`.
Original snapshot comparison and 147/802 source report retain their own identities.

Consumables config native follow-up: reopen with a charged item while the
bank is open and closed on Retail and Forever, then on Era, Anniversary, and
supported progression clients. Confirm the nil iterator error is gone,
configured icons remain visible, charge maxima/counts are correct, and weapon
target, secure click, combat, and layout behavior hold. Shared desktop fix
passes 149/804; see docs/RESTOCK_CHARGE_BANK_ITERATOR.md.

Consumables config follow-up: on Retail and Forever, verify configured icons
remain visible after adding an uncached item and reloading, including a
staff-only enchant while a dagger/sword is equipped. Repeat preset switching,
tooltip, secure click, error and layout checks across supported clients. The
shared source desktop fix passes five paired fixtures and full 148/803 suite;
native evidence is pending. See docs/CONSUMABLE_TARGET_DETECTION.md.

Latest steering: each Buy or Cancel makes the next operation slower. Continue
the progressive-cost audit after publishing this validated snapshot batch.
Capture 10/100/500-operation curves for retained pending mail, source reads,
copied rows, frames, callbacks, timers, hooks and error history with each provider.
The current snapshot changes do not establish that this growth has been removed.
Preserve all real mail facts and check collection cleanup rather than truncating.

Fresh native state: approved checks at 19:14–19:20 CET verified Forever70790,
FluxUI/Syndicator/Baganator loaded and source Syndicator; byte-matched files were
reloaded19:15:51 and profiler0/source marker20261105.1 confirmed afterward.
Provider mail/auction caches were empty; no transactions/performance test ran.
Use BugTabs1.4.9's public `BugTabs.sessionErrors`/own saved schema; BugGrabberDB
is nil in this session. An attempted BugGrabber method query generated one probe
error. Do not clear it or mistake it for an addon regression. Foreground checks
are finished; resume background work and preserve all preferences.

Desktop-validated continuation: Buy-to-mail is explicitly in scope. Baseline main
`437fda79136582282dde0f3989f3cb70c4411bad` is published; verified external
Mail-auction-publication-20261105T173546Z preserves 1,503 actual files, 122
on-disk settings files and all-ref history (source SHA256
`4921e61d4bce4f648bd95b428f7a0acea9eb11dfc99b0c66d1d5b32fd9a31f48`).
`Inventory/Builtin/Mail.lua` and `Auctions.lua` now prepare
completed index/count maps within their existing scan budget. Baseline desktop
replays prove an unbudgeted final fingerprint/copy/clear phase, including clearing
a large old attachment map when only two money messages remain. Keep the region
object, publish only complete generations, preserve original equality/cadence and
retain public Index APIs. The consumer audit found no cached inner mail/auction
index maps or public GetSnapshot exposure for these regions; internal map identity
changes are intentional and documented.
Tests `builtin_mail_publication.lua` and `builtin_auction_publication.lua` pass
baseline-rejecting replays. Auction replay is frozen at 5,884 passing checks; baseline fails
144 of 5,436 dynamic checks. Peak metered work 5,216→104, unchanged fingerprint
visits 10,240→0, getter-reentry errors 20→0; publications stay 20. Mail passes
8,194 checks versus baseline 25 failures in 8,203; peak arrival normalization
falls 1,600→46 constructors/update while retaining 1,600 total. Ten alternating
pairs, eight mutants and full 147 scripts / 802 syntax checks pass; all 802
normalized source hashes match. Reports:
`docs/validation/builtin-publication-comparison-2026-11-05.json` and
`docs/validation/builtin-publication-2026-11-05.json`.
Read [flow scope](docs/MAIL_AUCTION_REWORK.md),
[mail preparation](docs/BUILTIN_MAIL_PUBLICATION.md) and
[auction preparation](docs/BUILTIN_AUCTION_PUBLICATION.md). No connected native
test tool is available. Current native candidate identity, freeze removal and all-client
acceptance remain pending; leave WoW background and profiler0 untouched.
Read [external Syndicator finding](docs/EXTERNAL_SYNDICATOR_POSTING.md) separately:
the reference-only cold-post callback error does not explain an unloaded-provider
freeze. Do not patch or suppress external globals/errors.
Money-update cost inspection remains a separate read-only finding for a future
justified slice; no money-path runtime change is included here.

Earlier published runtime is `7a06b85f633d1945b7d6bf615636f486f3d7e627` (tree
`4e31f10131923c3d002faffe8036e631d1537402`), verified on GitHub main.
Publication-record updates are documentation only; the 800-file Lua manifest
still matches. Start with native loaded-source verification as described below.

Earlier lifecycle phase starts from published main
`e860ce6de499a7702b91e8a8d74f115fbc9e0293`. Read
[mail/auction flow scope](docs/MAIL_AUCTION_REWORK.md),
[query ownership](docs/AUCTION_QUERY_OWNERSHIP.md) and
[mail job lifecycle](docs/MAIL_JOB_LIFECYCLE.md). Preserve external checkpoint
Mail-auction-lifecycle-20261105T171132Z (1,496 files, 75 settings, verified history;
source SHA256 `38c16e1f0d1d928ffb6015a89ad10e78f991dc038d0d738f7d3483ace86a0e5e`).
Focused 628 auction / 880 mail checks pass; ten alternating pairs and eight mutants
are in `docs/validation/mail-auction-lifecycle-comparison-2026-11-05.json`.
Full validation passes 145 scripts / 800 Lua syntax files. Reproduce with
`lua tests/auction_query_ownership.lua` and `lua tests/mail_job_lifecycle.lua`;
the final full report is `docs/validation/mail-auction-lifecycle-2026-11-05.json`.

The freeze remains unresolved. Before native acceptance, establish actual loaded
source/client identity: the old PID47424 exited; later background inspection found
Forever PID25172 started at 17:55 CET. No native input, profiling or enable-flag
change was made in this batch. Keep WoW background, profile0 and flags unchanged.
Do not repeat heavy frame captures. Separate mailbox open/close, individual/final
Open All, post, sell, buy, cancel-to-mail and provider handoff; verify configured
cadence, last-mail cancellation and module/profile disable on each available
client/provider combination. Include Buy-to-mail delivery, later mailbox entry
and looting separately from immediate bag delivery. Native performance, taint
and pixels remain pending.
Guild-bank and void-storage callbacks remain excluded; ordinary main publication
is authorized without force push.

Earlier published phase `e860ce6`, based on
`b664bb0b93ac566a34744aec5895e927a7a1ffff`: three runtime fixes are published and
desktop-validated, not yet native-verified. Read [item data](docs/BUILTIN_ITEM_DATA.md),
[summary pruning](docs/INVENTORY_SUMMARY_PRUNING.md) and
[currency iteration](docs/GOLD_CURRENCY_ITERATION.md). Preserve external
Builtin-inventory-20261105T152153Z (1,488 files,75 settings, verified history;
source SHA256 `c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`).
Final full validation passes143 scripts /798 syntax files; five alternating
pairs per scenario and12 mutants are in
`docs/validation/builtin-inventory-comparison-2026-11-05.json`.
Reproduce with `lua tests/item_data_request_coalescing.lua`,
`lua tests/inventory_summary_pruning.lua`, `lua tests/gold_currency_iteration.lua`
and `python tests/run_validation.py --output docs/validation/builtin-inventory-2026-11-05.json --sync-docs`.

Historical source/client identity investigation: the user
reports re-enabled FluxUI and continued whole-game freezes on sold auctions,
cancellation-to-mail, individual items and Open All's second-last/final step.
The only verified active Forever process PID47424 reported17:35 CET legacy/nil
source revision/profile0, then17:37 FluxUI false/Syndicator false and nil globals;
client1.60.1/build70790/interface16001. This contradicts the reported enabled
state; final `Inv.itemDataRevision='20261105.1'` has not been verified in game.
Keep addon flags unchanged until clarified, leave WoW in the background and
preserve profile0/diagnostic roots. The previous foreground was restored. Do not
repeat profiler1 or heavy EnumerateFrames capture. Native checks for all three
fixes and all client/provider combinations remain pending; do not infer a cure
or FPS from desktop counts. Guild-bank/void callbacks remain excluded.

Earlier published phase: the native mail-command guard prevents progression/completion
while C_Mail reports pending, with bounded8s wait and existing cadence retained.
Five matched desktop pairs reproduce360 to0 unsafe requests and40 to0 premature
completions; three mutants rejected. Final full validation:140 scripts /795 Lua
syntax files pass. Earlier139/794 evidence describes the preceding four-fix tree.
The user still reports live sale/mail freezes, including Open All at Processing
Message2 and final mail; no live cure is claimed.
[Guard, source contract and pending native checks](docs/MAIL_NATIVE_COMMAND.md).

Reproduce with `lua tests/mail_native_command.lua`; final full report:
`docs/validation/mail-native-command-2026-11-05.json`. Native source comparison:
`docs/NATIVE_MAIL_AUCTION_REFERENCE.md`. Do not repeat the failed heavy frame
capture; preserve profile0 and prior nil report. Prioritize narrow attribution of
mailbox/auction events and retain crash evidence before any optional profiler.

5 November raid/mail/auction follow-up: read
[current evidence and acceptance steps](docs/RAID_MAIL_AUCTION_FOLLOWUP.md) first.
Baseline `8681672`; preserve the external Raid-mail-followup-20261105T132922Z
checkpoint. Full validation passes 139 scripts / 794 Lua syntax files:
`python tests/run_validation.py --output docs/validation/raid-mail-auction-followup-2026-11-05.json --sync-docs`.
Focused reproduction commands: `lua tests/raid_header_precreation.lua`,
`lua tests/mail_loot_scheduling.lua`, `lua tests/mail_copy_availability.lua` and
`lua tests/auction_refresh_batching.lua`. Five alternating pairs and eight
rejected mutants are in the linked comparison report. Progressive auction
refresh batching is linear in the modeled burst; a single formatted sale was
already linear, so its live spike/error chain remains unresolved. UNKNOWN header
attribution and native pet-driver capability remain pending. Forever is running;
the earlier no-client inference came from sandbox-limited process visibility.
The user reports Syndicator is not loaded in the current failing setup. Installed
Syndicator 289 is reference material; investigate the built-in provider and fresh
error history independently. Reporter-only warnings occurred at 14:53:50,
15:03:09 and 15:27:44; the initiating error remains unknown.
Approved native reload completed15:32:54CET. Read-only commands confirmed
Forever1.60.1/build70790/interface16001, FluxUI loaded, Syndicator unloaded;
at15:35:48 raid setup ready, scriptProfile0, session23 with11 historical /0 current
errors. The user confirmed the same freeze after reload; it is not resolved.
The old error history was saved privately; reporter counter50 still lacks an
initiating fault. Initial focus checks safely refused input, but a later split
chat attempt activated shortcuts; use atomic verified chat input only during an
authorized brief exception. A subsequent optional60s CPU capture started15:42:20
after scriptProfile1/reload15:41:45. User-reported crash during many auction-mail
opens ended PID38964; replacement PID33872 started15:48:36. No new crash report
was found and capture data was lost before save: no benchmark. Restored0/reload
15:50:55; FLUXCLEANUP0 true false verified15:51:34, original capture root nil
preserved by literal-only comparison. Prior foreground was restored. No profiling
cleanup remains; the exception is complete and background-only operation resumes.
Do not repeat the heavy capture. Read
[native mail/auction comparison](docs/NATIVE_MAIL_AUCTION_REFERENCE.md), finish
the smallest native command-pending guard and its regression (currently pending),
then consider narrower diagnostics avoiding full EnumerateFrames. Keep the new
external native-command-baseline checkpoint from14:53:38UTC (1,484 source files,
verified settings ZIP);139/794 remains the preceding completed batch's result.
Reproduce mailbox open/close, text/invoice/loot and auction refresh/sales separately
on available clients and provider/bag combinations; do not infer FPS, taint or
pixel parity from desktop counts. Guild-bank/void callbacks remain excluded.

5 November meter/header error fix: read
[exact failures, source pins and pending native steps](docs/METER_RAID_NATIVE_OWNERSHIP.md).
`lua tests/native_meter_ownership.lua` passes 180 checks;
`lua tests/raid_header_precreation.lua` passes 150. Full desktop validation passes
136 scripts / 791 syntax files. Comparison/raw samples:
`docs/validation/meter-raid-ownership-comparison-2026-11-05.json`.
Native reload is required to discard old in-memory meter method replacements.
Verify Forever first (source line535 matches log), then Retail meter tab/resize/
selection/row colors/timer/gamepad and each client's secure party/raid/MTMA roster
growth, disable and combat recovery. The two UNKNOWN blocks have no identified
header or taint writer; do not claim the capacity fix proves their cause. Prebuilt
raid children rise to the intended bounded 80 in the raid fixture (startup/native
memory cost unmeasured). Preserve newer consumable work and keep WoW background;
no renewed capture request or foreground control. Guild-bank/void remain excluded.

5 November consumable target work: read
[contract/evidence](docs/CONSUMABLE_TARGET_DETECTION.md) before changing the
noncombat consumables button. `lua tests/consumable_weapon_targets.lua` passes
30 checks and the full desktop runner passes 134 scripts/789 syntax files.
Native Retail/Forever/Classic staff-only item, general oil, flask/elixir/food,
equipment-swap, combat, locale, secure-click, pixel, taint and matched frame
time checks are pending. Keep the existing external bundle/settings checkpoint
and prior hidden-inventory checkpoint; leave WoW in the background.

5 November hidden inventory changes validated for publication on main; see
[reproduction, source identities and native checklist](docs/HIDDEN_INVENTORY_WORK.md).
Run `lua tests/visible_baganator_work.lua` (260 checks) and
`lua tests/visible_native_bag_work.lua` (65 checks). Full validation:
`python tests/run_validation.py --output docs/validation/hidden-inventory-work-2026-11-05.json --sync-docs`;
final 133 scripts / 788 syntax pass. Native checks are pending, not failed or
certified. When captures become possible, prioritize Forever mailbox open/close,
receive/open-message and buy/sell with Baganator 840 + Syndicator 289, then each
available client/provider combination and reveal/skin/protection parity. The user
cannot capture now; leave WoW in the background and preserve preferences. The
skin registry still scans linearly; do not infer live hitch removal from the
400,800-to-800 synthetic callback reduction. Guild-bank/void callbacks stay out
of scope. Continue independent justified work if native access remains absent.

5 November Syndicator mail/auction snapshots: unchanged mail now compares
normalized records without sorted fingerprint strings; unchanged auction callbacks
retain records/count maps and skip FluxUI publication. Link-only mail metadata now
updates correctly. Five matched desktop pairs:500 sorts/500,000 string keys,
500,000 auction row replacements,500 maps and500 pulses become zero for the
synthetic unchanged burst.80 checks pass, three mutants rejected; full131 scripts/
786 syntax pass. Real changed lists still publish at the original cadence; native
Forever Baganator+Syndicator lag attribution/improvement remains pending.
[Evidence and next checks](docs/MAIL_AUCTION_GUARDS.md#snapshot-change-checks).

5 November mail/auction safeguard: user reports Forever lag with Baganator840
and Syndicator289 on mailbox open/close, auction buying and sales; cannot run
native captures and requested safeguards. Resolved owned item-data completions
now notify consumers once, preserving explicit refreshes, incomplete metadata and
parser retries. Five desktop pairs: stable duplicate burst4,000 junk callbacks,
8,000 selector invalidations and2,000 Baganator timer creates/cancels become zero.
140 checks pass, three mutants rejected; full130 scripts/785 syntax pass.
Actual lag attribution/native improvement remains unverified.
[Evidence and remaining checks](docs/MAIL_AUCTION_GUARDS.md).

5 November clarification: Forever retains Blizzard's ProfessionMicroButton.
Only FluxUI's custom trade-skill buttons, flyout and related options are disabled.
Removed the native-button exclusion/parking added in the preceding batch; the
normal discovery/configuration path restores it without a settings reset.
Adventure Guide remains hidden. Five matched desktop pairs: baseline2 failures
versus0 of54 checks; custom service startup frames remain unchanged (zero per
Forever model). Full129 scripts/784 syntax pass; native bar click/pixel/taint
acceptance remains pending after reload. [Evidence](docs/17-micromenu.md#forever-native-profession-button-restored---5-november-2026).

5 November Forever trade-skill micro removal: the module now exits before
creating buttons/flyout frames or registering scans/events on Forever. The native
ProfessionMicroButton is excluded and parked through the existing micro menu
policy; trade-skill option controls are omitted only there. Saved profession
preferences remain stored; other clients and native profession access stay.
Focused48 checks pass (baseline10 failures); five matched pairs remove4 startup
frames per Forever model, with no startup event/timer work. Full129 scripts/784
Lua syntax pass. Native menu/config/pixel/taint confirmation pending after reload.
[Evidence](docs/17-micromenu.md#forever-trade-skill-micro-removal---5-november-2026).

5 November Forever native bank and micro menu: at the user's request, Forever's
Blizzard bank is excluded from window movement, bank-frame latch scripts, bank
junk/item decoration and native restock-button attachment. Bank tracking remains
on existing BANKFRAME/PIM events; carried-bag and optional Baganator features stay.
The supplied PurchaseBankTab stack confirms a protected native first-tab path,
not the original taint writer. Guide button EJMicroButton is excluded only from
Forever's micro menu via the existing eligibility/parking paths. Focused checks:
168 native-bank and34 guide checks pass; baseline36/8 failures. Full129 scripts/
784 Lua syntax pass. Native bank opening/purchase/taint and guide pixels pending.
[Bank evidence](docs/FOREVER_NATIVE_BANK.md); [micro menu](docs/17-micromenu.md).

5 November Forever reputation click fix: the user confirmed the native
ToggleCharacter("ReputationFrame") call opens Reputation out of combat after
WoW's custom-script prompt. Both bars now call that API directly; the wrong
CharacterMicroButton overlays and Forever early return were removed for these
bars only. Combat guard, other client behavior, tooltips and other proxies remain.
Five desktop pairs: baseline18 failures versus0 of180 checks; full128 scripts/783
syntax pass. Final native bar clicks/taint/gamepad checks remain pending; no
/run macro or confirmation popup is introduced by the addon.
[Evidence and native checks](docs/FOREVER_REPUTATION_CLICK.md).

5 November auction opening regression: the user's Retail stack showed Update
running before the ScrollBox view exists. Both modern highlighting variants now
check GetView before iterating; later initialized updates still paint normally.
The real delegate contract reproduces20 baseline failures versus0 of156 candidate
checks across five client/two provider labels. Five matched pairs retain600 active
visits/200 classifications; no new timers/events. Full127/782 passes; native
reopening and the original Buy spike remain pending.
[Reproduction and evidence](docs/AUCTION_PURCHASE_REFRESH.md#view-initialization-regression).

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](docs/AUCTION_METADATA_WORK.md).

5 November auction Buy investigation: active-row highlighting now uses the
ScrollBox view rather than enumerating its retained child pool. Five matched
production-module desktop replays: 200,600 versus 600 traversal visits, with
200 item classifications unchanged; 116 checks pass, two mutations rejected.
Full126 scripts/781 Lua syntax pass. Both provider labels exercise the shared
UI path; native provider integration and the reported Buy spike remain pending.
No game process or connected runtime tool was available; no foreground input.
[Evidence and exact next captures](docs/AUCTION_PURCHASE_REFRESH.md).

5 November utility pet faces: the user clarified a question-mark/wrong-icon
symptom. The manager now owns the selected journal-pet icon and tooltip via
existing override surfaces, with modifier changes, metadata completion and
cleanup. Summon macros/GUID storage remain intact. 920 checks pass (old40
failures), three mutants rejected; full125/780 passes. Native checks pending.
[Evidence and native steps](docs/UTILITY_PET_FACES.md).

5 November live-zero follow-up: exhausted food/water/potion/bandage buttons
now reset from reliable live bags before Syndicator's delayed cache callback.
The painter retains the verified count; loading holds and combat deferral
remain. Button-level375 checks pass (baseline200 failures), three mutations
rejected; full124 scripts/779 Lua syntax pass. Native acceptance pending.
[Evidence and native steps](docs/SYNDICATOR_CONSUMABLE_UPDATES.md).

5 November Syndicator consumables: batched bag callbacks now retain every
added/removed item and dirty bag until publication. This fixes a reproduced
missed selector update for better items and last-use depletion across food,
water, potions and bandages. Five desktop pairs: baseline 200 failures versus
candidate 0 per400 checks; three mutations rejected. Full suite123/778 passes.
Native gameplay, pixels, taint and performance remain pending.
[Evidence and exact native checks](docs/SYNDICATOR_CONSUMABLE_UPDATES.md).

4 November publication batch: all current local mail work included for main.
All 777 Lua files match the passing 122-test combined report. Native checks
and unfinished mail parity remain pending as recorded below.

4 November built-in mail: the user requires 1:1 Postal v4.3.4 controls and
settings. Read the [integration matrix](docs/MAIL_INTEGRATION.md). The current
controls match the inspected sizes/anchors, with separate fast opening and
bag reserve menus, but attachment forwarding, Express repeat send and advanced
BlackBook completion still need implementation. Native-check the menus,
buttons, recent-send persistence, selected take/return, C.O.D./full-bag guards,
category and Alt-left attachment, copy/invoices, subject, trade CVar restoration
and mailbox gain on Retail, Forever, Era, Anniversary and MoP. Leave clients
in the background and test sequentially. Preserve the All Rights Reserved
source boundary. Desktop suite: 122 scripts/777 Lua syntax pass; native pixels,
input, taint and matched performance pending.
The latest correction split main/Open All dropdown frames and fixed sparse
attachments/delayed item metadata; test these exact flows in each client.

4 November Classic combined bank: verify Era and Anniversary native banker
interaction, ten-column layout, six/seven bank bag slots, cursor drag/drop,
purchase confirmation/cost, item clicks, Baganator early/late ownership and
the bank restock button's click/drag/auto toggle. Desktop lifecycle models pass; native screenshots,
taint and matched performance are pending. Keep WoW in the background and
test named characters sequentially. [Evidence](docs/CLASSIC_COMBINED_BANK.md).

1 November 2026 GitHub publication: added a root README with a compact feature
overview covering the current inventory, links to all detailed feature controls,
client-specific availability, companion integrations, installation and command
entry points. The complete local payload includes the pending chat durability
loading-screen correction. Fresh combined desktop validation passes 113 scripts
and 758 Lua syntax files; native pending checks retain their recorded scope.

1 November trinket tint: on every client compare an equipped passive trinket
with a ready on-use trinket; then check unusable use spell, cooldown, dead/
revived state, tooltip, slot 13/14 clicks and bag flyout. Native pixels,
taint and frame time remain pending after 10 focused desktop checks.
[Evidence](docs/TRINKET_EQUIPPED_USABILITY.md).

31 October equipped trinket tint: sequentially verify ready equipped on-use
and passive trinkets, cooldown, dead/revive and bag flyout on all supported
clients. Check `/use 13|14`, keys, swap queue, gem/stone tint, pixels, taint
and matched frame time. Focused trinket and combat-grid desktop fixtures pass;
native acceptance remains pending.
[Evidence](docs/TRINKET_EQUIPPED_USABILITY.md).

31 October chat durability teleport follow-up: after reload, teleport through
a loading screen and confirm the character-button percentage remains visible
or returns when player equipment loads. Repeat with damaged/full gear, gear
swap and no readable durability; check clicks, text pixels, combat taint and
matched frame time on each client. Desktop timing/event fixture and full
112-test/757-Lua suite pass; native acceptance is pending.
[Evidence](docs/CHAT_CHARACTER_DURABILITY.md).

31 October secret-channel fallback: on Retail and Forever, test target/focus
and Blizzard nameplate casts in combat. Readable magic should keep school
colors; secret, item, physical and unidentified casts should keep default
appearance. Include channels, plate reuse, text/shield, combat taint, pixels
and matched frame time. Desktop 56-check nameplate regression passes;
native acceptance is pending. [Evidence](docs/SECRET_CHANNEL_FALLBACK.md).

31 October nameplate backdrop: sequentially check single/hybrid school casts
on Retail, Forever, Era and Anniversary at several plate sizes and during
target switching/reuse. Confirm artwork stays behind cast text, shield,
health text and selection chrome while fill/tip/halo/particles remain visible.
Check secret fallback, combat taint, pixels and matched frame time. Desktop
112-test/757-Lua suite passes; native acceptance remains pending.
[Evidence](docs/NAMEPLATE_BACKDROP_LAYER.md).

31 October chat character durability: sequentially check the native chat
button on each supported client with fully repaired, damaged and no readable
durability gear. Confirm `100%` is visible, lower values/color update on
inventory events, empty data hides text, and button clicks, pixels, combat
taint and frame time remain correct. Desktop 112 tests/757 syntax files pass;
native acceptance is pending. [Evidence](docs/CHAT_CHARACTER_DURABILITY.md).

31 October combat grid usability: sequentially check mana gem and healthstone
beside potion/bandage on every supported client while alive, dead/ghost and
revived; also at full health/mana, on cooldown, at zero/replenished charges and
during a zone-load bag hold. Confirm visual tint, counts, secure clicks,
hotkeys, combat taint and matched frame time. Desktop 111-test/756-Lua suite
passes; native acceptance is pending.
[Evidence](docs/COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast fill/tip correction: sequentially verify actual target,
focus and Blizzard nameplate casts on every supported client. Check visible
school fill and matching moving-tip Spark for single/hybrid schools; finish,
interrupt, option toggle, plate reuse, Retail/Forever secret fallback and
combat `SetUnit` taint. Desktop 110-test/755-Lua suite passes; native pixels
and matched performance remain pending.
[Evidence](docs/CAST_SCHOOL_FILL_TIP_FIX.md).

31 October nameplate school themes: sequentially validate Retail, Forever,
Era and Anniversary native Blizzard cast bars in combat. Check target/focus
and nameplate school color/effect parity, finish/interrupt/reuse/toggle,
secret fallback, text/shield/important-cast visibility, `SetUnit` taint and
matched frame time. Desktop 110 tests/755 syntax files pass; native evidence
is pending. [Evidence](docs/NAMEPLATE_CASTBAR_SCHOOLS.md).

Latest publication batch (30 October): all local stance-scale, loot-source and
Micro Menu fixes included for main. All 753 Lua hashes match the passing
109-test combined report. Native acceptance remains pending.

MicroMenu nil-center correction (30 October): on the client that produced
the user's stack and then each supported client, reload with the Flux LFG
button enabled, open/close Edit Mode, change Micro Menu placement and verify
native buttons retain their order/visibility without a `GetEdgeButton`
error. Check combat deferral, pixels, taint and frame time. The user's stack
is pre-fix evidence; desktop 109-test/753-syntax suite passes, native
post-fix checks pending. [Evidence](docs/17-micromenu.md).

Delayed loot correction (30 October): sequentially on each supported client,
loot two mobs/chests at distinct cursor locations, move the cursor and delay
chat through LOOT_CLOSED/next source. Confirm each item remains at its own
source position and late slot/chat does not duplicate. Check fast pickup with
FasterLoot enabled and disabled, currency and money, UI scale, taint, pixels
and frame time. Ambiguous uncaptured/linkless sources require native review.
Desktop 108-script/752-syntax suite passes; native checks pending.
[Evidence](docs/LOOT_CURSOR.md).

Cursor-position correction (30 October): in each supported client, loot a
multi-item mob/chest, move the cursor before all chat/slot alerts arrive,
then loot another source while the first rows remain visible. Verify each
batch stays at its opening cursor position, delayed currency follows it,
and UI scale/clamping remain correct. Check native pixels, taint and frame
time. Desktop 108-script/752-syntax suite passes; native checks pending.
[Evidence](docs/LOOT_CURSOR.md).


Loot-source correction (30 October): on each supported client, create an
item, receive a quest/pushed item, loot a mob/chest, win a group or bonus
roll, and gain currency both through loot and a quest. Confirm only loot
appears at cursor, including chat after LOOT_CLOSED; check the one-second
currency grace, duplicates, taint and frame time. Desktop 108-script/
752-syntax suite passes; native checks remain pending.
[Evidence](docs/LOOT_CURSOR.md).


30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).
[Evidence and native steps](docs/UNIT_FRAME_SCALE.md).

Current publication batch (30 October): all local cursor loot, fast pickup,
options, coin art and callback updates are included for main. Native checks
retain their pending scope in the loot chapter.

FluxLoot callback correction (30 October): verify a real login/reload emits
no `RegisterCallback` event-name error, then change, copy and reset a profile
and confirm loot events follow the selected profile. Repeat on each supported
client when available in the background; preserve settings and profiler
preferences. The user's stack proves the old failure, while desktop fixture
and full suite pass after correction. [Evidence](docs/LOOT_CURSOR.md).


Cursor money alert follow-up (30 October): verify real received amounts on
all five supported clients: copper-only, exactly 1 silver, mixed silver and
copper, exactly 1 gold, and mixed gold/silver/copper. Check white numbers,
coin symbols, threshold-selected leading icon, localized chat variants,
3-second expiry, pixels, taint and frame time. Desktop checks pass; native
acceptance remains pending. [Evidence](docs/LOOT_CURSOR.md).


Cursor loot default follow-up (30 October): verify new profiles on each of the
five supported clients start with fast pickup and cursor alerts on and
**Disappear after (seconds)** at 3. Check that existing saved choices persist
and the installed FasterLoot still owns pickup while enabled. Native checks
remain pending. [Evidence](docs/LOOT_CURSOR.md).


Cursor loot (30 October 2026): verify Tools → Loot on Era, Anniversary,
MoP Classic, Retail Midnight and Forever, sequentially in the background.
Check loot speed with FasterLoot both enabled and disabled, cursor placement,
localized self-loot/money/currency, repeated identical items, group rolls,
rarity, toggles, reload persistence, combat/taint, pixels and frame time.
Desktop event fixture and 107-script/751-Lua suite pass; these do not certify
native acceptance. [Evidence](docs/LOOT_CURSOR.md).


Latest publication batch (30 October 2026): current first-load settings and
Hearthstone fixes included for main. Combined desktop validation: 106 scripts,
748 Lua syntax files, zero failures. Native acceptance remains pending.

Historical Sticky Targeting follow-up (30 October 2026): verify the new
single-setting native Controls route on Pandasans Retail when its process is
available in the background. Check `deselectOnClick=1`, unchecked Settings
checkbox, first-load completion, reload persistence, manual Controls reset,
taint and frame time. The linked GitHub main source itself matches the old
local route; the 13 August local pre-rewrite snapshot supplied the distinct
native setting call. Focused desktop fixture passes 76 checks.
[Evidence](docs/RETAIL_CONTROLS_CAMERA_FIX.md).

Retail Controls follow-up (30 October 2026): check Pandasans in the real
Retail client when available in the background. Verify Sticky Targeting is
unchecked (`deselectOnClick=1`), camera factor reaches the accepted 2.6
fallback, the prior failed audit retries once without keybinding work, and
the next reload stays quiet. Check manual Controls reset, taint and frame
time. Mariosuper Era and other client checks remain pending. The user's
pre-fix Retail values were `1.900000 / nil / 0`; desktop fixture passes 68
checks. [Evidence](docs/RETAIL_CONTROLS_CAMERA_FIX.md).

First-load settings follow-up (30 October 2026): native first-account and
new-character checks are pending. Verify Controls (auto loot, sticky target,
interact, camera), nameplate size 2 and character scope, raid appearance,
quiet single completion, later reload preservation, and manual Reset All /
Reset These Settings. Check Mariosuper Era and Pandasans Retail in the
background when available, plus Anniversary, Mists and Forever. Record
protected-frame taint and frame-time evidence without changing profiler
preferences. Desktop suite: 106 scripts/748 Lua; first-load fixture: 60
checks. [Evidence](docs/NONBINDING_FIRST_LOAD.md).

Hearthstone selector hover follow-up (30 October 2026): the user's native
error at line 491 was a direct `GetItemInfo` call with that global absent.
The selector now uses `Flux.Item.GetInfo` and Toy Box name fallback. Focused
19-check regression and full 106-script/748-Lua desktop suite pass. Verify
hover, owned-toy choice, actual button use and reload persistence in the
native Toy Box client; combat/taint, pixels and frame time remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Hearthstone Toy Box panel follow-up (30 October 2026): the earlier candidate
still showed no panel because `FluxSmartHearthConfig.lua` loads before
`FLUX_API` is initialized. Its guard now reads already-loaded `Flux.Cap`.
The corrected 17-check TOC-order regression and 106-script/748-Lua full
desktop suite pass. Native Toy Box visibility, owned-toy selection, secure
button use and reload persistence remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Earlier Hearthstone Toy Box config attempt (30 October 2026): the Toy Box
capability and journal opener were corrected, but the 14-check fixture missed
the TOC load-order failure. Verify `/fluxhearth config`,
owned-toy selection, button use and account/character persistence after reload
on a real Toy Box client; combat/taint, pixels and frame time remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Atomic binding follow-up (30 October 2026): first-account keys now clear,
assign, verify, save and load in one call, with Blizzard action contexts on
modern clients and three immediate attempts only for wrong keys. Focused 507
checks and 105-script/747-Lua desktop validation pass. The user's Mariosuper
Era and Pandasans Retail clients were not visible in this workspace process
or window view, so native first-login/reload keys, labels, no replay, taint and
frame time remain pending. [Evidence](docs/BINDING_ATOMIC_CONTEXT.md).

Binding persistence rewrite (30 October 2026): first-load Retail account
cache was 29 bytes with no bindings although marker 5 claimed completion.
Source now avoids SaveBindings during PLAYER_LOGIN, selects account bindings
at first world entry, applies and verifies the template, SaveBindings(1),
LoadBindings(1), verifies again, then checks disk persistence on the next
login before recording version 6. Old version-5 empty
cache gets one migration repair. Focused 501 checks and 105-script/747-Lua
desktop suite pass. Native first-load/reload persistence, bridge key presses,
labels, taint and frame time remain pending.
[Evidence](docs/BINDING_PERSISTENCE_REWRITE.md).

Binding repeat follow-up (30 October 2026): the user confirmed the exact
"Applying keybindings..." line repeated after reload on existing clients.
Version 5 now claims a truly new account's first pass before its first native
write. Old pending markers and four already bound Flux bridge commands skip
repeat setup; overlapping requests cannot queue a second clear. The new
account still starts on the first world-entry frame. Focused 544 checks and
105-script/747-Lua desktop validation pass. Native reload/no-replay, bridge
key presses, hotkey labels, persistence and frame time remain pending.
[Evidence](docs/ACCOUNT_BINDINGS_ONCE.md).

Account-only binding correction (30 October 2026): user requires exactly one
automatic full template application on the first load of the whole account.
The previous per-character marker caused repeats; Settings reset callbacks
also had keyboard replay paths. Now only a pending first-account bootstrap
starts a full pass, and completion is account-wide. Existing accounts and
successful old character markers migrate without reset. Focused 528 checks
and full 105-script/747-Lua desktop validation pass. Native first-account
key presses, later character/no-replay, persistence and frame time pending.
[Evidence](docs/ACCOUNT_BINDINGS_ONCE.md).

One-time binding correction (30 October 2026): user requires exactly one
successful full setup per active binding set and no repeated login reset.
Version 4 now marks completion after the verified save, accepts preceding
pending version-4 markers, and removes `UPDATE_BINDINGS` replay. The setup
uses one registry scan and a maximum of eight binding writes per frame, with
clear/apply/save phases separated. Focused 521-check desktop test passes;
native first-load keys, reload persistence and frame time remain pending.
[Evidence](docs/FULL_BINDING_RESET.md).

Full binding reset follow-up (30 October 2026): user explicitly requested
clearing the active native binding set before applying the complete Flux
keyboard template on every client. Version 4 forces one batched full reset
for older markers, verifies the supported template before save, repairs late
native binding-set replacement in the same login and confirms persistence
after a later login. Focused 521 checks and full 105-script/747-Lua desktop
suite pass. Native first-login/reload key presses, grid labels, account and
character sets, combat and taint checks remain pending on each client.
[Evidence](docs/FULL_BINDING_RESET.md).

Binding persistence follow-up (30 October 2026): first-account full keybind
batch could finalize its queued seed before the late native-set check. Version
3 keeps saved Flux keys pending across login sessions and repairs a key lost
on reload before marking success. Old version-2 markers recheck. Focused 35
checks and full 105-script/747-Lua desktop validation pass. Native first
login/reload and actual bridge key/button/label tests remain pending on each
client and binding scope. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

Protected-client raid settings follow-up (30 October 2026): user chose to keep
the taint guard. Retail/Forever Flux raid cells and preview now follow own
class color, power, health text and aura options despite native CVar values;
existing own frame sizing applies at world entry. Blizzard Interface values
stay native-owned. Nine focused checks and full 105-script/747-Lua desktop
validation pass. Verify first account/new character, real raid cells, combat,
Edit Mode and Settings in native clients before acceptance.
[Evidence](docs/RAID_OWNED_SETTINGS.md).

Protected-client raid settings follow-up (30 October 2026): user chose to keep
the taint guard. Retail/Forever Flux raid cells and preview now follow own
class color, power, health text and aura options despite native CVar values;
existing own frame sizing applies at world entry. Blizzard Interface values
stay native-owned. Nine focused checks and full 105-script/747-Lua desktop
validation pass. Verify first account/new character, real raid cells, combat,
Edit Mode and Settings in native clients before acceptance.
[Evidence](docs/RAID_OWNED_SETTINGS.md).

Raid/nameplate defaults follow-up (30 October 2026): user reported Blizzard
raid power bars, class colors and frame size missing at first login and asked
for Medium nameplate size `2`. Classic profile application now waits for the
active native profile and reapplies its CVar pack after load, with bounded
first-world-entry retries. Both nameplate default tables use `2`; existing
size `3` migrates once, preserving other choices. Retail/Forever native raid
settings remain guarded because addon-owned compact-frame callbacks can taint
protected frames. Focused 15 checks and full 104-script/746-Lua desktop suite
pass. Native first-load checks on every client remain pending.
[Evidence](docs/RAID_NAMEPLATE_DEFAULTS.md).

Same-login binding follow-up (30 October 2026): the user reports no bridge
keys on first load. The revised path writes at first world entry and verifies
again five seconds later before marking the active binding set complete. The
old `true` marker is upgraded to version `2`; stock achievement `Y` can become
smart mount, while custom assignments are retained. The live EBS grid registry
now refreshes hotkey labels, and a dense module list refreshes combat click
owners. Focused 29 binding and 7 label checks and full 103-script/745-Lua
desktop validation pass. Native first-load presses for
Hearthstone `7`, teleport `8`, smart mount `Y`, vendor mount `6`, labels and
combat/taint remain pending on all clients. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

Default grid binding repair (30 October 2026): missing Flux template keys now
seed once into the current account or character binding set. The reported
Hearthstone (`7`), teleport (`8`), smart mount (`Y`) and vendor mount (`6`)
routes are covered. Existing custom targets and alternate bindings survive;
combat/full-template work defers the seed. Focused 21 checks and full desktop
102 scripts/744 Lua syntax files pass. Reload the affected character for the
one-time repair when native checking is appropriate. Verify actual key clicks,
labels, persistence, combat/taint and every client; no game/settings interaction
was performed. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

First-login defaults (30 October 2026): new characters apply only CVars and
nameplate bitfields that the active client reports as character-stored, then the
existing raid/chat setup. Full account setup and keyboard-template behavior are
unchanged. The focused 42 checks and full 101-script/743-Lua desktop suite pass.
Native fresh-account/fresh-character behavior across the client roster, queue
completion and secure/visual checks remain pending. The post-login three-sentinel
check still has an unreachable four-mismatch threshold; preserve customized
values when addressing it. [Evidence](docs/DEFAULTS_FIRST_LOGIN.md).

Current publication batch (30 October 2026): all local scale, vehicle/durability,
status-bar and vendor message updates are included for main. Fresh combined
validation passes **100 scripts /741 Lua syntax files, zero failures**.
See [publication record](docs/GITHUB_PUBLICATION.md). Native pending checks remain pending.

Vendor chat amounts now split copper into gold/silver/copper with matching coin
symbols in repair, junk sale and net vendor lines. Full desktop validation passes
100 scripts/741 Lua syntax files; native chat rendering remains pending. The
reported 3,494,236-copper repair should read 349 gold, 42 silver, 36 copper.
Preserve unrelated unit-frame, vehicle and status-bar working-tree changes.

Unit-frame scale follow-up: portrait offsets and focus alignment now use
frame-local coordinates; player and side-by-side target clear the action strip
at 50–200% scale. 3D portrait camera refreshes on an actual scale change.
Focused 23 checks and full 99-script/740-Lua desktop suite pass.
[Evidence](docs/UNIT_FRAME_SCALE.md). Native pixels, click areas and
combat/taint remain pending. Preserve concurrent vehicle/durability and
status-bar changes.

New unit-frame scale controls: Player tab sets shared player/target size;
Focus tab sets focus size (50–200%, default 100%). The root and attached
elements, dependent target frames, detached chrome and class resources scale
together. [Scope and pending native checks](docs/UNIT_FRAME_SCALE.md). The
focused bridge model passes 17 checks; full 98-script/739-Lua report is in that chapter.
Preserve concurrent vehicle-seat work and verify native pixels, hit areas and
combat/taint when background-safe access is available.

Latest vehicle/durability change (30 October 2026): the 70%-scale seat indicator
sits left of equipment durability. If the micro menu or status strip is visible
at the top-left, both indicators sit below the lower strip without moving it.
Otherwise the pair starts at the screen top-left, subject to PvP-widget clearance.
Focused source-driven checks and the full 99-script/740-Lua desktop suite pass.
Native vehicle art, seat clicks, combat,
taint and all-client pixels remain pending. No client/settings interaction.

Latest work (30 October 2026): [unit power visibility](docs/UNIT_POWER_VISIBILITY.md)
hides Flux-owned main/raid power bars for known zero maximum and expands health.
Live/Forever keep full-height health behind power and pass maximum power through
secret-safe alpha; zero current keeps the resource visible. Focus-target and
pet-target were health-only already. Focused models and full 96-script/737-Lua
desktop suite pass; native all-client geometry/combat/taint/secret checks pending.
Health text uses full-height HP for a known zero maximum and stays in the health
section for restricted maxima. The Flux separator restores resource alpha after
partition/chrome repaints, including ToT refreshes; secret maxima are never
tested for truth in Lua. Player/target labels move to the expanded HP bar's
vertical middle for known zero power and restore nested placement on return;
ToT's separator container follows its raised side-by-side frame level. Native
text/border pixels remain pending.
WoW and on-disk settings/profilers were untouched. Source/test/docs were
published on main in `c313dc98a1e782aee1224554c347cd616f3ad7af`.
Preserve newer user changes before further work.

Latest user work: [teleport counts/interruption](docs/TELEPORT_CAST_WORK.md),
BUG-012/PERF-011. User confirms Retail. Candidate uses native count text and
restores the host without popup/binding rebuild. 527 focused checks, three
mutations, five desktop pairs and full 95 scripts / 736 Lua files pass. Native
reload/interrupted casts and comparison with non-travel custom flyouts pending.
No live game/settings changes. This fix is included in the current local-snapshot
publication payload; native acceptance retains its pending scope.

Continue in the existing `_FluxUI` folder/repository. On 29 October 2026 the user
requested that the current local files be uploaded to main, with no other branch.
Work on main only and preserve existing history/newer local edits; no force pushes.
See [publication record](docs/GITHUB_PUBLICATION.md).
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[development tasks](docs/DEVELOPMENT.md) and the [original stage tracker](docs/MODERNIZATION_PROGRESS.md).
The formerly pending objective-tracker source/test/records are included in commit
`73ca9d2`. Inspect current status before new work and preserve any newer user edits.

Earlier runtime `677d85c` shares activation within bar paint batches. Current full
workspace evidence: [95 scripts/736 Lua files](docs/validation/main-local-snapshot-2026-10-29.json).
[Action/player-aura audit](docs/ACTION_AURA_WORK.md) has five matched native pairs
per Retail/Era client, exact sources, unchanged57 button/aura-root geometries and
zero recorded matched-run errors. Native highlight was inactive; active combat/
secure input, dense/restricted auras and long-session leak acceptance remain pending.

Next priorities:

1. Attribute assisted-host icon/count/cooldown/usable work and repeated next-spell
   queries before sharing facts. Retail baseline4.814ms/s is inclusive, not a sum
   with its children. Preserve identity, effects and response cadence.
2. Exercise live enabled effects, paging/forms/modifiers/pet/stance/vehicle/input,
   aura expiry/reapply/reuse and combat/Edit Mode on exact builds. Top-right player
   aura data/handlers/style remain Blizzard-owned; no replacement painter.
3. Continue original API/lifecycle/private-cache and long-session gates. Keep
   auction, guild-bank and void-storage callbacks excluded.

Both clients remain open. Account sessions displace each other: test the named
characters sequentially using normal warning dismissal/Reconnect/selection.
Verify current executable/PID/window before messages; do not take foreground or
PC mouse/keyboard/clipboard. Final state: Era in world, Retail reconnect screen.
Original profiler0 Retail/1 Era and prior diagnostic roots restored. The existing
mirror job stays running unchanged (actual timeout1s despite60s text); verify file
hashes before reload and preserve unknown destination changes. No extra sync job.

Reproduction from the addon root:

```powershell
lua tests/assisted_highlight_work.lua --source tests/fixtures/assisted_highlight_before.txt --measure
lua tests/assisted_highlight_work.lua
lua Core/_tmp_playeraurassmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure intentionally exits0 with20 unmet work budgets; candidate must
pass. Feature removal, settings reset, history rewrites and a separate release
remain outside the authorization. Main publication is authorized for this batch.
