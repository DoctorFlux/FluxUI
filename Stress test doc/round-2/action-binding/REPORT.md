# Round 2: action bars, bindings and secure integration

**Audit only. No runtime, test, TOC, settings or installed skill was edited.**
The prior applied fixes are the baseline. The current main identity is
`1fd463f4de4bbff659f4e402c6f31138c49765b4`, with the independent edits recorded by
the root's [fresh baseline](../baseline.json). This report adds six finding
groups, separating ordinary modeled paths, reentrant contracts and native-only
conditions. None is a newly observed native taint error.

The highest-priority new result is **R2-BIND-06**: distinct punctuation chords can
share one secure pool frame and therefore the same macro payload. The earlier
passing suite does not exercise that identity collision.

## Reproductions and evidence

Run from the repository root:

```powershell
lua 'Stress test doc/round-2/action-binding/replay.lua.txt'
```

A passing replay means the stated defects reproduced. Three runs each pass
**340 assertions** and produce **35 observations** across five client models
(Era, Anniversary, progression, live, Forever), including 10,000 alternating
modifier/key presses per replay. [Raw results](results.json) preserve stdout,
source identities and the distinction between reproductions and positive
controls. All **73** inventoried owner Lua files remain byte-for-byte unchanged
between [before](source-before.json) and [after](source-after.json).

### R2-BIND-06 — different punctuation chords share a secure macro button

**Severity: high functional correctness. Evidence: production pipeline fragment
and complete pool/chord modules; native dispatch acceptance pending.**

`Binding/Core/Apply.lua:1659` derives the frame name by replacing every non-word
byte with `_`. `ALT-=` and `ALT-/` both become `FluxBinding3Btn_ALT__`; their hover
siblings both become the same `_HC` name. The full `SecurePool.Acquire` returns
the same physical button for these identical names. The world and hover writers
at `Apply.lua:1743` and `:1770` then assign different requested bodies to it.

The replay executes the actual `ApplyFreeChords` block with complete production
`SecurePool.lua` and `ChordMap.lua`. It verifies both chords route as free keys,
both override records name one world button, and the final world payload is
identical for both. Hover routing contains two distinct desired bodies but names
one `_HC` button. Reapplying the same map preserves the collided world payload;
removing the chord whose body won can leave its surviving peer using that removed
body. Alphanumeric `Q` and `E` controls remain independent. Punctuation keys are
present in the addon's own `Binding/UI/KeyVisualizer/KeyLayouts.lua`.

**Future proposal:** use a stable, bijective encoding of the complete normalized
chord when naming pool frames. Escape the escape marker itself; a simple lossy
replacement or truncated hash recreates the problem. Preserve the world/hover
sibling relationship, existing pool reuse, override priorities, current macro
bodies and OOC application contract. Reconcile old named proxies through their
existing retirement path when changing the generated names.

**Regression gates:** pairwise uniqueness over letters, digits, punctuation,
modifier combinations and supported locale bytes; world/hover payload selection
for each key; reversed insertion order; reapply; removing either peer; profile
switch; pool reuse; both click edges/CVar modes; native input confirmation.

### R2-BIND-02 — a captured minus key cannot round-trip through ChordMap

**Severity: medium functional correctness. Evidence: actual capture function and
complete production chord module.**

`Binding/UI/Editor/Widgets/FluxKeyCapture.lua:16` emits `-` or `SHIFT--` for the
literal minus key. `Binding/Core/ChordMap.lua:40` tokenizes with `[^%-]+` at `:46`.
The bare key yields no token and normalizes to empty. `SHIFT--` yields base key
`SHIFT`, with no Shift modifier. The column cache therefore cannot locate a
column whose binding is `-`; a normal `SHIFT-Q` control locates column 1.
Ordinary bar overrides use raw GetBindingKey strings in `Bars.Clicks`; the
reproduced failure scope here is Binding capture, parsing and routing.

This is an incompatibility between two production functions, independent of
whether a particular native keyboard layout currently uses that key.

**Future proposal:** consume recognized modifier prefixes and preserve the
remaining base key verbatim, including the literal delimiter. Keep existing
modifier order/canonicalization and supported punctuation/locale keys.

**Regression gates:** capture → normalize → parse → route round-trips for `-`,
all modifier combinations, `=`, `/`, mouse/wheel keys, normal letters, native
GetBindingKey results and both inherited/manual editor bindings. Keep modified
bar fallback semantics and free-chord precedence intact.

