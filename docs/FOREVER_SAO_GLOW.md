# Forever SpellActivationOverlay button glow — 6 November 2026

## Retail-style combat callback candidate

The user tested the prepared Classic LBG candidate after `/reload` and again
reported that Arcane Missiles glowed only after combat. The user then requested
that button glow start with SAO's screen overlay and use the modern Retail proc
art. This is a new, unconfirmed candidate; the earlier live failures remain
recorded below.

Forever now pre-acquires and anchors the existing LibCustomGlow `ProcGlow`
flipbook outside combat when both Retail proc atlases exist. SAO and native glow
show/hide notifications carry a reason through the shared glow service. On
Forever combat callbacks, Bars.Effects settles the 19 columns synchronously,
and standalone Extra Buttons run their existing glow-only paint immediately.
SAO's 400589 screen show and hide trigger the same callback, while generic
`AddGlow`/`AddGlowNumber`/`RemoveGlow` and native button events cover the other
SAO-supported procs. Other clients retain their deferred refresh cadence.
The modern frame stays shown at zero alpha on its secure button between procs;
combat activation changes alpha and starts the existing Retail animation
script, avoiding a protected child `Show()` call. Each destination uses its own
frame when paging. If the client lacks the Retail atlases or the
library fails to prepare, the existing Classic LBG path remains as fallback.
The installed SAO files, settings, secure attributes and saved data are untouched.

The first native diagnostic returned `SAO screen=0/0 notify=128
modern=158/0/0 failed=0 classic=0` while the large overlay was visible in
combat. This proves the Retail frames were prepared but the screen hook never
delivered an activation to Flux; it does not prove the art can render. Flux now
reads the installed SAO frame's `overlaysInUse[400589]` directly when the
player aura changes, then checks again one frame later so SAO's event ordering
cannot leave the button dark. A failed unit-event registration falls back to
the shared event bus. The same global frame and `animOut` state clear the
button as the screen overlay fades. This replaces dependence on a hook for
Missile Barrage; generic SAO button procs still use their existing hooks.

The user retested the global-frame/alpha candidate and still saw the button
only after combat. Its in-combat counters were `screen=0/0 notify=330
modern=158/0/0 failed=0 classic=0 aura=7/1 frame=334`. Player aura events
and the global frame lookup are running, but no modern frame received a show
request. The single aura transition may have been the initial inactive state.
The next diagnostic is SAO's actual live `overlaysInUse` keys, Flux's
`Want(5143)`, and the bar paint counters during the visible proc.

The user ran that check: `want5143=0`, and no keys printed from SAO's
`overlaysInUse` table during the visible alert. This rules out that SAO frame
as the source of this particular on-screen effect. Forever's pinned
`SPELL_ACTIVATION_OVERLAY_SHOW`/`HIDE` events carry a spell ID, and the
installed SAO addon itself registers them. Flux now observes those native
screen events and maps 400589, base Arcane Missiles 5143, or its named ranks
to the missing button association. A nil hide clears the mapped state. The
empty SAO frame list no longer overrides an active event marker. This
native-event candidate still needs a fresh combat test; the event ID and
whether the Retail frame reveals remain unverified in the running client.

The native-event retest also failed: `screen=0/1`, `native=0/15/0`,
`aura=1/0`, `modern=158/0/0`, `want5143=0`, `bars=0/342/0/0`.
Installed SAO uses Blizzard AuraContainer slots for secret Forever auras:
`components/display.lua` sends those overlays to its AuraContainer item,
which bypasses the legacy screen show function and native show event. The
first candidate hooked the mapped buttons through SAO's private namespace,
but the next live test reported `container=0/0/0`, `want5143=0`, and
`modern=158/0/0`. Flux now reads Blizzard's global
`SpellActivationOverlayAuraContainer.auraSlotManager.auraSlots`, selects
slots whose static `includeSpellIDs` filter contains 400589, and hooks their
AuraButton show/hide edges OOC. This works without capturing SAO's private
namespace. The final hidden half clears the proc. The global registry path
passes 12 focused checks and still needs native acceptance.

Exact inspected source SHA-256: installed SAO `components/auracontainer.lua`
`58565be48ee5ee36202315405fa9818bda9c5a1d0623e7b4f6491779ef1912ce`;
installed `components/display.lua`
`b8459bdbcbe67d30908b67aa8973c2686007efa605d172e9a1caa776e1684056`;
installed `components/events.lua`
`e4755640829e2b048e1ffc3b8e030186063a8acc1e80aac3accdf9c056a2478f`;
inspected Forever Blizzard `Blizzard_CustomAuraButton.lua`
`e583c0306774cb209a7a4d1b4c29a96f39dab0761da965af173b843ef61704c5`;
`Blizzard_CustomAuraContainer.lua`
`4a47de0e56ba97acbea4e6a65916e9974b98303b4e7ffe6c305a98d62bba0f1`;
`Blizzard_AuraContainerSlots.lua`
`d883dfe3d2fcf71989c7fd8ad1dc085cbf1c7750ef89f75959692a9fc84a1ce8`;
`Blizzard_ManagedAuraContainer.lua`
`a31f6e6c79a2166fabdcdb945bb44abf0cf8854dcc39221a9271e7c9eb907363`.

