# Next session

Current publication batch (30 October 2026): all local scale, vehicle/durability,
status-bar and vendor message updates are included for main. Fresh combined
validation passes **100 scripts /741 Lua syntax files, zero failures**.
See [publication record](docs/GITHUB_PUBLICATION.md). Native pending checks remain pending.

Vendor chat amounts now split copper into gold/silver/copper with matching coin
symbols in repair, junk sale and net vendor lines. Full desktop validation passes
100 scripts/741 Lua syntax files; native chat rendering remains pending. The
reported 3,494,236-copper repair should read 349 gold, 42 silver, 36 copper.
Preserve unrelated unit-frame, vehicle and status-bar working-tree changes.

Unit-frame scale follow-up: portrait offsets and focus alignment now use
frame-local coordinates; player and side-by-side target clear the action strip
at 50–200% scale. 3D portrait camera refreshes on an actual scale change.
Focused 23 checks and full 99-script/740-Lua desktop suite pass.
[Evidence](docs/UNIT_FRAME_SCALE.md). Native pixels, click areas and
combat/taint remain pending. Preserve concurrent vehicle/durability and
status-bar changes.

New unit-frame scale controls: Player tab sets shared player/target size;
Focus tab sets focus size (50–200%, default 100%). The root and attached
elements, dependent target frames, detached chrome and class resources scale
together. [Scope and pending native checks](docs/UNIT_FRAME_SCALE.md). The
focused bridge model passes 17 checks; full 98-script/739-Lua report is in that chapter.
Preserve concurrent vehicle-seat work and verify native pixels, hit areas and
combat/taint when background-safe access is available.

Latest vehicle/durability change (30 October 2026): the 70%-scale seat indicator
sits left of equipment durability. If the micro menu or status strip is visible
at the top-left, both indicators sit below the lower strip without moving it.
Otherwise the pair starts at the screen top-left, subject to PvP-widget clearance.
Focused source-driven checks and the full 99-script/740-Lua desktop suite pass.
Native vehicle art, seat clicks, combat,
taint and all-client pixels remain pending. No client/settings interaction.

Latest work (30 October 2026): [unit power visibility](docs/UNIT_POWER_VISIBILITY.md)
hides Flux-owned main/raid power bars for known zero maximum and expands health.
Live/Forever keep full-height health behind power and pass maximum power through
secret-safe alpha; zero current keeps the resource visible. Focus-target and
pet-target were health-only already. Focused models and full 96-script/737-Lua
desktop suite pass; native all-client geometry/combat/taint/secret checks pending.
Health text uses full-height HP for a known zero maximum and stays in the health
section for restricted maxima. The Flux separator restores resource alpha after
partition/chrome repaints, including ToT refreshes; secret maxima are never
tested for truth in Lua. Player/target labels move to the expanded HP bar's
vertical middle for known zero power and restore nested placement on return;
ToT's separator container follows its raised side-by-side frame level. Native
text/border pixels remain pending.
WoW and on-disk settings/profilers were untouched. Source/test/docs were
published on main in `c313dc98a1e782aee1224554c347cd616f3ad7af`.
Preserve newer user changes before further work.

Latest user work: [teleport counts/interruption](docs/TELEPORT_CAST_WORK.md),
BUG-012/PERF-011. User confirms Retail. Candidate uses native count text and
restores the host without popup/binding rebuild. 527 focused checks, three
mutations, five desktop pairs and full 95 scripts / 736 Lua files pass. Native
reload/interrupted casts and comparison with non-travel custom flyouts pending.
No live game/settings changes. This fix is included in the current local-snapshot
publication payload; native acceptance retains its pending scope.

Continue in the existing `_FluxUI` folder/repository. On 29 October 2026 the user
requested that the current local files be uploaded to main, with no other branch.
Work on main only and preserve existing history/newer local edits; no force pushes.
See [publication record](docs/GITHUB_PUBLICATION.md).
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[development tasks](docs/DEVELOPMENT.md) and the [original stage tracker](docs/MODERNIZATION_PROGRESS.md).
The formerly pending objective-tracker source/test/records are included in commit
`73ca9d2`. Inspect current status before new work and preserve any newer user edits.

Earlier runtime `677d85c` shares activation within bar paint batches. Current full
workspace evidence: [95 scripts/736 Lua files](docs/validation/main-local-snapshot-2026-10-29.json).
[Action/player-aura audit](docs/ACTION_AURA_WORK.md) has five matched native pairs
per Retail/Era client, exact sources, unchanged57 button/aura-root geometries and
zero recorded matched-run errors. Native highlight was inactive; active combat/
secure input, dense/restricted auras and long-session leak acceptance remain pending.

Next priorities:

1. Attribute assisted-host icon/count/cooldown/usable work and repeated next-spell
   queries before sharing facts. Retail baseline4.814ms/s is inclusive, not a sum
   with its children. Preserve identity, effects and response cadence.
2. Exercise live enabled effects, paging/forms/modifiers/pet/stance/vehicle/input,
   aura expiry/reapply/reuse and combat/Edit Mode on exact builds. Top-right player
   aura data/handlers/style remain Blizzard-owned; no replacement painter.
3. Continue original API/lifecycle/private-cache and long-session gates. Keep
   auction, guild-bank and void-storage callbacks excluded.

Both clients remain open. Account sessions displace each other: test the named
characters sequentially using normal warning dismissal/Reconnect/selection.
Verify current executable/PID/window before messages; do not take foreground or
PC mouse/keyboard/clipboard. Final state: Era in world, Retail reconnect screen.
Original profiler0 Retail/1 Era and prior diagnostic roots restored. The existing
mirror job stays running unchanged (actual timeout1s despite60s text); verify file
hashes before reload and preserve unknown destination changes. No extra sync job.

Reproduction from the addon root:

```powershell
lua tests/assisted_highlight_work.lua --source tests/fixtures/assisted_highlight_before.txt --measure
lua tests/assisted_highlight_work.lua
lua Core/_tmp_playeraurassmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure intentionally exits0 with20 unmet work budgets; candidate must
pass. Feature removal, settings reset, history rewrites and a separate release
remain outside the authorization. Main publication is authorized for this batch.
