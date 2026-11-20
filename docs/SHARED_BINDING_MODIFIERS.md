# Shared bindings and minirow routing

15 November 2026, `SHARED-BINDING-MODIFIERS-20261115`.

The user reports that Shift selects a minirow visually but casts the main-row
spell, and asks to compare the current addon with DoctorFlux/FluxUI on GitHub.
They confirmed that their ALT-conditioned binding has **Key press (regular
targets)** turned off. That toggle disables keyboard emission for that binding;
an ALT-only keyboard cast needs regular key press enabled plus its ALT condition.
The saved profile is preserved and its meaning is unchanged.

## Requirements and findings

| Requirement | Result |
|---|---|
| Shift/Ctrl choose the mapped mini action at press time | Corrected inherited action selectors; desktop regression |
| Releasing a modifier works before the display driver updates | Removed live LeftButton selectors that masked the prepared nomod set |
| Minirow reconciliation cannot replace the main key proxy's program | Mini hosts no longer write action selectors onto the proxy |
| Surface macros, hidden delegates and native actions transition cleanly | Old proxy and live button selectors cleared outside combat |
| Preserve disabled regular/hover targets, ALT conditions, badges and profiles | Compiler, settings and badge owners unchanged |
| Compare the supplied older repository without replacing newer work | Seven routing/compiler owners matched pinned GitHub source before the fix |
| Native casting, secure execution and controller acceptance | Pending; no client input performed |

GitHub main resolves to
[`6b444eba4573092b57919ee3e497d86d2ebb3ece`](https://github.com/DoctorFlux/FluxUI/commit/6b444eba4573092b57919ee3e497d86d2ebb3ece).
Checkpoint copies of State, Clicks, SlotProgram, ChordMap, Apply, MacroFactory and
BadgeHost match that commit after newline normalization. The defective proxy
writer therefore exists in the linked version too.

The current on-disk configuration supplies a specific reproduction: F binds
column 11, and main slot 11 and Shift slot 71 both request interrupt/cancel-queued
spell behavior, producing hidden delegates. In the fallback's complete Shift
walk, the main host writes delegate 71 onto the keyboard proxy; the secondary
host overwrites it with delegate 11. The tertiary native host clears the local
type but leaves `clickbutton1`. The proxy then inherits the Shift click type
while selecting the stale main delegate. The regression reproduces expected
`Native71` becoming `Native11`. Saved data is a read-only snapshot; it does not
establish the running VM's current state or whether fallback is active there.

Native `SecureButton_GetModifiedAttribute` attempts local attribute lookup
before parent inheritance. A local bare macro or click target can thus mask
every prepared modifier route. Separately, live `type1` / `clickbutton1` on the
visible host can mask its nomod wildcard set immediately after releasing Shift.

## Correction and source evidence

[Clicks.lua](../Bars/Clicks.lua) keeps action selection on the parent and key
timing on the hidden proxy. Its existing creation/reuse path clears obsolete
local action selectors and installs their `useparent-*` flags. The fallback
also reconciles the main proxy through this owner. Mini hosts cannot overwrite
its program. [State.lua](../Bars/State.lua) retains live display attributes but
removes its obsolete LeftButton-specific selectors, leaving the pre-stamped
nomod/Shift/Ctrl click sets authoritative.

No new timer, event, driver, poll, settings migration or saved action/binding
write is introduced. Existing key-down and mouse-release registration remains.
This changes execution routing, with no new visual controls, artwork or focus
targets; controller input still uses the existing native binding path and needs
native verification. Existing Witchcraft preference is retained; no PC focus,
keyboard, mouse, clipboard, profiler or diagnostic root is changed by this work.

The target branches were resolved once for this task: Retail
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676`, Classic progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`. Their pinned SecureTemplates helper
has the same local-before-parent contract. Existing Era/Anniversary coverage
remains; no TOC/interface or client support change is made.

## Validation and remaining acceptance

[shared_binding_modifiers.lua](../tests/shared_binding_modifiers.lua) executes
the actual Init traversal, State fallback and stored secure child body, Clicks,
Action and MacroFactory, plus the source-pinned native modified-attribute helper.
It tests dynamic and static columns, disabled/enabled regular targeting, native,
surface, hidden and display programs, pre-driver modifier edges and cleanup.
The archived GitHub implementation fails the hidden-pair Shift reproduction;
the candidate passes 2,271 checks, including 246 in the exact reproduction.
Three syntax-valid harmful controls are rejected; twelve focused scripts pass.
The final bar smoke and fresh 1,092-file syntax sweep also pass. The first full
sweep preceded final test refinement and concurrent unrelated changes; other
script results remain explicitly historical for those newer sources. Frame
transport and macro clause selection are modeled.

The dated external source/history checkpoint contains 2,879 files, verified ZIP
CRC and Git bundle, plus metadata for four currently available settings files.
One previously recorded settings path no longer exists; no settings values were
copied. Exact source hashes, test results and scope are recorded in
[the evidence record](validation/shared-binding-modifiers-2026-11-15.json).

After loading the correction, verify main/Shift/Ctrl actions, especially Shift-F,
both before and after modifier release, in and out of combat. Check ALT-only
bindings with regular key press enabled, disabled-target behavior, badge previews,
forms/control pages, and controller bindings. Do not infer native casting, taint
safety, rendering parity or FPS from the desktop result. Earlier unresolved
main-row acceptance and unrelated inventory work retain their own status.

Documentation validation initially reported one unrelated broken evidence link
in `CONNECTED_BORDERS.md`. A final check also detects concurrent border source,
asset and generated-reference changes, seven issues in total. Those owner files
are preserved; task source/test hashes still match the focused evidence.

## Read-only saved-variable follow-up

The user then requested checking the Forever account's saved variables. Current
account/character files, both `.bak` files and native binding overrides were read
without changing them. Only the active character has Flux binding saved data.
Nine DB3 rows have valid unique identities/actions/placements, `nextUid=21`,
seven placements, valid fields and no broken UID references. Legacy binding
roots and Respec profiles are empty. Current and backup DB3 documents agree
semantically. Layout uses Default/account scope without minirow overrides; all
nine badge styles retain their normal 75% alpha, no hide flags and enabled digits.

In the latest saved copy, UID20 on `SHIFT-Ã‚Â½` selects Shift+Ctrl with ALT off.
Both regular key press and hover casting are off, so it emits neither input
path. An earlier read had ALT selected; current and backup now contain the newer
Shift+Ctrl selection. UID3 on R is deliberately hover-only. Historical UID20
order lists under old chords contain live references but do not install bindings
or redirect input; they are not a reason to reset data.

The native override cache has 117 entries without duplicate keys; F maps to
column11, and the half-key is the correct U+00BD character. There is no explicit
Shift-F/Ctrl-F override. Existing ALT-Q/E/Z/C assignments are intentional combat
extra commands. Missing numeric entries cannot prove missing bindings because
this file alone does not establish the complete effective native defaults.

No malformed save or saved bar/badge conflict was found. The disabled input
paths and changed modifier selection explain the inactive conditional entry;
the main/Shift hidden programs match the reproduced source defect. Actual action
contents, native page, learned-spell availability and running VM state still need
the client. No saved setting or binding was changed.

Account setup and nonbinding audit are complete. Binding bootstrap version 6
is validated with no saved pending reset/reseed state; this data does not request
automatic keybind replacement. The inspected latest save is 15 November 2026
at 16:56:37 Copenhagen time.
