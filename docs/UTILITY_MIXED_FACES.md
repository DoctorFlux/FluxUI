# Utility spell/item modifier faces — 7 November 2026

7 November modifier key routing (UTL-CHORD-13): user confirms no-mod works
but modifiers fail. Ordinary utility key overrides now carry their triggering
chord as a distinct virtual button. Wildcard-modifier native payloads and
release types preserve that selection independently of live modifier queries
during dispatch. Click wrappers retain the virtual button and CVar edge;
cached nonwrap keyers inherit its fields. Mouseover uses the same encoded
prefix and retains its native modifier gate. Physical mouse attributes stay
prepared for each chord. Bindings now install after action preparation in
the real slot-update lifecycle; clearing removes all encoded actions.
A masked-dispatch fixture reproduces the prior normal-action fallback;
the engine masking mechanism itself is unobserved. Five baselines fail and
five candidates pass41255 checks; four mutations rejected.12634 face/count/CD,
1473 VFX and4973 mouseover checks PASS; existing320-transition paint budget
unchanged. No new frame/event/timer/ticker/poll. Actual new modifier input/
mouseover/combat/taint/pixels/FPS acceptance remains NOT RUN.
Full run:894 syntax PASS;229/230 scripts PASS. The sole failure is the
unrelated portrait_camera.lua fixture missing GetFramePublicDimensions;
concurrent portrait work is preserved. Utility source owners/tests remain
at their recorded hashes; all five installed copies match via the existing
mirror. Native modifier acceptance is still pending.
[Evidence](validation/utility-chord-routing-2026-11-07.json).

7 November utility execution rework (UTL-EXEC-11; UTL-MO-12): user rejects the
ranked-spell attempt as still nonfunctional. Ordinary spell/item utilities now
prepare native secure action attributes for every exact modifier chord before
combat, removing macro-text/delegate execution. Saved IDs directly drive
icon/count/cooldown/VFX; rank names are used only as native spell cast tokens.
Both keys, base/preferred fallback, combat release, clearing and cursor drops
are covered; special macro/pet/mount/toy/outfit assignments retain their route.
Mouseover follows the existing setting/modifier through shared click-time
target wrappers, using the selected action help/harm gate and clearing unit
afterward. Range follows the same reaction during existing hover cadence.
Forever target wrappers require the existing repaired-VM probe; failed probe
or partial installation retains normal native targeting and is not a
mouseover pass. Existing combat setting deferral remains. No new event,
timer, ticker, OnUpdate or hover driver; existing320-transition paint budget
is unchanged.26962 input,10234 face/count/CD,1033 VFX and4973 mouseover checks
PASS; five old-contract rejections/five candidates and three mutations.
Full222 scripts/885 syntax PASS; tested Lua corpus unchanged; all five installed
client copies match the six runtime owners through the existing mirror.
Actual native casts, mouseover probe, combat/taint/visual/FPS remain NOT RUN.
[Evidence](validation/utility-native-actions-2026-11-07.json).

7 November utility ranked spells (UTL-RANK-10): user reports Arcane Intellect
and other utility spells fail. Read-only saved assignments include Arcane
Intellect(Rank 2). Native CAST prechecks the full ranked string; USE sends a
nonitem string directly to the protected cast function. Ranked/subtext utility
spells now use USE, retaining their exact rank; bare spells retain CAST priority
over same-name items. Mixed ranked/bare slots keep a single stable hidden macro
with mutually exclusive exact-chord lines. Item modifiers, both keys, release
and special assignments remain. No new events/timers/frames/polling or combat
action writes. Five baseline rejections and five candidate15491-check passes
exercise a ranked-lookup miss through five dated native dispatcher/handler
sources. This is a desktop failure model, not confirmation of the native root
cause or spell cast success. Full222 scripts/885 syntax PASS; corpus unchanged;
all five manager copies match. Existing6894 modifier/488 VFX checks PASS.
Native reload/target/mouseover/input/combat/taint/
visual/FPS acceptance is pending. [Evidence](validation/utility-ranked-spells-2026-11-07.json).

7 November utility item cooldown correction (UTL-CD-09): utility slots no longer
claim consumable buff durations as cooldowns. Clear already latched aura fields
before cooldown dispatch, including combat modifier release back to a spell.
The dedicated consumables button keeps its supplied aura countdown; existing
nonutility potion and food/water policy remains. No new timers, events, frames,
polling or protected action writes. Five paired desktop runs reproduce 30
baseline failures and pass 6894 candidate checks each; utility aura lookups
drop from five to zero per run. Full validation: 222 scripts and 885 Lua syntax
files PASS; post-run corpus unchanged. Native cooldown/input/combat/taint/visual/FPS
acceptance remains pending. [Evidence](validation/utility-item-cooldown-2026-11-07.json).

