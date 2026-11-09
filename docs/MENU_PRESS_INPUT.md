# Menu buttons activate on press — 9 November 2026

MENU-PRESS-20261109: food, water, bandage, healing potion, mana gem, mana
potion, healthstone and equipped trinket menu buttons must activate on mouse
or binding press, once per click, on every existing client. Use/conjure
assignments, modifiers, layouts, inventory selection and saved data remain.
This is an input-edge correction, with no visual redesign.

## Implementation

[Shared click policy](../Core/ButtonFX/Click.lua) already receives `onDown`
from both grid factories, locked HUD hosts and TrinketMenu. Its wrapped path
previously let use bindings follow ActionButtonUseKeyDown; the unwrapped
Forever path ignored `onDown` and registered release only. The press wrapper
now rejects release before remapping use/conjure. The unwrapped path registers
AnyDown with useOnKeyDown=true and pressAndHoldAction=false. Blizzard's
template OnClick remains the secure action owner; no addon OnClick replacement
or protected input-time rewrite is introduced. Ordinary hosts retain release
clicks and their configured key policy. Other HUD hosts already requesting
the same `onDown` policy now use that policy consistently for keys as well.
Generic popup children and their close/open policy are unchanged.

## Source and preservation

Fresh Gethe branch resolution: Retail live `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5/70783), Forever `9dc84f0d3bbae1768ac3405b3716000bd93eda06`
(1.60.1/70862), Classic progression `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`
(5.5.4/70631), existing Era `4192ac60067fc55566182291bc67c85dd9b6794d`
(1.15.9/70576), existing Anniversary `68e0a2ec559d9761dfc4e7f864c3944f9d758a49`
(2.5.6/70577). [Exact source records](validation/menu-press-upstream-2026-11-09.json).
SecureActionButtonTemplate's three-argument call and native keydown/hold-release
gates were inspected. Four local SecureTemplates files match the pinned blobs.
Anniversary's complete local file is older; the exercised dispatch block from
PRESS_TYPE_DOWN through SecureActionButton_OnClick exactly matches the fresh
pinned source. Reference trees were read-only; no Blizzard source was vendored.

Before runtime edits, external `press-input-checkpoint-20261109T103238Z`
preserved 2,351 actual files plus all-ref history; ZIP CRC and bundle verification
passed. Read-only on-disk settings metadata covers 125 files across five clients;
unsaved game memory is outside that scope. [Checkpoint](validation/menu-press-checkpoint-2026-11-09.json).
Existing extensive main changes remain. No commit/push or manual sync occurred.

## Validation and remaining native checks

[Production regression](../tests/menu_press_input.lua) loads native dispatch and
the actual click and consumable-binding modules. It passes 4,284 checks across
five clients, both global keydown settings, all eight faces, primary/secondary
use/conjure keys, mouse, SHIFT selection, combat/noncombat models, setup deferral,
ordinary-host restoration and zero input-time frame allocation/attribute writes.
Five alternating baseline/candidate pairs reproduce the old KeyBind press
failure and pass the candidate; two old Forever release/gate controls are
rejected. [Raw comparison](validation/menu-press-comparison-2026-11-09.json).
The existing bars smoke's obsolete fixed-release assertions were updated for
the requested HUD policy. Full265-script/932-syntax validation passes with zero source drift; result in
[full validation](validation/menu-press-full-2026-11-09.json).

The existing mirror synchronized the runtime file: all five installed normalized
hashes match. [Read-only verification](validation/menu-press-client-copies-2026-11-09.json).
No client reload/input/settings/profiler changes ran. Existing UIForever preference
is retained; no connected Witchcraft/UIForever tools are available this round.
Desktop results do not establish native secure-VM/taint, physical input or pixels.

Native acceptance pending after `/reload` outside combat: hold/release each use
binding and left mouse button; activation must start at press with no repeat at
release. Repeat with ActionButtonUseKeyDown disabled, secondary keys and relevant
conjure/right-click actions; check middle-click gestures, flyouts, both trinket
slots and the one-equipped routing. Confirm combat use and no taint/errors on
each installed build. No FPS/CPU/latency improvement is claimed.
