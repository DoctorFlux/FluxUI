# FluxUI HUD performance roadmap

**R187 implementation closeout · Live acceptance pending · Updated 20 November 2026**

Make party and raid membership changes, held-action crossings, rapid action-bar edits and other HUD changes feel immediate. Keep both border styles, T/X seams, shadows, action IDs, bindings, and combat behavior intact. This is the HUD performance gate in the [addon release roadmap](RELEASE_ROADMAP.md). The [border builder requirements](BORDER_BUILDER_LOCALITY.md) cover the implementation.

## Finish line

Use R187 and the pinned HUD and group sources as the acceptance candidate. The combined desktop pass is complete. The remaining milestone is one native acceptance round, starting on Forever where the hitches were reported. Exercise the first transition and a short burst of repeats. Close the goal when the checks pass. Reopen implementation for a specific failure and retest the affected paths.

| Acceptance check | Pass condition |
| --- | --- |
| Held-action crossings and rapid drops | Enter and leave the strip holding a spell, item, and macro, including crossings without a drop. Repeat rapid pickups and drops with partially empty slots. The strip responds without the reported hitch. The Combat Grid, Non-Combat Grid, Info, and Trinket joins update with the strip. Action IDs and click and key routes remain correct. |
| Party and raid changes | Join and leave a party and a raid, including party-to-raid conversion. First and repeated transitions have no reproducible hitch attributable to FluxUI. Unit borders and paint appear with the correct roster. Protected selection and click routing are intact across combat. |
| Border and combat regressions | Check both border styles, including shared edges, T/X shadows, and independent outlines. Affected joins settle with the layout. Check an embedded-minimap toggle with side buttons and combat exit, including portrait, class, and dispel paint. Window sizing stays stable, prepared paint stays local, and there are no new Lua errors or taint in these paths. |
| Client coverage | Record the affected workflows on Forever, Retail and Classic progression. The broader release matrix also covers the applicable Era and Anniversary/TBC paths. Identify the loaded source and client build and retain the observed behavior. Native frame time, pixels and taint need client evidence. |

If a native scenario is unavailable, retain the tested candidate and mark that check pending. Resume implementation when a failed acceptance check identifies work. Profiling is optional and is useful only when a reproducible hitch still needs attribution.

The expanded desktop gate passed all 50 scripts, including the repaired render-basis and shadow-material checks. The 14 pinned runtime files still match in all five installations. Three checks after the desktop gate found no current playtest result, so the goal is blocked pending player-performed live acceptance. Begin with held-action crossings and rapid drops on Forever.

## Implemented and verified on desktop

| Area | What is in place | Evidence |
| --- | --- | --- |
| Action strip and side panels | Reversed hover requests can cancel before layout. The strip settles Combat Grid, Non-Combat Grid, Info, Trinket Menu and nearby unit anchors before committing affected joins. Slot-only swaps avoid extra envelope reads. Buttons reuse verified border art after parking. The side grids fit each ring once per real width change. Trinket shares the envelope flyout pass and keeps its own slot anchors. Info reuses matching text measurements and its decorative slot follows the grid anchors. | [Slot settlement](validation/strip-event-ownership-2026-11-20.json), [side-grid widths](validation/strip-grid-width-2026-11-20.json), [button border art](validation/strip-parked-chrome-2026-11-20.json), [grid ring refits](validation/strip-grid-ring-2026-11-20.json), [flyout arrow refresh](validation/strip-arrow-owner-2026-11-20.json), [Info text and gap layout](validation/strip-info-measure-2026-11-20.json) |
| Party and raid | Roster bursts share existing layout and paint queues. Prepared frames retain bindings and event owners through visibility changes. The latest normal-party patch keeps role and level placement in the party indicator pass and skips unused text measurements. In 60 modeled batches, role anchor writes fell from 290 to 23 and level anchor writes from 360 to zero. Settled mouse-only roster discovery skips the action binding scan. Nameplate threat ranks share public group identity reads within the refresh. | [Group roster work](GROUP_ROSTER_PERFORMANCE.md), [latest party replay](validation/party-status-owner-2026-11-20.json), [roster binding replay](validation/roster-hover-driver-2026-11-20.json), [nameplate threat replay](validation/nameplate-rank-roster-2026-11-20.json) |
| Border builder | Changes can replace affected regions while retaining unrelated fields. Repeated layouts reuse validated plans. R185 cuts temporary observer allocations. R186 reuses verified nearby-panel inputs. R187 carries capacity totals forward and checks the replaced regions. | [Renderer progress](BORDER_BUILDER_LOCALITY.md), [R185 replay](validation/border-observer-scratch-2026-11-20.json), [R186 alignment replay](validation/border-panel-inputs-2026-11-20.json), [R187 capacity replay](validation/border-cell-budget-2026-11-20.json) |
| Minimap and unit paint | Flux Window has a fixed footprint across embedded-minimap modes. Side buttons pack within the available width. Combat, class and dispel paint use prepared unit geometry. | [Minimap and side buttons](18-minimap-and-trackers.md), [border requirements and evidence](BORDER_BUILDER_LOCALITY.md) |

## Acceptance order

