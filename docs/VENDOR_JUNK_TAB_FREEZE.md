# Vendor Junk tab work spike

10 November 2026 â€” `VENDOR-JUNK-TAB-FREEZE-20261110`. The user reports major lag or a freeze when selecting the merchant's added Junk tab. This fix addresses a reproduced source of excessive work; native freeze removal remains pending the user's retest.

The complete production panel, junk classifier, item cache and item display reproduce the problem in desktop models. Sorting a cold list repeatedly calls the metadata loader from the comparison function. Each item completion also sends an immediate visual notification, rebuilding and repainting the entire panel inside the metadata delivery path. Synchronous completions can nest these rebuilds. Scroll-child size writes can reenter painting through the range callback.

The two runtime changes sample each name once before sorting, route visual and item-event notifications through the existing 200 ms metadata retry, guard reentrant painting, avoid unchanged size writes, and remove a duplicate opening paint. Explicit edits and focus remain immediate; automatic visual notifications now share the existing metadata refresh boundary. No new driver, widget, binding, setting, selling rule or saved-data migration is introduced.

| Matched desktop scenario, per client | Exact checkpoint | Candidate |
| --- | ---: | ---: |
| 400 cold explicit entries: load requests | 13,768 | 1,200 |
| Same opening: row paints | 51 | 17 |
| 400 item completions: list/bag rebuilds | 400 | 1 |
| Same completion burst: row paints | 6,834 | 17 |
| 120 synchronous completions: maximum nested event depth | 65 | 1 |

Three matched pairs cover Retail, Forever, progression, Era and Anniversary models. All 85 focused checks pass; four harmful controls fail as expected. Coverage includes alphabetical ordering and numeric ties, complete membership, Useful protection, manual changes, late automatic junk, focus scrolling, geometry reentry, hide/reopen and stale timer ownership. Existing vendor-open and timer-ownership checks also pass. Tests use actual production Lua with modeled widgets and metadata; these numbers are not native frame times or an FPS result.

The broader run has 295 passing scripts, two raid-aura failures, and 969 passing syntax checks. Raid aura and other unrelated sources changed concurrently after the checkpoint. Their edits are preserved; this task does not claim a clean current full-suite result or attribute those failures to the Junk changes. The exact affected Junk sources match the full-run manifest. Documentation validation passes with 1,003 classified sources, 607 reachable files and 16,208 local links.

Recovery is the verified external 2,545-file source archive and Git history bundle at `junk-tab-checkpoint-20261110T165954Z`. Four available Retail Flux settings files were inspected for metadata only; no private settings were copied or written. Main and the existing user-managed synchronization policy remain. No manual other-client installation, publication, game input or profiler change occurred.

Fresh commit lookup failed through the available network routes. Existing packaged source contracts and ten local upstream files were inspected without advancing their recorded source pins. The Retail declaration marks `ITEM_DATA_LOAD_RESULT` synchronous: [pinned Item documentation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua). Source declarations do not establish an actual failing native call sequence.

Run `lua tests/vendor_junk_tab_work.lua` to repeat the focused checks. [Evidence and exact identities](validation/vendor-junk-tab-freeze-2026-11-10.json) retain the baseline/candidate pairs, controls and broader-run limits.

Native acceptance: reload, open a vendor and select Junk repeatedly; switch Useful/Junk, scroll, change one controlled entry, and reopen after item data finishes loading. Confirm automatic items, selling protections, row appearance, mouse/keyboard/controller operation and absence of Lua errors or freezes. Native latency/FPS, pixels, taint and controller checks are NOT RUN. The accepted UI and existing interaction handlers are preserved; no new focus stop is added. User-performed reproduction remains the established testing route.
