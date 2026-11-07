# Stress-test requirements — 7 November 2026

<!-- STRESS-FIXES-20261107 -->
The later user instruction “fix everything now” authorizes runtime fixes. Earlier no-edit/proposal-only requirements are superseded for this implementation phase. Preserve simulation-only execution, all features/settings and the captured audit evidence. [Applied requirements and acceptance](applied-fixes/README.md).
<!-- /STRESS-FIXES-20261107 -->

User request: audit and simulate the whole addon now; document errors and future
feature-preserving optimizations/fixes; do not change addon code or test in game.

| ID | Requirement | Acceptance evidence |
|---|---|---|
| ST-01 | Era, Anniversary, Retail live and Forever are separate targets | Exact Gethe branch/commit/version pins and separate coverage/unknowns |
| ST-02 | Preserve current addon, settings, commands, appearance and features | Raw-byte before/after manifest; no existing files intentionally modified |
| ST-03 | Run the complete existing desktop suite | Canonical runner without `--sync-docs`; syntax and each script exit/output retained |
| ST-04 | Very fast Shift/Ctrl, overlapping chords and repeated release | Production-executing stress harnesses, counts, ordering and cleanup assertions |
| ST-05 | Rapid mouseover/target changes mixed with other events | Positive and reversed-order controls; missing/friendly/hostile target paths where modeled |
| ST-06 | Combat entry/exit and protected state | Production queue/security checks; distinguish modeled illegal-write traps from native taint |
| ST-07 | World, dungeon and raid; solo/party/raid sizes | Explicit scenario ledger; mark real modeled axes versus unexecuted combinations |
| ST-08 | Whole-addon performance and lifecycle review | Source/load/driver coverage; burst/backlog/disabled work and scaling checks; remaining hotspots |
| ST-09 | Whole-addon taint review | Protected/global/native-hook/secret ownership review; reproduced defects separated from risks |
| ST-10 | Continue testing despite failures and incorporate later user errors | Per-test isolation and error intake template with stable finding IDs |
| ST-11 | Future fixes preserve features | Each finding has trigger, evidence, proposed remedy and regression acceptance; no fixes now |
| ST-12 | Reusable `Stress test doc` folder | README, run instructions, scripts, raw results, source identities and resume record |
| ST-13 | No foreground/game input or settings/profiler changes | Desktop-only commands and private metadata outside AddOns; no native acceptance inferred |

Explicit scope decision: the four requested branches extend the skill's three-target
shortcut; `classic` progression is only additional regression coverage and does not
stand in for Era or Anniversary. The user's current no-edit constraint takes
precedence over repository instructions to rewrite existing continuity files.
Continuity and parity/client/performance deltas for this audit stay in this folder.

Testing preference is already explicit: simulations here, no in-game testing.
No UI change or mock-up is requested. Native rendering, C-side restrictions,
hardware input, real secret values, FPS and native taint propagation remain pending.
No finite mock suite establishes that every possible addon/client combination works.

## Delivery reconciliation

| IDs | Delivered evidence | Remaining boundary |
|---|---|---|
| ST-01 | Four current branch pins, versions, targeted current-source comparisons and separate client ledger | Installed/in-memory builds unqueried |
| ST-02 | Audit writes confined to new folder/external checkpoint; original manifest retained; concurrent source changes preserved and canonical suite rerun | Final preservation records external documentation/settings and four Lua-file changes; do not claim global byte-for-byte stability |
| ST-03 | Initial and final full runs:222/222 scripts;885 syntax files;zero failures | Desktop Lua5.4.6 differs from WoW runtime |
| ST-04/05 | Saturated modifier/utility/modern+legacy mouseover tests; two repeatable findings with controls; three repeats | Native hardware/secret/secure VM unverified |
| ST-06 | Combat queue/reentry/ownership/cancellation stress; three reproduced security/correctness findings | Native taint is not certified by mocks |
| ST-07 |0/1/5/40 raid-owner scale;400 native-source roster transitions in existing secure fixture per client; actual six-type Binding gates and mount/geography restriction/settle tests | Whole integrated encounters/server restrictions/native instance semantics unverified; some raid axes are labels only |
| ST-08 |598-path load inventory;575 reachable Lua driver scan; sustained auction/queue/idle/plate/raid work counts;8 future performance investigations | No native CPU/FPS/GC or exhaustive executed-branch coverage |
| ST-09 |663-file lexical security screen;62 manually reviewed boundaries;8 native-only review items;focused reproductions;USER-001 intake/source trace | Remaining code is screened rather than manually proved; native provenance/actual taint reproduction pending |
| ST-10 | Runners continue after individual findings; USER-001 added during testing; user confirms Forever and does not know trigger | First taint source/frame/combat/context unconfirmed |
| ST-11 | Every ledger entry has a feature-preserving direction and regression acceptance; no fixes applied | All implementation belongs to later request |
| ST-12/13 | Reusable scripts/reports/raw results/source identities/continuity; no foreground/game/settings/profiler action | Preserve private metadata externally and repeat source checks on future work |

This reconciliation completes the documented desktop audit scope and preserves
unperformed or unknowable checks explicitly. It is not acceptance of every native
client, branch, integration or encounter, and no open finding is marked fixed.
