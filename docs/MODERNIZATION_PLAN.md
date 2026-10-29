# Modernization audit and implementation sequence

The source checkpoint and fresh baseline are complete. BUG-001 fixes builtin
currency callbacks after external Syndicator readiness; BUG-002 cancels stale
mail and owned-auction scans at the same ownership boundary. BUG-003 prevents
pending builtin mail completion from modifying provider-owned recipient data.
Next reproduce remaining auction/guild/Void event work after Ready.
The broader modernization and native acceptance remain unfinished.
The supplied Word/Markdown plan and all 26 supplied specification documents are
requirements sources. Current code and later fixes take precedence over historical
claims about what has already been implemented; discrepancies remain explicit in
the feature inventory.

## Current findings

| ID | Finding and evidence | Status / consequence |
|---|---|---|
| BUG-001 | Builtin currency starts before Syndicator Ready. Its four subscribed callbacks lack the provider check already present in Refresh and Store setters. Real Store/Currency/Adapter replay overwrites provider money 999 with builtin 654 after readiness. | Reproduced on baseline; fixed in first batch. See `tests/currency_provider_handoff.lua` and [performance evidence](PERFORMANCE_PROTOCOL.md). |
| PERF-001 | Per 400-event mocked handoff burst: 100 unnecessary GetMoney calls, 100 generation writes, 300 requests without warband or 400 with warband. | Deterministic measured desktop operation counts; candidate removes that work. Requests are not scheduler executions. Native CPU/FPS benefit remains unmeasured. |
| BUG-002 | Queued/partial builtin mail and owned-auction StepScan callbacks continued after Ready, overwriting provider snapshots and notifying consumers. An unchanged provider mail fingerprint could leave the overwritten data in place. | Fixed in runtime commit `05e9f79`; 210 targeted checks pass, plus 83 complete-suite scripts and 724 Lua syntax files. [Lifecycle evidence](PROVIDER_HANDOFF_LIFECYCLE.md). No particular native tooltip/gameplay symptom established. |
| PERF-002 | After handoff, queued/partial mail reads were 105/56 and auction reads 71/38 per mocked case; stale snapshot increments and notifications were one each. | Candidate reduces these operations to zero. Five alternating pairs have zero per-case count variation; no native CPU/FPS or whole-addon speedup claim. |
| BUG-003 | Pending builtin mail send/return completion crossed Ready and obtained/appended to a provider-owned recipient table through Store.GetCharacter. | Fixed in runtime commit `ab4e658`; 410 focused checks pass after eight baseline failures. Five matched pairs reduce lookup/foreign append counts from one to zero in four successful completion cases. Standalone 100-cycle checks retain one frame, zero final completion subscriptions and 50 credits per action. Full suite: 84 scripts/725 syntax files pass. Native acceptance pending. |
| AUDIT-001 | Core.Module has no generic resource scope/cancellation; production registrations do not provide OnDisable cleanup. | Source finding, not proof that every feature leaks. Trace real disable and combat-deferred callers before changing the shared contract. |
| AUDIT-002 | Production Events replay confirms self-removal skips a later handler and remove-plus-add changes same-event behavior. Context.DisarmEvents is the sole active source consumer through alias Ev; no production Context.Unsubscribe invocation was found. | [Latent API defect](EVENT_DISPATCH_AUDIT.md), not demonstrated gameplay failure. Defer dispatcher changes until an actual teardown consumer or reproduced trigger justifies them. RegisterUnit lifetime audit remains separate. |
| AUDIT-003 | Core/API and Core/FluxAPI both load; client flag meanings and callers differ. | Inventory migration contracts before moving a domain. Do not introduce a third backend. |
| AUDIT-004 | Older integration docs described removed global item API wrappers and timeout fallback; current code uses local adapters and late Ready handoff. | Reference prose corrected from actual source. Retain older performance reports with their historical limits. |
| AUDIT-005 | Installed Retail executable 12.1.5 differs from spec 12.1.0 and TOC 120100. Other installed builds and unavailable Wrath/Cata targets need separate evidence. | Exact build matrix records metadata, not acceptance. Do not change TOC declarations without testing. |
| AUDIT-006 | Earlier native CPU/resource optimizations are present; the original baseline passed 81 scripts/722 syntax files and latest BUG-003 candidate passes 84 scripts/725 syntax files. | Preserve as regression controls. Historical hotspots are not newly reproduced performance problems. |
| AUDIT-007 | Auction SHOW queries, guild-bank queries and Void callbacks have additional provider-ownership boundaries. | Source-audit candidates only; reproduce and measure independently before expanding scope. |

No additional current native bugs or FPS deficits were reproduced in this session.
Historical taint/performance reports stay pending revalidation against exact builds.

## Priorities and gates

1. **Provider ownership:** BUG-001, BUG-002 and BUG-003 are complete in desktop
   validation. Next reproduce auction/guild/Void event work after Ready against
   production callbacks; preserve standalone and pending-provider behavior. Those
   findings remain unmeasured until replay. Keep each correction separate with raw
   before/after counts and complete suite.
2. **Core lifecycle correctness:** event-dispatch mutation is now reproduced as a
   latent API defect; no current production unsubscribe path justifies prioritizing
   a dispatcher change over active provider work. Trace queued enable-after-disable
   callers and define desired state/cancellation before migrating feature lifecycles.
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
- [Deferred provider scan evidence](PROVIDER_HANDOFF_LIFECYCLE.md) and [event-dispatch consumer audit](EVENT_DISPATCH_AUDIT.md).
- [Client/native validation](CLIENT_VALIDATION.md), `CLIENT_MATRIX.csv`, `REFERENCE_MANIFEST.csv`.
- [Performance protocol](PERFORMANCE_PROTOCOL.md), `PERFORMANCE_RESULTS.csv`, `validation/` raw evidence.
- Existing [source coverage](30-source-coverage.md), [controls](26-options-map.md),
  [commands and bindings](31-commands-and-bindings.md), [persistence](32-saved-variables.md),
  and generated `reference/` indexes remain the detailed source cross-reference.