### R2-BIND-01 — switching held columns abandons the earlier visual owner

**Severity: medium appearance/lifecycle correctness. Evidence: complete production
PushPress/ChordMap replay with real press hooks.**

`Binding/Core/PushPress.lua:334` starts a new hold by calling `StopHoldPoll()` at
`:354`. That helper (`:281`) discards the previous frame/key/chord without
restoring its visual. Only the current hold is later restored by
`FinishHoldPoll()`. The strip's hook at `:536` tracks down presses, with no
matching strip PostClick release cleanup for the abandoned hold.

The replay presses Q/column 1, then E/column 2 before releasing Q. Releasing both
and waiting beyond the two-second control interval restores column 2 but leaves
column 1 PUSHED with the 0.62 tint. A single-key control restores correctly, and
explicit `ClearAll()` recovers the orphan. A 2,000-press alternating Shift/Ctrl
burst per client reproduces the same final orphan without allocating extra
poller frames. Other/native painters can subsequently change the visible result;
the test establishes the missing owned release, not permanent native pixels.

That synthetic same-frame burst also retains 2,000 zero-delay reassert callbacks.
This is an operation-count observation, not evidence of normal client latency.

**Future proposal:** keep the existing poller but retain bounded ownership of
active columns/physical keys until each is released or reaches its safety cap.
Do not merely clear an earlier column while its key is still held if simultaneous
held-key feedback must remain. Coalesce the next-frame reassert kick while
retaining immediate press paint and the original post-native timing.

**Regression gates:** overlapping Q/E and multiple keys sharing a column;
press/release in both orders; repeat; modifier flips; mouse/wheel/hover paths;
page/profile clear; hide/disable; original grace and safety deadlines; correct
public hue restore; bounded frames, timers and active records.

### R2-BIND-03 — a reentrant supersession loses the newest snapshot owner

**Severity: medium callback/API correctness. Evidence: complete production
Binding.Respec replay; requires a reentrant completion callback.**

`Binding/Respec.lua:467` finishes a queued request before installing the incoming
one. `FinishPending` (`:324`) clears pending state and invokes the superseded
callback synchronously. If A's callback queues C while an outer B call is
superseding A, C is installed, then B overwrites it at `:471`/`:472`.

On regen the replay applies B and completes B. C's document is not installed and
C's callback is never settled. A receives its expected SUPERSEDED notification.
Existing ordinary detach/cancel/supersede controls still pass. A normal UI path
that automatically issues this reentrant request was not established; the public
callback contract is the reproduced boundary.

**Future proposal:** give the incoming request an ownership token before invoking
the old completion, recheck that token afterward, and settle a request that lost
ownership. Regen completion must target the exact detached request, rather than
whatever happens to occupy mutable pending fields later. Reuse the local request
identity pattern already used by the action-bar restore owner.

**Regression gates:** A → B with A's callback submitting C; cancel callbacks that
submit replacements; reentry during the restore callback path; duplicate regen;
exactly-once completion; newest-owner survival; detached input snapshots; sticky
rows/UID/order preservation; original delayed successful completion.

### R2-BIND-04 — press tint performs arithmetic on unvalidated native RGB

**Severity: medium conditional runtime-error risk. Evidence: production function
replay plus fresh four-client declarations; actual affected icon unconfirmed.**

`Binding/Core/PushPress.lua:205` reads `icon:GetVertexColor()`, stores the returned
RGB and marks the icon dimmed, then multiplies all three components at `:208`.
The actual press hook raises an arithmetic error for a getter returning nothing
or an opaque arithmetic-denying surrogate. The button state has already changed
to PUSHED. There is no claim that the native action itself was blocked.

Fresh pinned `SimpleRegionAPIDocumentation.lua:66` declares `MayReturnNothing`
for GetVertexColor on all four requested clients. Live/Forever additionally
declare secret returns for VertexColor and Alpha aspects; Era/Anniversary omit
that annotation. The [provenance record](api-provenance.json) identifies all four
remote blobs, with the Forever local normalized blob matched exactly. Opaque
inputs in Classic replay test generic Lua handling and do not establish native
Classic secret values. Native exposure on these particular addon icons remains
unconfirmed.

**Future proposal:** retain known public presentation tint in its existing owner
and never cache secret RGB as a supposedly usable last value. For unreadable
native tint, investigate an owned darkening overlay that achieves the same push
appearance without reading/multiplying the restricted color. Preserve range and
usability hues and precreate any required artwork OOC; do not conceal the getter
error with a broad pcall or replace unknown tint with arbitrary white/black.

