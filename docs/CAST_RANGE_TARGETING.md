# Range follows the action's cast target

15 November 2026, `CAST-RANGE-TARGET-20261115`.

The reported native case is now confirmed by the user: after reload, unbound
Frostbolt on button1 follows the selected enemy's range while a friendly unit
frame is hovered. Other targets and surfaces have separate desktop evidence;
this confirmation does not certify every client, macro, badge or controller.

| Requirement | Owner / acceptance |
|---|---|
| CR-01: Native Frostbolt ignores an ineligible friendly hover | Core Range + MouseoverCast mirror the native per-slot helpful/harmful gate; user actual-client PASS |
| CR-02: Plain spells/items follow eligible cast targets and configured modifier | Native action classifier includes neutral actions; standalone adapters reuse help/harm/exists; 4,288 source-model checks PASS |
| CR-03: A macro ranges its selected cast, independently of tooltip/idle icon | Real cast/use parser; pinned-tooltip/focus mismatch, inactive branches, sequence state and stopmacro covered; 66 parser checks PASS |
| CR-04: A reverse badge uses the displayed action's own target | Apply retains original regular/hover clauses; BadgeHost fingerprints them; EBS resolves only matching original identity and eligible conditions |
| CR-05: Preserve explicit target semantics | @target/focus/player/mouseover retain authority; cursor and missing/unknown units cannot borrow another target; 380 integration checks PASS |
| CR-06: Main/mini paging and hover-only bindings retain their current target | Range reads the current live slot and full executable body; icon/idle body remains stable; native route/visual and actual factory regressions pass |
| CR-07: Preserve timing, input, settings and measured work | Existing one shared ticker, per-unit probe memo and bounded burst catch-up retained; no secure program/settings/input changes |
| CR-08: Report actual-client and performance scope accurately | Native reported Frostbolt case PASS; wider native checks and FPS remain unverified |

The previous hotkey tint work correctly displayed its supplied range flag. The
underlying resolver, however, chose any hovered unit frame for every plain action.
Native casting first checks whether the action is helpful or harmful for that
unit. With a hostile selected target and friendly hover, Frostbolt therefore
cast at the enemy but ranged the friend. This was a target-selection defect,
independent of the earlier main/mini execution correction.

[Range.lua](../Core/Engine/Range.lua) now passes each current plain action identity
to [MouseoverCast.RangeUnit](../Core/Engine/MouseoverCast.lua). Native action slots
use the same friendship and helpful/harmful include-neutral predicates as
Blizzard. Standalone spell/item adapters reuse their established suitability gate.
Explicit macro targets win; self remains self, and ground targeting has no unit
range. Missing explicit targets clear unknown range rather than falling through
to the selected enemy. Eligible world mouseover follows the same rule as unit
frames; the existing shared scheduler still throttles hop storms.

[ProgramFace.CastBodyForSlot](../Bars/ProgramFace.lua) supplies full execution text
for range, preserving stable idle icon text. [Action.CastFromBody](../ExtraButtonSystem/Engine/Action.lua)
reads the selected cast/use command without letting #showtooltip supply its spell
or target. Active stopmacro blocks subsequent casts. Sequence queries read only
native sequence state; unavailable state, redirected/target-changing delegates
and unsupported random selections remain unknown. This does not predict whether
a multi-action macro's casts will succeed, nor execute or rewrite its commands.

Badges are visual complements. Reversing a token preserves the other token's
condition text, so that reverse text cannot define the swapped action's target.
[Apply.lua](../Binding/Core/Apply.lua) now retains original clause metadata beside
the existing badge display. EBS matches the current badge identity to its own
eligible original clauses. A native Frostbolt badge while a focus-targeted binding
is active therefore uses Frostbolt's native target, not that binding's focus.
If an inactive binding has no currently eligible own clause, its range is unknown
and no red is invented. Hover-only branches use their original hover clauses.
No badge interaction, reverse icon behavior or secure action body changes.

The fresh external checkpoint preserves 2,902 source files, verified source ZIP
CRC and Git history on main plus metadata for five available settings files.
Private settings were not copied. No layout, option, localization label or focus
owner is added; existing direct implementation and user-assisted in-game testing
preferences apply. This is passive feedback, with no new controller interaction.

The frozen full sweep passed 413 of 415 scripts and all 1,104 syntax checks. One
failure was an older native-mouseover fixture calling the range resolver without
its newly required action identity; the corrected fixture passes 4,984 checks.
The unrelated portrait fixture still lacks GetUnitClassColor. After a final
stopmacro refinement, all 14 selected scripts and 1,104 syntax checks pass with
stable sources. That is a scoped final rerun, not a second full sweep.

Matched desktop counters reproduce the old wrong mouseover/normal result and the
new selected-enemy/red result. One actual range probe serves ten same-frame
paints in both revisions. Native classification deliberately remains live for
same-frame slot replacement: two classification reads per UpdateRange, twenty
for ten repeats. Standalone immutable classification is cached. These correctness
and work counts establish no native timing or FPS improvement.

Generated reference views and scoped whitespace checks pass. The global docs
gate retains five unrelated concurrent border/inventory issues: the /fluxborders
alias, two later border-source verification hashes and two absolute audit links.
These do not certify or block the independently recorded range checks.

[Exact source identities, raw evidence and native scope](validation/cast-range-target-2026-11-15.json).
