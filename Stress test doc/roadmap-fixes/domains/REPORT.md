# Remaining-domain roadmap fixes

All six R2-DOM finding groups now have implemented fixes and permanent production-executing regressions. This phase preserves the newer PvP formatter, vertical target health, focus aura packing and portrait restore work. The prior geometry, raid, nameplate and chat optimizations remain the baseline.

[Raw results](results.json) record **10 matched checkpoint rejection cases**, each failing the intended behavioral acceptance before the fix and passing afterward. Nine focused scripts ran three times: **27 passes, zero failures**. [Source freeze](source-freeze.json) records byte and LF-normalized SHA-256 identities before and after these runs; every consumed identity is unchanged. The root combined validation separately reports **247/247 scripts and 911 Lua syntax checks passing**.

The immutable baseline is the current local source captured before this phase, including newer local edits; it is not an older Git checkout. Source/history recovery is external at `roadmap-fixes-20261107T184559Z`, recorded in [checkpoint.json](../checkpoint.json). This agent changed ten runtime files, added three permanent tests, and updated two existing fixtures to load actual helper dependencies/add direct level controls. No branch, publication, game input, profiler, WTF or settings writes were issued. Guild-bank and void-storage callbacks remain excluded.

## Implemented behavior and controls

| Finding | Fix and retained behavior | Modeled acceptance |
|---|---|---|
| R2-DOM-01 | Micro proxy tooltip operations have current hover/original ownership, cancellation on leave/hide/disable/rebind, and one reusable deferred positioning driver. Standard handlers retain their native tooltip owner and data processor; shared `GameTooltip.Show` is never replaced. | Leave before position cannot resurrect a broker tooltip; native handler sees unchanged Show; later text updates survive; stale A leave cannot hide B; hide cancels owned work. |
| R2-DOM-02 | Private proxies persist by logical name across disable/enable. One hook pair per original icon dispatches to its current enabled proxy. Rebuild requests coalesce through one reusable frame. Clicks resolve the current original at dispatch. | 500 conversion cycles keep one proxy/two icon hooks and fixed frame count; one icon change paints once; 1,000 same-frame rebuild requests produce one rebuild; replacing the original retires old dispatch and retains click payloads. |
| R2-DOM-03 | Visible salvage combat transitions park the existing anchor updater before protected geometry/attribute work. Existing regen queue reconciles one pending anchor/entered state; deferred hide takes priority. | All five policy fixtures: visible before combat, 1,000 modifier events, native secure-show callback model, no blocked mutation, one safe restoration, and hide cleanup. Existing action/atlas/lock tests remain passing. |
| R2-DOM-04 | Portrait, outer-border and private threat layering use guarded public levels and relationships recorded at actual owned level writers. Private ThreatGlow start/recolor also requires a permitted owner level before allocation or changes. | Public levels preserve exact offsets; opaque getter controls perform no forbidden arithmetic; first private child derives from known owner; parent 40→70 moves preserve relative levels; no known external owner leaves existing art unchanged; private glow first unknown defers, permitted start/recolor and later opaque fallback work. |
| R2-DOM-05 | Each vendor metadata panel owns one retry operation. Concurrent tab/list entrypoints share the pending retry; its callback reads the current list. Hide/completion invalidate the operation before cancellation. | 250 initial entries leave one retry, retain 200ms delay, follow a changed item list, reject an old hidden owner's callback after reopen, and stop when metadata becomes available. |
| R2-DOM-06 | Status/Info layout work, Details resize debounce and equip flyout hover timers use independent operation identities. Native NewTimer cancellation is used when available; no-return After fallback remains safe against stale callbacks. | 1,000 layout calls leave one timer; deliberate stale cancelled callbacks cannot paint or clear a replacement; Details preserves trailing 50ms quiet time and embed identity; flyout retains 60ms show/250ms hide and latest hover ownership. |

The DOM-01 standard tooltip path intentionally keeps the third-party handler's original native owner while anchoring the same tooltip to the proxy. It no longer copies a fixed number of text lines or blanks/hides the shared tooltip for capture. A synchronous handler may show its tooltip in the current hover frame rather than the old capture frame. Lines, colors, native widgets and asynchronous updates are retained by keeping the original tooltip; actual third-party/native presentation still needs visual acceptance.

DOM-02 retains two module-level frames once needed: one coalesced rebuild frame and one bounded tooltip-positioning frame. No additional ticker or permanent idle updater was added. Tooltip positioning gives up after ten unpositioned frames. Proxy retention is bounded by distinct configured logical buttons rather than conversion cycles; original icon hooks are non-removable native hooks, installed once per distinct icon object, with retired dispatch cleared.

DOM-03 preserves the existing 0.03s out-of-combat anchor cadence and secure action payloads. The existing PLAYER_REGEN_ENABLED queue owns recovery; no combat polling recovery driver was added. A combat hide request is deferred when ordinary insecure Hide would be protected. Native secure drivers can still hide their own prepared overlay; the mock does not certify actual driver permissions.

DOM-04 extends the existing narrow public-level ledger. It records actual portrait +1/pet +5, model +2, outer border +5, border +10, threat shell +10 and threat text +25 relationships. Existing public native levels take precedence. When a getter becomes inaccessible, known owner relationships follow later public owner moves. Unknown values do not become zero and do not hide/reset the renderer. Combat portrait border remains outer border +2; normal portrait border remains portrait +10; private threat glow remains border +5 with text another +5 above it. Existing Pet/ToT public parent writers were reviewed and already record their level writes, so those files were not edited this phase. The conditional modern/Forever FrameLevel contract risk is mitigated; this does not establish that these actual frames ever receive a native secret FrameLevel aspect.