7 November reported keybind failure, UTL-MACRO-08: the user confirms that a
normal spell plus Shift item still attempted the normal spell from its keybind.
That rejects earlier native-input assumptions; preceding desktop pass counts
retain their historical scope. Read-only on-disk assignments confirm the Study
spell, Shift water item and a native utility key command. No settings were changed.

Plain spell/item utility slots now execute a single compact conditional macro.
Explicit modifier clauses come first, followed by the existing normal/preferred
mirror fallback. Mixed spell/item clauses share one /cast command with explicit
item:ID tokens, using Blizzard's actual CAST handler's item fallback. Pure item
slots retain /use. The full conditional body is stored once on the existing
hidden delegate, with one left-button type/release action; no modifier-specific
execution attributes select an unmodified branch. The same macro body drives
icon, count, cooldown and VFX identity. Special named macro, outfit and pet paths
remain. Right/unmapped buttons remain inert.

The no-wrap key path also had a distinct timing gap: visible hosts register
AnyUp, so releasing Shift before the action key could select the normal action.
A compiled macro alone reproduces that failure in the source replay. Nonwrap
utility keys now follow the existing action-bar AnyDown parent-inheritance
pattern: a cached hidden SecureActionButton inherits the host's prepared native
attributes, samples the held modifier on key-down and ignores key-up. At most
four small keyers exist, created only for bound slots outside combat and reused.
Mouse cadence remains unchanged; wrap clients retain their CVar input policy.
No new frame event handler, timer, ticker, poll or modifier-time action rebuild.

[The strengthened input regression](../tests/utility_secure_input.lua) now loads
both actual SecureTemplates and actual CAST/USE slash handlers from five dated
local source trees. It checks 11114 cases including both keys, all modifier
chords, combat, both CVar choices, the saved spell/Shift-item setup, cold item
metadata without casting the normal spell, and releasing Shift before key-up.
The old attribute contract is rejected in five baseline runs; five candidates
pass. A preserved intermediate source isolates the AnyUp timing failure. Three
broken key-route/macro-command/registration mutations are rejected. Native
hardware, engine taint and actual item-use permission remain untested; the
replay establishes command selection, not native gameplay success.

The current modifier/count regression passes 6,609 checks and VFX state checks
pass 488; the smaller totals reflect fewer assignment attribute writes. The
320-transition count budget remains 640 baseline to 120 candidate updates,
with zero duplicate-chord paints. Existing transmog/pet controls pass. Source,
external recovery, raw pairs and exact local native source hashes are recorded
in [macro/key evidence](validation/utility-conditional-macro-key-2026-11-07.json). Full222
scripts/885 Lua syntax PASS with unchanged tested corpus; all five installed
manager copies match through the existing mirror. No manual client copy.
Actual native reload/input/combat/taint/FPS remains pending. No foreground,
mouse, keyboard, clipboard, game, WTF or profiler control was taken.


7 November VFX follow-up, UTL-VFX-07: cast fill, channels, empower, targeting
reticles, finish bursts, interrupts and proc glows follow the selected utility
spell/item when modifiers are held or released. Macro translation previously
refreshed icon/count/cooldown/glow but did not settle standalone utility cast
paint: those widgets have no strip column for FollowColumn. Cast.FollowExtra
now uses the registered current use-spell identity and the existing live cast,
reticle, finish and interrupt windows. It clears departed paint/stamps and
removes only that player widget from event-owner bags, preventing later
STOP/interrupt events from repainting its replacement action. Returning matching
faces use existing SyncCast/reticle/burst/interrupt helpers. Strip/pet owners
are excluded; the pre-DF VFX setting remains authoritative.

The macro paint hook invokes this settle only when a utility's selected kind,
spell or item changes. Repeated identical modifier events and unrelated macro
context paints add no cast settle. Existing bag/charge/metadata and shared proc
callbacks remain. Known utility item use-spells can show their proc even when
the item icon differs from the spell icon; unresolved/passive items clear old
spell glow. Clearing a utility drops cast and proc paint, including the case
where a hidden icon retains its former texture. Other macro/item policies
remain unchanged.