Focused desktop checks: modern preparation/show/hide 60; low-level screen
signal, native screen event and global-frame fallback 20; secure AuraContainer
slot lifecycle 12; standalone Extra Button immediate
refresh 10; bar immediate refresh
7; Bars smoke 17,454 plus contract checks. The current full desktop suite passes
166 scripts and 823 Lua syntax files. These model callbacks and frame
ownership, not native pixels or taint. The full desktop manifest is
[modern combat validation](validation/forever-sao-modern-combat-2026-11-06.json).
Native combat appearance, proc clearing, atlas availability, startup memory,
frame time, and Era/Anniversary regression remain pending. An optional
`/run print(FluxEffectGlow.Diagnostics())` readout reports cumulative SAO
screen show/hide, modern frame preparation/show/hide and bar paint counters
without changing settings or taking control of the client.

**FOREVER-SAO-GLOW-01:** When the installed SpellActivationOverlay activates a
spell, its glow must appear on matching Flux action bar, Extra Button and badge
faces. It must clear on deactivation or a changed face, transfer with paging,
and keep the existing animation cadence. Era and Anniversary behavior stays on
their existing renderer.

The installed Forever companion is SpellActivationOverlay 2.8.9 (TOC interface
16001). Its `components/glow.lua` keeps `GlowingSpells` private, calls
`AddGlowNumber`/`RemoveGlow`, and paints its buttons with LibButtonGlow. The
saved `SpellActivationOverlayDB.glow.enabled` is `true` (read only). Flux already
captures the private namespace and distributes membership through `Glow.Want`.
Its paint path tried a native alert template first and could accept a shown
frame without a visible SAO glow. That render result did not match Forever's
installed companion. The correction uses the companion's LibButtonGlow renderer
for Flux faces on Forever, with the existing template/LCG fallback if the library
is unavailable. It moves the LBG owner flag with a transferred overlay and lets
LBG release its own pooled frame on hide. `skipBirth` finishes its intro when a
spell was already active. No SAO globals, protected attributes, settings or
companion files are changed; the established events and refresh cadence remain.

