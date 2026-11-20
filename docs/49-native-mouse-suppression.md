# Transparent native mouse blockers — 23 October 2026

## Flux party separator and combat group hover — 14 November 2026

`GROUP-GHOST-HOVER-20261114`. The second screenshot selects an anonymous UIParent
frame anchored to FluxUnitFrame_party4 and created at old
UnitFrames/FluxUnitFrames_Shared.lua:9452. This is Flux's detached separator,
not a Blizzard party button. Its owner can be locally shown during construction
under a hidden group dock. Initializing the detached object with IsShown exposes
it; hiding an already effectively hidden owner does not produce OnHide to repair
the mistake. Separator and atlas initialization/OnShow now use IsVisible. The
separator explicitly has mouse input disabled. Existing OnHide callbacks retire
these unprotected detached decorations on real visibility transitions, including
secure combat group changes. Protected parents/anchors are not moved or rewritten.

The casting path had separate gaps: setup-bindings accepted absent/invisible
units, and mouseover-exists cleanup retained a disappeared source solely because
its geometry stayed hovered. A secure valid-hover snippet now checks effective
visibility, resolves the current unit through frame handles and validates
UnitExists. The entered handle is remembered separately from active overrides.
An extra prepared secure OnAttributeChanged wrapper handles unit changes on a
root or entered descendant: retire the old override, then rearm only if the
current unit exists, is visible and is still under the cursor. This supports
valid unit reassignment without mouse movement. Leave/hide clears remembered
entry. Unrelated active peers remain untouched; both ordinary context scans
exclude hidden group ancestors. All original native callbacks continue because
the attribute wrapper never returns false. No ordinary protected mutation is
introduced during combat; existing native group/visibility drivers own those
transitions. No new state driver, ticker or per-frame Lua update is added.

The new regression covers absent party/pet/target/raid slots, joins/leaves,
party→raid→party, unit reassignment/removal, active child ownership, stationary
cursor recovery, stale mouse-focus geometry and the screenshot's exact separator
constructor. It passes 120 checks across five policy models, rejects nine compiled
harmful controls and passes three candidate comparisons per old source owner.
Both exact old owners reproduce their distinct failures. Existing combat roster,
native contract, party steady-work and primary-binding tests also pass. Full
381 scripts/1,069 syntax PASS with every Lua hash verified; all 10 owned runtime
copies match across five installations read-only. These are desktop native-
dispatch models, not certification of the game's protected/secret VM.

