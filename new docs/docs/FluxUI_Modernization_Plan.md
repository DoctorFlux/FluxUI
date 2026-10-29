# FluxUI modernization and optimization plan

29 October 2026

## 1 Recommended direction

Modernize the existing DoctorFlux/FluxUI repository in place. Keep the addon usable while repairing defects, consolidating duplicated responsibilities, introducing real module ownership and optimizing measured hotspots. Retain sound code and existing fixes; rewrite individual subsystems when their contracts, defects or measured cost justify it. The end result should be clean and modular throughout, with the same player experience and feature set.

Definitive user instruction: continue directly from the existing _FluxUI files in the current DoctorFlux/FluxUI repository. Do not create a second working addon, a separate working repository, a derived FluxUI package or a renamed addon. Reuse, refactor, repair and selectively rewrite the current implementation. This supersedes all earlier empty-project, reference-only-source, separate-addon, separate-repository and rename instructions. Preserve the appearance, features, settings, performance-testing, client and AI-continuity requirements.

Use a branch such as refactor/modular-runtime in https://github.com/DoctorFlux/FluxUI. Keep its history. Do not create a second product, fork its feature set, or switch to an empty runtime. Keep the current _FluxUI folder/TOC, addon identity, public commands, bindings and SavedVariables during stabilization. The addon remains _FluxUI. No rename or separate product is part of this plan.

This is a full modernization scope, not permission for endless cosmetic edits. Every feature needs clear ownership and a supported contract. Work in small, runnable stages, removing obsolete paths as their consumers migrate. A file move is not proof that a system became modular, and a third API wrapper is not consolidation.

## 2 Current findings and evidence

GitHub returned main as the default branch and 7436820453d2248c84c99fff71507553efc47c19 as the latest commit during this review. Inspect actual HEAD and local changes again when implementation begins; never reset newer work to this research revision. Selected source and repository records were reviewed. No source changes or new native performance tests were performed in this planning turn.

| Finding in the current source | Implication for the rework |
| --- | --- |
| A shared Flux kernel, API adapters, scheduler, inventory service and phased startup already exist | Consolidate these foundations and preserve their working contracts |
| The TOC loads Core/API and Core/FluxAPI | Migrate callers to one canonical contract and retire the legacy layer after its consumers reach zero |
| Client flags have different meanings between the two layers | Define identity and capability semantics before changing callers |
| Core/Module delegates cleanup to OnDisable and only its enable path has a generic protected/combat guard | Add scoped resources and explicit safe enable, suspend and disable transitions |
| Events.RegisterUnit allocates a frame per registration | Audit caller lifetime and reuse; this does not establish that every existing caller leaks |
| Large files combine construction, state, rendering and policy | Extract responsibilities behind tested contracts rather than moving arbitrary line ranges |
| Existing test/performance facilities and fixes are present | Extend and reproduce them before adding competing infrastructure |

The latest commit reports 81 desktop scripts and 722 Lua syntax checks, while older verification records describe 72 and 710. These are repository reports, not checks rerun here. Make evidence identify the exact tested tree and dependencies. Prior loader analysis counted 554 potentially reachable Lua files across declared variants; this is not a measured per-client execution count or an FPS diagnosis.

The repository's Retail profile report records addon CPU dropping from 13.78 to 5.56 ms/s while average profiled FPS changed from 288.82 to 285.49. It supports a lower recorded CPU cost, not an FPS improvement. Preserve its measurement distinctions. Existing optimizations should be regression controls, not presented as unimplemented opportunities.

Preserve the outcomes of existing fixes: customized keybindings are not reset automatically; failed Respec restore retains recovery information; Baganator identity uses local adapters; legacy settings migration retains data; frame/watchers are reused where already fixed. Historical findings in older reports are not automatically current bugs. Reproduce the trigger before applying another fix.

## 3 Backup and behavior contract

