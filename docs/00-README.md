# FluxUI implementation documentation

This is a reference for **how the current addon works**, for its author, maintainers, and coding agents. It replaces the former backup-derived concept/rewrite specification. Current source wins over old documentation, comments, intended designs, and reference addons.

Source review: **23 October 2026**, including the current working-tree changes since GitHub commit `7882474`. The [source inventory](reference/inventory.json) records source hashes with CRLF normalized to LF, load parents, client gates, and extracted declarations. Binary asset hashes retain their original bytes. This is not a claim that the addon was tested in every live client.

The current reference includes Forever's separately probed secure bar paging, native mouse-up/key-down routing, stock grid-event suppression, Questie pin handoff and tracker ownership/combat deferral. These behaviors are integrated into the system and API chapters, rather than inferred from older client flags. The [current verification record](41-verification.md#current-verification-23-october-2026) reports 28 desktop smoke scripts: 26 passing and two existing source-contract failures. The removed browser simulator and its extracted client assets are not part of the addon or this documentation.

## Start here

Read the [product and system overview](01-product-overview.md), then [runtime architecture](07-runtime-architecture.md). For a particular feature, use its system chapter below. For a setting, command, saved table, or source filename, start with Reference.

## Architecture

| Chapter | What it explains |
|---|---|
| [Runtime architecture](07-runtime-architecture.md) | TOC/XML loading, startup/reload, hybrid module lifecycles, ownership |
| [Shared services](08-shared-services.md) | APIs, event buses, scheduling, timers, combat queues, identity/range/VFX, diagnostics |
| [Persistence and profiles](09-persistence.md) | Account/character scopes, AceDB, bootstrap, migration and reset behavior |
| [Clients and capabilities](02-multi-client-matrix.md) | Live Midnight, Forever/Camelot, Era, Anniversary, progression variants |
| [Secrets and combat restrictions](03-midnight-constraints.md) | Actual guards, display paths, secure execution and verification limits |
| [Visual system](04-visual-system.md) | Accent, borders, chrome and shared styling |
| [Defaults and keybinding pack](05-defaults-and-bindings.md) | Automatic setup, CVar packs, keybind writes, reset effects |
| [Layout](06-layout.md) | HUD presets, geometry, squeezing, embedding and propagation |
| [Dependencies and provenance](90-reference-inspirations.md) | Bundled libraries, imported components, integrations, attribution limits |

## Systems

| Chapter | Feature |
|---|---|
| [Flux Window](10-flux-window.md) | Tab host, map providers, meters and embedding |
| [Action bars](11-action-bars.md) | Main/mini rows, paging, modifier selection, pet/stance bars and effects |
| [Extra buttons](12-extra-button-system.md) | Combat/utility grids, smart buttons, favorites, flyouts, categories, trinkets |
| [Binding](13-binding-system.md) | Binding document, editor/browser/visualizer, compilation, key routing and badges |
| [Unit frames](14-unit-frames.md) | Unit-specific frames, auras, resources, casting, swing/flight helpers |
| [Raid and party frames](15-raid-frames.md) | Secure headers/cells, layout, auras, private auras, preview and BigDebuffs |
| [Status and Info bars](16-status-bars.md) | XP/reputation/gold/PvP/currencies, account ledger, pinned statistics |
| [Micro Menu](17-micromenu.md) | Native and Flux actions, visibility/order, bags, professions and addon buttons |
| [Minimap and trackers](18-minimap-and-trackers.md) | Map shape/embedding, objectives, player buffs and minimap buttons |
| [Nameplates](19-nameplates.md) | Flux-owned overlays, threat, levels, combo points and countdowns |
| [Vendor, restock and junk](20-vendor-restock-junk.md) | Merchant sessions, buying/selling/repair, tier rules, bank planning and execution |
| [Inventory foundation](21-inventory-foundation.md) | Snapshot facts, scanners, Syndicator, persistence, notifications, crafting |
| [Salvage](22-salvage.md) | Classification, profession gates, modifier overlay and protected clicks |
| [Respec](23-respec.md) | Profile capture, presets, talents, equipment, runes and asynchronous application |
| [Baganator integration](24-baganator-compat.md) | Views, categories, protections, API wrappers and restocking |
| [Other QoL](25-other-qol.md) | Chat, equipment flyouts, vehicles, HUD helpers and frame positioning |
| [Character Info](27-character-info.md) | Statistics, localization, GearScore/ilvl and paper-doll overlays |
| [WindowMover](28-window-mover.md) | Blizzard-window discovery, drag/scale, persistence and combat handling |
| [Integration matrix](29-integrations.md) | Optional addons, readiness, ownership changes and fallback paths |

## Reference

| Reference | Contents |
|---|---|
| [Options map](26-options-map.md) | Actual sidebar/pages, scopes, controls, defaults and custom widgets |
| [Setting definitions](reference/settings-details.md) | Every extracted option table and factory call, ranges, getters/setters and gates |
| [Custom widget controls](35-custom-widget-controls.md) | Every embedded editor/preview control, interaction, scope and apply path |
| [Literal AceDB defaults](reference/defaults.md) | Every literal default path in FluxOptionsDefaults |
| [Source coverage](30-source-coverage.md) | Active/compatibility/inactive/harness classifications and load order |
| [Commands and keybindings](31-commands-and-bindings.md) | Effective slash behavior, subcommands, bindings and conflicts |
| [SavedVariables](32-saved-variables.md) | All declared roots, current schemas, owners and retained legacy declarations |
| [API and events](33-api-and-events.md) | Important cross-system contracts and callback payloads |
| [Interface/event index](reference/interfaces.md) | Discoverable declarations and registration sites, with extraction limits |
| [Assets](34-assets.md) | Resource families, localization, flight/salvage data and regeneration tooling |
| [Glossary](99-glossary.md) | Terms used in source and docs |

## Verification and findings

- [Findings and uncertainties](40-findings.md): observed discrepancies and suspected problems, without silently repairing code.
- [Fix priorities and outside-WoW testing](42-fix-priorities-and-testing.md): impact-ranked findings, source-backed reproductions and evidence limits.
- [Verification procedures](41-verification.md): source/mock evidence, existing smoke baselines, and in-game scenarios.
- [Current recurring-driver inventory](performance-driver-inventory.md): source sites, not a performance measurement.
- [September performance audit](performance-audit-2026-09-19.md): explicitly historical results and procedures.

Claims are source-confirmed unless a chapter explicitly names a mock test or live observation. TOC inclusion proves reachability, not eligibility or successful runtime behavior. “Not live verified” means the code path is documented but needs the listed game-client check.

## Maintaining this reference

1. Read the affected implementation, its callers, data owner, and client guards. Update the explanatory chapters and any findings together.
2. Run `python docs/tools/build_reference.py` to regenerate source-derived views. It writes only documentation; it does not evaluate Lua or launch WoW.
3. Run `python docs/tools/validate_docs.py`. This command is read-only and checks source freshness, load references, classifications, inventory coverage, curated evidence, dated verification manifests/totals and local links. If Lua changed, rerun applicable checks and update the dated record rather than carrying old results forward.
4. Use [verification](41-verification.md) for checks that require actual protected execution, API behavior, rendering, or performance.

Generated inventories supplement the explanations. Regenerating a list alone does not establish that changed behavior has been understood or tested.
