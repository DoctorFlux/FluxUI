# Baganator junk detector activation

<!-- LHO-BACKPACK-ITEM-UPDATE-COST-20261119 -->
19 November. Forever's category backpack first open took 155.39 ms, with a 167 ms frame gap. Baganator's 54 item-detail calls took 117.61 ms. Acquiring 55 pooled buttons took 0.55 ms and reported zero new frames. The retry measured 123.06 ms across the same 54 detail calls. FluxUI Junk checks contributed 2.96 ms in that retry, and the instrumented quest, cooldown and context methods each took under 3 ms.

The native combined backpack first open took 155.73 ms with a 166 ms frame gap. The item update took 125.85 ms, and 18.54 ms was inside the observed button methods. Junk accounted for 12.57 ms in that group. A separate read of all 76 carried slots with the backpack closed took 0.63 ms for item data and 0.14 ms for quest data. The closed-bag read ran after the automatic spirit release with both addons enabled. It leaves cold first-open metadata behavior unverified.

The character died after the native capture finished. The release timer elapsed and the character is at the graveyard as a ghost. The first deeper probe encountered Syndicator's frozen Search API. A reload cleared that probe, and the instance-level retry reported zero errors and zero restoration failures. Both provider flags were restored and the idle jump helper is running. The measured backpack hitch remains open. Continue investigating nearby item widget and per-addon work, and use the prior measurements for separate Pending, consumable retry, cast and inventory integration fixes. [Evidence](validation/backpack-item-update-cost-2026-11-19.json).

<!-- LHO-NATIVE-BACKPACK-JUNK-GLOW-20261119 -->
19 November. Forever allocated 76 hidden Junk glows on the first native combined backpack open. The corrected probe identified FluxUI's specific glow texture and found zero instances before open, 76 immediately after open, and 76 after warm reopen. `FluxJunkOverlay.lua` now creates the glow on its first visible use and reuses it on later paints. The coin path and repaint timing are unchanged.

The same backpack test after reload found zero allocated glows. The before and after opens each ran 112 Junk checks with zero positive verdicts, matched all 76 visible slot positions and frame dimensions, preserved the bag generation and restored the closed state. Both samples reported zero Lua errors. The positive display transition, bank buttons and other clients still need native coverage.

The first open took 155.23 ms before and 157.93 ms after, with frame gaps of 164 and 169 ms. The warm opens took 24.74 and 27.66 ms. The pair confirms fewer allocations and provides no timing improvement. `UpdateItems` still accounted for 125.00 and 128.57 ms on the first opens. Measure item and quest reads, the quality and extended appearance path, then cooldown and tooltip work separately. Continue the Pending, mail, bank, vendor, receive, craft and cast checks. Both external addons were verified loaded with all four original enable readings restored. The idle-only three-minute jump worker resumed. [Evidence](validation/native-backpack-junk-glow-2026-11-19.json).

<!-- LHO-NATIVE-BACKPACK-JUNK-QUALITY-20261119 -->
19 November. On Forever with Syndicator and the native combined backpack, the original first open took 156.52 ms and coincided with a 164 ms frame gap. Across its first and second opens, native `UpdateItems` accounted for 136.83 ms inclusive. Of that, 127.31 ms fell outside the explicitly nested observers. This remainder can include unmeasured Lua descendants. FluxUI Junk display checks accounted for 16.69 ms across 224 calls.

The warm baseline found 194 native Junk fallback calls, all on slots with known non-gray quality and all returning false. `FluxJunk.lua` now returns that result directly for ordinary slot tables with a readable numeric quality above poor. Explicit and rule-based Junk decisions still run through their existing entry points. Gray and unresolved slot qualities follow the existing checks.

Across two warm opens, fallback work fell from 1.1866 ms for 194 calls to 0.2709 ms for 196 calls. The 224 display checks took 6.77 ms before and 3.79 ms after, and observed settings reads fell from 1,682 to 1,285. Slot order and geometry signatures matched. The bag generation and final closed state were preserved and all captures reported zero errors. One before and one after warm sample across reloads establish the scope of this observation. Positive gray or unknown quality and other clients still need native checks.

