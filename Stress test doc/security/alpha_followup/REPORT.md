# Alpha and fade follow-up to USER-001

Date: 7 November 2026. Audit and simulations only; **no addon code changed**.
This folder is a separate follow-up snapshot. Earlier reports remain intact.

The user has supplied seven consolidated occurrences of the same Forever
`FrameUtil.lua:427` secret `startAlpha` error:12:31:53 twice,12:32:26 once,
13:05:58 twice and13:09:17 twice. Repeated pasted blocks are not counted again.
Action, affected frame, combat and instance context remain unknown; the user
does not know the preceding action. These timestamps do not identify seven
different frames or prove a permanently broken fade.

The original cast/swing OUT suppliers remain under
[USER-001](../USER-001-FADE.md). **The six patterns below are additional conditional
source risks, not six newly observed native errors or attribution of USER-001.**

## What was examined and executed

The named fade/flash-family scan covers695 non-test/non-temporary Lua/XML files,
including bundled libraries. It finds23 lexical family rows in four files and
40 alpha getter rows. The smaller [family inventory](fade_family_inventory.csv)
and [getter locations](getter_review_locations.csv) support this focused review;
the earlier650-row alpha-write list is not repeated as a finding list.

There are five direct fade-creation calls: cast/swing OUT, player-combo IN and two
combo-highlight IN calls. Others remove/check fades. No direct named alias,
replacement of `UIFrameFade*`/`UIFrameFlash*`/their queues, or direct native flash
call was found in production source. This lexical result cannot exclude arbitrary
reflection or names composed at runtime.

[Results](results.json) reuse Forever pin
`9dc84f0d3bbae1768ac3405b3716000bd93eda06`. The external native FrameUtil body
is rechecked against Git blob `a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d`, with
CRLF→LF normalization. [FrameUtil](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua)
and the prior
[alpha API evidence](../user-001-fade-results.json) identify source contracts;
they do not establish the restrictions of a specific user frame. GetEffectiveAlpha
also has an alpha-access requirement, so some real callers could fail at the
getter before returning any value. This follow-up models its returned-value case.

Run from the repository root:

```powershell
python 'Stress test doc/security/alpha_followup/run.py'
```

Three independent processes each execute125 assertions. Actual production
function bodies/fragments run against mocked frames. A table has arithmetic/order
traps; a scoped `type` function reports `number` for that table to model the
runtime type of a secret number. **It is still a Lua table, not a native secret
value, and these tests do not emulate the secure/taint VM.** Each process includes
seven loaded comparison-site failures, two loaded-library arithmetic failures,
one explicitly separate legacy-path control,84 public-state equivalence controls,
and native fade/flash controls. All consumed source hashes stayed unchanged;
other concurrent runtime/test edits are recorded by the root checkpoint, so no
whole-current-addon immutability or acceptance is claimed.

## Six conditional patterns and future fixes

| ID | Actual source and conditional result | Feature-preserving direction for later work |
|---|---|---|
| ALPHA-01 | `Bars/Blizzard.lua:1030`: `QuietGrid` orders a native frame's `GetAlpha()` against0 without checking access. The production Dim helper traps with the opaque-number getter. | Avoid the read where the owner already knows it intends to suppress native chrome, or use the existing access helper with public presentation state. Preserve grid suppression, mouse ownership and Edit Mode/combat exclusions. |
| ALPHA-02 | `UnitFrames/FluxSwingTimer.lua:917`: `CastBarIsBusy` compares alpha after active cast flags have cleared, although both branches then returnfalse. The read has no effect on the returned priority result. | Remove that return-redundant predicate. An in-memory experiment retains the exact result for84 public visibility/alpha/active-state combinations and avoids any alpha getter for the opaque case. Production remains unchanged. |
| ALPHA-03 | `Core/ButtonFX/Charges.lua:135`: `SetBling` accepts `type(alpha)==number` then orders effective alpha against0.4. Type does not establish access. | Use the existing value helper and caller-owned public presentation alpha/visibility policy. Retain no-bling idle behavior, real recharge bling and the intended threshold. |
| ALPHA-04 | `Core/ButtonFX/Cast.lua:499` and `Bars/BadgeHost.lua:1230`: getter `pcall` succeeds, then the subsequent type-only `alpha<=0` comparison executes outside it. | Reuse existing safe-value helpers and owned parked/hidden/public-alpha state. Preserve visibility pruning, modifier faces, cast/proc ownership and updates for actually visible buttons. Wrapping another broad pcall around the painter would hide failures. |
| ALPHA-05 | `ExtraButtonSystem/Engine/Button.lua:2268` and`:2612`: duration-object and numeric cooldown appearance paths both compare effective alpha against0.4 before deciding edge/bling. | Share the already established appearance policy through existing helpers/owners; preserve swipe transparency, charge edges, bling, OOR0.4 and ordinary1. Keep native duration objects opaque and do not add a poll. |
| ALPHA-06 | Loaded `LibCustomGlow-1.0` minor20 divides a texture's `GetAlpha` at`:717` and`:726` during uncolored/colored glow reapplication. The actual threat caller caches its band at `UnitFrames/FluxUnitFrames_Shared.lua:7297` before the library pcall at`:7300`. Under the conditional library failure, that caller returns normally and the next same-band call skips the still-incomplete update. | Preserve threat color transitions, alpha and animation using known public glow presentation state; only record successful updates as applied. Keep library attribution/license and current shared-library ownership. Do not turn this into repeated failing work or disable the glow. |

