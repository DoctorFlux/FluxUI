# Next session

Continue in the existing `_FluxUI` folder/repository. On 29 October 2026 the user
authorized uploading the complete tested work to main. Preserve the development
branch and existing history; no force pushes. See [publication record](docs/GITHUB_PUBLICATION.md).
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[development tasks](docs/DEVELOPMENT.md) and the [original stage tracker](docs/MODERNIZATION_PROGRESS.md).
The formerly pending objective-tracker source/test/records are included in commit
`73ca9d2`. Inspect current status before new work and preserve any newer user edits.

Current runtime `677d85c` shares activation within bar paint batches. Full actual-
workspace evidence: [94 scripts/735 Lua files](docs/validation/github-publication-2026-10-29.json).
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