The user-linked [TheMizeGuy guide](https://github.com/TheMizeGuy/wow-addon-dev/blob/f928572a9428d29327a96c2549b0068101961c4e/references/ui-and-secure-templates.md)
was inspected read-only at f928572a9428d29327a96c2549b0068101961c4e (MIT). Its
combat-lockdown/defer advice is useful background. Its broad Retail/Classic
claims are not target-specific Forever evidence, and its SKILL.md claim that
tonumber scrubs secrets is not adopted. The captured current Blizzard contracts
remain authoritative for RestrictedEnvironment UnitExists, RestrictedFrames
RunFor/handle returns, and SecureHandlers attribute dispatch. No external runtime
code, media or skill installation was copied into the addon.

Actual candidate native casting, combat/taint, pixels and controller validation
remain **NOT RUN**. Existing background/user reproduction preference applies;
the separate broad profiling goal remains paused. Reload outside combat, verify
solo slot geometry, then join/leave during combat, convert party↔raid, remove/reuse
members and pets/targets while hovered, and inspect native Lua/blocked-action
errors. Prepared frames can react securely in combat; genuinely new protected
frame creation or configuration still waits for a legal setup boundary. The
retained hidden object can remain inspectable with show-hidden filters.
[Exact evidence and remaining acceptance](validation/group-ghost-hover-2026-11-14.json).

## Secure hover registration and literal-deletion limit — 14 November 2026

`PLAYER-GHOST-SECURE-FOLLOWUP-20261114`. The user supplied a fresh screenshot,
confirmed reload and reported intermittent hovercast interference after the
preceding candidate. They explicitly require full removal, including Frame Stack,
and rejected describing hiding as removal. Prior desktop counts do not establish
that the native interaction was fixed; mark that candidate not accepted.

The prior fix guarded `_PerformHoverContextScan`, which drives visual context.
The separate registered secure `OnEnter` still called `setup-bindings` for the
retained native PlayerFrame, and a prior active override could survive a setting
transition. The new production regression reproduces that behavior with the old
source before applying the candidate.

`SyncNativePlayerSuppression` now runs at the existing suppression/toggle boundary
and discovery lifecycle. While native player input is suppressed, `RegisterFrame`
rejects that exact object on all registration paths, including ClickCastFrames.
If already registered, Flux's own header uses a frame reference and the existing
secure clear snippet to retire an active root or wrapped legacy-child override,
then removes Flux's wrappers through its existing unregister path. A peer's active
override is preserved. Legacy entered callbacks are balanced on unregister, and
retained hooks check registration/owned-child status before waking again. Selecting
Blizzard restores registration. No ordinary native Show/Hide/SetParent, frame
script replacement, unit mutation or state-driver registration is added.

Registration/cleanup runs only outside combat and the native Edit Mode reset
stack. Already-in-combat requests retain the existing fallback until a legal
reconciliation. The source does not attempt to bypass combat restrictions.

Literal frame destruction remains **unsupported**. Blizzard's XML creates the
native PlayerFrame before FluxUI; the public frame API exposes no supported
destructor. Assigning its global reference to nil would leave the actual object
alive and break Blizzard's player/vehicle/aura references. DebugTools forwards
its hidden-frame preference to the native SetFrameStack enumerator. Retained
native objects can remain in its inspection. The screenshot establishes the
object/location, not the loaded candidate byte identity or a complete taint
trace. No alteration of the inspector is attempted to manufacture disappearance.
[Pinned sources and exact scope](validation/player-ghost-secure-followup-2026-11-14.json).

Three before/after pairs reproduce and correct active secure overrides; 300
casting assertions across five client models and nine compiled harmful controls
PASS. The 15 affected scripts and all 1,068 Lua syntax files PASS. The prior full
suite is historical; this follow-up is an incremental replay. All 10 changed
runtime copies match across the five installed clients read-only. A fresh
2,799-file external source/history/index checkpoint and 113 settings metadata
entries precede edits; private settings/profiler preferences are untouched.

Actual new-candidate cast/combat/taint/controller acceptance is **NOT RUN**.
Use the established user-reproduction/background-only route: reload outside
combat, test the former stock rectangle and the visible Flux frame, then native
selection restoration, combat and Edit Mode transitions. Inspect native Lua and
blocked-action errors separately. No claim of literal deletion, Frame Stack
absence or taint-free native execution is made.

14 November `PLAYER-GHOST-HOVER-20261114` final validation: 380 scripts / 1,068 syntax PASS after retaining newer unrelated inventory work. Player-frame source identities remain the tested candidate; native acceptance remains pending.

## PlayerFrame ghost hover follow-up — 14 November 2026

`PLAYER-GHOST-HOVER-20261114`. The user identifies the invisible frame as
`PlayerFrame` on Forever and reports that it affects unit-frame hover casting.
Source inspection found two relevant gaps: initially secret native mouse
switches are intentionally left untouched by `SetMouseSuppressed`, and the
binding context scan accepted shown native roots/descendants through geometry
without consulting suppression policy. The user's report does not establish
which native switches were secret in that session.

The player coordinator now saves the root's four public hit insets outside the
native frame, then sets all four to 10,000 while Flux's replacement is active.
This empties the ordinary 232x100 player hit rectangle independently of mouse
switch readability. Repeated reconciliation repairs changed insets without
replacing the original snapshot or rewriting an unchanged rectangle. Selecting
Blizzard restores the exact original insets. An unreadable initial rectangle is
left untouched rather than guessing its restore state. Every mutation remains
behind existing combat and Edit Mode reset barriers; no secure handler is
replaced, no root is hidden/reparented and no unit attributes are changed.

`Blizz.IsMouseSuppressed` exposes the existing external ownership table as a
plain policy boolean. Binding scans exclude suppressed registered roots and
their descendant attribution in both GetMouseFoci and the geometric fallback.
Overlapping suppression owners retain the exclusion until the final release.
An independently registered pet still participates. Secure binding snippets,
native aura/vehicle events, separate pet/resources/totem/cast-bar ownership,
saved settings and the 50ms context cache are preserved. No visible UI or
localized strings are added, so a UI mock-up/options expansion is unnecessary.

Fresh pinned Gethe source was checked for all five existing FluxUI clients.
Their player roots inherit SecureUnitButtonTemplate and
EditModePlayerFrameSystemTemplate. GetHitRectInsets declares four uiUnit returns
without secret annotations; SetHitRectInsets is protected (Retail/Forever also
disallow secret arguments). Only public saved numbers or constant insets are
passed. Source annotations do not certify native caller permission or taint.
[Exact commits, versions and file hashes](validation/player-ghost-hover-2026-11-14.json).

The expanded production-path regression passes 3,387 checks across five policy
models, rejects 20 harmful variants and preserves aura/vehicle handlers. Each of
the three old owners reproduces the relevant regression in three isolated
comparisons; three candidate repeats pass. Full 379 scripts / 1,067 syntax files
pass with every Lua hash checked afterward. All 15 runtime copies across the
five installations match read-only. The 2,797-file external source/history/index
checkpoint and 113 settings metadata entries were verified before edits.

Native candidate acceptance is **NOT RUN**. Existing user reproduction and
background-only testing preferences apply; the actual Forever process/window
was identified without activation. No available connected game execution/error
tool was exposed for this task. Reload outside combat, then check hover casting
over the former stock rectangle and the visible Flux frame; repeat combat,
vehicle, Edit Mode close/save and Flux/Blizzard toggle transitions. Verify native
auras, independent controls and controller cursor hover. Directional controller
focus is unchanged and untested. Repeat on the other clients. No taint-free or
FPS claim follows from desktop checks. The native object may still be listed by
Frame Stack's show-all filters; physical deletion would discard native owners.

## Raid secret mouse follow-up

On 6 November the user reported `Blizzard/Hide.lua:139: attempt to compare local
'current' (a secret boolean value, while execution tainted by '_FluxUI')` from
`FluxRaidLayout.lua:778`. `pcall` protected the getter call but returned the
opaque boolean successfully; the subsequent Lua comparison failed. The helper
also tried to snapshot getter results by ordinary type, which could retain an
opaque state that cannot safely be compared or restored.

The helper now rejects secret getter results before saving them. If a readable
state was saved and a later getter is secret, it passes the known saved or
suppressed boolean straight to the native setter after the existing combat/Edit
Mode gates. It does not infer split click/motion values from a combined getter
when split methods are present. Initially opaque switches remain untouched, so
their native hit testing needs live review. Parent, alpha, event, script,
overlapping-owner and restoration paths are otherwise preserved.

The supplied stack is native evidence for the error, not evidence that all raid
frames or taint paths are fixed. `tests/native_mouse_suppression.lua` now models
initially opaque split/legacy switches and a getter becoming opaque after a
readable snapshot. It passes 2,545 checks across five branches and rejects 14
mutants; `tests/raid_startup.lua` passes 2,073 assertions. The desktop sentinel
does not emulate the native secret VM. Full validation passes 159 scripts / 816
Lua syntax files with no failures; the current source hashes are in
[the validation record](validation/raid-secret-mouse-2026-11-06.json). Reload and check party/raid visibility,
click/hover/wheel interaction, Edit Mode close, combat roster changes, and
Flux/Blizzard enable/disable restoration on real clients.

The user reported transparent Blizzard player/status frames blocking the mouse on Forever, also visible in Frame Stack. Their alpha-zero suppression left input enabled: the player root is a secure unit button, while native XP/reputation status containers include independently mouse-enabled children.

[Hide.lua](../Blizzard/Hide.lua) now provides `Flux.Blizz.SetMouseSuppressed(frame, suppressed, skipChild)`. It snapshots click, motion and wheel settings outside native frames and disables those inputs throughout the selected subtree. Capability detection supports separate click/motion switches and the legacy combined switch without guessing original values. Restoring a subtree restores its exact saved input policy. Overlapping owners cannot restore each other's still-suppressed children. Reconciliation includes newly created children and restores input to children moved to another owner.

[Player suppression](../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua) uses the helper only when the replacement is initialized and selected. Re-selecting Blizzard frames restores their mouse policy. Native player/unit/vehicle events, aura ownership and original handlers remain intact. Independent pet, class-resource, totem and casting-bar subtrees are excluded; Flux's replacement frame is also excluded. No native root is hidden or reparented by this input change.

[Status HUD suppression](../StatusBars/FluxStatusBar.lua) disables input on the native XP/reputation containers and children, legacy XP/reputation bars and replaced durability display, after the Flux HUD is ready. The existing combat/readiness gates remain authoritative. All input changes defer during combat; the existing Blizzard-helper regen waiter coalesces requests by root, using the latest requested state. No idle ticker, native script replacement or permanent input hook is introduced. Repeated unchanged suppression does not write input settings again.

## Edit Mode exit follow-up

The user reported native `CompactUnitFrame_UpdateHealthColor` comparing a secret old color under FluxUI taint while Edit Mode closes. The supplied Forever source shows `OnHide → OnEditModeExit → EditModeFrameReset → ResetPartyFrames → RefreshMembers → CompactUnitFrame_SetUpFrame → UpdateAll` running before `EditMode.Exit`. A hidden manager alone therefore does not mean its native reset is complete.

The recent mouse helper lacked the Edit Mode boundary already used by reparenting. It now queues both suppression and restoration until the existing busy latch clears and its next-frame queue drains. Per-root keys coalesce requests without colliding with reparent requests; newer immediate input policy cancels a stale queued change. Unit-frame suppression, overlay suspension, player runtime toggles, both-side refreshes, native status suppression and Blizzard settings transactions also wait through that boundary. Combat starting before the queue drains hands restricted work to the existing combat deferral rather than mutating native frames on the exit stack. No Blizzard compact-frame/color/reset function is replaced or bypassed.

This closes a source-supported timing gap. It does not prove that every possible native taint source is eliminated; the secret-value VM cannot be reproduced by desktop Lua. Reload is required to clear already-tainted native state before repeating Edit Mode enter/exit in game.

## Edit Mode save follow-up

The user reproduced the error after the timing barriers, on both Retail and Forever, with stock stance/possess bars left visible. The barriers alone were insufficient. The current change also removes insecure hidden-parent suppression from the native party/raid roots. `Blizz.Hide(..., { keepEvents = true, keepParent = true })` retains native parent, shown state, events and scripts, suppressing only artwork and input. Native `DefaultCompactUnitFrameSetup` and `RefreshMembers` continue to run. Unhide restores the original alpha and input policy; repeated requests and cancelled combat restoration retain the first snapshot. This applies across all five clients. No compact-frame health/color/setup function is replaced, skipped or error-suppressed. A native frame that Blizzard keeps visible can continue its own display updates at alpha zero; measure grouped idle/combat CPU during native validation rather than assuming the former hidden-parent cost is unchanged.

The centralized settings writer also bypassed the CUF guard already present in `Flux.CVar` and `FluxSetCVar`. It now rejects native compact-frame CVar writes on Retail/Forever, including forced resets and case variants; native CUF profile setters use the existing non-secret-client policy too. Blizzard's CUF implementation translates these CVars into persistent native option tables and refreshes frames. Waiting for a later timer does not establish safe ownership for those callbacks. Existing native preferences remain untouched on secret clients, Flux's own raid options remain independent, and Classic retains its native CVar/profile defaults. The first taint writer in a live session is still not established by a desktop test.

Stock stance and possess selections are muted only after Flux input is ready. The subsequent [form-change follow-up](51-input-and-native-callbacks.md#stance-flicker-player-artwork-containers-and-retained-idle-optimization) suppresses replaced stance buttons and securely mutes the parent artwork/input without parent OnShow reentry; it also hides the unused player artwork container with exact visibility restoration. Exit reconciliation reasserts the existing secure stance suppression and suppresses empty possess presentation using restricted frame handles. An added Enter suppression sweep was subsequently removed after comparison with v9 and GitHub main; native-bar suppression now waits through Edit Mode in every public entry point. See the [baseline comparison and recovery follow-up](51-input-and-native-callbacks.md). The secure possess snippet retains the native bar whenever `[possessbar]` is active, preserving real cancel-possession controls. Native controller methods, original button scripts and the early-combat fallback remain intact. Classic's stance parenting and early Forever's restricted-engine policy are retained. No repeating visibility driver or idle poll is added.

## Frame Stack

Frame Stack can still list the retained native objects, depending on its filters. Retaining the shown native player root supports Blizzard's own unit/vehicle/aura behavior; retaining Edit Mode roots avoids the known shown-state/reparenting taint path. Being listed there does not establish that a frame accepts mouse input. Verify clicks, hover tooltips and wheel input reach the intended FluxUI/world surface.

## Verification

[native_mouse_suppression.lua](../tests/native_mouse_suppression.lua) executes the complete production Blizzard helper and unit-frame coordinator, plus the real status suppression function. Across `live`, `classic_era`, `classic_anniversary`, `classic` and `forever`, it checks readiness and already-in-combat fallback, exact restoration, modern/legacy input APIs, nested status bars, independent controls, native script/unit/event ownership, overlapping owners, late/moved children, repeated reconciliation, latest-request combat recovery and zero illegal mutations, including errors caught by pcall. It also executes the actual Edit Mode busy latch/queue/callbacks, player runtime entry point and Blizzard settings writer, including the manager-hidden/native-reset window, next-frame reconciliation, superseding input changes and combat starting before exit work drains. Twelve negative controls reject disabled suppression, broken restoration, native grid reparenting, lost alpha snapshots, missing combat protection missing Edit Mode barriers in the helper and callers, omitted decorative-container suppression and lost original false visibility snapshots.

The [full validation record](validation/native-mouse-2026-10-23.json) includes the preceding clear-transmog cursor regression and all existing startup, compatibility, migration and idle fixtures. These are desktop/source tests. Native testing remains required on all five clients: reload out of combat, click/hover/scroll through the former player/status rectangles; toggle between Flux and Blizzard player frames; enter/exit vehicles and Edit Mode; change specialization and status-bar content; load already in combat; and verify independent pet/totem/class-resource controls. No native client test of this input change has been performed.

The expanded [native mouse test](../tests/native_mouse_suppression.lua) checks in-place native grid suppression and snapshot restoration. [Raid startup](../tests/raid_startup.lua) now executes the real Blizzard suppression service with the real raid lifecycle rather than substituting a hiding stub. [Settings dispatch](../tests/edit_mode_settings.lua) checks all five client policies, forced writes, combat/Edit Mode queuing and two rejected unsafe mutations. [Bar contracts](../tests/bars_contract_regression.lua) execute the production secure snippets with Blizzard's pre/post message contract, failure retry, native possess visibility in combat and rejected dispatch/possession mutations. The [native stance smoke](../Core/_tmp_stancehidesmoke.lua) still executes the supplied `HANDLE:Hide` implementation and 800 combat show callbacks. After a clean reload, save/close Edit Mode repeatedly and verify the error does not recur, empty stance/possess chrome stays suppressed and real possession/taxi cancellation remains usable; these native outcomes remain pending.