Create a source checkpoint before edits: current committed revision plus relevant dirty/untracked files, media and a file hash manifest. Keep a dated archive of the actual _FluxUI source outside active Interface/AddOns folders as an immutable restore/comparison artifact. This is a backup, not another working addon or installation. A branch/tag captures committed source only and does not preserve the user's settings. Preserve any older concept backup separately. Do not force-push or move existing checkpoint tags.

Before live changes that affect saved data, bindings or game settings, back up the relevant account/character SavedVariables and affected settings. Close WoW for offline WTF copying/restoration. Keep private data out of the public repository. Continue implementation in the existing _FluxUI project, optionally using an ordinary change branch within that same repository. Protect unrelated local edits. Test baseline and candidate sequentially using preserved revisions/artifacts; do not create or enable a second addon. The frozen archive and settings backup must not be overwritten by development.

Record all current features, options, defaults, independent scopes, commands and integration outcomes in a parity ledger. Include stored preferences without visible controls and failure/recovery behavior. Use the 26 product documents as detailed input, then reconcile them with observed current behavior and later fixes. They contain old from-scratch wording and some inconsistencies; retain their product intent, with this modernization decision overriding their implementation method.

Preserve pixel geometry, scaling/squeeze, textures/UVs, fonts, colors/alpha, borders, gaps, strata/clipping, labels/order, hit rectangles, tooltips, hover/press effects, animation continuity and input/update timing. Preserve every existing visibility mode, profile operation and account/character scope. Do not redesign options or reduce animations, portraits, badge density or responsiveness as an optimization shortcut.

Fixing a reproduced defect can intentionally change the broken output. Record its trigger, intended outcome, affected parity rows and regression tests. Treat that documented correction separately from unchanged surfaces so exact parity does not require preserving a known bug. Routine fixes already requested do not require a new approval flow; ambiguous product changes need a concrete discrepancy record.

## 4 Required feature coverage

The package includes all 26 original specifications. The following families are a minimum index, not an exhaustive control checklist. Expand each into testable behavior and options before declaring completion.

- Shared borders/accent, unified bottom envelope and gap fills, status/micro envelope, every layout placement and resolution/UI-scale squeeze.
- Nineteen-column action strip with twelve paged and seven additional slots, SHIFT/CTRL minirows, promotion, badges, identity-stable VFX, binding mode, pet/stance bars and permitted forms/vehicle/possess/override/skyriding behavior.
- Combat/noncombat grids, consumable selection and tiers, mount/hearth/mage helpers, four utility slots with modifiers, trinkets/queues, flyouts and scoped custom categories.
- Conditional binding documents, browser/editor, conditions/targets/forms/multicast, chord routing, mouseover input, keyboard visualizer, spellbook hooks, sticky bindings and Respec previews.
- Flux Window Map/Meter/Respec/Buttons tabs, order/visibility, map/minimap embed, pin routing, embedded extra actions, Details/native meter fallback and pane layout.
- Player/target/ToT/focus/focus-target/pet/pet-target with Flux/Blizzard choices, portraits, casts, auras/own-debuff prominence, threat, health-loss/power-cost, prediction/absorbs/class power and supported MP5/swing/flight helpers.
- Party/raid grouping, reverse/MT/MA layout, range/status, auras/dispel/highlights, manager, live preview, sizes and transparency.
- Status XP/rep/gold/Honor/Arena/currencies, item-currency slots, account ledger, inventory tooltip awareness, FPS/ping/durability and pinned character stats.
- Micro menu/professions/Addon popup, minimap button promotion, square minimap, objectives/buffs, nameplate overlays/countdowns and safe Edit Mode coexistence.
- Inventory facts/last-seen ledgers for supported storage locations, mail-to-known-alt awareness, metadata/classification, Syndicator handoff and tooltip deduplication.
- Vendor repair, restock/reagent/tier targets, bank refill, junk rules/manual lists/protection, bag indicators, bulk buy and Already Known behavior.
- Salvage with spell/skill/rank checks, Forever comprehension/profession variants, modifier-click input, exact colors and protected gear handling.
- Masked Respec save/load, unchecked snapshot retention and protection, duplicate item identities, presets, talent/loadout/rune/bar/binding/utility/pin sections, Blizzard set sync/adoption/ownership and partial-failure recovery.
- Optional Baganator, Syndicator, Details, Questie, ConsolePort, BigDebuffs, TacoTip and other supported integrations; chat/copy/buttons, window movers, character overlays, trade/equip flyouts and remaining QoL.

