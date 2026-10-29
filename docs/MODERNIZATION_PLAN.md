# Modernization audit and implementation sequence

The source checkpoint and fresh baseline are complete. The first runtime batch
fixes built-in currency callbacks after external Syndicator readiness. This is
the start of the requested modernization, not completion of the larger project.
The supplied Word/Markdown plan and all 26 supplied specification documents are
requirements sources. Current code and later fixes take precedence over historical
claims about what has already been implemented; discrepancies remain explicit in
the feature inventory.

## Current findings

| ID | Finding and evidence | Status / consequence |
|---|---|---|
| BUG-001 | Builtin currency starts before Syndicator Ready. Its four subscribed callbacks lack the provider check already present in Refresh and Store setters. Real Store/Currency/Adapter replay overwrites provider money 999 with builtin 654 after readiness. | Reproduced on baseline; fixed in first batch. See `tests/currency_provider_handoff.lua` and [performance evidence](PERFORMANCE_PROTOCOL.md). |
| PERF-001 | Per 400-event mocked handoff burst: 100 unnecessary GetMoney calls, 100 generation writes, 300 requests without warband or 400 with warband. | Deterministic measured desktop operation counts; candidate removes that work. Requests are not scheduler executions. Native CPU/FPS benefit remains unmeasured. |
| AUDIT-001 | Core.Module has no generic resource scope/cancellation; production registrations do not provide OnDisable cleanup. | Source finding, not proof that every feature leaks. Trace real disable and combat-deferred callers before changing the shared contract. |
| AUDIT-002 | Core.Events iterates a mutable handler list; Unregister removes array entries. RegisterUnit allocates a frame per call. | Reentrancy and caller-lifetime audit required. No native defect or general frame leak inferred from these source patterns. |
| AUDIT-003 | Core/API and Core/FluxAPI both load; client flag meanings and callers differ. | Inventory migration contracts before moving a domain. Do not introduce a third backend. |
| AUDIT-004 | Older integration docs describe removed global item API wrappers and timeout fallback; current code uses local adapters and late Ready handoff. | Correct reference prose from actual source; retain old performance reports with their historical limits. |
| AUDIT-005 | Installed Retail executable 12.1.5 differs from spec 12.1.0 and TOC 120100. Other installed builds and unavailable Wrath/Cata targets need separate evidence. | Exact build matrix records metadata, not acceptance. Do not change TOC declarations without testing. |
| AUDIT-006 | Earlier native CPU/resource optimizations are present; fresh original suite passes 81 scripts and 722 syntax files. | Preserve as regression controls. Historical hotspots are not newly reproduced performance problems. |

No additional current native bugs or FPS deficits were reproduced in this session.
Historical taint/performance reports stay pending revalidation against exact builds.

## Priorities and gates

1. **Provider ownership (this batch):** retain standalone/pending-provider immediate
   currency behavior; prevent stale built-in callbacks after handoff. One runtime
   file, one focused regression, raw before/after counts and complete suite.
2. **Core lifecycle correctness:** reproduce event-dispatch mutation and queued
   enable-after-disable behavior using actual consumers. Define cancellation and
   desired-state semantics; make one bounded fix before migrating features.
3. **Client API consolidation:** compare return shapes, nil/readiness/secret rules
   and flag meanings; migrate one domain's consumers with aliases only where needed.
4. **Inventory and economy:** audit remaining provider callbacks, duplicate scans,
   metadata/classification/protection and operation-time slot validation. Preserve
   restock quantities, saved ledgers, gear masks and late-provider continuity.
5. **Layout, bars and bindings:** establish native screenshots/input baselines;
   measure redundant geometry/paint/compilation; retain current cadence, effects,
   paging and binding retention. Separate mechanical moves from algorithms.
6. **Unit/raid/nameplates and integrations:** map resource lifetimes and hidden work;
   verify all client/security gates and provider absent/ready/late-load orders.
7. **Persistence and release:** remove only proven obsolete consumers, validate
   non-destructive upgrades/rollback, and complete cumulative native acceptance.

Each step needs affected parity rows, before identity/scenario, outcome tests,
matched measurements and a small reviewable change. Missing native tests prevent
native certification; they do not prevent independent audits or desktop fixes.

## Audit records

- [Feature inventory and discrepancies](FEATURE_INVENTORY.md), `FEATURE_PARITY.csv`.
- [Module dependencies and lifecycle](MODULE_DEPENDENCIES.md), `MODULE_OWNERSHIP.csv`, `API_MIGRATION.csv`.
- [Client/native validation](CLIENT_VALIDATION.md), `CLIENT_MATRIX.csv`, `REFERENCE_MANIFEST.csv`.
- [Performance protocol](PERFORMANCE_PROTOCOL.md), `PERFORMANCE_RESULTS.csv`, `validation/` raw evidence.
- Existing [source coverage](30-source-coverage.md), [controls](26-options-map.md),
  [commands and bindings](31-commands-and-bindings.md), [persistence](32-saved-variables.md),
  and generated `reference/` indexes remain the detailed source cross-reference.