**Regression gates:** colored public RGB and exact 0.62 dim/restore; no returned
values; denied/opaque values; native Alpha/VertexColor restriction transitions;
range/usability repaint during a hold; release after a failed press paint;
no protected creation in combat; native visual comparison before accepting an
overlay equivalent.

### R2-BIND-05 — deferred slot-program removal omits the protected clear

**Severity: low currently demonstrated reach; medium if this public combat path
is used. Evidence: complete production SlotProgram API replay.**

`Bars/SlotProgram.lua:327` updates the logical tables immediately. In combat it
queues one shared callback whose loop at `:356` visits only remaining programs.
An entry removed with `Apply(slot, false)` is absent from that loop. Its old
`flux-p-<slot>` and live macro type therefore remain on the widget after regen,
while `Get(slot)` reports nil. Repeating the clear short-circuits because the
logical state is already nil. An ordinary changed-then-cleared OOC control works.

The current main Binding apply paths guard against combat before calling this
API. No ordinary current caller reaching the failing combat branch was proved.
This is a latent supported-branch defect, not a demonstrated normal-play ghost
cast or a newly observed taint error.

**Future proposal:** retain a dirty-slot set including tombstones and reconcile
each touched slot against the latest logical model on regen. Preserve full
initialization/reconciliation for new hosts, hidden delegate retirement and
modifier click-set restamping. Keep one coalesced existing combat wake.

**Regression gates:** combat add/update/remove; removing the last entry; A→nil→B
before regen; repeated identical clear; hidden and surface modes; current host
replacement; cancellation/profile changes; no combat protected writes; final
nomod/Shift/Ctrl click attributes agree with the logical model.

## Coverage, prior fixes and native limits

[Coverage matrix](coverage.csv) distinguishes deep inspection, executed modules
and inventory-only surfaces. The six reproductions load complete ChordMap,
PushPress, SecurePool, Binding.Respec and SlotProgram modules; GenerateChord and
ApplyFreeChords are actual named production fragments with narrow dependencies.
They do not pretend to load the entire editor or complete macro planning stack.
BadgeHost belongs to the input agent's report.

Ten existing targeted controls pass, including the 25,920 modeled Forever
mouse/key/mini actions, native-mouseover 4,973 checks, raid casting 182, party
casting 310, unit click edges 41, suppression/Edit Mode 2,545, binding/Respec 110,
driver ownership 264, and utility secure input 41,255. These are native-source
Lua replays/mocks, not real client actions. Root's fresh canonical suite is
recorded separately in `round-2/existing-suite.json`.

Prior fixes retain their scoped passing controls: native driver globals stay
unchanged; owned Forever fallback/paging paths remain; world mouseover sweeps do
not create the prior input work burst; supported mouse/keyboard/CVar edge models
continue to pass. This report does not reopen those old findings as new ones.

No game, profiler, foreground input, WTF, protected runtime or true secret-value
execution was used. In-/out-of-combat flags and mock dispatch establish only the
stated owner logic; native instance restrictions, taint origin, hardware dispatch,
FPS and rendered parity remain pending. Passing old controls alongside these new
reproductions demonstrates the tested coverage boundary, not whole-addon safety.

## Suggested later implementation order

1. Fix bijective frame identity and literal-minus parsing first. They can select
   or lose a requested binding independently of native secrecy.
2. Fix hold ownership and snapshot reentrancy with bounded local request state;
   preserve simultaneous holds, coalescing and exactly-once completion.
3. Design the restricted-color presentation fix around public state/native-safe
   rendering; validate pixels and native restrictions before changing appearance.
4. Repair and permanently test deferred slot tombstones before expanding callers
   that rely on SlotProgram's combat API.

Each later change needs its own dated checkpoint, baseline rejection and focused
regression, then the full suite. No candidate fix has been applied in round 2.

## Explicit fast-modifier follow-up

The later user-requested [Shift/Ctrl/Alt consumer matrix](MODIFIER-FOLLOWUP.md)
adds two runs of 1,938,260 assertions each, with all eight held masks, overlapping
keys, duplicate/reordered payloads, release permutations and combat/regen. It
reproduces R2-BIND-01 throughout while verifying physical-truth routing, explicit
cleanup and bounded fixture resources. Its scope excludes native hardware and
the secure VM; it does not change the six base finding groups.
