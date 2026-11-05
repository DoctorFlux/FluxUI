# Minimap mail indicator lifetime

5 November 2026: the user reports minimap flickering/disappearing when mail
changes and increasing Buy/Cancel lag. `PositionIndicators` searched two native
mail-frame locations but omitted its own named fallback. On Forever's source
layout neither native location exists: each reconciliation created another
`FluxMinimapMailFrame`, texture, two event registrations and two layout hooks.
Every retained mail listener then created another indicator on the next event.

The fix adds the already-created `FluxMinimapMailFrame` to the existing lookup.
It retains native global/`Minimap.MailFrame` preference, the current 20×15 atlas,
anchors, tooltip, visibility rules, combat checks and immediate update cadence.
It does not adopt Forever's differently sized native indicator or change saved
settings. The separate Retail cold-tooltip fix has its own evidence record.

## Source and recovery

Baseline: `c1a5f901467ff5015938442c74580d6d4781cbaa`; baseline minimap file SHA256
`d5f6c48a568ebd1d135253ee42d20693ffa048e0b08feed30443272028ea536e`.
Candidate file SHA256:
`448c762562c5bb2d62aeca43139d1ca5e42eb56b41ad86f4254caa34f78d670a`.
External checkpoint `Mail-auction-publication-20261105T194013Z` preserves 1,529
actual files, 122 on-disk settings and all-ref history, including the pending
cold-tooltip work. Source archive SHA256:
`a6fb41fd4042442bd9d9c6d5c70320fe9001feadd068312e3b328d0dfb694449`.

At pinned Gethe commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`, the
[minimap TOC](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Minimap/Blizzard_Minimap.toc)
loads Mainline family XML and Camelot mail/indicator templates. The
[indicator template](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Minimap/Camelot/MinimapIndicatorFrameTemplate.xml)
creates `MinimapCluster.IndicatorFrame.MailFrame` using `parentKey`, without a
global `MiniMapMailFrame`. Its
[mail template](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Minimap/Camelot/MinimapMailFrameTemplate.xml)
is 32×24; retaining Flux's existing fallback avoids an appearance change.
This is source evidence for Forever build70790, separately from native operation
validation. Legacy native lookup paths are also exercised by the regression.

## Desktop evidence

Run `lua tests/minimap_mail_lifecycle.lua`. The actual production function runs
against explicit frame/event/API mocks, with global, Minimap-key and Forever
cluster-key layouts. Provider namespaces are absent or present; this fixture
does not emulate Syndicator/Baganator behavior. One candidate warm-up precedes
five alternating AB/BA baseline/candidate pairs. No game input, profiling or
preference changes are used. Raw resource samples and variation are recorded in
[the comparison report](validation/minimap-mail-lifecycle-comparison-2026-11-05.json).

| Mock scenario | Baseline | Candidate |
|---|---:|---:|
| 500 layout reconciliations | 500 fallback frames/textures | 1 |
| 10 unchanged mail events | 1,024 fallback frames/textures | 1 |
| Requested 100/500 unchanged events | capped after15 completed events | completes |
| Requested 10/100/500 alternating events | capped after9 completed events | completes |
| Registrations/hooks after500 candidate events | baseline capped | 2 each |

The baseline safety cap is 32,768 frames. Event dispatch snapshots existing
listeners; new registrations receive the next event, avoiding assumptions about
native registration during dispatch. Candidate passes 504 checks; baseline
fails100 of494 attempted checks because capped loops omit their final visibility
checks. Five rejected mutants cover missing/conditional reuse, native preference,
anchor offset and event-layout cadence. Additional checks cover cold no-mail,
hidden minimap, combat, world entry, tooltip and native-hide behavior.

These counts establish the fixed retention defect independently of inventory
providers. They do not establish native memory use, FPS, frame times, taint safety
or a complete cure for auction/mail freezes. Whole-harness wall times are not
comparable native benchmarks, particularly because baseline loops hit the cap.

## Pending native regression

Reload before testing: WoW cannot reclaim orphan frames already created by the
old code in the current UI session. First verify the candidate loaded on Forever
70790; repeat on Retail, Era, Anniversary and supported progression builds,
recording exact builds, profile, resolution, scale and addon list.

For each client, test without external providers and with Syndicator/Baganator:
compare matched unread/no-mail screenshots in normal and embedded Map modes;
check other Flux Window tabs remain hidden, tooltip/clock/tracking/queue behavior,
combat visibility, zoning and reload. During separately authorized activity,
capture repeated Buy, Cancel, sale-arrival, mailbox open/close and attachment/Open
All sequences at10/100/500 operations. Record frame/listener/resource growth and
matched optional profiler measurements without changing preferences permanently.
Native flicker/disappearance and transaction performance acceptance remain pending.