[The regression](../tests/utility_modifier_vfx.lua) loads the actual Modifier
bus, manager, translator, painter and Cast owner, with modeled native unit
information and Overlay/Glow draw methods. It passes 578 checks across five
client models, covering cast/channel/empower/targeting/finish/interrupt/proc,
spell-to-item-to-spell, items sharing a spell, items without a use spell,
expiry, clear, VFX off, independent strip/pet owners and 50 repeated cycles.
Five baseline runs reject the stale cast paint and five candidates pass. Four
broken cast/owner/proc/icon-filter mutations are rejected. The prior 7,329
modifier/count and 11,015 native-source input checks pass unchanged, including
the scoped count-work budgets. No extra frame/event/timer/ticker/poll, combat
secure write or saved setting is added. State checks do not certify actual
client pixels, animations, secret values, combat/taint or FPS. Native checks
remain pending, with no foreground/input control taken.
[Exact sources, recovery and raw paired evidence](validation/utility-modifier-vfx-2026-11-07.json). Full
222 scripts/885 syntax PASS with unchanged tested corpus; all 15 installed
runtime copies match through the existing mirror. No manual sync performed.


7 November combat-release and optimization follow-up, UTL-REL-05 and
UTL-PERF-06: existing native modifier attributes already select the normal action
when the modifier is released, including combat. Tests now verify the normal
action before the visual callback runs, and drive the actual shared Modifier
bus to verify kind, ID, icon and count after every release. Both spell/item
directions, partial multi-key release, charges/reagents/stacks changed while
held, depleted zero, authoritative blank digits and 50 repeated cycles are
covered. No protected attributes, bindings, frames or timers are created or
rewritten by these combat modifier transitions.

The utility callback formerly walked slots in three passes and repainted count,
checked and usability after TranslateMacro had already painted them. It now
uses one loop: changed plain spell/item faces get the existing translator's
complete paint once; unchanged selected fallback faces do no visual work. A
single transient chord memo skips duplicate events for the same effective chord.
The special pet/outfit ownership/cleanup path remains, as do independent bag,
charge and metadata events. No new event/frame/timer/ticker owner or polling.

Five matched desktop measurements using the same 320 modifier transitions
reduce icon updates 320 to 120, count updates 640 to 120, usability updates 660
to 140 and checked updates 640 to 120. Redundant unchanged-chord paints fall
from 1,120 to zero. The remaining extra usability calls belong to the existing
cooldown readiness transition, not a utility repaint. These are utility-callback
work counts; other shared context subscribers and actual native CPU/FPS are
outside that measurement. The old manager passes functional return-to-base
checks but fails the new work budgets. Two deliberately broken release/duplicate
paint mutations fail. The actual-bus regression passes 7,329 checks and the
five-source native-input replay passes 11,015 checks. Exact pairs, identities,
recovery and pending native checks are in
[release evidence](validation/utility-modifier-release-2026-11-07.json). Full217 scripts/880
syntax PASS at snapshot. A later unrelated native-bank test edit causes global
corpus drift and two pending bank-test inventory/verification issues in the docs
check. Utility runtime remains at its tested hash; preserve newer bank work.
All five installed manager copies match
through the existing mirror. No additional client copy was performed.


7 November execution follow-up, UTL-USE-04: the initial tests used a substitute
SetAction and checked compiled text, so they missed that modifier attributes
bypassed EBS's hidden macro delegate. Exact actions now remain on that existing
delegate; the visible host uses type/typerelease=click and forwards LeftButton.
Its bare macro body is cleared so neither an unmapped virtual button nor a
right-click can execute the long visual compiler body. Native protected
selection uses the held chord at the hardware event; no action rewrites are
needed when modifiers change in combat.

Utility key overrides now use the actual LeftButton on clients without the
KeyBind remap, as the existing consumable binding service does. Each explicitly
assigned modifier is bound for both keys using the existing chord normalizer.
This covers item modifiers that have no spell-strip implicit mapping, and
retains unrelated unassigned chords. Empty/replaced slots clear stale delegated
attributes. Saved assignments, commands, appearance and scheduling remain.

[The new execution regression](../tests/utility_secure_input.lua) loads actual
Blizzard SecureTemplates from all five recorded local trees, plus production
Click, SecurePool, Action, chord normalization and the utility manager. It
executes 8,135 checks for mouse/primary/secondary keys, eight chords, both
press/release CVar choices, both spell/item directions and combat/deferred
edits. Clearing and modifier-only mirrors are covered. Five old-manager runs
fail and five candidates pass; three broken-route mutations are rejected.
The former bars source fixture forbade LeftButton on every client and is
corrected to the capability contract. Native macro execution, access checks,
hardware and taint are modeled; no actual-game combat acceptance is claimed.
[Execution evidence](validation/utility-secure-input-2026-11-07.json) preserves
exact source identities, external recovery and the raw desktop pairs. Final full run passes
217 scripts and 880 syntax files with unchanged corpus at audit; all five
installed manager copies match through the existing mirror.


The user reported utility slots whose normal action is a spell and modifier
action is an item (and the reverse), with inconsistent icons and counts.
Existing assignment data and the four-slot layout remain unchanged. This is
a correction to the accepted UI; no new controls or artwork were introduced.