## 5 Architecture and migration rules

Retain the useful existing kernel. Core owns lifecycle/settings/events/jobs/diagnostics. Client adapters own API shapes, native UI and security differences. Services own inventory, classification, protection, action/binding identity, layout and theme. Features own state and presentation; integrations remain thin optional bridges. Configuration calls the same contracts instead of reaching into feature internals.

Document public inputs/outputs, callbacks, ownership, readiness, security restrictions and invalidation. Keep hot paths direct and avoid a general framework or chains of trivial wrappers. Resolve stable dependencies once. A feature can be independently disabled only if its subscriptions, jobs, presentation and ownership actually stop or suspend correctly. Distinguish source modularity, runtime disablement and genuine load-on-demand loading.

Consolidate API layers by domain. Prefer the newer typed Core/API contracts where they cover the required semantics, but compare old/new return shapes, nil behavior, client meaning, async readiness and security rules before choosing. Inventory all legacy consumers and external/public contracts. Move one bounded set of callers at a time with unchanged outcomes. Temporary aliases delegate to the canonical implementation, have a named owner and a removal condition; they cannot become a third independent backend. Remove a legacy domain only after static and runtime consumer checks plus tests.

Preserve globals still consumed by integrations until a deliberate compatibility transition. Do not rename every file/global and change behavior in the same patch. Mechanical extraction/load-order changes and algorithm changes should have separate commits where feasible, so regressions are attributable. Keep WoW's private addon namespace for newly internal state. Update TOC/XML dependencies and packaging references with each move.

Extend resource ownership incrementally in existing modules. Track event subscriptions, timers/tickers, queued jobs, hooks, frames, unit bindings and provider observers. Enable/retry must be idempotent; partial failures must clean up or retain bounded reusable state. Disable unprotected work immediately while deferring only protected teardown in combat. WoW frames generally cannot be destroyed; retain/reset them. Permanent native hooks install once and gate callbacks, with residual cost or reload requirements recorded honestly.

Protected jobs need an owner, stable key, current generation, latest desired state and execution-time validation. Cancel stale work after disable/profile/session change. Re-pause if combat returns. Preserve existing queue ordering and input-readiness barriers, including Forever's native setup. Do not hide exceptions with broad pcall, replace Blizzard APIs globally or move restricted values into generic caches/comparators/logs.

## 6 Prioritized implementation stages

Each stage keeps the addon runnable, has a bounded file/feature scope and ends with relevant correctness/parity plus before-and-after measurements. A stage may contain several small commits. Do not combine an entire addon rewrite into one review or stop at another roadmap once implementation is commissioned.

### Stage 0 Establish checkpoint and reproducible evidence

Inspect AGENTS, Git status/remotes/HEAD, installations, references, existing tests and diagnostics. Freeze source/settings references, record client/builds, create the change branch and expand parity/ownership/load maps. Reproduce the current validation suite, recording missing reference dependencies and actual tool versions. Capture native baseline scenarios where clients are available. Distinguish pre-existing failures from new regressions.

Exit: checkpoint evidence, baseline reports or explicit pending rows, reproducible command list, scope/decision record and one immediate implementation task. Do not spend the whole project documenting before fixing a bounded verified issue.

### Stage 1 Correctness and lifecycle foundations

