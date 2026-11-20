# FluxUI release roadmap

**20 November 2026 · Release acceptance pending**

## Addon end goal

Deliver a stable main snapshot of FluxUI for Retail, Forever, Classic Era, Anniversary/TBC and Mists Classic. The addon is ready when supported workflows work as documented on the shipped snapshot, upgrades preserve user data and controls, and the reported hitches pass their live checks. At that point, close the release effort and move to maintenance. A later feature or regression gets its own scope and acceptance check.

## Release gates

Run one acceptance round on a pinned candidate. Record the commit and any local changes used for testing. Give each gate a result of passed, failed, pending, or inapplicable under the documented client contract. Include the evidence and the workflow that remains for every pending or failed gate.

| Gate | Done when | Current evidence |
| --- | --- | --- |
| Install and upgrade | Each advertised client loads and reloads on fresh data and on a protected copy of an existing profile. The active layout, bindings, account and character settings, and saved data survive. No startup or load-order errors block normal use. | Target clients and test steps are documented. Release-snapshot results are pending. [Client matrix](02-multi-client-matrix.md) · [Verification checklist](41-verification.md#startup-and-persistence) |
| Core gameplay and UI | Check actions and bindings with modifiers, protected actions through combat, player and group frames, and HUD placement. In supported inventory and commerce paths, verify counts and controls with built-in providers and the applicable optional integrations. Required workflows retain their documented behavior and have no unresolved blocking errors, wrong actions, data loss, or new addon taint. | Desktop and selective native observations exist. Complete the applicable native smoke checks against the release snapshot. [Feature inventory](FEATURE_INVENTORY.md) · [Client results](CLIENT_VALIDATION.md) |
| Reported performance | The HUD acceptance matrix passes, including action-strip crossings without a drop, rapid drops and party/raid changes. Carry forward the verified inventory fixes and resolve a deferred inventory scenario before release if it reproduces a material problem in a supported workflow. | R189 carries forward the HUD performance changes and fits the cast rim and divider. The inventory optimization pass closed after 82 regression scripts. Native HUD acceptance and deferred inventory checks have separate records. [HUD roadmap](HUD_PERFORMANCE_ROADMAP.md#finish-line) · [Inventory roadmap](INVENTORY_PERFORMANCE_ROADMAP.md#finish-point) |
| Source and distribution | Run the existing desktop regression suite, Lua syntax and load checks, and documentation validation for the pinned snapshot. Triage failed fixtures against their exact baseline and record unresolved coverage. Verify the installable payload, notices and main publication identity under the existing policy. | Prior runs cover individual snapshots. The full release gate is pending for the selected release candidate. [Contributing](../CONTRIBUTING.md) · [Publication policy](PUBLICATION.md) |

## How this ends

1. Take the current candidate through the gates once. Start with the HUD live scenarios where the hitches were reported.
2. Fix a reproducible release blocker in its owning subsystem. Rerun the failing scenario and the tests affected by the fix. Carry previous results forward when the tested feature and its dependencies still match.
3. When the required gates pass, record release readiness in [status](STATUS.md) with the candidate identity and evidence. Publish under the existing policy when authorized. Close the release effort.

Small improvements, coverage beyond the supported release workflows, and performance ideas without a reproducible release blocker stay in the relevant backlog. If a required scenario is unavailable, record the specific blocker and retain the candidate. Further optimization needs a failing check or a separately requested goal.
