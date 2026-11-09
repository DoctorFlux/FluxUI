# Hidden inventory work — 5 November 2026

The user still reports pauses on Forever with Baganator and Syndicator when
opening/closing mail, receiving/opening messages, buying auctions and selling
listings. Prior safeguards have not established resolution. No native capture or
game-Lua connection is available; the user cannot run captures now. This batch
removes two reproduced hidden-work paths. Native lag attribution and improvement
remain **pending**.

## Reproduced failures and changes

`FluxBaganator_ItemViews.ForEachVisibleItemButton` used `IsShown` on the public
skin registry fallback. Buttons under hidden bank, cached-character and previous
skin parents therefore received protection classification, click-guard updates
and shield painting. It now uses effective `IsVisible`, retaining the old
`IsShown` fallback for older adapters. The all-button traversal and durable item
listeners still cover hidden pools; only visible refresh work is filtered.

Skipping hidden work needs a reveal path. Baganator can toggle a root without
`BagShow`, switch child tabs/characters, and assign new slot identities after
showing the root. The adapter discovers existing and future `ButtonFrame` roots
tagged `bank`/`backpack` through its public skin registry, including arbitrary skin
names such as `Frameblizzard` and `Framedark`. Numeric/legacy names remain fallbacks.
One hook per tracked root and the explicit bank/view/character callbacks coalesce
one `After(0)` refresh after that dispatch, reading final slot identities. This is
a new reveal correction, not a guarantee of native input/timer ordering. Existing
merchant/BagShow 0.2s debounce stays; there is no `ViewComplete` refresh listener.

Separately, the default-bag overlay called native `Update()` on closed allocated
containers before its later paint gates. Item buttons could also pass `IsShown`
under hidden parents. Updates, classification and async junk/protection painting
now require effective visibility and existing eligibility. Existing container
hooks refresh current decorations on reveal; unified combined bags retain their
existing 0.05s reveal pass. Disabled painting, inaccessible banks and Forever
gamepad/native-bank exclusions remain enforced.

The native overlay exits at load when an alternative bag UI owns the bags. Its
fix covers the default-bag path, not proof of the reported Baganator pause. Both
changes use existing inventory/protection services without changing provider
ownership, mail/auction operations, saved data, options or presentation.

## Recovery and measured evidence

Baseline: `2dd6cfd53394240861476b632c42dff34c64f2f2` on clean main. External
`Hidden-inventory-work-20261105T121000Z` preserves 1,462 actual source files,
verified all-ref Git history and 123 accessible on-disk Flux settings files.
Archive SHA256: `b31d629042f1e398778a79081cbf281a22d62f2e6f967f80a74d0a1f57a2baf7`.
It is outside AddOns; unsaved in-memory settings are not included.

[Source identities, raw five-pair samples, mutations and environment](validation/hidden-inventory-work-comparison-2026-11-05.json).
[Full validation and normalized Lua manifest](validation/hidden-inventory-work-2026-11-05.json).

| Desktop scenario | Baseline | Candidate |
| --- | --- | --- |
| Baganator: 40 refreshes, 2 visible/1,000 hidden-parent rows, 5 client and 2 integration labels | 400,800 guard calls, shield writes and item queries each | 800 each |
| Default bags: three paint passes per nonunified model | 6 hidden native Updates and 6 hidden reads | 0 / 0 |
| Default bags: three paint passes per unified model | 3 hidden reads | 0 |
| Visible reads per default-bag model | 6 nonunified / 3 unified | unchanged |

Counts are identical in all five alternating fresh-process pairs. The integration
fixture warms up durable listener installation before the measured burst; the
native fixture initializes frames/decorators before three deterministic passes.
Startup/reveal controls are outside the displayed burst counts. These synthetic
sizes and frequencies are not observed user-session data. The skin registry still
has a linear traversal; this reduces hidden callbacks, not total work to constant
time. Baganator checks: baseline 120 failures, candidate 260 pass. Native checks:
baseline 28 failures, candidate 65 pass. Six mutants fail for hidden-parent work,
missing reveals, premature slot painting and missing skin discovery.

The real production modules run in desktop Lua 5.4.6 with mocked native
frames/timers/inventory. Client/provider labels exercise shared contracts, not
native client or provider emulation. Reveal tests cover changed slot identities,
skin replacement, character/tab switches, bounded scheduling, current guards and
shields, disabled work, alternative-UI bypass and missing-API fallbacks. The full
133-script / 788-Lua suite passes, including existing mail, auction, consumable,
provider-handoff and Forever bank-policy regressions. An initial full run failed
one old literal-source smoke check; it now recognizes an aliased Update call while
retaining the gamepad-before-call requirement. Its failed report is preserved in
the external checkpoint.

The comparison records wall-time ranges including process startup/assertions;
they are not operation latency or native performance results. Native CPU,
memory/allocation, frame time, resource counts and capture duration are unavailable.
No FPS or memory-leak claim is made. New lifecycle cost is one filtered persistent
root listener, one hook per created root/native container, and at most one pending
reveal timer; no polling or per-item reveal hooks. Existing tracked root references
remain session-lived, matching Baganator's persistent frames.

## Client evidence and pending acceptance

Installed executables freshly read: Era 1.15.9.70576, Anniversary 2.5.6.70577,
MoP 5.5.4.70631, Retail 12.1.5.70783 and Forever 1.60.1.70790. Baganator 840 and
Syndicator 289 TOCs were read from Forever. Exact active `GetBuildInfo`, complete
enabled-addon list, profile/graphics settings, RAM/GPU and native measurements
are uncaptured. Desktop host CPU is i7-12700F; other hardware reads were unavailable.
Original Wrath 3.3.5.12340 is distinct from modern Wrath; retained/unavailable
targets are not newly certified by these shared-contract tests.

Read-only references: installed Baganator `API/Main.lua`, `Skins/Initialize.lua`,
`ItemViewCommon/BackpackView.lua`, `ItemViewCommon/BankView.lua` and
`ViewManagement/Initialize.lua`; normalized hashes are in the comparison.
Forever [source at 1.60.1.70790](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua)
declares `IsVisible` with conditional secret-return annotations. Declarations do
not certify native access/secure behavior; traversal stays within inventory UI.
No external addon code/assets were copied or edited.

When native testing is possible, sync then `/reload`. Record baseline/candidate
source, exact build/hardware/profile/addon list and resolution/UI scale. Test each
available client with default bags and Baganator, using both supported inventory
provider configurations. Keep actual provider readiness/handoff visible in the
record; do not treat an impossible addon combination as tested.

1. After 30s warm-up, capture mailbox open, close, receive and open-message cases
   separately; verify attachments, counts, open-all/select, contacts and tooltips.
2. Capture auction buying, posting/cancelling and own-listing sales separately;
   verify purchased/sold quantities and delivery. Do not automate purchases.
3. With cached bank/character/previous-skin views created, compare bags closed
   versus visible. Reopen via bag binding, switch live/cached characters, bank tabs
   and skins. Verify current junk/inferior/shield paint and protected click behavior
   through merchant/disenchant contexts and combat recovery.
4. Use the existing optional `/fluxperf capture 20` then `/fluxperf last` for at
   least five matched alternating pairs per scenario. Preserve diagnostic roots
   and profiler preferences; record overhead, raw variation and frame time. Match
   screenshots/geometry. Do not sum overlapping inclusive CPU or infer FPS.

These checks are recorded for later, not a renewed request for the unavailable
capture. WoW stayed in the background; no input, clipboard, settings, profiler
preferences, mailbox transactions or auction actions were controlled. Guild-bank
and void-storage callbacks remain unchanged.