Prioritize reproduced startup/security/data-loss faults over cosmetic cleanup. Extend Core/Module, Events, Timer/Scheduler and Combat ownership/cancellation as evidence requires. Preserve existing custom-bind, Respec, migration and resource-reuse fixes. Migrate a small representative feature first, then extend ownership across remaining modules.

Exit: partial initialization, combat enable/disable, profile supersession and repeated lifecycle scenarios behave correctly without resource growth or stale callbacks. Relevant native secure/taint results remain separately recorded.

### Stage 2 One client API contract

Resolve conflicting flag meanings, make capability/readiness/security contracts explicit and migrate domains/callers from Core/FluxAPI to the chosen canonical implementation. Keep temporary compatibility narrow and tracked. Add exact build/source rows for every target.

Exit: one implementation per migrated domain, remaining consumers explicitly counted, no silent Classic/Retail/Forever semantic changes, and legacy code deleted only after its final consumer is removed.

### Stage 3 Layout and rendering work

Map every console/native surface to one owner. Introduce dirty reasons and coalesced passes around the existing placement rules. Cache completed nonsecret style/geometry state and avoid redundant writes. Preserve frame levels, effective scale, fractional positions, clipping and transition timing. Stop anchor fights without blanket throttling.

Exit: screenshot/geometry parity across supported layouts/scales, fewer measured redundant writes and no new settling delay or Edit Mode regressions.

### Stage 4 Inventory and economy consolidation

Finish the shared facts/classification/protection model already present. Use changed bag/slot/item information and safe revisioned aggregates; deduplicate metadata/tooltip requests. Retain correct full reconciliation when unknown/reconnect state requires it. Avoid caching mutable usability until the next bag event. Ensure Syndicator readiness hands off only supported domains without double tracking or an inventory blackout.

Restock/junk/salvage/gear consumers share facts, but revalidate live slot identity/count/lock/protection immediately before an operation. Cancel plans on session close or unexpected results. Keep live, last-seen and unknown state distinct. Preserve masks and protection for unchecked stored Respec gear.

Exit: exact winner/tier/tie/protection/quantity outcomes with fewer measured redundant scans and correct late metadata, provider handoff and interrupted operations.

### Stage 5 Actions bindings badges and feedback

Separate authoritative action/binding state from per-view paint. Reconcile duplicate compilation/query paths and update only affected documents/slots. Share safe query samples at the existing cadence. Reuse buffers where ownership permits it. Maintain input edge semantics, identity-stable VFX, secure paging, modifiers, mousewheel, gamepad and hover-on-unit-frame routing.

Exit: equivalent actions and visual continuity with reduced measured compile/query/allocation work. A timer is not inherently cheaper than OnUpdate; do not remove required per-frame physical input feedback without an equivalent verified path.

### Stage 6 Frames and large feature files

Extract unit/raid/nameplate construction, state, aura/cast/resource logic, layout and rendering into coherent responsibilities. Keep clear per-unit ownership and reusable icons/watchers. Use unit-filtered events and incremental aura information where contracts allow it. Preserve 3D portraits, prediction, active effects and client-supported feedback. Secret values require supported display consumers; set-if-changed comparisons apply only to readable data.

Split Binding/Core/Apply, ExtraButtonSystem/Engine/Paint, Inventory/Init and other large files only after their contracts and callers are mapped. Prioritize extraction by coupling and hotspot evidence, not a target line count.

Exit: smaller responsibilities, stable lifetime/visibility, matching visual/input outcomes and native combat acceptance per affected client.

### Stage 7 Optional integrations and deferred interfaces

Audit map/meter/Questie/Baganator/Syndicator and other bridges in absent, normal and late-load orders. Keep provider startup ownership intact. Reuse hidden panel widgets and cancel stale tab work. Lazily construct editors/previews, and consider actual load-on-demand packaging only after measuring startup versus first-open cost. Do not freeze map pins, meter updates or native animation to improve idle numbers.

