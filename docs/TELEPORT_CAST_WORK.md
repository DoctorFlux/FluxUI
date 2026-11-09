# Teleport counts and interrupted casts — 29 October 2026

User confirms Retail: severe lag when interrupting teleport/portal casts, including
flyout selections, and unwanted count numbers for reagent-free travel spells.
The suggestion that every custom flyout is affected remains unconfirmed. This
change targets the reproduced teleport host path; shared flyout effects and other
travel modules are unchanged.

BUG-012/PERF-011 removes redundant work. Destination eligibility previously built
reagent/restock rows just to count spell choices. Unlock ran the complete Update,
reapplying click handlers, repainting, rebuilding the popup and bindings. Eligibility
now requests only the existing filtered spell list. Unlock restores the macro,
current modifier face and visible tooltip. Spellbook/options/favorites handlers
still own complete updates. Combat deferral and success delay remain unchanged.

The preset count uses C_Spell.GetSpellDisplayCount when available, including empty
text and direct FontString forwarding of opaque display text. Known legacy rune
costs still use inventory counts, including zero. No identified reagent clears
stale digits instead of falling through to the generic cast-count painter.
Inaccessible tooltip text no longer manufactures a Rune of Teleportation/Portals
requirement. Inventory reagent fallback, restock targets, saved variables and
popup reagent editing remain in place. No new runtime resources are introduced.

Baseline HEAD `b45eb5ecd52472b54eefe0249707c972c45c8d2d`, tree
`1325e1301dfe2b11f49fd4057ef75bee6fa344d1`; initial working tree clean.
[External recovery](RECOVERY.md) verified before runtime edits. Normalized SHA-256:

| Source | SHA-256 |
|---|---|
| Baseline fixture | `dedea8c43d47f150888993bc54e2a0445e94ceacb53b141b3c6b3d3cf57b20a6` |
| Candidate TeleportPortal.lua | `1722862a1b1417df699382172d8b13a37f86f387ef0bd06050c43004efdae8fb` |
| Focused test | `7842024ac5441f7f3298f77d8dc32c6820b45c074946ff30147a0248f5c02e8e` |

[Real-source replay](../tests/teleport_cast_work.lua) loads the full module/event
handler plus the exact installed count override. APIs/UI transport are mocked.
Integrated replay retains production lock/unlock, macro construction, click setup,
icon restoration and count handling. Five alternating fresh-process pairs:

| Per 100 start/interruption cycles | Baseline | Candidate |
|---|---:|---:|
| Integrated tooltip SetSpellByID calls | 2,000 | 0 |
| Popup rebuild boundary calls | 100 | 0 |
| Focused failures among 527 assertions | 14 | 0 |

All five pairs have identical counts. Assertions cover modifier macros,
right/middle click attributes, hidden choices, legacy rune counts, native
empty/opaque text and deferred combat unlock. Three mutations restoring a full
unlock update, disabling native display or reintroducing destination reagent scans
are rejected. [Raw pairs/source identities](validation/teleport-cast-comparison-2026-10-29.json).
[Full suite](validation/teleport-cast-full-2026-10-29.json): 95 desktop scripts /
736 Lua syntax files, zero failures.

Counts do not establish native latency/FPS or prove the in-game hitch fully
resolved. No game window/input, profiler preference, saved setting or diagnostic
root changed. Native Retail reload, both mode counts, favorite/modifier and
flyout-selected casts, movement/Escape interruptions, success, combat/taint and
matched latency/pixels remain pending. Compare a non-travel custom flyout before
attributing this to every shared flyout. Other native clients remain pending.

```powershell
lua tests/teleport_cast_work.lua --source tests/fixtures/teleport_cast_before.txt --measure
lua tests/teleport_cast_work.lua
python tests/run_validation.py --output docs/validation/teleport-cast-full-2026-10-29.json --sync-docs
```

Baseline measure mode intentionally exits zero with 14 unmet assertions. Candidate
must pass. The user has authorized including these current local files in the
main-only publication. Native validation remains pending; publishing does not
promote desktop checks into native acceptance.