The first open after the edit still took 150.95 ms with a 159 ms frame gap. Trace the work inside `UpdateItems` at the item-button allocation, update, and icon or skin hook boundaries. Keep the Baganator category layout and Pending, mail, bank, vendor, receive and cast validation open. Both external addons were restored and verified loaded with their original character and overall enable flags. The idle-only jump worker resumed. [Evidence](validation/native-backpack-junk-quality-2026-11-19.json).

9 November 2026, BAGANATOR-JUNK-ACTIVATION-20261109. The user requested an
addon change after the initial configuration diagnosis. Baganator's selected
detector was RXPGuides in the sampled saved DEFAULT profile. Registering FluxUI
left that valid detector active, so Baganator did not call FluxUI's consumable
junk rules. This follow-up supersedes the manual-selection remedy in the
[initial diagnosis](validation/baganator-junk-detector-2026-11-09.json).

The existing junk bridge now adopts FluxUI once per active Baganator profile.
It retains the previous detector in that profile's additive
`fluxui_junk_detector = { version = 1, previousPlugin = ... }` record. This
intentional first adoption also replaces an initial `none` selection, as required
to activate the requested integration. Subsequent manual detector choices survive
bag reopen and reload. Inactive profiles are untouched; opening bags after a
profile switch adopts an unconfigured profile independently. Existing flat
profiles and the normal DEFAULT fallback are supported.

After a changed selection, the bridge emits Baganator's existing
`SettingChanged("junk_plugin")` notification and requests widgets, searches and
layout refresh through its public refresh API. This updates cached item callbacks,
the ignored-plugin list and category classification. An already selected FluxUI
detector only receives the migration record; no extra refresh is requested.
Missing settings or notification access defer adoption. One existing `BagShow`
callback retries late configuration and later profiles. There is no new frame,
timer, ticker, polling service or Blizzard API usage. Repeated opens after
adoption do not rebuild or override settings.

The junk callback still uses the shared classifier and protection checks.
Consumable rankings, rule switches, manual Useful/Junk marks, manual restock,
gear protection, conjured exceptions, vendor actions and appearance are unchanged.
No external addon code or artwork was copied. Installed Baganator846 reference
files were read only; their exact identities and All Rights Reserved notice are
recorded in the initial diagnosis. The change uses its existing profile and
callback surfaces, matching the other FluxUI Baganator integrations.

The verified external checkpoint preserves 2,389 actual source files and all-ref
Git history; 56 available settings metadata entries were inspected read only.
No unsaved-memory or quiescent settings backup is claimed. No game input, native
reload, settings-file edit, profiler change, manual client synchronization or
publication was performed. The migration changes the in-memory Baganator profile
when this code next initializes in the game.

Desktop checks execute the production bridge with a modeled single selected
detector and cached item callback. Five alternating old/new pairs reproduce
162 failures in the old source and pass all 403 candidate checks. Coverage includes
all five consumable verdict routes, protected slots, RXPGuides/poor-quality/none/
FluxUI initial choices, separate profiles, repeat opens, reload persistence,
missing/late config, unavailable notifications and ordinary refresh reasons.
Existing real tier/junk/seller and metadata checks also run in the full suite.
These fixtures do not execute native Baganator rendering or establish CPU/FPS.
The full runner passes all 269 scripts and 936 Lua syntax files; its source
manifest still matches. The bridge is the sole changed pre-existing Lua source
since the checkpoint. All five existing client copies match through the user's
continuous synchronization; no manual copy was performed.

Native acceptance remains pending through the existing user reproduction route;
no connected Witchcraft/UIForever tool is available. After a normal out-of-combat
reload, open bags and check that Junk detection became FluxUI automatically.
Carry lower and strictly better usable potions, bandages, food and water; verify
the existing rules' coins and category placement, including Useful/restock and
conjured exceptions. Confirm a later manual detector change survives reopen and
reload. Record the actual build, profile, item IDs and any Lua errors. Other
installed clients retain separate pending native results.

- [External checkpoint](validation/baganator-junk-checkpoint-2026-11-09.json)
- [Matched source identities and focused checks](validation/baganator-junk-activation-comparison-2026-11-09.json)
- [Full validation](validation/baganator-junk-activation-full-2026-11-09.json)
- [Source guard and installed copies](validation/baganator-junk-activation-source-guard-2026-11-09.json)

Reproduce the focused checks with `lua tests/baganator_junk_detector.lua`.