Exit: companion-free functionality plus equivalent integrated UI, bounded discovery/retries, no duplicate tooltip/tracker and no hidden view resurrection.

### Stage 8 Settings cleanup and release

Preserve current saved-data roots and independent scopes unless a change is necessary. Schema migrations are versioned, idempotent, validated and non-destructive with recovery data. Do not turn modernization into a mandatory settings reset. Test clean/upgraded/malformed roots, profile copies, partial Respec and rollback compatibility before live use.

Remove dead paths only after loader/reference/runtime evidence. Keep tests/tools/reference copies out of the installed release. Remove narrated comments, stale implementation history, unused wrappers and contradictory notes while retaining restriction/invariant explanations and attribution. Use linting for accidental globals and source checks appropriate to WoW's Lua subset. Avoid minification and unnecessary framework code.

Exit: complete ownership/parity records, reproducible packages and exact-revision validation. Run cumulative full-addon measurements and native acceptance. Keep the existing _FluxUI folder/TOC identity and saved-data ownership. Do not introduce a rename, parallel addon or separate repository as part of release work.

## 7 Performance testing for every change

Keep the original frozen baseline for cumulative comparison and the last accepted version for each local change. Before editing, record source SHA/tree fingerprint, configuration/assets, scenario, build, dependency versions and measurement mode. Preserve raw data. A reconstructed older baseline must be labelled retrospective; do not imply it was captured before the edit.

After editing, verify equivalent completed work and intended outcomes before interpreting timings. Test the subsystem with necessary shared services, its integration neighbors and the complete addon. Shared work must not be counted twice or attributed by naive timing subtraction. New features disclose added cost; they cannot claim a speedup against an old version missing that work.

For native steady scenarios, start with five alternating matched baseline/candidate pairs of about 30 to 60 seconds with equivalent warm-up. Adjust for observed variance. Use repeated operation trials for startup, first-open and bursts. Match scene, hardware, graphics, resolution/scales, caps/VSync, focus, addons, client and settings. A focus change or changed feature set invalidates a foreground performance comparison.

Measure addon CPU ms/s, query/scan/compile/layout counts, allocations where attributable, frame/timer/subscription growth, time to usable input, first-open/operation latency and unprofiled frame-time distributions. Record median/spread and p95/p99 only when a suitable frame-time stream exists. Sampled FPS averages cannot reconstruct tails. Process-wide heap changes are not per-addon allocations. Do not sum inclusive timings. Modern profiler APIs and legacy scriptProfile captures have different semantics and overhead; verify facilities per client and restore diagnostic settings/reload as required.

Extend existing /fluxperf and /fluxstartup and tests/run_validation.py where appropriate; do not duplicate them without a reason. Inspect their current command contracts. The inspected runner uses Lua/luac, accepts --output and --sync-docs, and some fixtures need external references. The following is an existing command shape to verify in the actual checkout, not a new test result:

python tests/run_validation.py --output docs/validation/current-run.json

Do not run --sync-docs as a substitute for fresh evidence. Reports must identify tested source fingerprint, environment, corpus, commands/results and missing dependencies. No command was run against a complete native installation in this planning turn. Add a scenario registry/comparison reporter incrementally with opt-in owned-boundary instrumentation; proposed commands remain proposed until implemented.

### Required scenarios by subsystem

