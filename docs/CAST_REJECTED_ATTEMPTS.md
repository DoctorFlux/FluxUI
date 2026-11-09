# Rejected casts do not display a cast bar — 9 November 2026

CAST-REJECTED-20261109: a cooldown or otherwise rejected spell attempt must not
summon the shared unit cast bar. Valid casts retain their normal progress,
completion and interruption appearance, timings and settings on all five
existing clients. No visual redesign; existing UIForever preference retained.

The prior event handler sent FAILED/INTERRUPTED directly to HandleInterrupt,
whose normal behavior includes Show(). Its routed GUID fallback intentionally
accepts missing/restricted identity, so an idle rejection could enter that path.
STOP/channel/empower terminal events could similarly finish or interrupt an
inactive bar. This also let repeated failures replace post-cast or custom-timer
feedback. The production regression reproduces an idle FAILED showing the bar.

[Shared event handler](../UnitFrames/FluxCastBar.lua) now accepts these terminal
events only while its own casting/channeling state is active and the bar is
shown. It does not query UnitCastingInfo at termination: native cast data may
already have cleared for a real interruption. Existing secret-safe identity,
unit routing, channel/empower behavior and finish/interrupt timing stay intact.
No polling, frames, callbacks, timers, hooks, CVars or saved data were added.

Fresh pinned Gethe CastingBarMixin:HandleInterruptOrSpellFailed likewise requires
a shown, active matching cast outside empowered interruption. Generated FAILED
payloads are synchronous and carry unit/castGUID/spellID/castBarID; modern fields
may be restricted. [Exact five-client source and event records](validation/cast-rejected-upstream-2026-11-09.json).
Primary builds: Retail12.1.5/70783, Forever1.60.1/70862, Classic5.5.4/70631,
existing Era1.15.9/70576 and Anniversary2.5.6/70577. Reference files remained
read-only and no native source was copied into the addon.

Before runtime editing, verified external `cast-rejected-checkpoint-20261109T104735Z`
preserved2,364 actual files and all-ref history; ZIP CRC and bundle verification
passed.125 on-disk settings metadata entries were read, with no settings writes
or claim to unsaved client memory. [Checkpoint](validation/cast-rejected-checkpoint-2026-11-09.json).
Preserved prior menu-input, nameplate and other main work; no commit/push.

[Regression](../tests/castbar_rejected_cast.lua) runs the actual CastStart,
custom/reset and OnEvent handlers via the established five-client fixture.
24,775 checks cover player/target/focus/pet/party, idle/reset/success/interrupt/
hidden/custom states, repeated public/missing/opaque terminal identities, real
failure/interruption after native cast data clears, replacement casts, unit
isolation, empty START, channel completion and empowered interruption. Rejected
terminal events do not allocate frames/textures, repaint bar ranges, release the
swing slot or alter existing feedback. Five alternating baseline/candidate pairs
reproduce/pass; three harmful active-state/visibility/channel controls reject.
Party lifecycle215 and timer379 checks also pass.
[Comparison and exact source hashes](validation/cast-rejected-comparison-2026-11-09.json).
Full267-script/934-syntax validation PASS; no source drift. The initial all-pass
run was superseded after concurrent unrelated unit-frame/test changes.
[Full validation](validation/cast-rejected-full-2026-11-09.json).

All five installed runtime copies match through the existing mirror; no manual
sync or reload ran. [Copy verification](validation/cast-rejected-client-copies-2026-11-09.json).
No connected Witchcraft/UIForever tool is available; no game input, foreground,
settings, profiler or diagnostic-root changes. Desktop models establish only
the exercised lifecycle, not native events, secure VM/taint, pixels or performance.

Native checks pending after an out-of-combat `/reload`: repeat cooldown, range,
resource and invalid-target rejections while idle and after a successful cast;
the bar must stay absent or retain its existing finish/fade without restarting.
Check a genuine failed/interrupted cast, a completed channel and empowered cast,
plus normal flight/custom timers and party/target/focus behavior on each build.
No CPU/FPS/latency improvement is claimed.
