# FluxUI desktop stress-test record — 7 November 2026

<!-- STRESS-FIXES-20261107 -->
Implementation is now authorized and applied. [Current fix results](applied-fixes/README.md) supersede the earlier proposal-only status below. Current combined suite: **232 scripts / 896 Lua syntax files PASS**. Historical audit/proposal observations and source snapshots are retained with their original scope.
<!-- /STRESS-FIXES-20261107 -->

New phase: [concrete fix proposals before application](fix-proposals/README.md)
contains external candidates, staged diffs, baseline-versus-prototype tests and
explicit rejected/held options. No fixes have been applied to the addon.

Follow-up: [recurring secret-value errors](security/secret-value-followup/README.md)
adds the latest USER-001 logs and targeted alpha/geometry checks. Its source
checkpoint records newer external changes; the full-suite results below retain
their original captured-source scope.

The existing suite passes, and the additional stress tests reproduce **seven
issues** and identify **eight performance/freshness investigations**. The user's
additional **Forever fade taint error (USER-001)** is recorded and traced separately.
No fixes
were applied. This folder holds the test scripts, raw evidence and proposals
for later feature-preserving work.

The requested targets are **Classic Era, Classic Anniversary, Retail live and
Forever**. Existing progression fixtures provide extra coverage. Exact addon
hashes, dirty-working-tree identity and Gethe source pins are retained.

| Evidence | Result |
|---|---|
| Complete existing runner | **222/222 scripts pass; 885 Lua files compile; zero syntax failures**; full rerun also passes after concurrent source changes |
| TOC/XML/load scope | **598 reachable paths; no missing load references; 27 module groups indexed** |
| New modifier/mouseover/input tests | Five harnesses × three repeats; **4,940,991 assertions including 90 repeatable failed expectations for two issues** |
| Latest secure-input refresh | Three additional repeats after concurrent utility changes: **201,401 assertions per run**, all pass; original evidence retained |
| New security/combat/Respec tests | Five repeated processes; **121 assertions and 21 defect observations per process**; 3 million aggregate combat-queue requests |
| New performance/lifecycle tests | Four harnesses × five repeats; **58,850 expectations**, deterministic work counts, 3,864,000 aggregate modeled raid events; two service anomalies remain open |
| Independent service review | Scheduler 8-versus-9 callback control and event self-removal control independently reproduce both anomalies |
| Actual instance-dependent branches | Binding load gates: **113,715 assertions** across three repeats; mount/geography helper: **405,215 assertions** and **400,000 rapid transitions** across five repeats |
| Mail/Salvage lifecycle extension | **300,000 assertions** across three repeats; **60,000 mail cycles** and **15,000 Salvage cycles** |
| Existing documentation validation | Latest PASS:918 classified sources,598 reachable paths,24 SavedVariables,15131 local links. An intermediate six-entry stale-reference result is retained; other work refreshed those docs, and this audit made no existing-doc writes |
| New audit-folder validation | Python/Lua/JSON/CSV syntax, local links, finding references and latest885-file identities pass |
| Runtime/test source preservation | No runtime, test, TOC, XML, artwork or existing tool changes issued by this audit; compare final preservation evidence |
| Native taint, hardware input, pixels, FPS and native instance rules | **NOT RUN**, following the simulation-only request |

The input totals count assertions and repeated workloads, not millions of unique
scenarios. Security/performance harnesses can succeed while confirming an explicitly
recorded bad observation. Read finding status and evidence scope alongside exits.
Supplementary surface-lifecycle and real instance-gate tests have separate records
in the subfolders; they are not silently added to the table's original run totals.

Start with [the findings ledger](FINDINGS.csv) or [machine-readable findings](FINDINGS.json).
The detailed reports include exact triggers, source locations, evidence, proposed
fixes and regression acceptance:

- [Input ordering, hover and secure-dispatch stress](input/README.md).
- [Combat, native API ownership, Respec and remaining security surfaces](security/AUDIT.md).
- [Performance work counts, queue behavior, raid scaling and sustained auctions](performance/PERFORMANCE_AUDIT.md).
- [Independent review of the two latent service findings](input/service-peer-review.md).
- [User-reported Forever fade error and ranked caller trace](security/USER-001-FADE.md).
- [Actual instance/geography branch tests](performance/extra_instance_report.md).
- [Latest utility secure-input refresh](input/secure-input-latest-report.md).
- [Actual instance-dependent binding gates](input/instance-gates-report.md).

The highest-priority follow-up is Respec failure/deferred completion and cancellation
ownership (SEC-02/03), followed by the Forever global driver boundary (SEC-01).
INPUT-001/002 cover ordinary refresh ordering and a capability-dependent hover
fallback. LOGIC-01/02 are real service-contract edge cases whose ordinary current
gameplay trigger has not been established. USER-001 is the user's actual native
error report: Forever's outgoing fade arithmetic receives secret `startAlpha`.
Cast-bar and swing-timer getter-fed fades are leading candidates; the affected
frame/action is unknown. No agent-run native reproduction or fix is claimed.

[SCENARIOS.md](SCENARIOS.md) states what each model actually exercises. The raid
dispatcher has 96 parameter rows, but its world/dungeon/raid labels do not emulate
native encounter restrictions. [SOURCE_COVERAGE.csv](SOURCE_COVERAGE.csv) and
[MODULE_MATRIX.csv](MODULE_MATRIX.csv) include every loaded source/module and
make unverified branches visible. A literal test reference is not executed-line
coverage. Many indirect/unreferenced paths and integration permutations remain
unverified; this record does not establish that every possible addon path works.

Use [RUNBOOK.md](RUNBOOK.md) to reproduce checks, [SOURCES.md](SOURCES.md) for exact
client/version evidence, [CLIENT_LEDGER.csv](CLIENT_LEDGER.csv) for per-client
acceptance boundaries, and [PERFORMANCE_LEDGER.csv](PERFORMANCE_LEDGER.csv) for
future optimization work. [REQUIREMENTS.md](REQUIREMENTS.md) and
[CONTINUITY.md](CONTINUITY.md) retain the current task contract and handoff.
New user errors can be added through [ERROR_INTAKE.md](ERROR_INTAKE.md) while
other tests continue.

Only new files inside `Stress test doc` and the external checkpoint were written
by this audit. Other work updated existing documentation and four Lua files
(`ExtraButtonSystem/Engine/Paint.lua`, `tests/utility_mixed_faces.lua`,
`ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua` and
`tests/utility_secure_input.lua`), and
on-disk settings changed during the run; those observations are retained in
[preservation.json](evidence/preservation.json), with no rollback or attribution
to an addon test. The full suite was rerun against the newer code; its exact
manifest is [existing-suite-latest.json](evidence/existing-suite-latest.json),
with [full before/after identity verification](evidence/latest-corpus-check.json).
Earlier stress results keep their original hashes; utility secure-input stress
was refreshed separately for the changed Manager/fixture, with three new passes.
The changed Paint module is not consumed by the new stress reproducers. No game input,
settings/profiler write, manual sync, Git commit, branch or push was issued.