- Startup/core/settings: fresh and upgraded login/reload, world-entry bursts, late providers, combat during initialization, malformed/migrated settings and readiness latency.
- Lifecycle: 100 warm toggle/open-close cycles, partial setup/retry, unit rebinding, cancellation and stale work; stable frame/job/subscription counts and expected residual hooks.
- Layout/theme: each placement, window mode, accent/profile, low scale/ultrawide/resize, unchanged versus changing geometry; passes/writes and visual comparison.
- Bars/bindings/extra buttons: keydown/up/release-only, modifiers/wheel/gamepad/hover input, forms/vehicle/pet, badge/glow continuity, one versus many edited bindings, cold/warm consumables, no/single/two trinkets and query/compile cost.
- Inventory/economy/salvage: one-slot and burst changes, full bags, late item data, player usability change without bag events, supported bank topology, provider handoff, manual/protected junk, tier ties and interrupted plans. Use fixtures for destructive operations; native cases use suitable test items and deliberate input.
- Unit/raid/nameplates: unit swaps, casts/resources/auras, predictions, portraits, 5/40-unit groups, range/roster churn, many plates and reuse, secret contexts and session-only previews.
- Window/map/meter/integrations: each active/hidden tab, rapid switches, embed/restore, pins/pan/zoom, provider absence/readiness/late loading, pane layout and equivalent ongoing updates.
- Micro/status/chat/character/QoL: changing counts/text at existing cadence, minimap/profession discovery, chat tab/fade/copy/buttons, native relayout, movers/equip/trade and repeated open-close.
- Respec/migration: no-op/full/masked apply, duplicate gear, set ownership, profile supersession, combat wait, bank changes, partial failures/recovery and saved-data rollback.

Every feature/control row maps to a scenario or a justified shared case. Include cold/warm, idle/active/burst and hidden/disabled controls where relevant. Hidden shared facts may still be required; sample-driven FPS/ping and permanent hook dispatch have explicit exceptions. Settled unused presentation must not continue scanning/rebuilding.

Desktop CI checks outcomes and deterministic operation/resource budgets. Wall-clock benchmarks on shared runners are advisory until noise is understood. Set numeric budgets from measured baselines and meaningful latency limits, not arbitrary promises. Preserve failed/inconclusive data and do not rerun selectively until a result looks favorable. Reject unexplained correctness/visual/input regressions even when CPU decreases. Missing native tests remain pending; continue independent work without claiming native completion.

## 8 Visual and client acceptance

Use lossless, unscaled baseline/candidate screenshots in separate sessions on the same client/build, locale, assets, settings and physical viewport/effective scale. Compare readable nonsecret frame geometry, textures, fonts, layers and hit areas as well as pixels. Static controlled regions target zero unexplained differences. Report differences per region; do not hide a one-pixel border shift behind a similarity score.

Separate the world background and narrowly declared variable content from the addon UI. Match dynamic widgets at equivalent animation phases, preserving fixed geometry/style and timing. Record masks/variability; never mask an entire animated component. Capture hover/press/drag, minirows/paging, every tab/options state, unit/raid/aura density, vendors/bank/salvage/Respec and supported scale/placement variants. A synthetic owned preview aids visual checks but does not prove native secure behavior.

Track Era, Anniversary, MoP, Retail Midnight and Forever/Camelot separately. Keep requested Wrath and retained Cata explicit. Original 3.3.5 and modern Wrath are distinct targets; record which is intended. Record exact build/project/interface, matching Blizzard source revision, adapter capabilities/readiness/security, package and native results. A broad Classic flag, TOC interface number or desktop mock is not certification. Forever's hybrid bank/swing/threat/character behavior must stay distinct from Live Retail.

Use documented native display consumers for secret values. Do not compare, sort, stringify, log or use opaque combat values as table keys through generic helpers. Private-aura anchors do not automatically replace all existing ordinary aura filtering. Preserve accessible Classic functionality when Retail restrictions differ. If an exact former operation is unavailable on a client, record the precise exception and permitted display outcome; do not silently drop the feature across all clients.

Native acceptance covers startup/reload/reconnect, combat and secure input, taint/Edit Mode, paging/vehicles/forms, actual aura/raid/secret displays, inventory/bank/vendor/salvage, profiles/migration/recovery, optional addons and resolution/UI scale. No actual client acceptance or new FPS improvement is claimed here.

## 9 AI continuity and local references