The two EBS locations are one pattern, and the two getter-pcall visibility owners
are one pattern. The public-control experiment is documentation code only.
Library minor20 is the bundled source identity; another addon may provide a newer
winning LibStub implementation at runtime, which has not been captured.

For ALPHA-02, the change has a particularly small behavioral contract: existing
active-cast/hold/fade flags keep their current true results; all other states
still returnfalse. No hidden fallback alpha is needed. Other predicates require
their actual owner policy, rather than defaulting every unknown alpha to0,
hiding widgets, or treating every unknown widget as fully opaque.

The root's separate [guard controls](../secret-value-followup/guard-controls-results.json)
execute the existing Secrets services. Later fixes should use these helpers with
known public presentation values; type checks and successful getter pcalls are
insufficient. Do not store an opaque value as a supposedly public last number.

## Important exclusions and controls

- `ExtraButtonSystem/Engine/Style.lua:279` has another type-only alpha predicate,
  and its isolated helper traps under the same artificial condition. Its
  `UseQuickslotRing` gate explicitly excludes Forever and post-DF Retail, so this
  is a separate Classic/pre-DF contract review, not a leading USER-001 cause.
- `libs/LibActionButton-1.02/LibActionButton-1.0.lua:4469` contains a similar
  effective-alpha predicate, but this library is absent from Flux's current TOC
  load graph. Its on-disk presence alone is not a loaded Flux defect.
- `Battlezonemap/FluxDetailsWoWSkinTint.lua:13` is a local function named GetAlpha
  that reads a Details configuration color; it is not a frame alpha getter.
- The real portrait visibility helper at
  `UnitFrames/FluxUnitFrames_Shared.lua:3978` checks secrecy before ordering and
  passes the opaque positive control. Raid native-overlay helpers also have
  explicit access guards; meter guarded controls are in the parallel value audit.
- Cached alpha in `Blizzard/Hide.lua`, Classic combined-bank restoration and
  `FluxCastBarThemes.lua` is primarily saved/restored through display sinks.
  These locations were inspected separately from numeric interpolation.
  Preserving a value opaquely for an allowed sink is not the same operation as
  comparing or dividing it; their real native permissions still need validation.

## IN/OUT defaults, shared manager and finite failures

Native IN/OUT wrappers with omitted endpoints supply plain0/1 defaults and pass
the controls. Explicit opaque endpoints reach arithmetic in either interpolation
branch: IN at425 and OUT at427. USER-001 specifically identifies OUT; the IN
control is a related family regression, not a new reported error. The native
public-duration flash control also completes; no addon direct flash call was
found. LibDBIcon uses its own Alpha animation group, which is distinct from the
FrameUtil flash queue.

Crucially, native `fadeTimer` increments **before** alpha arithmetic. In the
0.30s control,0.05s updates produce five expected arithmetic traps, then the fade
retires and the queue is empty within1.0s without requeueing. A bad row can delay
later rows during the failing update; the source does not support claiming an
infinite error or permanent manager block from that alone. Repeated registrations,
different frames or other native state could produce recurring reports, but none
is identified by the user's stack. Native chat/map/reticle owners remain possible
shared-queue alternatives until the actual fading frame is known.

Later regression coverage must retain public alpha0/0.4/1, charge and normal
cooldowns, hidden/parked badges, cast/swing priority, threat recolor/restart,
normal/interrupt fade durations, multiple queue owners and finite completion.
Run real client checks per build and OOC/combat/world/dungeon/raid only when that
scope is authorized; these simulations do not certify native taint or pixels.