| Requirement | Implementation | Desktop evidence | Native acceptance |
|---|---|---|---|
| UTL-MIX-01: selected action, icon, tooltip, cooldown and range agree | Exact eight-chord compilation; unassigned combinations use the existing preferred-base mirror; canonical native modifier attributes prepared outside combat | Both directions, all assigned chords, fallback, modifier-only mirror, held/released modifiers and one compiled command per selection | Pending click/key/hover/pixels on every installed client |
| UTL-MIX-02: item stacks/charges and spell reagents/charges stay live | Shared EBS count painter; no utility forced-count latch; existing bag listener refreshes visual counts during combat | Stack/reagent changes, depleted zero, unique charged item, charge events, authoritative blank display, opaque display write-through | Pending actual bags/reagents/charge recharge and secret values |
| UTL-MIX-03: preserve assignments and secure ownership | No SavedVariables/schema/default/layout/command change; existing manager and spell-count service updated; protected action edits still defer | Existing pet and transmog regressions plus full suite; no protected writes during modeled combat | Pending native combat input/taint and reload persistence |

Previously the generated body had separate `/cast` and `/use` lines with an
unconditional base action. A modifier item could therefore retain the base
spell as its displayed face and attempt both commands. Single modifiers also
matched unassigned multi-key combinations, while the utility count resolver
selected its base fallback. Every chord now has exclusive conditions, and
every native click attribute contains only the selected action. Canonical
combination prefixes follow Blizzard's existing secure attribute contract.
The full conditional body supplies visual parsing; individual click bodies
stay short. Existing mouseover clauses and rank-specific spell tokens remain.

Utility slots also had their own count implementation: spell counts were
latched, and only stackable items qualified for item counts. That masked
charged single items and allowed old digits to survive shared paint events.
The optional Classic reagent-library fallback remains in the shared spell
count service when native count APIs are unavailable. They now use the same spell/item identities and live count policy as other
EBS buttons. Native display strings, including an authoritative empty string,
retain the shared secret-safe setter. No new frame, event, recurring timer,
ticker or listener is introduced. Existing modifier, inventory and coalesced
charge callbacks retain their scheduling. Inventory callbacks update visuals
in combat without rewriting actions. Assignment work prepares eight bounded
click bodies outside combat; modifier changes do not rebuild them.

Targets preserve the repository's installed Retail, Forever, Mists/Classic,
Era and Anniversary coverage. GitHub lookup was unavailable (web access failed;
shell DNS denied), so no fresh upstream SHA is claimed. The existing local
FrameXML versions/hashes and packaged source-pinned spell contracts are
recorded in [the evidence](validation/utility-mixed-faces-2026-11-07.json).
Packaged source declarations are not runtime certification. No reference
implementation was copied or external installation manually synchronized.

The external dated checkpoint preserves 1,739 source files and verified Git
history at `75cf2bcba83adfea0501934f4eeb2a980c46fdf8`; available settings were
inspected as metadata (121 files), and the previous external settings archive
was hash-verified. No live WTF/profiler settings or game input was changed.
Exact checkpoint, baseline/candidate hashes and installed-copy hashes are in
the evidence. All five installed manager copies match via the existing mirror.

[The production-code regression](../tests/utility_mixed_faces.lua) passes
3,269 checks across five client models. Five alternating fresh-process pairs
reject the old manager (720 failures each) and pass the candidate. Three
mutations are rejected: nonexclusive macro compilation, an incorrect combined
modifier prefix and frozen combat inventory counts. The
[full validation](validation/utility-mixed-faces-full-2026-11-07.json) passes
215 scripts and 878 Lua syntax files at the tested snapshot. A subsequent
unrelated edit to `UnitFrames/FluxUnitFrames_Party.lua` caused global corpus
drift; both utility runtime owners remain at their tested hashes. Preserve the
newer party work; this is not a whole-current-tree acceptance. Desktop process timings include fixture/assertion work;
they establish neither native latency nor FPS.

The established background-safe native route could not run because this
session exposes no Witchcraft client tool. No foreground/input control was
taken. After reload, check a reagent spell with a stack item on Shift, then
reverse them; also check a multi-charge spell and a single charged item.
Compare icon, tooltip, cooldown, range tint and digits while holding/releasing
each modifier, including unassigned combinations. Consume items/reagents and
spend/recharge spell charges during combat, then check restored faces and
saved assignments after reload. Native pixels, secure input, taint, genuine
secret values, actual builds and matched frame-time/FPS remain pending.

Final documentation validation is pending five issues from newer concurrent
party source/test edits (inventory, interfaces view and verification); the
checker reported no utility source errors and made no edits.