| Track | Status | Work and exit criteria |
| --- | --- | --- |
| **HUD-1 · Action-strip crossings and drops** | First native check | Check held-action crossings, rapid pickups and drops, side-panel joins and input routing. Include a layout with hidden or empty slots. |
| **HUD-2 · Party and raid membership** | Native check pending | Exercise normal party and compact raid join, leave and conversion. Include optional pet and target frames where enabled. Check member appearance, hitching and protected input. |
| **HUD-3 · Shared border builder** | Verify alongside HUD-1 and HUD-2 | In both styles, verify immediate joins, rounded corners, shadows, mixed tints and independent outlines. Confirm an actual layout change updates affected borders while unrelated borders stay stable. |
| **HUD-4 · Embedded minimap and other HUD changes** | Native regression check pending | Check embedded-minimap toggles with side buttons present, including changes in button count or grid scale and nearby Flux Window contacts. Verify stable window size and immediate seam updates. |
| **HUD-5 · Combat and final verification** | Native regression check pending | Exercise first and repeated combat exits, class/combat/dispel paint and target/focus changes. Check protected layout settlement after lockdown and taint. Verify the combined behavior on all supported client families. |

## How the active goal is tracked

- Use the track IDs above to record each acceptance result. Start with HUD-1. Follow a failing check to its owner before making a new source change.
- After each slice, update the matching row and add the strongest new result with an exact-source validation link. Keep detailed measurements, regressions and client exceptions in the existing ledgers. Use [Next session](../NEXT_SESSION.md) to point back here.
- Keep desktop work counts, reported symptoms and native verification distinct. A desktop pass can establish layout and operation parity in its fixture. Native frame time, pixels and taint require an actual client run. Use current native evidence when the scenario is available, with Forever first for the reported hitch.
- Close the goal when HUD-1 through HUD-5 meet their acceptance criteria. Reopen a track for a reproducible failure that affects those criteria.

## Latest checkpoint

**20 November 2026 · Desktop verification repair** — Fixed two stale border fixtures so they exercise the current renderer. Both detect the regressions they are meant to catch. All 50 acceptance scripts passed against the same R187 runtime sources. [Validation](validation/hud-acceptance-r187-2026-11-20.json)

**20 November 2026 · Acceptance candidate** — 48 combined desktop checks and 1,252 Lua syntax checks passed. All 14 pinned runtime paths match in all five local installations. Forever build 70959 was running in the foreground, so the live round was left pending. [Validation](validation/hud-acceptance-r187-2026-11-20.json)

**20 November 2026 · HUD-1 and HUD-3** — Carried forward committed border capacity totals. Sixty warmed crossings visit 2,340 regions for capacity accounting, down from 7,560 per style. Sampled joins and draw-cache admission match. 70 focused tests passed. Two older fixtures fail on both revisions. Live timing and taint remain open. [Validation](validation/border-cell-budget-2026-11-20.json)

**20 November 2026 · HUD-2** — In a modeled raid transition with 32 hostile nameplates, public GUID queries fall from 2,624 to 82. With confirmed tanking, detailed threat queries fall from 2,592 to 64. Displayed ranks and colors match. 56 focused tests passed. Live group timing and native permissions remain open. [Validation](validation/nameplate-rank-roster-2026-11-20.json)

**20 November 2026 · HUD-2** — Stable mouse-only roster discovery skips 570 binding queries over 30 modeled bursts. First registration of 40 raid cells uses 600 queries instead of 1,179 in the Forever model, with matching click routes. 46 focused tests passed. Live group timing and combat taint remain open. [Validation](validation/roster-hover-driver-2026-11-20.json)

**20 November 2026 · HUD-1, HUD-2 and HUD-3** — Reused verified nearby-panel inputs. Sixty warmed crossings create zero panel records, down from 420 per style. Stable-HUD reflow scans show the same reduction. The same boxes are written during the crossings. 37 focused tests passed. Native latency, seams and taint remain open. [Validation](validation/border-panel-inputs-2026-11-20.json)

**20 November 2026 · HUD-1** — Info strips reuse verified text widths. Sixty modeled width changes halve measurements for the FPS and ping row. The decorative gap skips 120 grid-height reads. 28 focused tests passed. Live frame time, seams and combat taint remain open. [Validation](validation/strip-info-measure-2026-11-20.json)

**20 November 2026 · HUD-1** — The envelope and Trinket Menu now share a flyout-arrow scan. Across 60 modeled crossings, arrow updates fell from 4,800 to 3,600 and final arrow placement matched. 25 focused tests passed. Native strip frame time, seams and combat taint remain open. [Validation](validation/strip-arrow-owner-2026-11-20.json)

**20 November 2026 · HUD-1** — Removed the duplicate ring fit during side-grid width changes. Modeled art and placement match across 60 crossings in each client profile. Twenty-three focused tests pass. Native action-strip frame time, side seams and combat taint remain open. [Validation](validation/strip-grid-ring-2026-11-20.json)

**20 November 2026 · HUD-2** — Normal party indicators now keep their portrait anchors through the shared roster paint. The matched replay also removes unused level and host-width measurements. Twenty-five focused desktop scripts and 1,252 Lua syntax checks passed. Live join/leave timing and indicator rendering remain open. [Validation](validation/party-status-owner-2026-11-20.json)
