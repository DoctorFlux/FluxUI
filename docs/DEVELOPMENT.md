# Development tasks

31 October combat grid conjured-item usability: verify gem and healthstone
tint in native alive/dead/ghost, full-resource, cooldown and empty/replenished
states alongside other combat items. The loaded-paint fixture passes 14 checks;
full desktop validation passes 111 tests/756 Lua files. Native clicks, taint,
pixels and matched frame time remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast fill/tip correction: shared renderer now parents school fill
to the actual progress bar, hides/restores Blizzard's underlying fill and
tints/restores the native tip Spark. The focused test rejects the published
source; full 110-test/755-syntax desktop suite passes. Native acceptance is
pending. [Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

31 October Blizzard nameplate cast school themes: same Flux school renderer as
target/focus over Blizzard's own status bar, with a default-on option and
secret-value fallback. The 48-check nameplate model and full 110-test/755-Lua
desktop suite pass; native combat/pixels/performance pending.
[Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

30 October MicroMenu nil-center correction: reparent selected and unused
native children before their Show/Hide callbacks can invoke Blizzard
`GetEdgeButton`. [17-micromenu.md](17-micromenu.md) records the regression,
exact source identity and native limits. Full desktop suite: 109 tests /
753 syntax files; post-fix native checks pending.

30 October delayed loot correction: pending source sessions retain the
opening cursor through lagged item/currency/money chat and reconcile late
slot/chat reports. [LOOT_CURSOR.md](LOOT_CURSOR.md) records the fixture,
source hashes and native limits. Full desktop suite: 108 scripts / 752 syntax;
native five-client placement and performance pending.

30 October cursor-position correction: each loot window now retains its
opening cursor origin for all rows, including delayed chat. The two-batch
fixture and exact hashes are in [LOOT_CURSOR.md](LOOT_CURSOR.md). Full desktop
suite: 108 scripts / 752 syntax; native five-client pixels/timing pending.


30 October loot-source correction: cursor alerts now exclude crafted and
pushed gains and gate ordinary self-loot/currency chat to a loot window.
[LOOT_CURSOR.md](LOOT_CURSOR.md) records the focused fixture, exact source
identity and native checks. Full desktop suite: 108 scripts / 752 syntax.


30 October FluxLoot callback correction: user native stack at line 402,
signature-aware regression and exact candidate hashes are in
[LOOT_CURSOR.md](LOOT_CURSOR.md). Focused and full desktop validation pass;
native post-fix login/profile acceptance remains pending.


30 October cursor money alert follow-up: gold/silver/copper symbols, white
numbers and threshold-selected icons are documented in
[LOOT_CURSOR.md](LOOT_CURSOR.md). The focused desktop fixture and full
107-script/751-syntax runner pass; native five-client acceptance remains
pending.


30 October cursor loot: Tools → Loot controls and slot/chat alerts are
documented in [LOOT_CURSOR.md](LOOT_CURSOR.md). Run `lua tests/loot_cursor.lua`
for the focused desktop event model and `python tests/run_validation.py --output
docs/validation/loot-cursor-full-2026-10-30.json` for the full desktop suite.
Native five-client acceptance remains pending.

Current Retail Sticky Targeting check (30 October): exercise the targeted
registered `deselectOnClick` setting route in a native background client when
available. Verify checkbox state, CVar readback, first-load/reload behavior,
manual Controls reset, taint and frame time. The 13 August historical source
informed this change; 76 desktop checks pass. [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

Current Retail Controls priority (30 October): verify in a background native
session that `deselectOnClick=1` and camera factor 2.6 persist after the
settings-only retry, then check a second reload, manual Controls reset,
taint and frame time. The user's pre-fix readback was `1.900000 / nil / 0`;
the corrected desktop fixture passes 68 checks. No WoW process was visible
during this repair. [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

Current Hearthstone hover follow-up (30 October): verify the selector tooltip
and owned-toy choice in a real Toy Box client. The native stack trace showed
`GetItemInfo` nil at hover; the focused fixture now covers that path with the
global unavailable and passes 19 checks. Native secure use, reload scope,
combat/taint, pixels and frame time remain pending.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Current Hearthstone correction (30 October): load the Toy Box on a real client
and verify the panel appears beside it. The editor now uses the core capability
available before its TOC entry; the previous desktop fixture missed that
order and was superseded by a 17-check regression. Then select an owned toy,
reload and confirm the grid button uses it. Native combat/taint, pixels and
frame time remain pending. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Current Hearthstone follow-up (30 October): verify the Toy Box editor and
owned-toy choice on actual toy-capable clients after reload. Desktop checks
cover the missing journal-toggle capability, opener alternatives, visible
selector and saved item readback; they do not prove native secure item use,
combat/taint or frame time. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Current binding priority (30 October): verify the one-call context-aware
transaction on Mariosuper (Era) and Pandasans (Retail) once their actual
processes/windows are visible without foreground control. Confirm keys,
reload persistence, no repeat setup, grid labels and frame time.
[Evidence](BINDING_ATOMIC_CONTEXT.md).

Current user priority (30 October): verify the version-6 native binding
transaction on actual clients, especially Retail's empty account-cache
migration and first-load reload persistence. The desktop
[evidence](BINDING_PERSISTENCE_REWRITE.md) cannot certify secure input,
disk persistence, hotkey labels, taint or frame time.

Current user priority (30 October): verify native no-replay on reload and
immediate first-account binding setup after the version-5 attempt gate.
Desktop [evidence](ACCOUNT_BINDINGS_ONCE.md) covers five client models; native
secure keys, saved-variable persistence and frame time remain pending.

Current user priority (30 October): verify account-only automatic keybindings
on native clients. One successful first-account setup must be followed by no
automatic full keyboard reset on character logins or Settings callbacks.
Desktop [evidence](ACCOUNT_BINDINGS_ONCE.md) cannot prove real input,
persistence, protected execution or frame time.

Current user priority (30 October): verify the corrected one-time binding
reset and its native frame time. A successfully saved active scope must never
reset on a later login; desktop tests cover the one-scan/eight-write frame
bound, while real latency, input and persistence still need client checks.
[Evidence](FULL_BINDING_RESET.md).

Current user priority (30 October): native verification of the new full
first-load binding reset on every client and active account/character binding
scope. The user explicitly requested clearing all keys before applying the
Flux template; [desktop evidence](FULL_BINDING_RESET.md) cannot prove actual
key presses, labels, persistence or protected execution.

Current user priority (30 October): finish native all-client checks for
[unit power visibility](UNIT_POWER_VISIBILITY.md) when background-safe access is
available. Verify health/power geometry, combat/taint and restricted values;
the 96-script/737-file desktop suite does not establish these native results.
Main is the current branch; older change-branch/hold instructions below are
historical and superseded by the 29 October user request.

Latest user priority: verify Retail teleport/portal count and interrupted-cast fix
after reload. [BUG-012/PERF-011](TELEPORT_CAST_WORK.md) passes 527 focused checks and
full 95-script / 736-file suite. Native latency/combat/input/pixels and non-travel
custom flyouts remain pending. Keep foreground PC use undisturbed. Older source/
publication/task statements below retain historical scope.

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

Objective tracker follow-up: the first-module gap correction now covers saved
native container callbacks on Retail and Forever and runs before the cached-height
sync return. Zero offsets restore after child resizing. The new regression passes
40 checks and the full report passes 90 scripts/731 syntax files. Native checks:
fully scroll up with Campaign plus Quests, remove/re-add Campaign, collapse sections,
resize while scrolled, toggle Questie, and enter/leave combat. Leave WoW in the
background; these live checks remain pending. [Behavior](18-minimap-and-trackers.md).


1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Keep skipping auction, guild-bank and void-storage callback audits. The current
   cached personal/warband count change does not authorize those callbacks.
3. Read [recovery](RECOVERY.md). Eleven verified external checkpoints retain source,
   history and private settings. Latest 12:35 UTC / 13:35 Copenhagen covers d3bce5b,
   1,234 actual files and 403 WTF files. Both clients were running: on-disk settings
   only, not quiescent in-memory state. Preserve a fresh checkpoint before another
   runtime batch if source/settings differ; retired originals stay outside AddOns.
4. Current runtime/test `013bf40db1d5b57c238ac3ac377e8ced98446fd1`, tree
   `4f0d827bb26bba3ee8b20e21de891596fad0e98b`. PERF-006 filters bag/cached-bank tier
   matches before live usability; quantities, live gates/protections/fallback remain.
   1,710 focused checks and full 89 scripts/730 syntax pass. Five alternating native
   Era getter pairs return identical results with lower CPU. Personal-bank native
   outputs are zero; positive/warband parity is desktop-only.
5. **Leave WoW in the background while the user uses the PC.** Do not activate it,
   take keyboard/mouse focus, or repeat the foreground controller without renewed
   coordination. Cleanup is complete: original three automation flags true and
   profiler=1 retained, temporary sampler/namespaces/exports cleared. Edit the normal
   addon folder; the user's existing sync delivers files. No new sync/deployment job.
6. The clean Era 1.15.9.70576 pilot reproduced a 333 ms UI interval across four opens
   and about 320 ms per target build. Getter CPU medians per five kinds fell from
   132.199 to 15.237 ms bags and 118.897 to 22.517 ms cached bank. Whole-vendor after
   remains pending. When foreground testing is convenient, use [exact procedure](TIER_COUNT_WORK.md):
   five matched alternating four-open/20-second windows, same NPC/profile/resolution/
   scale/inventory/addons, 30-second warm-up, separate cold and steady work, profile
   on/off with preference restored. Compare screenshots/input/taint and normal
   allowed transactions separately. Do not infer native FPS from getter CPU.
7. BUG-001 through BUG-008, PERF-005/006 and editorial cleanup retain their documented
   tested scope. Other classification, Already Known, reagent-name or layout work
   needs attribution before edits. Reservations are not native acknowledgement;
   unchanged-ID price/stock changes and delayed/rejected requests remain separate.
   Event mutation is latent with no production unsubscribe trigger; do not redesign
   the shared dispatcher speculatively.
8. Complete [client validation](CLIENT_VALIDATION.md) separately on available targets.
   Era gains only partial native count evidence; pixels, security/taint, unprofiled
   FPS, external providers and other clients remain pending. Desktop mocks do not
   certify real secret values or original Wrath 3.3.5.

Reproduction from the addon root:

```powershell
lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure
lua tests/tier_count_work.lua
lua tests/idle_tiers.lua
lua tests/vendor_tier_work.lua
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Count measure mode exits zero with ten expected failures among 1,710 checks;
candidate passes all. Verify all current Lua hashes against
`docs/validation/tier-count-full-2026-10-29.json` before reusing the full result
(Lua/luac 5.4.6, Python 3.10.6). Some legacy tests need adjacent reference trees;
missing fixtures are not addon failures. Use --sync-docs only with a fresh full run.
Native probe/source hashes and samples are in the focused evidence; its local
candidate bodies are not a replacement for complete addon foreground acceptance.

Update status, decisions, work log, ledgers and these tasks before stopping. No
push/merge to main, settings reset, second addon, rename or release is authorized.

## Next steps after the Retail audit

Current runtime fixes: loot waiter reuse `6ac4389`, capture snapshot release
`3046478`; [evidence](RETAIL_PERFORMANCE_AUDIT.md). Actual current suite passes
92 scripts/733 syntax files including the preserved pending tracker correction.
Use validation/retail-lifecycle-full-2026-10-29.json for current Lua hashes.
Do not stage or overwrite that separate tracker work as part of another fix.

Finish native capture follow-up/cleanup, retaining original profiler=0 and background
PC use. Then prioritize nameplate add/remove/disabled work and assisted-action
same-fact paint traces; preserve timing. Stress options, map, inventory, bindings,
respec and unit/raid resources through real lifecycle cycles and long sessions.
Existing GUID freshness TTL is not an eviction policy; quantify older-client
inspection churn before a cache policy change. Mirror timer idempotence already
exists; no runtime fix needed there. Auction/guild-bank/void callbacks remain
excluded. No whole-addon leak-free/FPS/security certification is established.

```powershell
lua tests/loot_roll_lifecycle.lua
lua tests/perf_capture_retention.lua
lua tests/perf_capture.lua
python tests/run_validation.py --output docs/validation/next-check.json
```

Retail capture follow-up/cleanup is complete; original profile0 restored. Five
actual candidate reports and native endpoint limitations are retained in the audit.
Next prioritize nameplate/assistant work and real lifecycle/long-session stress.
Keep background PC use and preserve the pending tracker work.

## Chat offset/reload/tab follow-up complete

Current runtime7f13000 includes78fe4e7. Use validation/chat-column-alignment-full-2026-10-29.json
for all733 current Lua hashes;92 scripts pass. Social uses shared inset8, relative
tab height for late startup movement and primary dock geometry for every tab.
2,009 column checks cover five branches/both sides/scales and custom tab geometry.
Native Retail General/Global/Combat Log seven-selection coordinates match; untouched
reload inspected before chat input. [Evidence](CHAT_COLUMN_ALIGNMENT.md).

Keep other-client rendering, combat/Edit Mode and broader performance/lifecycle/
long-session acceptance pending. Current native diagnostics are cleaned up and
profiler0 restored. Preserve background PC use, main, deferred callbacks and the
separate uncommitted tracker correction.

## Next tasks after PERF-009

Read [original stage tracker](MODERNIZATION_PROGRESS.md) and root next-session
record. Runtime `efca305` and [full report](validation/nameplate-countdown-full-2026-10-29.json)
cover93 scripts/734 syntax files including preserved pending tracker work. Focused
countdown replay1160 checks, five desktop/native widget pairs; actual restricted
plate-aura/combat/native pixels remain pending. [Exact steps](NAMEPLATE_COUNTDOWN_WORK.md).

Native cleanup is complete: original profile0, diagnostic root nil and normal
candidate file loaded. Leave WoW open in the background. Next attribute assistant
same-fact paint/queries and stress remaining real lifecycle/private-cache churn.
Do not infer leaks/FPS from changed scenes or extend to excluded callbacks.

```powershell
lua tests/nameplate_countdown_work.lua --source tests/fixtures/nameplate_countdown_before.txt --measure
lua tests/nameplate_countdown_work.lua
python tests/run_validation.py --output docs/validation/next-check.json
```

Baseline measure exits0 with15 unmet work budgets; candidate must pass. Preserve
user tracker changes while staging shared/generated records.

## Next after action/aura batch

Current runtime `677d85c`; use validation/action-highlight-full-2026-10-29.json
for735 Lua hashes/94 passing scripts. [Audit/evidence](ACTION_AURA_WORK.md) and
[seven ownership groups](ACTION_AURA_AUDIT.csv). Keep unrelated pending tracker
source/test/docs uncommitted. Main and deferred callback domains remain protected.

Next attribute assisted-host icon/count/cooldown/usable work (Retail baseline
4.814ms/s inclusive) and repeated next-spell reads before sharing facts. Preserve
cadence/identity/animation/input and native aura ownership. Test actual enabled
highlight/combat/paging/modifiers/pet/stance/vehicle/input, dense/restricted aura
churn and long-session caches on exact builds. Do not treat one CPU block or stable
short geometry as FPS/leak-free certification.

Both clients stay open; sessions displace each other, so reconnect/select the named
characters serially after inspecting each window. No foreground takeover. Original
profile0 Retail/1 Era and prior diagnostic roots restored. Existing mirror remains
running unchanged; verify target hashes before reload, with only known test-file
copy if delivery lags. No new sync job or broad manual deployment.

```powershell
lua tests/assisted_highlight_work.lua --source tests/fixtures/assisted_highlight_before.txt --measure
lua tests/assisted_highlight_work.lua
lua Core/_tmp_playeraurassmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
```

Baseline measure reports20 unmet work budgets and exits0 intentionally; candidate
must pass. Source tokens/settings/features remain the implementation contract.

## Publication handoff

Main publication is now explicitly authorized by the user. Include the complete
addon and tested tracker correction (`73ca9d2`) with current generated records;
older instructions to keep that work uncommitted are superseded. Preserve the
existing development branch and history; no force push or separate release.
Use [publication validation](validation/github-publication-2026-10-29.json) for the
combined735-file/94-script corpus and [publication record](GITHUB_PUBLICATION.md)
for source/recovery scope. The next optimization/native acceptance tasks above
remain pending; uploading is not a claim that every scenario is certified.

## Main-only local snapshot instruction

The user's latest request supersedes earlier branch-retention/unpublished-work
instructions: work on main only and publish the actual current local files,
including the teleport fix and all tests/docs. The redundant branch was removed
locally/remotely; its commits are already in main. Preserve newer local changes,
existing history, native pending scope and ignored/private data. Use
validation/main-local-snapshot-2026-10-29.json for the current95-script/736-file
publication corpus. Do not create another branch unless the user asks later.
