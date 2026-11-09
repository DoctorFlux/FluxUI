# Round 2 audit requirements

The active request is to look for more errors, taint risks and performance issues
throughout the current addon, give extra attention to extra buttons, action bars,
bindings and badges, and prepare documentation and a roadmap. **Do not change
addon code in this phase.** Earlier fix authorization does not authorize new fixes.

| ID | Requirement | Evidence required |
|---|---|---|
| R2-REQ-01 | Inspect the current worktree; preserve newer independent changes. | Fresh revision/dirty-state/source manifest; final preservation comparison. |
| R2-REQ-02 | Cover the whole loaded addon and optional integrations. | Current TOC/XML closure and source screening index; module review matrix identifying actual reviewed paths and unresolved coverage. |
| R2-REQ-03 | Deeply inspect extra buttons, action bars, bindings and badges. | Production-code review and focused executable scenarios with exact source identities and state transitions. |
| R2-REQ-04 | Investigate errors and taint/secret/protected-operation hazards. | Source-pinned access contracts, call/ownership trace and reproducible conditional or actual failures; no inference of native taint safety from mocks. |
| R2-REQ-05 | Investigate performance, lifecycle and rapid-input behavior. | Deterministic work/resource counts and cleanup checks, including modifiers, mouseover, reuse, hidden/disabled state and combat transitions. Native CPU/FPS remains separately untested. |
| R2-REQ-06 | Retain Era, Anniversary, Retail live and Forever targets. | Four freshly resolved Gethe commit pins, version metadata and target-specific availability/unknown states. Extra progression fixtures are supplementary. |
| R2-REQ-07 | Produce usable findings and a dependency-ordered roadmap. | Stable finding IDs, severity/evidence class, trigger, exact source, impact, feature-preserving fix options and concrete acceptance criteria. |
| R2-REQ-08 | Avoid repeating fixed or unreachable findings as new bugs. | Compare prior applied findings and current loading/capability paths; retain negative controls and rejected leads. |
| R2-REQ-09 | Keep this phase read-only for addon code and settings. | Writes confined to audit documentation/harnesses, external source snapshot and final documentation continuity/ledger updates. No runtime/test/TOC/art changes, game control, profiler or WTF writes. |
| R2-REQ-10 | Deliver honest scope and maintain continuity. | Current results, known limits, next actions and requirement-by-requirement completion audit; update documentation ledgers without implementing proposals. |
| R2-REQ-11 | Explicitly simulate very rapid Shift, Ctrl and Alt press/release. | All eight held chords, taps, overlapping holds, release-order permutations, same-frame bursts, duplicate/reordered payloads, mouseover/target overlap and combat transitions. Test final state, selected bindings/faces, work/queue/resource bounds and stated protected-write guards; keep native input/taint/FPS untested. |

The original simulation-only preference remains in effect. Native secure VM,
true secret values, rendering, FPS and instance restrictions are not emulated by
desktop Lua. Guild-bank and void-storage callbacks remain excluded by the
repository instructions; record their exclusion rather than silently reviewing
or changing them. Normal world/dungeon/raid/combat labels establish only the
branches the fixture actually drives.

The goal is an actionable audit and roadmap, not a claim that every possible
native execution is error-free. Review gaps and native acceptance belong in the
roadmap and must remain visible.
