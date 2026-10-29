# Shared Social-button position and reload/tab stability — BUG-011

The user requested the same Social-button offset across clients, using the supplied
cropped reference, then clarified the final lower inset, reload behavior and Combat
Log/custom-tab stability. This is an intentional position correction; button art,
sizes, spacing, actions, visibility settings, saved roots and profiles remain.

## Failure and intended behavior

Retail anchored the modern column below the chat Background while the adjacent
Micro Menu includes the tab row. Actual native geometry put Social about33 UI
units below the menu top. The final shared offset is **eight UI units below the
tab/menu top**, expressed relative to the chat tab-row height. This places it25 UI
units above the original Retail position, with the final slight downward adjustment
applied equally to every supported client path.

Using a future absolute column top against a provisional login chat rectangle
left a stale offset when chat moved later; changing tabs recomputed it. The relative
tab-height offset follows the final chat pin without another callback. Modern
placement also followed the selected window, whose Combat Log rectangle can differ.
The column now anchors to ChatFrame1 consistently; selected-window handling still
supplies Copy Chat's target. The holder remains parented to UIParent so hiding the
General tab does not hide the column.

Era/Anniversary retain native button-frame ownership; other clients retain the
existing holder. Scale conversion keeps offsets in the actual column owner's units.
Other Micro Menu positions and unavailable tab-height metrics retain their existing
Background fallback. Existing tall Classic stack/floor protection, combat waiter,
Edit Mode/native ownership, visibility and three retry deadlines remain intact.
No runtime timer, event, hook, frame, cache or framework was added.

## Identity and recovery

Baseline HEAD `30464782f39a435c3b402048387a1a47ac0acb0c`, tree
`df72b2c48996012c89257a42352271738d2a981c`, plus preserved pending tracker/audit
records in verified external `Chat-alignment-recovery-20261029T153201Z`.
The checkpoint contains1,263 actual files/history and403 on-disk WTF files while
Retail remained open; unsaved in-memory state is not covered.

Alignment/reload commit `78fe4e7022db14d25b3ba847cde014ab0e6d8273`; all-tab follow-up
`7f13000e99be9e7e2e2f98f52c9589dbe03787bc`, tree
`b6fa7e9f63df7d5d6bcc168daeafce030cfdcdc2`. Exact hashes/raw samples are in the
[comparison](validation/chat-column-alignment-comparison-2026-10-29.json).
Main and the excluded auction/guild-bank/void callbacks remain untouched. The
separate objective-tracker source/test changes remain preserved and uncommitted.

## Desktop and native evidence

The existing column fixture now gives other docked windows different heights,
positions and scales. It covers General, Global, Combat Log and a custom tab,
both sides, five branch models, late login pins without a tab switch, late metrics,
other menu positions, saved chat scales0.65/1/1.4 with UIParent0.75, combat/regen,
button visibility, Copy selection and anchor-cycle ownership. **2,009 checks pass**:
1,311 original controls,508 social ownership and190 new alignment/lifecycle checks.
The frozen original source fails the new assertions in measure mode.

Five alternating fresh-process pairs retain identical layout point counts and zero
new frames across100 settled layouts. Shared tab-height reads increase from zero
to103 modern /203 legacy-model reads including three scale probes. This is explicit
correctness overhead; no native CPU/FPS improvement is claimed. Existing chat layout
165, startup478 and layout retry5,869 checks remain regression controls. Full
[actual-file validation](validation/chat-column-alignment-full-2026-10-29.json):
**92 scripts,733 Lua syntax files, zero failures**, including the preserved pending
tracker test. Commits alone do not identify those uncommitted baseline files.

Actual Retail12.1.5.70575/interface120105, profiler0, UI scale0.75:
[geometry](validation/chat-column-alignment-native-2026-10-29.json) observes an
eight-unit Social gap with unchanged measured chat/menu/background rectangles.
A private background screenshot was inspected after reload **before any chat or tab
input**, avoiding the reflow that initially masked startup ordering. World pixels
are dynamic; the cropped reference has no build/resolution metadata. No full-screen
pixel, combat/taint or other-client native certification is claimed.

[Native tab samples](validation/chat-column-tabs-native-2026-10-29.json) execute
seven ordinary General1/Global3/CombatLog2 selections out of combat. Two-second
delayed samples before further chat input report identical visible Social coordinates
on every selection: left57.600, top361.059 UI units. The original observed General
tab is restored. No public/native API was replaced; no OS activation, mouse or
clipboard control was used. Ordinary PC focus changes during the run are not a
foreground test. Temporary exports/namespaces were removed by normal reload and
the original profiler0 remains. Additional/custom native tabs and other clients
retain their pending status; desktop coverage does not certify them.

```powershell
lua tests/chat_column_layout.lua --column-source tests/fixtures/chat_column_alignment_before.txt --measure
lua tests/chat_column_layout.lua
lua tests/chat_layout.lua
lua tests/chat_startup.lua
lua tests/idle_layout_retries.lua
python tests/run_validation.py --output docs/validation/chat-column-alignment-full-2026-10-29.json --sync-docs
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Measure mode retains known baseline failures with exit zero. Native continuation:
reload without touching tabs/chat first, compare General/Global/Combat Log/custom
docked tabs, hide individual column buttons, resize/change side/scale, then test
combat login/regen and Edit Mode on each available client. Preserve the selected
Copy target and settings. Original Wrath remains distinct and unverified.