Source identities (SHA-256): installed `SpellActivationOverlay.toc`
`c564aab5f5cfcbc1d37768ef06a392f59bc7666296e9d73e7abfd12bbf54a366`;
installed `components/glow.lua`
`f2fd1e234fdaefe996ba846716fb8fd4a2fcd7ed7fc29680ee5a303227709671`;
installed `libs/LibButtonGlow-1.0/LibButtonGlow-1.0.lua`
`7c34efbb281b95e83d043b16cf17752d315a053d4eda5c777c51e1079d0986e9`.
Main baseline is `a07c449b1783a7bc876943e5909c3573cfec267a`; the dated
external `FluxUI-forever-sao-20261106` checkpoint holds the pre-edit Glow.lua
(SHA-256 `6062c9b9310b2980eb2c0a98e6daef6fe8d2d2a4e2a49cc98c16ea4a01dbdb2c`)
and a verified all-ref history bundle
(SHA-256 `f8ce33384b6f1e982a2a6aa2d303ad7224a5dae8e1a5c4fe9687996b662d5e9d`).
The previously recorded [Forever UI source checkpoint](https://github.com/Gethe/wow-ui-source/commit/eac30af597e5aaa43a60f6675ef5fdcea100375f)
is retained; the installed SAO files above are the integration contract here.

`lua tests/forever_sao_glow.lua` passes 25 checks for private SAO membership,
bar/Extra/badge LBG paint, fade reversal, skipBirth and transfer/hide ownership.
The same fixture fails on the saved pre-edit source at the bar-render assertion.
`lua Bars/_tmp_barsmoke.lua` passes 17,454 refresh checks and its existing
contract/owner checks. Earlier SAO-stage validation: 819 Lua syntax files pass;
160/162 scripts pass. The two failures are `Core/_tmp_coresmoke.lua` meter
centering/gamepad anchor assertions and `tests/native_meter_skin.lua` title/menu
assertions in unrelated in-progress meter work. Neither script loads Glow.lua.
The subsequent combined [meter/native-boundary run](validation/meter-timer-native-boundary-2026-11-06.json)
passes all 162 scripts /819 syntax files with unchanged source hashes.

## Follow-up after the live report

The user reported that the renderer correction still produced no Forever button
glow, using Missile Barrage as the example and requiring the bridge to work for
all spells and procs supported by SAO. Inspection of the installed 2.8.9
`classes/mage.lua` (SHA-256
`07fa4e56891363a619eb8e1827a947d99c7caa9b86c2a97cef2c6eea48ff7afa`)
shows why this example escapes the generic SAO button path: its Forever
`missile_barrage` effect has an overlay for aura 400589 but no `button` entry;
its SoD and Wrath definitions explicitly glow Arcane Missiles. The generic
`AddGlowNumber` hook therefore never receives a Forever Arcane Missiles ID from
that effect. Flux now checks that player aura for Arcane Missiles, including
ranked IDs by spell name, and refreshes on player `UNIT_AURA` only when its
active state changes. SAO's explicit button glows and the client native glow
events/API remain the general route for other supported spells and procs.
Opaque native API results and event spell IDs are guarded before Lua condition
or table use, so they cannot abort a shared glow refresh. The existing icon
identity check and LibButtonGlow paint path continue to own bars, Extra Buttons
and badges.

The pre-edit source and private saved settings are held in the dated external
`FluxUI-forever-sao-followup-20261106` checkpoint, outside AddOns, with verified
main history bundle. Baseline main was `b6cb2c7bdff70e88b3bdca4bc2de7d753352eac9`;
pre-edit Glow.lua SHA-256 is
`02f770f7758b3879838ccd284b2c720daa460c34aec8fa3b4b28406afcb48a99`,
and the bundle SHA-256 is
`924f15fc5a8b50d044a65c301b1b7982d3bbca361781aeecb71aa1920f8c7fcd`.
The saved SAO glow switch was enabled; no saved settings were
changed. The revised focused fixture passes 41 checks, including the missing
Missile Barrage trigger, ranked spell, clearing, secret native value, native
show/hide and generic SAO `AddGlowNumber`. The saved pre-edit source fails the
Missile Barrage assertion. The [follow-up desktop manifest](validation/forever-sao-glow-followup-2026-11-06.json)
passes 162 scripts and 819 Lua syntax files. Real Forever proc rendering and
taint, plus Era/Anniversary regression, are still pending in-client checks.

These desktop fixtures establish code paths, not actual
pixel output or client security. Native checks remain pending: reload Forever
with SAO enabled, trigger a real proc on each face type, compare SAO art on a
stock button, test paging and macro/icon changes, then verify clearing, taint
and frame time. Test Era and Anniversary separately for regression. Leave WoW
in the background and keep the saved profiler and diagnostic roots intact.

## Combat button-glow correction

The user clarified that the missing effect is the glow **around action bar
buttons in combat**, while SAO's large Missile Barrage screen overlay does
appear. That proves SAO received the proc. The first live retest found the
button still dark in combat, then glowing after combat if the proc remained.
SAO caches the overlay functions on its private table during load and calls
`self.ShowAllOverlays`/`self.HideOverlays`; the first hook on their global
names missed those calls. Flux now hooks the table methods after their
original calls, using the resolved 400589 screen activation as the
combat-readable signal for Arcane Missiles. The direct aura query remains an
initial-state fallback. The hooks filter to source-backed missing button
associations and refresh the shared bar, Extra Button and badge owners only on
state changes. SAO's existing `AddGlowNumber` and native glow paths remain the
general path for its other supported button procs.

The user reloaded and retested the private-table candidate: the button still
glowed only after combat and remained lit after the proc ended. Flux now also
hooks `SpellActivationOverlay_ShowOverlay`, which the cached SAO method looks
up globally for each screen overlay, and
`SpellActivationOverlayTexture_TerminateOverlay`, which SAO's fade-out callback
calls. This lower-level pair does not depend on capturing SAO's private table.
When that table is available, `Glow.Want` checks SAO's live `overlaysInUse`
list and animation-out state, so a stale show marker cannot hold the button
glow after the screen overlay fades. The direct aura query remains an
initial-state fallback when no SAO overlay signal was seen. The
[five-check low-level fixture](../tests/forever_sao_combat_signal.lua) models a
restricted combat aura with no private SAO namespace: show lights the button,
and termination clears it. The saved pre-edit source fails its show assertion.

The user retested the low-level signal candidate: the action button still
began glowing only after combat ended. The remaining combat boundary was the
renderer. Flux's secure button host code already requires child frames and
anchors to exist before combat (`Bars/Hosts.lua` charge edge). LBG's first
`ShowOverlayGlow` creates, parents and anchors its animation frame; doing
that on a Flux secure action button during combat can fail while the proc
state remains active. Flux now prepares the Classic-style LBG frame in
`Glow.InstallSAO` while out of combat, hides it in the same startup tick,
and retains it through fade-out. Combat show/hide only plays its existing
animations. Prepared frames stay with their button during paging; the
destination uses its own frame and skips the birth animation. The shared
LBG post-hook ignores the one-time preparation, so startup does not schedule
a full glow refresh per button. The 53-check fixture models a secure button
whose LBG create/parent call fails in combat and verifies that its prepared
frame can show, hide and show again without calling that path then. This
adds one hidden LBG frame per Forever Flux button; native startup memory,
frame time and in-combat pixels remain unmeasured.

Standalone Extra Buttons also lacked a `Glow.OnChange` subscription, so a
proc could wait for a later generic refresh. EBS now requests `ebs.glow` on
the existing eval lane whenever the shared glow state changes; bar-hosted
badges stay under Bars.Effects ownership. The focused 8-check EBS fixture
models an in-combat proc refresh and verifies that repeat startup does not
duplicate the listener. The saved HEAD EBS.Init source fails its missing-listener
assertion.

Combat spell texture APIs may yield unreadable values. `FaceShowsSpell` now
returns an unknown result for these rather than a false icon mismatch. A known
spell ID remains eligible to glow; a nil-ID face still needs a readable icon
match before retaining a previous glow. The same guard is applied to bar,
badge and standalone Extra Button paint. This preserves the macro/icon-change
clearance when an actual different icon is readable.

The Forever paint path still calls LibButtonGlow with the same
`IconAlert`/`IconAlertAnts` artwork and 18 animation setup calls as the installed
Classic Era SAO library. The installed Forever SAO
`SpellActivationOverlay.lua` has SHA-256
`72cb648d96ae50b1860643820d4262b1a5c9fe784f35930b49e83fdd23c6ebcc`.
Main baseline remained `b6cb2c7bdff70e88b3bdca4bc2de7d753352eac9`;
the dated external `FluxUI-forever-combat-glow-20261106` checkpoint holds the
pre-edit Glow.lua (SHA-256
`0dcfcf1e2a2a614919dccb76656ec24046f72780138b2c7159752559f2d0e2e7`),
private SAO settings, HEAD copies of the other changed sources, and a verified
all-ref history bundle (SHA-256
`d2abedc9994ff302bb6123afa9b8f18a7d8bdc8171082c6a28d20a2104138a60`)
outside AddOns. No saved settings or SAO files changed.
The HEAD source baselines in that checkpoint are Bars/Effects.lua SHA-256
`167c272993fd6b6b3e1a092c5266a1b88320d2ddaa26c8ec2e9139ab7bb80c42`,
ExtraButtonSystem/Engine/Paint.lua SHA-256
`d6e089f508c97bba4c15fe53c3b1acc317085d7ade3d46d7828ebb54c87bab90`,
and ExtraButtonSystem/Init.lua SHA-256
`5272a73080d63f3584055c25f469733a786ec31b1b07ef648bd85a5544822a5c`.

The 53-check fixture covers SAO screen show/hide in a modeled combat state,
generic SAO button activation, unknown versus different icons, LBG paint on
bar/Extra/badge and glow cleanup. The
[combat desktop manifest](validation/forever-sao-combat-glow-2026-11-06.json)
passes 164/164 scripts and 821/821 Lua syntax files in the current combined
tree. An intermediate run had two failures in concurrently edited meter tests;
those were resolved before this final run and did not load the glow service.
The saved pre-edit Glow.lua fails
the unreadable-combat-icon assertion. The verified Forever process/window was PID 37088,
`F:\World of Warcraft\_forever_\Wow.exe`, window title `World of Warcraft`.
That process started before this file change; no input, focus, reload or native
combat check was performed by Codex. The user reloaded and tested the earlier
global-hook candidate, reporting no glow until combat ended. The second
private-table candidate also failed and left stale glow after the proc. The
low-level signal candidate also failed to show in combat; the prepared-frame
renderer candidate still needs a fresh in-client retest;
appearance, taint, frame time and Era/Anniversary regression remain pending.
The user subsequently retested the prepared-frame candidate after reload and
again reported that the button glowed only after combat. The Retail/direct
callback candidate described at the top of this document received the same
post-combat-only report. The first in-combat diagnostic command called its
readout but failed inside the readout before printing counters. The readout was
simplified to plain counters and a fresh reload/read is pending. The disk copy
of Glow.lua matches the installed Forever copy byte-for-byte; the TOC lists it.
