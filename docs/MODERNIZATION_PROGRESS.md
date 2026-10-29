# Original plan: implementation progress

Updated 29 October 2026. The governing requirements remain the supplied
[modernization plan](../new%20docs/docs/FluxUI_Modernization_Plan.md) and
[26 specifications](../new%20docs/docs/specs/00-README.md). Work stays in the
existing `_FluxUI` addon and repository. The existing change branch continues;
main stays at `7436820453d2248c84c99fff71507553efc47c19`.

This tracker distinguishes completed batches from the original stage exit gates.
No stage with pending native acceptance is declared finished merely because its
source inventory or desktop tests pass.

| Original stage | Established evidence | Remaining gate / next work |
|---|---|---|
| 0: checkpoint, inventory and baselines | External actual-file/history/settings recoveries; all 26 specifications indexed; 1,384 parity requirements/control rows, eight client rows, 35 ownership rows; complete desktop validation and scoped native Era/Retail captures | Extend per-feature native scenarios, matched screenshots and exact-build acceptance. Preserve newer local work at every batch. |
| 1: correctness and lifecycle | Provider handoff, pending mail, disabled mover, queued merchant identity/stock, chat ownership, loot waiter reuse and diagnostic snapshot release have focused regressions | Exercise real enable/disable/partial setup/profile/combat cycles across remaining modules. Event mutation is latent with no production unsubscribe trigger; avoid speculative shared rewrites. |
| 2: one client API contract | Existing ownership/dependency and API migration ledger identifies overlapping Core/API and Core/FluxAPI contracts and distinct client flag semantics | Choose one bounded domain, compare actual consumers/return shapes/readiness/security, migrate it, then retire its last duplicate implementation. No third backend. |
| 3: layout/rendering | Stable chat column/reload/tab geometry verified on Retail; existing unit/layout idle regressions retained | Native pixel/input/geometry acceptance across layouts, scales and clients. Attribute repeated writes before changing paint. |
| 4: inventory/economy | Provider continuity, merchant validation/stock and redundant tier checks fixed; native Era count getter pairs preserve outputs with lower measured CPU | Whole-vendor after latency, positive bank/warband quantities, cold metadata, external providers and interrupted operations. Auction/guild-bank/void callbacks stay deferred by user instruction. |
| 5: actions/bindings/feedback | Existing paging, badges, binding and resource regressions retained; Retail assistant tick identified in CPU capture | Matched assisted-action query/paint traces, affected-slot reconciliation, native secure input and animation continuity. Keep current timing. |
| 6: frames and feature ownership | Unit resources and loot waiters have bounded reuse tests. Nameplate countdown now has measured duplicate-lookup/allocation removal and lifecycle controls | Native countdown reuse/restricted-display acceptance, unit/raid density and private-cache long-session stress. Extract responsibilities only when coupling/measurements justify them. |
| 7: optional integrations | Inventory includes absent/ready/late-provider requirements and existing Questie/Baganator/Details/Syndicator contracts | Test installed versions and readiness order natively, then consolidate only proven duplicate work. |
| 8: persistence/package/release | Addon identity, 23 saved roots, options/defaults/assets/licenses preserved; no forced reset or new addon/repository | Non-destructive upgrade/rollback/malformed roots, cumulative native acceptance and reproducible release packaging. No merge/release authorized. |

For the latest bounded batch see [nameplate countdown evidence](NAMEPLATE_COUNTDOWN_WORK.md).
For the broader resource/CPU pass see [Retail audit](RETAIL_PERFORMANCE_AUDIT.md)
and [26-domain driver inventory](PERFORMANCE_AUDIT.csv). The feature ledger records
requirements, not universal native certification. Original Wrath 3.3.5 remains
distinct from modern Wrath Classic and unsupported/unverified in this checkout.

Working rules and exact next commands are maintained in the root continuity files
requested by the user, alongside the existing contribution/development records.
Private WTF exports and screenshots remain outside the repository. Background
PC use, main and the three deferred callback domains remain protected.