Persist the modernization direction in repository instructions and a decision log. Explicitly mark all earlier fresh-start, second-addon, separate-repository and rename directives superseded so another AI continues directly in the existing _FluxUI project. Merge the supplied context templates with existing records; never overwrite unrelated AGENTS guidance or erase current progress.

AGENTS.md sets permanent rules and read order. docs/STATUS.md records current milestone, tested source fingerprint, accepted work, active task, blockers, native tests, dirty work and one immediate next action. NEXT_SESSION.md is derived from STATUS. Maintain docs/DECISIONS.md, FEATURE_PARITY.csv, MODULE_OWNERSHIP.csv, API_MIGRATION.csv, CLIENT_MATRIX.csv, REFERENCE_MANIFEST.csv, PERFORMANCE_RESULTS.csv and WORK_LOG.md. Store the 26 input concepts and sanitized evidence with durable links.

At each session start, read the instructions/status/decisions and relevant specs/ledgers, then inspect actual Git state and reconcile newer/dirty work before editing. At each meaningful checkpoint and session end, update records with exact commands/results, source fingerprints, artifacts, pending native work and the next action. Persist before context limits. Commit relevant code/context together where appropriate without including unrelated changes; do not invent commit IDs or mark unfinished work complete. Chat memory is supplementary.

Local references may be at F:\World of Warcraft\_retail_\Interface\AddOns. A local Codex session can inventory selected folders read-only; this hosted session cannot access that drive. Record TOC/version/interface/dependencies, origin and hashes. Accept selected addon ZIPs if needed. Identify classicthreat from its actual TOC, and verify installed Syndicator/Baganator APIs rather than assuming the old fork matches current distributions.

Use MoveAny, EllesmereUI, Bartender4, Button Forge, Clicked, Buffet, Restocker, Scrap, TrinketMenu, ItemRack and Blizzard source as versioned behavior/API references. Keep optional Questie, Baganator, Syndicator and Details integrations, plus existing supported companions. Existing code retention does not override upstream permissions: preserve attribution and audit provenance for retained libraries/assets instead of blindly copying new reference code. Keep private account files and full reference installations out of public Git history.

## 10 First task and completion criteria

The first implementation task is to preserve/checkpoint the current state, reproduce the existing validation commands, establish current behavior/performance evidence, map ownership and select a small verified lifecycle or hotspot fix. Implement and verify that bounded change, then proceed through the stages. Native access gaps block native certification, not all independent source work.

Completion requires preserved features/options/scopes, recorded intentional bug fixes, equivalent controlled appearance/input, one canonical contract per domain, resource ownership across all features, retired obsolete paths, clean reproducible packages, exact-revision evidence and separate per-build native acceptance. Formatting/comment cleanup alone does not meet the objective.

This planning deliverable changes no repository or installation. The package is a proposed execution plan and mergeable context templates, not completed modernization. It defines continued work in the current _FluxUI addon and repository, with only a frozen restore checkpoint outside the active addon folders.

## 11 Source register

Reviewed source revision: https://github.com/DoctorFlux/FluxUI/tree/7436820453d2248c84c99fff71507553efc47c19

Primary paths: _FluxUI.toc; Core/Module.lua; Core/Engine/Events.lua; Core/Engine/Combat.lua; Core/Client.lua; Core/FluxAPI/Client.lua; Inventory/Init.lua; Inventory/Syndicator/Adapter.lua; tests/run_validation.py.

Supporting repository records: docs/07-runtime-architecture.md; docs/43-startup-optimization.md; docs/52-retail-idle-hotspots.md; docs/55-resource-lifecycle-audit.md; docs/41-verification.md. Historical reports are evidence with their original revision/limits, not a list of still-open defects.

Blizzard API source: https://github.com/Gethe/wow-ui-source. Pin matching sources for each actual build. The 26 supplied product specifications are packaged verbatim; this modernization decision governs implementation methodology where their old rewrite wording differs.