DOM-05 keeps immediate user entrypoint refreshes immediate. It coalesces the retry chain rather than delaying a new tab selection. DOM-06 preserves StatusBar notification, Info immediate-first layout/cooldown policy, Details 50ms debounce and equip hover timing. With a no-return After fallback, cancelled native callbacks may still dispatch once and return without work; the operation identity prevents stale ownership effects. NewTimer-capable clients physically cancel the pending handle as well. These are measured work/ownership properties, not an estimate of native milliseconds.

## Exact production scope

| Runtime file | Changed owner |
|---|---|
| MicroMenu/FluxMinimapToMicro.lua | Proxy create/rebuild, tooltip ownership and current-original icon/click dispatch |
| Salvage/FluxSalvage_Overlay.lua | Visible combat anchor/update/regen/hide lifecycle |
| UnitFrames/FluxUnitFrames_Shared.lua | Public level relationships, portrait and private threat layering consumers |
| Core/ButtonFX/ThreatGlow.lua | Public level guard for direct start/recolor |
| Inventory/Restock/Junk/FluxVendorJunkPanel.lua | One metadata retry owner and hide cancellation |
| Inventory/Restock/Vendor/FluxVendorRestockPanel.lua | One metadata retry owner and hide cancellation |
| StatusBars/FluxStatusBar.lua | Layout notification timer ownership |
| StatusBars/FluxInfoFrame.lua | Integrated cooldown timer ownership |
| Battlezonemap/FluxDetails.lua | Resize/embed debounce ownership |
| Other/FluxEquipSlotFlyout.lua | Hover show/hide operation identity |

The exact whole-file hashes, including preserved newer content, are in `source-freeze.json`. No TOC, artwork, XML, public commands, saved roots, option defaults, integrations or external library ownership changes were needed in this domain slice.

## Reproduction and evidence

Run `python "Stress test doc/roadmap-fixes/domains/run_evidence.py"` from the addon root. It reuses current permanent fixtures, routes only the ten owned runtime reads to the immutable checkpoint for baseline cases, and records both outputs. It never replaces installed files. The selector wrapper changes only which existing test sections run; production functions and acceptance assertions are unchanged. Baseline private-glow rejection is ordinary Lua arithmetic on an explicitly opaque table, not a real native secret error.

| Permanent script | Checks per run | Scope |
|---|---:|---|
| tests/domain_lifecycle_fixes.lua | 5,104 | Complete micro factory/proxy owners in Classic/HUD branches; strict complete salvage module in five policy fixtures |
| tests/native_timer_ownership.lua | 54 | Actual six timer/retry owners with After-only and cancellable NewTimer contracts |
| tests/public_frame_level_safety.lua | 13 | Complete current public-level helpers and portrait/threat consumers |
| tests/alpha_reader_safety.lua | 655 | Existing alpha controls plus private glow public/changed/inaccessible/missing level controls |
| tests/portrait_camera.lua | 1,191 | Existing portrait camera/geometry and negative controls |
| tests/unit_portrait_combat_restore.lua | 66 | Existing party/focus combat tint and backdrop restoration |
| tests/salvage_overlay.lua | 2,033 | Existing full overlay, atlas compatibility, locks/actions and mutations |
| tests/prediction_public_geometry.lua | 8,460 | Existing prediction layers, clips, public geometry/phase/layout controls |
| tests/unit_vertical_target_health.lua | 1,243 | Existing vertical target health across five policy models and six target tokens |

Counts overlap broader validation and are not a coverage percentage. Repeated policy labels do not emulate separate native engines. The micro Classic/HUD branches, salvage strict client templates, and actual owner function paths define the proven scope. All copied module licenses and animation/art declarations remain intact.

## Client evidence and remaining acceptance

The root refreshed [four source pins](../source-pins.json): [Retail 12.1.5.70783](https://github.com/Gethe/wow-ui-source/commit/297d7aaaa736f346b3e036f38ee088eaf7f8c07f), [Forever 1.60.1.70862](https://github.com/Gethe/wow-ui-source/commit/9dc84f0d3bbae1768ac3405b3716000bd93eda06), [Era 1.15.9.70576](https://github.com/Gethe/wow-ui-source/commit/4192ac60067fc55566182291bc67c85dd9b6794d), [Anniversary 2.5.6.70577](https://github.com/Gethe/wow-ui-source/commit/68e0a2ec559d9761dfc4e7f864c3944f9d758a49). The relevant generated contracts declare no return for C_Timer.After and a cancellable NewTimer handle; modern/Forever FrameLevel can be secret for its aspect. Source declarations and desktop traps do not prove actual frame aspect provenance or native taint safety.

Native acceptance remains pending for all four requested clients: real combat/world/dungeon/raid transitions, secure salvage visibility/actions, third-party broker/native tooltips, private glow/portrait draw order and pixels, real restricted values, long-session CPU/FPS and reported fade-taint first-cause provenance. No native error, FPS improvement or full-addon safety certification is claimed by these tests.

An independent read-only review of the root-owned Context, Range, Bars Paint and EBS Paint changes found no additional actionable defect: full invalidations supersede narrow timer generations; narrow cursor streams have a bounded deadline; per-unit probe invalidation preserves unrelated same-frame memo answers; the central ticker owns burst throttling; visible bar range need survives bursts; usable palettes remain independent from temporary range red. Root-owned stress results and their exact source identities are recorded separately.
