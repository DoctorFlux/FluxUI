# Auction house restock

## Shortage-only opening and stable passive refresh

14 November **AHR-105:** opening the Restock tab starts one preparation for
targets below their configured amount, including needed recipe materials.
Skip filled known items and tiers; a configured consumable kind without a saved
SKU may discover usable stock. Bag, mail and profession/material changes repaint
live counts without resetting proposals, canceling owned searches or starting
new queries after work has finished. Clear an offer once its shortage is filled.
Resume a user-started initial stock-loading wait once reliable; retain automatic
next-shortage preparation after matching purchase receipts. Buy next restarts
preparation after later consumption. No automatic purchase or tier acceptance.

An explicit setting edit can replan once. The explicit modern Scan all restock
continues full listed-item pricing, including stocked rows. Old AH has no such
control and continues scan/buy per item. The shortage-only opening requirement
supersedes earlier automatic filled-tier discovery on opening.

**AHR-106:** Loot & Items → Restock exposes independent saved AH upgrade prompt
toggles for healing potions, mana potions and bandages. Defaults: on, on, off.
Disabling one keeps the current tier's direct/craft-material restock and blocks
stale acceptance of its old proposal. Global minimum-restore rules, exclusions
and automatic Junk protections retain their existing owners.

Keep / Block now fit the compact native card's 36px / 42px bottom hit regions
with a 2px gap. Tooltips retain full action labels/details. Passive painting does
not rewrite unchanged native enabled states. Existing controller cursor controls
remain; directional navigation and native text fit require separate validation.
76 affected scripts/82 syntax, 440 passive checks/20 profiles and 11 compiled
harmful controls PASS. Native flicker/input/performance NOT RUN. [Evidence](validation/auction-passive-refresh-2026-11-14.json).

## Global potion minimum restore

14 November **AHR-104:** healing/mana potion next tiers must not have a lower
minimum restore than the current potion. Apply the rule throughout FluxUI, not
only the AH. The shared classifier now ranks these potions by the actual lower
endpoint and keeps independent resource axes and upper metadata. A larger
maximum cannot win against a better minimum; food/water/bandage rules remain.
This feeds Best, owned buttons/ladders, recipes, vendor/tier counting and automatic
junk. The Discolored/manual exclusions and manual Junk priority still apply.

Parse range endpoints from effect text, including dash forms, thousands and
percentages; level/cooldown/other-resource digits cannot raise the floor. Zero
and up-to restore cannot establish a positive guaranteed tier. Keep potion cache
minimum/text/axis facts through live-tooltip gaps. A legacy maximum-only cache
cannot become verified minimum data. Old persisted refs/vendor values and saved
thresholds normalize from canonical classification; unknown observations are
retained and cannot compete or promote before resolving. No names/IDs catalogue.

Existing explicit AH upgrade choices and buy gestures remain. 74 affected scripts,
79 syntax files, 510 minimum checks/50 profiles, 388 restore checks/20 profiles and
10 compiled harmful controls PASS. Native client acceptance remains pending;
no input/reload/profiling action was sent. [Evidence](validation/potion-minimum-restore-2026-11-14.json).

## Compact upgrade cards and preset order

14 November **AHR-102:** replace the 174px inline card with a 44px two-row control
area. Candidate icon and Upgrade sit together; Keep and Blacklist sit beneath.
Name, actual restore comparison, unit price and available funds remain in the
native item/action tooltip. Each action still resolves only its own live proposal.
Use existing ordinary native buttons/highlights and scrollbar behavior. The short
Keep label has English fallback and its long action label remains in the tooltip.
No setting is required for this requested fixed presentation.

**AHR-103:** order healing and mana potion presets first, then bandage presets,
spell reagents, consumable configuration and other targets. Use tier/source fields
rather than names. Break ties by name then item ID within each group. A preset
merged into a manual item retains preset priority; a virtual proposal without a
remembered reference is sorted alongside real presets. Preserve row/proposal
identity when painting and reusing cells. Craft materials remain among other
targets unless they also have an independently configured source.

Existing direct implementation/background testing choices remain. Controller
cursor access to all 3 buttons, native highlights and scrolling remain; directional
navigation and native text fit are not certified. Inline 1220/20, confirmation 672/20,
geometry 780/20 and 8 compiled harmful controls PASS; auction scripts/1053 syntax.
Verified external source/history 2776 files and 129 settings metadata. Native capture
found active crafting with AH closed; no reload/input was sent. [Evidence](validation/auction-compact-upgrades-2026-11-14.json).

## Inline upgrades, bandages and item exclusions

14 November `AUCTION-INLINE-UPGRADES-20261114` continues the accepted direct
implementation and background Forever test route. **AHR-96:** replace the modal
upgrade popup with Upgrade / Keep current controls attached to each restock cell.
Collect healing, mana and bandage proposals together; each item has an independent
decision. Discovery, painting and another item's choice cannot commit a tier or
junk change. Acceptance changes the tier, with junk handled globally by AHR-99.
Preserve current target/price policy until explicit acceptance and
revalidate eligibility, source, target and policy at that press. Combat, closing,
foreign auction work and stale controls cancel safely. Actual buying retains its
separate player press. Old AH retains per-item pricing/whole-stack purchases and
no Scan all restock control; relevant consumable upgrade catalogues can supply
several cell proposals without pricing the whole restock list.

**AHR-97:** bandage discovery uses its item subclass and parsed healing amount,
with live level/First Aid/other usage restrictions checked by the existing score
service. Save accepted bandage tiers through the same shared tier owner. No new
item-name or tier catalogue. Preserve known recipe/material planning.

**AHR-98:** add a persistent per-item upgrade blacklist. Each candidate cell has
a Blacklist action which excludes that item and considers the next eligible
candidate from fresh results. Settings can add an item link/ID or remove an
exclusion. This lets players exclude discolored or other unwanted consumables
without a hardcoded name filter or an automatic judgment about their downsides.
Never silently accept or mark the blacklisted candidate as junk.

Reuse ordinary native buttons within the existing scrolling cell grid, with
candidate tooltip, restore comparison and price. Each proposal's actions must be
reachable independently through the existing controller cursor route; retain
scrolling and visible native highlight states. Decorative labels/icons add no
focus stops. Native directional navigation and other-client art remain pending
unless actually tested. All new text has English localization fallback; expose
blacklist management in the existing built-in addon settings registration.
External `restock-inline-upgrades-20261114T063938Z` verifies2772 source/history
files and 129 settings metadata before runtime edits; no private contents copied.
Current acceptance: inline 880 checks/20 models, shared exclusions 240/10,
global junk 1230/30 and geometry 120/20 PASS; 22 compiled harmful controls rejected.
Final 365 scripts/1053 syntax PASS. Native inline actions/controller/purchases are
pending; the active Forever user was not interrupted. [Evidence](validation/auction-inline-upgrades-2026-11-14.json).
The unrequested source/load-list rollback was separately recovered; see
[recovery](validation/flux-source-recovery-2026-11-14.json).

**AHR-99 / global consumable junk safety:** the user's follow-up applies beyond
the AH. Provide three independent, default-on settings in Loot & Items → Vendor
for keeping weaker bandages, healing potions and mana potions until a strictly
better usable tier is physically in bags. Use the existing carried-reference
and shared junk/selling/display services. Bank/mail/craftable/remembered tiers
are not owned replacements. Consuming or banking the last better item protects
the remaining tier immediately. Turning a type's protection off permits its
ordinary automatic junk rules and remembered-tier comparison; other types keep
their own settings. Explicit manual Junk/Useful choices remain authoritative.
AH upgrade acceptance must stop creating explicit manual junk marks, so these
global protections and per-type settings cannot be bypassed by an AH proposal.

**AHR-100/101 / shared exclusion and automatic discolored healing filter:** the
same exclusions must apply to automatic Best ranking, owned ladders, persisted
references and the healing consumable button, including its previously latched
item. Add a default-on per-character toggle that excludes every healing potion
whose name contains `discolored`, case-insensitively and anywhere in the name.
This keyword rule is explicitly requested by the user; it adds no item-ID or
full-name tier catalogue and must not exclude mana potions/bandages solely for
having the same word. Manual per-item exclusions remain available for any item.
Changing either policy refreshes existing Best/binding and tier owners, without
an AH dependency or requiring a new bag event. Combat still defers secure writes.
Excluded items must not act as better owned replacements for automatic junk, or
be purchased/planned as automatic AH restock outputs. Turning the rule off allows
them again unless manually excluded. The user explicitly chose **manual Junk
wins**; existing explicit Junk/Useful marks remain authoritative.

## Forever empty browse and restore amounts

14 November `AUCTION-POTION-BROWSE-20261114` / **AHR-94:** preserve AHR-93's
explicit Upgrade/Keep current decision before changing tiers or marking junk.
Potion ranking uses parsed health/mana restore amounts and live eligibility,
never an item-name tier list. Parse flat/ranged health and mana independently;
unrelated required-level/cooldown digits must not inflate either restore axis.
If completed modern phrase searches return no potion listings, make one
name-free potion-category query without Usable only and classify its results
locally. This does not scan the whole AH or add an old-AH bulk restock scan.

A queued request has no result ownership until it is sent. Ignore late results
while waiting for throttle readiness, wake on the native ready event, and show
the native queue wait/unavailable status instead of reporting no potions from
an unsent request. Keep existing bounded timers, caps, vendor exclusions and
separate purchase presses. No persisted tier or junk changes while unavailable.

Background checks on Forever1.60.1.70938 observed the native ready API returning
false and zero browse rows, including Blizzard's normal Buy search; the user
also reports that normal search is empty. This was unavailable native delivery,
not evidence that the market contains no potions. A fresh Mario Super character
connection restored62 potion-category browse rows. After the AHR-95 retry fix,
the r24 Restock scan displays a native Greater Healing Potion → Superior
Discolored Healing Potion prompt at22s93c/unit. Upgrade/Keep current is left
unanswered and the old5/5 target remains visible. A native mana prompt follows
the healing choice and remains pending; no purchase was submitted.
The user explicitly authorized background
window messages/captures; do not take foreground or use global input/clipboard.
Verify empty chat focus before diagnostics; earlier input during reload entered
the search box and is excluded from acceptance. A protected InteractUnit probe
was rejected; no further scripted interaction calls. Use ordinary native input.

External `potion-restore-20261114T005500Z` verifies2770 source/history files
and 129 settings metadata before this slice; no private settings copied.
Candidate `AH-restock-potion-browse-20261114-r24`:363 scripts/1051 Lua syntax
checks PASS. Confirmation672/20 and restore/browse388/20 checks PASS; three
matched before/after trials per20 models for each regression and15 compiled
harmful controls retain exact sources and raw outcomes. Five runtime files
match all five installed copies read-only; no manual synchronization occurred.
[Exact source identities, checkpoints, native captures and acceptance scope](validation/auction-potion-browse-2026-11-14.json).

**AHR-95 / cold linked-spell text:** the background native check found a loaded
next mana item with only its required-level line. Requesting its dynamically
linked spell data made the actual700–900 mana line available. Discovery now
uses the existing `Flux.Item.GetSpell` adapter and requests that spell record
once per item/discovery job while the existing bounded classifier retries.
Late ready spell text invalidates an earlier negative parse once. The pending
classifier does not request metadata that is already loaded: duplicate metadata
replies otherwise cleared its retry evidence repeatedly, leaving utility potions
pending and blocking both upgrade kinds. Known unusable items are rejected before
restore parsing. No tier/name/spell-ID catalogue, new observer, polling loop or cast is added.
Fresh external `potion-cold-spell-20261114T015100Z` verifies2771 files/history
and 129 settings metadata before this addition. The subsequent
`potion-loaded-pending-20261114T020800Z` checkpoint verifies2771 files/history
and 129 settings metadata before the native-discovered retry fix. Native text
checks observed900 health for Superior Healing at requiredlevel35 and900 mana
for Greater Mana at requiredlevel31. These names/IDs occur only in diagnostics
and evidence, not in a new production tier catalogue. Actual tier/junk commit,
native buying/receipts, other clients, controller navigation, broad taint and
CPU/FPS checks remain pending.

## Confirm potion upgrades before changing tiers

14 November `AUCTION-POTION-CONFIRM-20261114` / **AHR-93:** a usable stronger
healing/mana potion found by the existing scan must ask **Upgrade** or **Keep
current** before changing the saved tier, replacement or inherited price policy.
Keep current (including Escape/dismissal) preserves the old potion and junk
state. Upgrade commits the new tier and marks the previous item as explicit
junk through the existing junk service; it never buys an auction. The prompt
shows the observed unit price and available gold so an unaffordable upgrade
can be declined. Buying still needs its own player press and live wallet check.

Declining suppresses further prompts for that current kind/reference until a
new Restock tab session or explicit modern scan. Closing the tab/AH, combat or
foreign auction activity cancels the pending decision. A stale callback cannot
change tiers or mark junk. Eligibility, current reference/target and price mode
are checked again on acceptance. Missing popup/tier/junk services fail closed.
This supersedes AHR-92's automatic promotion, preserving its stocked-target
discovery, level-aware cache and old-AH per-item restrictions.

Use the native static-popup buttons and Escape/back handling; no custom input
capture, global binding or native navigation replacement. Verify both choices,
focus visibility/acquisition, activation and back with each client's native
controller/cursor route. Actual directional controller navigation, layout,
taint and protected purchases remain NOT RUN. The user subsequently authorized
the scoped Forever background native test described above. English localization
fallback is required for every new label.
Fresh external `potion-confirm-20261114T004200Z` source/history checkpoint:
2769 files and 129 settings metadata; no private contents copied. Desktop
confirmation672/20 and the native visible pre-commit prompt pass their stated
scope. No native accept/decline decision was made on the user's behalf.

## Usable potion tier upgrades during per-item scans

14 November `AUCTION-POTION-TIER-20261114` / **AHR-92:** AH preparation checks the
next configured healing/mana potion kind for a stronger usable tier, including
when weaker potions already fill its target. After the AHR-93 explicit acceptance,
the stronger item fills its entire target and updates the remembered potion tier.
Preserve the original unit-price
limit/No limit policy, reject unusable/restricted/conjured/non-discount vendor
offers, and require a separate player press for every native purchase.

The old AH remains per-item only with no Scan all restock control or bulk item
pricing. After the current purchase is acknowledged, the next potion kind can
be discovered. This supersedes the earlier filled-potion-idle part of AHR-88;
ordinary filled and disabled targets remain unscanned. Existing fresh kind
catalogues are reused, but a changed character level invalidates their
usable-only coverage so a newly usable potion is not hidden behind the old
30-second cache. No new timer/event/poll or setting is added.

External `potion-next-tier-20261114T002500Z` verifies2767 source files/history
and 129 settings metadata before changes; private contents are not copied.
Existing direct implementation and user-managed native testing choices remain.
Desktop acceptance: 361 scripts/1049 syntax;3 controls;complete current Lua manifest PASS. New240/20 checks and three matched trials per20
models verify stocked-tier discovery and changed-level cache invalidation.
[Exact sources, raw trials and controls](validation/auction-potion-tier-2026-11-14.json).

Reload out of combat, keep a full weaker healing/mana stack, and open Restock.
As each potion kind is prepared, verify the stronger usable item in its
Upgrade/Keep current prompt. Keep current must retain the old tier and junk;
acceptance updates the saved tier, inherited unit limit and complete target.
The next kind prepares after
the current buy receipt; each purchase needs its player press. Native scanning,
usability, visible tier/icon updates and purchases remain pending.

## Restock mail opening speed

14 November `AUCTION-MAIL-SPEED-20261114` / **AHR-91:** collecting AH restock mail
uses the saved Mail → Opening Speed interval between native take requests. Zero
requests the next item as soon as the native command and item proof permit.
Reply time is not added to the configured interval. A successful batch keeps
its deadline across identical-message compaction; cancellation/failure starts
a fresh session. Changing speed updates the active deadline.

One initial bounded native inbox snapshot establishes the owned candidate list.
Subsequent attachments require live header, COD/GM, item/quantity, receipt-budget,
free-space and native command checks. They do not wait for another full inbox
scan. Background snapshots still publish authoritative mailbox counts and keep
their existing48-read/1ms budget. Snapshot publication wakes the existing command
owner; initial missing data and genuine metadata/native-command waits remain
bounded. Ordinary Select/Open All collection keeps its existing behavior.

External `restock-mail-speed-20261113T235900Z` verifies2765 source files/history
and 129 settings metadata before changes; private settings are not copied. The
14 November local date is Europe/Copenhagen; checkpoint names use UTC. Existing
direct implementation and user-managed native testing remain selected. Desktop
cadence/safety acceptance: 360 scripts/1048 syntax;5 controls;complete current Lua manifest PASS. Focused940/20 and existing mail3100
checks pass. Three trials per20 models at six speeds preserve raw timestamps.
[Exact sources, timing/control evidence and limits](validation/auction-mail-speed-2026-11-14.json).

Reload out of combat and collect several restock attachments at0 and a positive
Opening Speed. Repeat with a delayed reply and a changed speed mid-batch. The
server command and live item checks still control when the next take is safe.
Actual server throughput, command latency, taint and CPU/FPS remain NOT RUN.

## Stable craft completion and restock work

13 November `AUCTION-CRAFT-STEADY-20261113` continues the user's restock goal.
**AHR-89:** a known pending craft item must not disappear/reappear merely because
the native stop notification precedes reliable bag publication. During that
same-job settlement gap, retain its known presentation with clicks, glow and
automation disabled. Reliable quantities update in place; reliable completion,
cancellation, another job/character and combat still retire/hide appropriately.
Do not revive a generic waiting/questionmark action or keep a completed job alive
with an arbitrary delay.

**AHR-90:** optimize the existing restock flow with measured reductions in
redundant row/count work and identical UI paints. Keep actual purchase/quote,
price/recipe/receipt, bank/mail/vendor ownership, optional integration and cache
freshness behavior. Old AH remains per-item only (AHR-88); modern explicit full
scans remain available. Use current owners and publications rather than new
polling or blanket caches. Preserve per-item buttons, sizes, one-pixel spacing,
tooltips, native scrolling, current pressed art and usable-only proc glow.

External `craft-settle-performance-20261113T203900Z` verifies2758 source/history
files and 129 on-disk settings metadata entries before runtime edits; private
settings contents are not copied. Existing direct implementation and
user-managed native testing choices remain selected. Candidate
`AH-restock-craft-steady-20261113-r18` passes358 scripts/1046 Lua syntax checks and
16 syntax-valid harmful controls, with the complete current Lua manifest and15
component hashes verified. All four changed runtime files match the five
installed copies read-only; no manual synchronization was performed.

Actual follow-up/craft driver/storm/HUD regression412/20 shows zero host
Hide/Show calls during settlement and one Hide at trusted completion. A known
same-job craft is held disabled; a cast observation is never inventory credit
or permission. One job-owned START observer captures only safe public tradeskill
cast facts and returns without a full refresh. Matching stopped tokens provide
a bounded cumulative potential-output hold; explicit failure/cancellation and
trusted completion stay authoritative. Modern public spell-ID equality or
public name equality can identify the observation. Legacy name mismatches fall
back safely; source declarations do not guarantee recipe/cast-name equality or
native event order.

| Work scenario | Before | After | Evidence scope |
|---|---|---|---|
| One80-item row refresh |160 deficit/bag reads;320 mail reads |80 deficit/bag reads;80 mail reads |Three trials per20 models; identical row values/checksums; no query/purchase. |
|25 ready follow-up refreshes |275 carried-count reads |250 carried-count reads |Three trials per20 models; memo lives only inside one Build, split physical/charges. |
|50 identical pending paints |1200 sizes/anchors/clears;250 fonts/textures;300 text/Show;50 sorts |Zero avoidable measured setters/sorts |Three trials per5 proc-enabled widget models; fallback/late-art coverage is separate. |

Quantity-only paints update the badge/caption and the required hovered tooltip
without geometry, icon or glow restart. Data1900, UI63063, render1020 and
integration290 checks pass. No new timer/poller is added; the one passive START
subscription retires with the job. Existing protected craft/purchase handlers
and cache/receipt policies remain unchanged. [Exact source identities, raw
matched trials, controls and limits](validation/auction-craft-steady-2026-11-13.json).

For native acceptance, reload out of combat and craft a multi-item batch. Watch
the known icon remain stable/disabled between outputs, counts update in place,
and the completed job disappear once. Cancel before any output and after a
partial batch, then retry with the normal player press. Repeat delayed/coalesced
outputs, charged targets and optional providers on the selected clients. Live
event delivery, craft permissions, visible flicker/art/clipping/controller/taint
and matched CPU/FPS remain pending; model call counts cannot establish them.

## Old auction house: per-item searches

13 November `AUCTION-LEGACY-ITEM-20261113` / **AHR-88** supersedes bulk-scan
requirements for the old auction house. Detect the actual AH generation with the
existing capability owner. On old AH, do not create a Scan all restock button or
offer that action in help text. Even a retained caller requesting
`ScanQueue(true, true)` prepares only the next eligible shortage, its relevant
recipe inputs and current potion kind. A search cannot spend; each player Buy
press purchases one indivisible listing, then prepares the next purchase. The
old-AH excess-stack policy and all price/recipe/receipt guards remain in force.
Modern AH keeps its explicit full-list refresh and filled-target potion upgrade
discovery. Old AH checks potion upgrades when preparing that missing potion
kind. There is no old-AH all-target refresh.

The existing direct-implementation/user-managed native test choices continue.
External `legacy-per-item-20261113T192100Z` verifies2750 source files/history and95
available settings metadata before changes; private settings are not copied.
Only the optional bulk control is removed from old-AH navigation. The existing
native primary button, editors, scrolling, close/back and bindings keep their
owners. Native controller navigation, clipping, taint and buying remain pending.
Desktop acceptance: 352 scripts/1040 syntax;3 controls;complete current Lua manifest PASS. Current source identities, initial fixture
failure/resolution and native limitations are in [the acceptance record](validation/auction-legacy-item-2026-11-13.json).

## Fast purchases and usable pending item buttons

13 November `AUCTION-FOLLOWUP-BUTTONS-20261113` carries the full restock goal
forward after the user's clarification: each item must be the actual button,
and each button must perform the same whole-step action. This supersedes the
r13 common clickable panel design in AHR-74/76/77; all earlier restock behavior
and current price/automation preferences remain requirements. Existing Implement
directly and user-managed native testing choices remain in effect. The external
`followup-overflow-audit-20261113T153032Z` checkpoint verifies2743 source files,
history and95 available settings metadata. The latest speed/readiness/mailbox
slice starts at `restock-speed-ready-buttons-20261113T164325Z`, with2745 source
files/history and95 settings metadata. Private settings are not copied.

| ID | Requirement | Implementation / acceptance |
|---|---|---|
| AHR-81 | Each pending item is its own normal icon button. More items form a smaller-button grid; every item button dispatches the same whole-step action. | UI67489/integration290 PASS: inert container/caption, pooled ordinary item Buttons,44px single-item baseline, stable IDs/counts, adaptive grid. AHR-86 specifies usable-only proc glow and one-pixel spacing. Native acceptance pending. |
| AHR-82 | Long pending lists remain bounded by the screen, with readable caption and every item reachable. | UI67489 PASS, including193/500/1000 items: normal small-list geometry, bounded native scrolling viewport, retained native scrollbar/cursor/wheel paths, whole-step activation and offscreen guards. Resize/scale/combat/cleanup/shrink add no poller. Native clipping/input pending. |
| AHR-83 | Keep the pending item buttons a normal clickable size and normal when pressed. The interim request removed glow. | UI67489 PASS:44px single item,40/36/34px intermediate sizes and32px minimum, ordinary square Button with its own normal/pushed/highlight art. Caption/container are inert. AHR-86 supersedes only the interim no-glow choice. Native pressed-art/geometry pending. |
| AHR-84 | After collecting AH mail, advance to needed bank/vendor materials without opening a trade skill. Remember the character's recipes, profession, materials and output across login/sessions. | Closed/progress1220, knowledge524/cache848 PASS: trusted planning, storm-settled refresh and durable owned recipe facts survive serialized reloads and transient/partial replies. Explicit revocation invalidates; actual crafts still revalidate ownership/materials/output. Native persistence/progression pending. |
| AHR-85 | Avoid repeated full AH scans and minimize presses/time between buying one item and the next. | Speed492/20 profiles and3 matched query trials/profile PASS:4→1 queries before first ready,6→3 for three purchases,3 player presses in both. Demand-scoped pricing, exact fresh owned-result reuse, next preparation after receipt, failed-quote read-only advance and explicit full scan remain separate. Native latency/purchase permission pending. |
| AHR-86 | Update pending quantities as crafting produces items. Glow when a pending item button can actually perform its step, with exactly one-pixel item gaps. | UI67489, closed/progress1220, craft1844, automation1260 and owner-rejection620 PASS: planned output badges update including rounded6→3; published readiness avoids recursion; only visible usable items glow. Known zero-command refusals recover; issued/in-flight commands remain guarded. Latest glow supersedes AHR-83; normal sizing/pressed art retained. Native actions/art pending. |
| AHR-87 | Remove the mailbox-window Restock button because pending item buttons already perform collection. | Mail3100/menu32 PASS: mailbox button/adjacent checkbox/tooltip UI removed; scoped worker and saved automatic collection options retained in settings. Any pending mail item requests all relevant restock attachments through the existing owner. Native coexistence pending. |

Candidate `AH-restock-speed-ready-20261113-r16` passes the complete352-script /
1040-Lua syntax suite and79 syntax-valid harmful controls. The complete normalized
Lua manifest and48 owned raw hashes match; all18 runtime files checked match the
five installed client copies read-only, without manual synchronization. Three
matched trials per20 profiles retain raw query/press counts and baseline/candidate
identities. These counts do not establish native latency, secure permissions,
rendering or FPS. The initial mail/recipe full report retains four failures and
their documented resolutions rather than being overwritten. [Exact acceptance,
source identities and raw evidence](validation/auction-speed-ready-2026-11-13.json).

Intent recovery stays with the execution owners. Vendor sessions remember
whether a native buy was issued; bank MoveExec marks the scoped session before
each native transfer attempt. Only a known zero-command/zero-step terminal
failure downgrades its submitted follow-up intent. Successful or unacknowledged
commands keep their duplicate guard until reliable inventory publication.
Stable vendor invoice facts allow a restored price/stock to retry once without
treating an unchanged index rebuild as new permission to buy.

Opening Restock prepares the next actual shortage. A successful purchase prepares
the next one automatically; the next Buy press purchases that prepared item.
Routine preparation does not refresh full targets or all price cells. **Scan all
restock** explicitly refreshes the entire list and discovers stronger usable
healing/mana tiers even when the weaker target is already full. Routine potion
discovery is limited to the kind needed by the next candidate; a cached healing
search cannot count as a mana search. Fresh prices are comparison data. A buy
still needs exact current owned query results and the existing live purchase
checks, with one native transaction per player press.

Native acceptance for this slice stays on the existing user-managed route:

1. Reload outside combat with a saved recipe job and its profession closed.
   Open Restock, buy successive items without pressing Scan between purchases,
   and verify each press issues one purchase. Repeat commodity/item markets and
   old whole-stack listings on their actual clients.
2. Use Scan all restock once to check every listed price and stronger usable
   healing/mana tiers, including a full weaker target. Confirm price-limit and
   craft/direct choices still agree with the selected policy.
3. Collect the restock mail from any pending item button; the mailbox window has
   no Restock button. Without opening a profession, verify the next bank/vendor
   step and its material counts, both ingredient Count Bank modes and both
   independent/global automation preferences.
4. Start the saved crafting batch with its player gesture. Check each output
   updates the badges, normal pressed item art and one-pixel gaps. Only buttons
   that can perform the current step glow; completion and combat hide the job.
5. Repeat full-bag, failed/cancelled collection and refused bank/vendor cases,
   then restore space/price/readiness and retry. Successful in-flight work must
   remain single. Check login persistence, optional Auctionator/Syndicator
   coexistence, localized layout, controller operation and taint separately.

The completion audit inspected AHR-1–80 against current source and concrete
assertions. The r13 complete348-script/1036-syntax manifest and its30 owned
source/test hashes matched before this slice. That audit found a real layout
limit:193 icons at20px/eight columns produce a620px host, which cannot fit a600px
UIParent merely by clamping it. It also retains the outstanding native acceptance:
protected buying/crafting, live mail/bank/vendor coexistence, persistence,
visual/localized/controller behavior, taint and matched CPU/FPS are **NOT RUN**.
Read-only process enumeration identifies the running Forever executable but
provides no usable native window handle in the sandbox; it is not evidence the
client has closed. No connected Witchcraft/UIForever/native UI tool is available.
Do not replace that missing native evidence with another desktop count.

## Item overview, follow-up automation and explicit price limits

13 November `AUCTION-FOLLOWUP-ITEMS-20261113` extends the active restock goal.
AHR-1â€“73 remain requirements. Implement directly and the existing user-managed
native test route remain selected; no additional approval or PC input is needed
for implementation. Fresh external checkpoint
`followup-items-limit-20261113T150000Z` verifies2729 source files/history and95
available settings metadata records; private settings are not copied.

| ID | Requirement | Implementation and acceptance |
|---|---|---|
| AHR-74 | Show every item needed for the current mail, bank or vendor step, with its own quantity. Shrink and wrap icons as more items are pending. | UI16763 PASS: stable IDs/physical counts, uncapped rows, shrinking/reset/reuse and craft output yield. Native appearance pending. |
| AHR-75 | Glow when the matching bank, vendor or mailbox opens so the next action is noticeable. | UI16763 and actual-owner integration270 PASS: published readiness avoids recursive paint, cached bank views fail closed, glow lifetime/resize is bounded. Native glow pending. |
| AHR-76 | Make the text below the pending items easier to read. | UI16763 PASS: outlined14px contrast-backed caption and one stage hit/focus host. Native pixels/localized/controller checks pending. |
| AHR-77 | Pressing any shown item handles every available item in that step. | Automation800 and integration270 PASS: real scoped queues, all targets, busy-owner continuation, price guards and stale-publication duplicate latch. Native execution pending. |
| AHR-78 | A separate option automates this AH restock's collection/vendor/bank steps independently of normal bank/vendor auto restock and also works alongside those options. | Automation800 and options6532 PASS: saved default-off independent toggle, global flags preserved, bounded retry after real readiness changes. Native persistence/coexistence pending. |
| AHR-79 | An explicit No limit toggle defaults on. With it off, zero Gold/Silver/Copper is a real zero cap. | Price788, scroll772 and36 combined controls PASS. Old positive caps preserved; oldzero/new defaulton; explicitoff0 blocks paid AH/output budget. Ingredient AH limits retain vendor policy. Native input/persistence pending. |
| AHR-80 | Preserve the original scan-all and stronger-tier requirements and keep Clear pending out of the UI. | Scan340 and market2532 PASS: all listed full/zero/free-route prices, forced fresh paid comparisons, stronger-tier updates despite filled weaker bags, correct grouped market availability. Clear pending absent; scroll772 PASS. Native scans/tier/delivery pending. |

The pending overview remains owned by this restock and hidden in combat or with
no work. Waiting is still an internal stage. All items in the current step must
remain visible and reachable; a full list is not reduced to the first item or a
tooltip-only list. The independent automation preference covers only these
mail/bank/vendor targets; normal restock preferences and other tasks are kept.
Auction purchases and protected crafting retain their native player gestures.
The price switch changes the AH cap, including the parent recipe budget; normal
vendor purchasing preferences are preserved. Older zero-is-unlimited help and
shortage-only/manual-clear acceptance below describe their dated implementations
and are superseded by AHR-79/80 for the current build.


Desktop acceptance is complete for this implementation:348 scripts/1036 syntax,
36 harmful controls and the complete current Lua manifest pass. Exact source
identities, initial obsolete scan-assertion failures and final results are in
[the acceptance record](validation/auction-followup-items-2026-11-13.json).
Native acceptance remains pending: open each matching interaction, check glow
geometry and every item badge, press any icon once with global automation off,
then repeat with independent/global options off/on and busy existing workers.
Test No limit on/off with zero/positive amounts and persistence after reload;
verify actual secure purchases/crafts separately on every selected client.
No native input, taint, pixel/controller or CPU/FPS result is inferred from mocks.

## Silent waiting and changed ingredient stock

13 November `AUCTION-RESTOCK-RECOVERY-20261113` carries the active restock goal
through the latest UI, bank, recipe, vendor and auction-generation corrections.
AHR-1 through AHR-65 and their prior feature sections remain requirements below.
This matrix adds the current steering; a reported item name is a reproduction
example, never a source-classification exception. Earlier evidence retains its
dated scope and does not certify the current charge integration or native build.

| ID | Requirement | Acceptance checkpoint |
|---|---|---|
| AHR-66 | Never show Restock materials pending on the HUD or require a skip click. | Waiting remains internal. No initial frame, tooltip or focus target; placement, login and combat exit cannot reveal it. Keep the job/listeners so the next valid action appears on a normal inventory/profession refresh. UI229 and state664 PASS; native pending. |
| AHR-67 | Reprepare missing AH ingredients automatically when previously owned stock changes, while preserving each selected source route. | Reprice changed source quantities before exposing the next purchase. An unlimited vendor input follows its valid vendor route unless a fresh eligible AH offer is strictly cheaper. Preserve user caps, whole-listing fit, shared stock and recipe budgets. Source1464 and crafting836 PASS. Source guard and final desktop integration pass; native checks remain pending. No automatic native AH purchase. |
| AHR-68 | The latest unambiguous learned vendor stock type replaces the opposite stock flag. | Unlimited observations clear stale limited flags; finite observations clear stale unlimited flags. Unknown or ambiguous observations preserve typed facts and exact prices. Learned data overrides the client catalogue without item-specific policy. Merchant-learning480 PASS; native vendor observation pending. |
| AHR-69 | Each ingredient's Count Bank flag controls both AH and vendor quantities and cost comparisons. | Off ignores its bank stock; on subtracts available bank stock once and retrieves required bank materials before crafting. Required10, bags0, bank5 means buy10 off or buy5 on, for either source. Existing bag/mail/shared allocations still count once. Change only the temporary ingredient preference, never its permanent restock target. Source1464, bank UI180 and scroll832 PASS. Temporary vendor rows retain the saved ingredient flag and physical bank count; final desktop integration passes; native checks pending. |
| AHR-70 | Detect the active old/new AH through the central capability service and preserve the proper purchase gesture. | A typed native result, including false, wins over stale cache/brand flags. Shown native owner/API fallback ignores an empty compatibility namespace. Modern commodity40 aggregates into one authorized Buy intent across price levels; old AH two20 listings require two distinct presses. Zero unit cap stays unlimited. Generation276 PASS; native detection/protected buying pending. |
| AHR-71 | Persist the character's professions, learned recipes, materials and output/yield for AH comparison and later character use. | Valid saved recipe facts work while that profession is closed. The same follow-up button opens the required profession and submits the exact verified batch when its native input requirement is met. Do not invent unknown recipes or materials; execution rechecks the live owned recipe/output/reagents. Closed-cache848 and craft-driver1692 PASS; final desktop integration passes; native open/craft pending. |
| AHR-72 | One modern noncommodity PlaceBid reserves one physical item, regardless of grouped result availability. | Availability2 must not become a two-item purchase when native PlaceBid buys one listing. One acknowledged five-charge item contributes5 pending charges once, not10; the unit price and budget also apply to the one physical purchase. Commodity quantities remain explicit native quantities. Implemented normalization and observed receipts use one physical item; source cases cover builtin and Syndicator ownership. Base19524, charges19882 and incoming743 PASS, including live availability validation. Native checks pending. |
| AHR-73 | Allow excess whole stacks applies only to legacy, noncharged listings. Charged SKUs always ignore that option. | Modern commodity purchases use the required quantity; modern noncommodities retain one listing per press. A nine-charge target with five charges per full item normally rounds to two physical items even when excess is off; that required rounding is independent of the legacy excess option. A larger unnecessary charged listing is not authorized by excess-on. Canonical charged-item policy and required rounding are implemented; charge regressions pass. Scroll832, charges19882 and source1464 PASS. Native checks pending. |

The ingredient bank flag is a source preference for the recipe material. Its
meaning is the same for vendor and AH inputs, including when there is no
permanent restock entry for that ingredient:

| Recipe requirement | Bags | Bank | Count Bank | Missing AH quantity | Missing vendor quantity |
|---|---:|---:|---|---:|---:|
|10 physical ingredients|0|5|Off|10|10|
|10 physical ingredients|0|5|On|5|5|
|10 physical ingredients|5|5|Off|5|5|
|10 physical ingredients|5|5|On|0|0|

These examples assume no additional pending/shared allocation. Bank-on does not
make bank items available to the native crafting call while they are stored;
the bank reminder and existing automatic/manual bank owner retrieve the needed
physical materials first. A bag-only direct restock target remains protected,
and one bank copy cannot supply several recipes or source routes twice.

Waiting is skipped only as a displayed button stage. It does not bypass genuine
missing ingredients, unavailable inventory facts, a native command in progress
or live craft verification. Mail, bank, merchant and profession notifications
prepare the next real stage automatically. Crafting and buying still retain
any player press required by the selected native client; a callback cannot buy
a second auction listing from the first listing's gesture.

The per-item price limit remains Gold/Silver/Copper and is per physical item;
zero remains unlimited. A modern commodity material shortage of40 can use one
commodity transaction rather than forty buttons. A modern noncommodity result
can describe a group of comparable listings, but its group availability is not
the number bought by one PlaceBid. After one five-charge physical item is
confirmed, its five pending uses reduce the charge target exactly once. A
second required noncommodity copy needs its own native purchase gesture.

Saved profession/recipe facts remain character-owned. Opening a profession may
be necessary to learn or refresh genuinely unknown facts, but it must not be a
condition for using a valid cached learned recipe in an AH comparison. Keep
output identity, yield and exact material quantities with that cached recipe;
starting a batch still verifies the selected live owned profession and recipe.

Existing Implement directly and user-native reproduction choices remain. Fresh
external checkpoint `restock-waiting-vendor-20261113T134409Z` verifies2699 source
files/history and95 available settings metadata records; private settings were
not copied. Waiting visibility changes no purchase or craft permissions. Bank
preferences and their existing controls retain keyboard/cursor focus paths;
hidden waiting and inapplicable excess controls are not focus stops. All new
visible help uses the existing locale service and English fallback; localized
layout and native controller acceptance remain pending.

The requested corrections and final desktop integration pass. The captured
suite passed341 scripts and1029 syntax files; all owned auction manifest entries
still match. Later unrelated edits are preserved and recorded without extending
that global source claim. All26 harmful controls reject their intended failures.
[Current source identities and acceptance](validation/auction-restock-recovery-2026-11-13.json).
Previously corrupted reservations cannot safely be halved without transaction
provenance; authoritative mailbox reconciliation remains the recovery path.
Native Retail, Forever, MoP, Era and
Anniversary detection, commodity/item/legacy purchases, mailbox delivery,
merchant learning, bank retrieval, closed-cache profession opening/crafting,
visual/controller behavior, taint and matched CPU/FPS checks remain **NOT RUN**.
Desktop model/profile counts establish only their stated Lua scope. No client
foreground/input, settings/profiler writes, manual install sync or publication
is introduced by this correction.

## Mailbox tooltip argument correction

13 November `MAIL-RESTOCK-TOOLTIP-20261113` fixes the reported Restock/Auto hover
error at Mail/Restock.lua152. The old SetText call put a boolean wrapping flag
in its numeric alpha position. The common helper now clears the tooltip and
adds one wrapped white localized help line, retaining its owner, anchor, show
and leave behavior. No restock quantities, settings, automatic actions or input
paths change. AHR-65 requires both mailbox hover controls to display without
argument errors. Strict tooltip stubs reproduce the bad call and reject it;
3160 mail checks/20 modeled profiles plus focused regressions pass. Native hover,
visual and controller revalidation remain pending; user reproduction retained.
[Evidence](validation/mail-restock-tooltip-2026-11-13.json).

## Integrated restock workflow (13 November 2026)

`AUCTION-WORKFLOW-20261113` implements the current mail/bank/vendor/crafting
workflow in `AH-restock-workflow-20261113-r11`. This intentionally supersedes
older scan-all, pagination, HUD mail-looting and purchase-only activation rules.
Implement directly and user-native reproduction remain selected.

| ID | Requirement | Implementation / desktop acceptance |
|---|---|---|
| AHR-57 | Missing vendor recipe inputs become temporary targets, including vendor-only recipes. | Saved source plans feed the existing manual and automatic vendor owner. Normal buyer purchases exact physical deficits; permanent targets remain unchanged. Sources800/20 profiles PASS. |
| AHR-58 | Advance stages automatically; click only for native actions requiring it. | Inventory events prepare the next mail/bank/vendor/craft stage. No stage-advance click. Exact craft/profession opening retains hardware input. Workflow300, state654, driver1692 PASS. |
| AHR-59 | Mailbox Restock button and saved Auto toggle collect only this restock's items. | One Postal command owner; speed/free-space/COD/GM/native-command gates, no takeover. Auto defaults on, saved off persists. Visible partial inbox items collect without claiming absent hidden items. Mail3040/20 profiles PASS. |
| AHR-60 | Automatic queue recovery scans shortages; explicit scans retain the user's original all-item requirement. | Superseded where necessary by AHR-80: explicit scans include full/zero targets and filled weaker potion tiers can upgrade. The prior shortage-only acceptance did not satisfy AHR-31; its old counts are historical. |
| AHR-61 | Compact cells, coin symbols, row wrapping, scrolling, no pages. | Shared restock cells in native ScrollFrame, compact coin-marked editor, clear selection, variable bank-row heights and clamped wheel/scrollbar. Modeled800x600 fits32 ordinary cells. Scroll800/20 and market2508 PASS; native pixels/controller pending. |
| AHR-62 | Empty mail clears pending collection/reminder automatically, without a Clear pending UI control. | Only complete native inbox proof clears absent receipts, private pending and HUD. Failed/unproved shifted mails never claim delivery. Inbox and delayed bag publication credit once. AHR-80 removes the accidentally reintroduced control; an internal cancellation API is not exposed as a pending-reset step. |
| AHR-63 | Recipe materials count bank; retrieve via HUD or normal auto/manual bank restock. | Physical source pools protect direct stock and shared vendor-owned allocations. Temporary goals reuse the normal move owner, bank-open auto path and manual button; changed goals invalidate its button cache once. Sources800/workflow300 PASS. |
| AHR-64 | Keep saved recipes, charges, all five clients and optional providers. | Closed-profession cached recipes, reload readiness, charge-to-physical conversion, exact unit caps/budgets and one AH transaction per press are retained. Current focused40 scripts/owned syntax PASS; initial full336/1024 passed before concurrent unrelated edits. Native acceptance remains pending. |

Source/history checkpoint: external `restock-workflow-20261113`,2684 source
files, verified history bundle and95 available settings metadata records. Private
settings were not copied. Current restock source hashes are verified; later global manifests drift during
concurrent unrelated Bars/meter/raid/unit work.26 harmful
controls are rejected:9 workflow,6 UI,5 source allocation and6 mail ownership.
[Evidence](validation/auction-workflow-2026-11-13.json).

Final scoped acceptance:40 scripts PASS, owned Lua syntax PASS and no restock
source drift. The initial complete suite passed336/1024 before concurrent work;
later whole-tree results and documentation inventory drift are tracked separately.
Unrelated work is preserved.

The mailbox scanner runs only for acknowledged collection work, with at most48
native reads or1ms per slice. It caches the current event generation and passes
validated matching headers to the existing mail worker. Interrupted/incomplete
attachment metadata cannot publish authority. The scanner detaches at completion,
close, no demand or timeout; no ticker is added. Loaded<total inboxes can collect
verified visible items; their absent/inaccessible receipts survive. A settled0/0
inbox clears the saved collection job and the **Collect restock mail** reminder.
The empty0/0 placeholder before initial inbox update is not treated as proof.

Native mail failure/index shifts cannot credit an uncollected attachment. Exact
owned proof and complete native counts preserve arrivals awaiting bag publication,
so delayed charges/copies cannot erase another attachment's pending quantity.
Provider maps remain read-only. A native correction to stale provider counts
expires when the provider changes or a new restock receipt arrives; later complete
snapshots can refresh existing corrections without creating unrelated HUD work.

Vendor and bank material goals are temporary per-character plans, including jobs
with no AH purchase. Bank credit does not cancel a direct carried-stock target
whose bank flag is off. Shared bank/vendor-owned ingredients count once. Whole
legacy listings retain their intended size when excess is off, and separate
purchases still consume their exact recipe budget. The normal vendor/bank buyer
and mover keep their ownership and native restrictions. Guild bank/void callbacks
remain out of scope.

New visible strings have complete English fallbacks; translations/localized-layout
review remain pending. Restock automation is reachable in built-in addon settings
through Loot & Items > Restock, as well as the mailbox toggle/menu. Coin decorations
are not controller focus stops. Cell/price controls retain keyboard Tab/Enter/
Escape; native scrollbar/cursor paths are preserved. Native directional focus,
virtual keyboard, clipping and controller activation are **NOT RUN**.

Native acceptance still needed on Retail, Forever, MoP, Era and Anniversary,
with optional Auctionator/Syndicator both present and absent:

1. Reload, open AH Restock, scroll many rows, edit coin fields and verify selection.
2. Scan a mixed full/zero/missing list; verify every listed item is priced and
   full weaker healing/mana targets can upgrade. Buy only real shortages, with
   one auction transaction per physical press.
3. Visit mail with Auto on/off and a free-space reserve. Collect only matching
   restock attachments; preserve unrelated/COD/GM mail, hidden partial-inbox
   receipts and another owner's active job. Empty inbox must remove collection HUD.
4. Exercise exact temporary recipe quantities through normal automatic/manual
   vendor and bank controls, including shared and charged items. Verify saved
   recipes with the profession closed, reload and count-bank settings.
5. Craft the exact batch via HUD, then verify next stage/completion, combat hide
   and automatic-mail resume. Check native errors/taint and matched CPU/FPS.

No client focus/input, settings/profiler writes, install synchronization or
publication was performed. Desktop tests establish modeled behavior only.

## Vendor catalogue, observations and auction discounts



13 November `AUCTION-VENDOR-ROUTES-20261113` replaces unconditional unlimited-vendor

exclusion with a strict discount rule. The user explicitly accepts a bundled

vendor catalogue combined with learned vendor data, so detection can work before

the character visits the seller. Item names are not policy exceptions.



| ID | Requirement | Implementation |

|---|---|---|

| AHR-52 | Unlimited vendor items stay out of AH restock unless AH is cheaper per item. | Hidden candidates receive read-only price probes. Only fresh, usable exact-item listings strictly below the vendor benchmark admit a row. Equal/dearer, owned/account-owned, stale, unavailable and historical-only offers cannot authorize the exception. Ready/click/commodity confirmation recheck the rule. |

| AHR-53 | Detect known vendor goods before a visit and keep learning. | Generated, client-scoped catalogue records supply base buy prices and unlimited gold-stock membership. Typed merchant observations take priority; observed limited stock can override a catalogue assumption. Missing catalogue records remain unknown. |

| AHR-54 | Repair/sell/manual-only vendor visits also learn applicable stock. | Configured restock targets request the existing paced merchant index even with automation off. This adds no new purchase or automation permission; Shift retains action-skipping behavior. |

| AHR-55 | Crafting selects the cheapest actual missing-material invoice. | Every ingredient is priced. A cheap AH unit price does not beat a vendor when an indivisible excess stack costs more overall. Chosen vendor/AH input routes and vendor prices stay with the plan; shared mixed routes cannot turn planned AH quantities into vendor purchases. |

| AHR-56 | Preserve unit caps, charge quantities, saved targets, optional addons and source ownership. | Zero user cap remains unlimited; the vendor discount rule still applies. Whole-stack unit fractions use exact multiplication. Vendor-only temporary targets are removed from AH row copies, without mutating their vendor-list owner. Food/water exclusions remain. |



Catalogue prices are neutral base prices, identified as such in the AH tooltip;

observed buy prices include that character's actual vendor price. Native item

sell prices, guessed sell-price multipliers and optional historical price APIs

are not vendor-stock proof. Auctionator continues to provide display hints and

receive complete scan results; it is not required. Typed observed unlimited,

unknown-price and free supplies retain their meaning.



The standalone catalogue is generated from the pinned MIT-licensed LibItemDB1.9.0

release. Only its vendor maps and required notice are included, not its runtime

or dependencies. [Generator](../tools/build_vendor_catalog.py),

[notice](../licenses/LibItemDB-MIT.txt). Stock membership is dated, emulator-derived

reference data with client-specific item-price profiles, not native certification

of every seller, access condition or reputation discount. Actual learned stock

and prices supersede it. Source headers, input hashes and release checksum are

retained; regeneration checks the complete source before changing data.



Retail has its own generated data from pinned TrinityCore12.1.5 world-vendor

records and matching client ItemSparse, with the

[GPL notice](../licenses/TrinityCore-VendorData.txt) and

[license](../licenses/TrinityCore-GPL-2.0.txt) kept separately. Unlimited gold

item rows exclude limited stock, extended costs, player conditions and server

vendor conditions. Only the vendor/condition tables were streamed from the

source archive; no full world database or server code is shipped.



| Selected client | Catalogue stock rows | Priced rows | Client price build |

|---|---:|---:|---|

| Retail | 3,710 | 3,693 | 12.1.5.70783 |

| Forever | 849 | 849 | 1.60.1.70888 |

| MoP | 3,005 | 3,005 | 5.5.4.68806 |

| Era | 862 | 862 | 1.15.9.69722 |

| Anniversary/TBC | 1,708 | 1,708 | 2.5.6.68941 |



Wrath/Cata profiles are retained for existing client adapters. Across the seven

source profiles there are15,327 stock records and15,310 prices; only the selected

profile is allocated. Retail's17 stock-only records stay vendor-classified with

unknown prices until observed. Missing records remain unknown rather than

incorrectly marked vendor-only.



Every catalogue price is per physical item: raw BuyPrice divided by the matching

VendorStackCount. All11,617 legacy raw prices/counts were checked against their

own client build, without guessing from maximum stack size or item charges.

Exact numerator/denominator comparisons reject equal fractional prices; recipe

invoices and wallet affordability multiply before dividing to avoid rounding

underbuys or rejecting equal-cost crafting. The unit-price tooltip/offer shows

fractions instead of rounding them up to a whole copper.



Current desktop acceptance:332 scripts and1,019 Lua syntax checks pass, including

30,990 catalogue checks,1,170 price-policy checks,1,130 queue checks,600 recipe

route checks and415 merchant-learning checks.16 harmful controls are rejected.

The generator verifies pinned original inputs and licence notices. Source/history

checkpoint2670files/95 currently present settings metadata entries is external;

private settings were not copied. Native stock/access/discounts, protected buying

and crafting, delivery latency, HUD/controller/taint/FPS remain unverified.

[Evidence](validation/auction-vendor-routes-2026-11-13.json). Build:

`AH-vendor-catalog-20261113-r10`.



## Follow-up button and closed-profession recipes



13 November `AUCTION-FOLLOWUP-20261113` adds one ordinary HUD button beside the

extra-action area. It follows acknowledged FluxUI restock purchases through mail,

missing vendor materials and exact selected recipe batches. Pending work survives

reloads in the existing character auction settings. Arbitrary mailbox items,

manual purchases in other auction interfaces, unsuccessful attempts and merely

pricing a crafting route do not activate it. Older accepted private reservations

can resume after inventory becomes reliable; an unpurchased vendor plan alone

cannot create a job.



| ID | Required behavior | Implementation |

|---|---|---|

| AHR-46 | Remind the player to collect this restock's mail, using the extra-action area. | One addon-owned44px button beside the native host, with the same Flux Window fallback on clients without that host; item/count tooltip. Each press takes one matching non-COD/non-GM attachment. |

| AHR-47 | Remind the player to visit a vendor with needed ingredients. | Exact missing materials and the chosen recipe's vendor unit limits survive closing AH/reload. A press at a vendor rechecks slot identity, current price, currency type, wallet and existing buyer ownership before one needed purchase. |

| AHR-48 | One button opens the required profession, batches needed crafts and advances the queue. | Persisted exact output, learned recipe, yield, ingredients, allocation and profession identity; one recipe batch per press. Asynchronous opening needs another press when ready. Events prepare the next step and never start a craft. Legacy indices are re-found from live recipe/output/material identities. |

| AHR-49 | Hide in combat and disappear when this restock has no follow-up work. | Combat hides the ordinary widget immediately; unfinished work restores out of combat. Completion removes the job and demand subscriptions. Existing native action buttons and bindings are untouched. |

| AHR-50 | Follow-up quantities remain correct after stock changes. | Recipe materials preserve their own restock targets, including partial charged copies. Owned attachment receipt proof handles an old last charge being used while a new copy is collected; provider tables remain read-only. |

| AHR-51 | Decide Craftable versus Direct using this character's saved recipes while professions are closed. | Only a matching, visible, ready, owned profession may override saved facts with live learned/schema/output data. Closed/wrong/linked/NPC/changing contexts use complete cached deterministic facts. Uncertain quality output still needs live operation proof; actual crafting always verifies current data. |



The staged job is a workflow, not a new preference or SavedVariables root. It is

discovered through the existing AH Restock path and appears only for unfinished

acknowledged work. Existing targets, caps, bank flags, crafting/excess preferences,

vendor automation and permanent item lists retain their owners. Shared direct

material targets are protected both when calculating missing ingredients and

immediately before the native craft.



The widget has one mouse/controller-cursor action region, normal hover highlight,

localized stage/help text and no editable fields or navigation panel. It does not

capture the native extra-action binding or add a secure visibility driver. Native

gamepad reachability, actual placement, combat transition, mail/vendor delivery,

profession opening and crafting permission remain user-native checks. Forever's

current generated/native source exposes OpenTradeSkill, while TSM uses a secure

spell-opening path there; direct opening is not certified by desktop tests.



The fresh external checkpoint `followup-actions-20261113` contains2,663 source

files, verified source/history archives and103 settings metadata entries, without

private contents.26 pinned profession Lua/XML/TOC/API blobs were verified; current

Forever source is `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` (1.60.1.70938).

Other client pins remain in the source ledger. Debug build:

`AH-restock-followup-20261113-r9`.



## Purchase identity, selection and charged items



13 November `AUCTION-PURCHASE-CHARGES-20261113` follows the screenshot with one

potion purchased, an unrelated Pending38 cloth against a two-cloth target, and

a Buy next button with no remaining offer. The native completion event also fires

for commodities. The built-in observer now credits an item completion only when

an observed matching item bid identifies that auction; it no longer reconstructs

unobserved purchases from an arbitrary cached auction row. Legitimate whole-stack

receipts still credit the complete purchased stack. Existing predictions have no

reliable purchase provenance: a normal mailbox refresh replaces an older incorrect

prediction with actual attachments; no Clear pending control or destructive reset

was added.



| ID | Required behavior | Implementation |

|---|---|---|

| AHR-41 | A potion purchase cannot also reserve unrelated cloth; the next real shortage stays buyable. | Matching observed receipts only; real planner/receipt regression covers potion1, cloth2 and a fresh press for the next item. |

| AHR-42 | Before a commodity quote, reduce an older offer to the current shortage. | Rebuild from exact-item native cached rows before cap, wallet and crafting-budget checks; applies with either excess-stack preference. |

| AHR-43 | Make the cell selected for price editing obvious. | Three-pixel gold outline and warm background using decorative textures; the automatic buying queue remains independent. |

| AHR-44 | Share consumable charge detection and count targets as remaining uses. | Shared Registry owns detection/capacity; unknown capacity blocks buying. Bags, bank and incoming stock use matching units. Target9 on a five-charge item buys two physical items for ten uses. |

| AHR-45 | Preserve charge units through recipes, pending mail and shared material targets. | Recipe yields/ingredients and AH quantities/prices remain physical items. Reservation scale and physical arrival metadata prevent role changes or using an older charge from inventing extra pending stock. Mixed direct/craft purchases charge only the recipe share to its budget; whole-stack surplus remains in that budget. |



Whole items always round up to fulfill a charge target, including when excess

whole stacks are disabled. That preference still controls indivisible auction

listings: an old-AH listing of three items needs opt-in if only two are required.

The offer states physical item quantity, charge supply and total/unit cost; the

maximum price is per physical item. Charged generic tier references count exact

SKU uses; ordinary potion/bandage tiers retain their aggregate tier owner.



Selected-cell decoration adds no interactive frame, focus stop or purchase action.

The existing cell, right-click quantity editor, money fields, bank toggle, pages

and single Buy next button remain the input owners. Controller focus/activation,

native pixels, actual charge metadata, mail delivery and protected purchases still

need the already selected user-native reproduction, including the earlier Forever

blocked action. Debug build: `AH-purchase-charges-20261113-r8`.



External checkpoint: `purchase-identity-20261113`, 2,654 source files, verified

source ZIP/history bundle and103 settings metadata entries; private contents were

not copied. [Current validation](validation/auction-purchase-charges-2026-11-13.json).



13 November CHARACTER-RECIPES-20261113: per-character recipe snapshots now support AH

planning after profession close/reload, shared output queries and temporary vendor

material targets. Finished-item unit caps include the crafting route;0 remains

unlimited. See [saved recipes and vendor targets](CHARACTER_RECIPES.md).



Request `AUCTION-RESTOCK-20261112`; follow-up `AUCTION-AUTO-CRAFT-TAB-20261112`.

The user chose direct implementation and user-performed native reproduction.

Changes stay in this existing Retail working tree on main; the user manages

client synchronization. No client foreground/input, private settings/profiler

write, manual installation sync, commit or publication was performed.



## Potion scan stall follow-up



12 November potion discovery stall (AUCTION-POTION-STALL-20261112; AHR-38Ã¢â‚¬â€œ40): the new

screenshot remains Finding stronger usable potions. The real parser reproduced

a spent shared-budget failure that the earlier classification stub missed. Each

deferred AH batch now renews that budget (still at most8 IDs). Potion results mark

whether restore is known; name-only placeholders retry until real tooltip data

arrives and cannot be ranked as restore1. Known unusable potions are skipped first.

Native ADDED browse payloads now contribute later rows and cumulative unique-key

progress, preserving the initial catalog instead of repeatedly reading its first

batch. Read-only /fluxah debug adds search phase/term/results/page/deadline.

Five repeated desktop work models: baseline refs100/101,734 load requests and

timeout; candidate refs201/300,30 requests and ready. Simulated elapsed times are

not native measurements. 552 potion/16525 auction checks;20 restock/15 receipt models;6 new harmful controls;314 scripts/995 syntax PASS.

Four existing runtime/test files changed;0 new; external2,608-file source/history

checkpoint and47 settings metadata entries verified. Existing UI, settings,

unquoted terms, price/usability/shared tiers and per-press buying are preserved.

User native reproduction route/direct implementation remain selected. Current

native retest and earlier Forever purchase BLOCKED resolution remain pending.

No client input/focus, private settings/profiler write, manual sync or publication.

[Current behavior](AUCTION_RESTOCK.md);[evidence](validation/auction-restock-potion-stall-2026-11-12.json).



| ID | Requirement and current evidence |

|---|---|

| AHR-38 | Upgrade discovery continues after inventory consumes the shared tooltip budget; real Classify owner now tested across all five clients. |

| AHR-39 | Native incremental browse payloads can contain stronger later tiers; cumulative distinct-key progress requests every chunk. |

| AHR-40 | A potion name without a restore line is unresolved; retry it, reject known unusable candidates first, and never rank placeholder restore1. |



## Screenshot, grid, sources and potion tiers



`AUCTION-DENSE-STOCK-20261112` implements the latest steering. The screenshot

reports a phantom Pending1, unwanted recipe/cost pane and limited Mageroyal

misclassified as vendor-only. The user then requests more item room, scanning

every listed item and Auctionator price reads/write-back. These requests supersede

the detailed recipe pane and price-only vendor witness behavior described below.

Direct implementation/user native reproduction remain selected.



| ID | Required correction | Current checkpoint |

|---|---|---|

| AHR-28 | Persist only acknowledged incoming reservations; discard old/failed attempts; legacy list updates alone are not purchase receipts. | Implemented; acknowledged/provisional/migration regressions pass. |

| AHR-29 | Full-width dense cell grid; compact Direct/Craftable labels; no learned-recipe/cost pane; preserve three money inputs and one buy button. | Desktop layout/route regressions pass; native comparison pending. |

| AHR-30 | Learn unlimited versus limited/unknown stock from merchant metadata, without item-name/ID exception lists. Limited/unverified sources stay AH eligible. | Unlimited/limited/unknown/extended-cost regressions pass. |

| AHR-31 | Scan prices for all listed nonvendor items, including full/zero targets; buy only real shortages. | Full/zero-target price scans pass; purchases still require shortage. |

| AHR-32 | Optional Auctionator public price reads and guarded native database write-back of complete exact-item scans; cached prices never authorize buying. | API reads/unit-price writes/one notification/empty-result regressions pass; native coexistence pending. |

| AHR-33 | Food/water are absent from auction cells and scans; keep vendor restock behavior/settings. | Tier-kind and item taxonomy filtering implemented. |

| AHR-34 | Vendor-supplied spell reagents stay out of AH; limited/unknown/loot reagents remain eligible. | Existing dynamic spell-reagent owner plus typed unlimited vendor predicate. |

| AHR-35 | Find stronger usable health/mana potions offered at AH, preserve the configured limit, and use the upgrade for restock. | Usable partial-name catalog plus live-offer validation implemented; real Classify/Best.Score reused. |

| AHR-36 | Fill the full target with the stronger potion; update the shared healing/mana reference and tier too. | Real Best.Persist/Tiers owners; weaker bags/bank stock excluded even with inferior marking disabled. |

| AHR-37 | Search plain healing potion / mana potion as partial names, without literal quotes or exact matching. | Modern usable/class-scoped browse and legacy usable/class-scoped partial queries; all result chunks/pages read. |



External source/history/settings-metadata checkpoint:

`auction-restock/tab-crafting-followup/screenshot-reconcile` (2,602 source files;

47 metadata entries; ZIP and Git bundle verified). Previous evidence remains

historical. Current desktop acceptance is recorded below; native acceptance remains pending.



## Current behavior



Open the auction house's **Restock** tab, `/fluxah`, or

Vendor Ã¢â€ â€™ Restock Ã¢â€ â€™ Auction restock & prices. The panel belongs to the auction

house. Opening it prepares current shortages automatically. An explicit Scan

restock prices every listed item, including full/zero targets and newly displayed

ingredients. Cell selection only chooses which price to edit;

buying never requires selecting a particular item.



Cells reuse `FluxConsumablesGridUI` chrome/counts and the current matching

bandage/potion button icon, falling back to the actual item's icon. Left-click

edits its price; right-click edits its existing restock quantity; the coin toggles

its existing bank-count preference. Gold, Silver and Copper are three numeric

fields. Enter, Tab or focus loss saves; Escape restores the saved amount.

**No limit** is an explicit per-item switch. It defaults on for new or previously

unlimited items; existing positive copper caps are preserved with the switch off.

With No limit off, all-zero Gold/Silver/Copper is a real zero cap and authorizes

no paid AH purchase. Material cells can impose additional saved AH limits, and

parent output budgets include their complete missing-material invoice.



The shared **Buy next** button authorizes one transaction per press. On modern

clients that press starts an exact-quantity quote and confirms that same item and

quantity once if its price meets the captured/current unit limit, wallet, remaining

shortage and crafting budget. An unrequested price event cannot start a purchase.

Duplicate events cannot consume the intent twice. Closing, competing searches,

configuration changes, timeout and combat revoke it. Preparing the next purchase

after a receipt is read-only; it needs a new press.



For Era/Anniversary, an auction stack cannot be split. Default behavior skips

need10/listed20, prefers an exact stack, then fitting stacks by unit price. If

**Allow excess whole stacks** is enabled, a complete no-fit search may offer the

smallest excess stack, showing full total and surplus. Each press buys at most

one whole listing. Cached planning books never authorize stale legacy indices:

the next listing is queried and revalidated live. This is not a global cart

optimizer across combinations of stacks.



There is no Clear pending control. Incoming items are tracked automatically from

purchases awaiting delivery and the existing current-character mailbox cache.

For19/20 Light Feathers, buying1 immediately adds Pending1 and prevents another

purchase. Seeing it in the inbox replaces the transit reservation once; collecting

it transfers that credit into bags. Existing mailbox items count before buying.

The combined bags/inbox baseline prevents taking older mail from erasing a

different purchase still in transit. Mailbox/bag-storm handoff waits for stable

facts; a completed empty inbox overrides the cold persisted fallback.

Only acknowledged purchases retain incoming credit after a transaction ends.

Old/unacknowledged attempts are removed, while previously accepted units survive

a later failed attempt for the same item. The built-in observer

can release its identified failed confirmation; a synchronously blocked submission

releases its own known-unexecuted reservation. No

automatic retry spends gold. AHR-27 adds immediate confirmed-purchase predictions

to the built-in provider; other inbox visibility still uses its last observation.

No new mailbox scanner or inventory provider is introduced.



## Recipes and materials



The recipe/cost pane was removed to give the item grid the full available width.

Each cell shows **Direct** or **Craftable**. The modeled800Ãƒâ€”600 owner fits24cells;

other sizes use the same grid and pagination. Open the relevant profession once

to populate the existing character recipe cache. The saved **Prefer crafting

materials** toggle is in this tab and Vendor Ã¢â€ â€™ Restock. On (default): compare and

select economic materials. Off: queue finished items only. It survives closing/reopening

and does not reset quantities or price limits. This reuses Inventory.Professions;

there is no new scanner or automatic crafting.



Only verified learned, usable recipes for the exact requested potion/bandage

output qualify. Operations round up using minimum yield. Modern quality choices

must guarantee the requested output ID without concentration. Unknown recipes,

reagents, output quality or prices do not become guessed/free materials.

Missing materials are chosen when full acquisition cost is cheaper than or equal

to the finished shortage and within any explicit output cap. Equal cost prefers

materials. Unknown finished price cannot establish a cheaper route except when

all inputs are owned (zero acquisition cost).



Carried/pending ingredients are allocated once across outputs and direct restock

targets. Shared ingredients merge into one target. Verified unlimited vendor ingredients contribute

remembered purchase prices and remain visible to obtain at the vendor; they are

not auction-bought. Legacy comparison includes entire allowed excess stack costs.

Each parent keeps a finite remaining material budget even with zero/unlimited

output cap. Actual costs are allocated to the parents that need the bought units.

Finished outputs covered by a material plan are not bought again during mail wait.



Only witnessed unlimited, purchasable gold/free merchant stock is excluded:

`numAvailable == -1`, purchasable and no extended cost. Limited (`>=0`), unknown,

old price-only records and sell-to-vendor values do not prove unlimited supply.

This keeps limited herbs such as the reported Mageroyal auction eligible without

an item-name/ID exception list. There is no universal Blizzard vendor-source

database here: an unclassified item can remain in the auction list. Food/water

are excluded by existing tier kind/item taxonomy. The same unlimited-supply rule

applies to spell reagents. Existing vendor targets/settings remain intact.



## Stronger potion discovery and market data



Healing and mana slots search plain **healing potion** / **mana potion** (no

literal quotes). Modern browse uses usable-only and consumable/potion filters;

legacy searches use partial matching, usable-only and the same class filters.

All browse chunks/legacy pages are collected before ranking. Existing Classify

and Best.Score determine actual restore value and level/class/skill usability;

name matches alone never establish a potion tier. Unknown item data receives

bounded retries and holds potion purchases if still unresolved. Closing or a

competing search cancels discovery.



A stronger usable candidate must have a live purchasable offer inside its

configured/inherited unit cap. Own-only, unavailable and over-cap candidates fall

back to the next offered tier. Zero/unset stays unlimited. The chosen potion

updates the existing shared Best.Persist reference and Tiers saved threshold,

without arming vendor selling. Weaker potions in bags or bank do not count toward

the stronger target, including when inferior marking is disabled. Existing bank

preferences still apply. Losing usability revokes a prepared buy; if the old ref

is scrubbed, the replacement retains its price source. Manual/preset edits still

address their original quantity target.



Optional Auctionator hints use its public v1 item-price reader. Complete exact-item

scans publish the lowest unit price and total availability through a guarded

Database:SetPrice compatibility adapter, then coalesce its PricesProcessed event.

No public price writer exists in the inspected345 API. Empty scans preserve its

history. Historical prices are hints; a fresh native search/quote authorizes buys.

Missing/changed optional APIs leave standalone scanning available.



## Requirements and acceptance



All rows have desktop implementation/regression coverage. Native operation,

visual comparison and optional-addon coexistence are pending for this candidate.



| ID | Requirement / final implementation |

|---|---|

| AHR-01 | Modern exact quantities; old AH one whole listing per press on all five targets. |

| AHR-02 | One action button and transaction per press; AHR-20 updates initial two-press quote semantics. |

| AHR-03 | Existing manual/preset/bank targets; exclude witnessed vendor items. |

| AHR-04 | Saved integer copper caps; AHR-79 now separates No limit from an explicit zero cap. |

| AHR-05 | Fitting legacy stacks by default; explicit excess with surplus/total; live listing revalidation. |

| AHR-06 | Standalone and optional Auctionator/Syndicator; no copied addon code or required dependency; yield to competing queries/dialogs. |

| AHR-07 | Bounded throttle/partial results; stale prices/counts, combat, close, pending mail and uncertain outcomes. |

| AHR-08 | Options/tab/slash discovery; English fallback; mouse/keyboard; controller acceptance pending. |

| AHR-09 | No idle polling, getAll/whole-house search or new inventory provider. All eligible listed items/materials and two relevant partial potion searches; no getAll. |

| AHR-10 | No-search failure addressed by removing cap-gated discovery and scanning on tab show; native retest pending. |

| AHR-11 | Real auction-owned Restock tab; preserve native/other tab handlers. |

| AHR-12 | Three Gold/Silver/Copper fields; inherited native focus-loss behavior. |

| AHR-13 | Learned exact-output potion/bandage recipe comparison; equal cost prefers materials. |

| AHR-14 | Minimum yield; owned/pending/shared material allocation; full stack/vendor costs. |

| AHR-15 | Per-parent material budgets; one purchase per press; no auto-crafting or duplicate finished purchase. |

| AHR-16 | Unknown learning/quality/reagent/price evidence cannot authorize speculative material buying. |

| AHR-17 | Two Forever mouse-click ADDON BLOCKED reports: direct/unwrapped restricted calls, Start remains unhooked, native action before input-button disabling. Native resolution UNVERIFIED. |

| AHR-18 | Shared restock cells/price labels and matching current bandage/potion icons. |

| AHR-19 | Automatic whole-list/material planning; price editor independent of buying. |

| AHR-20 | One press quotes/confirms one qualifying quantity; callbacks/timers cannot start another purchase. |

| AHR-21 | Superseded by final user instruction AHR-26: remove Clear pending entirely. |

| AHR-22 | Superseded by AHR-79: explicit No limit switch; off plus zero is a real zero cap. Existing positive caps and finite craft budgets remain. |

| AHR-23 | Superseded by AHR-29: compact Direct/Craftable labels replace the recipe/cost pane. |

| AHR-24 | Screenshot's lowered tab: match neighboring top edge/height; native pixel comparison pending. |

| AHR-25 | Saved Prefer crafting materials toggle in AH and addon settings; off buys finished items only. |

| AHR-26 | Automatic current-character inbox plus transit credits;19/20+1pending prevents rebuy; no Clear pending control or user command. An internal cancellation function is retained by AHR-62/80. |

| AHR-27 | Built-in inventory publishes confirmed AH purchases into its shared mail snapshot immediately, including other auction controls; ready Syndicator owns its own ledger. |



## Native failures and reference inspection



Initial native attempt FAILED: no search/response. Forever mouse-click traces

then showed ADDON BLOCKED at11:44 through pcall and at11:57 at the direct

StartCommoditiesPurchase call. Removing pcall alone did not resolve it. The current

candidate also leaves the actual input button enabled until after the restricted

quote/bid call and registers LeftButtonUp. These source corrections are not proof

of a successful native purchase. `/fluxah debug` prints candidate tag, mode/state/

reliability and last attempt's item/quantity/button/security facts without buying.



The user's explicit requests authorized read-only Auctionator/TSM/Syndicator source inspection,

superseding earlier reference-folder restrictions for this task. External documents

were reference material, not user requests. No external source was copied or

modified; both addons' All Rights Reserved notices remain intact. Exact inspected

file hashes/version/license identities are in follow-up evidence.



Auctionator345 directly starts commodity quotes from its button, then confirms

through its dialog; legacy buys revalidate and bid once per stack. TSM4.15.6 also

calls native APIs directly through a wrapper and executes button actions before

applying disabled/cooldown state. TSM hooks auction APIs, so hook presence alone

is not a proven cause of the native block. No secure-delegate bypass is used.



Pinned modern declarations mark StartCommoditiesPurchase restricted; Confirm has

no HasRestrictions flag. Native modern UIs pass a displayed unit price as a third

Start argument despite the generated two-argument declaration. These source facts

inform one-use intent; they do not certify running-client addon permission.



Syndicator290 captures purchase context and publishes confirmed quantities directly

into its character mail ledger, then signals MailCacheUpdate. The built-in service

now supplies equivalent immediate incoming publication independently: its receipt

observer captures commodity confirmation, modern item buyout or legacy buyout

context using native post-hooks, and publishes only after the corresponding receipt.

StartCommoditiesPurchase remains unhooked. A legacy ordinary bid is not incoming

until a buyout acknowledgement; modern item quantities use the full actual stack.

Receipts/auction IDs are consumed once. Context maps are bounded128 and expire at

receipt validation without allocating another timer, frame, tooltip or inbox scan.



Publication updates the built-in mail snapshot/count/generation and durable

current-character mail list immediately, then uses the existing notification and

summary invalidation service. It applies to native/other-addon auction controls

as well as Restock. Existing inbox scans replace prediction rows with observed

attachments. The own in-transit reservation remains until observed bags/inbox

credit, so an early empty inbox cannot discard it. Provider prediction and private

reservation count once. Already-ready or newly-ready Syndicator keeps exclusive

write ownership; stale built-in completion never appends to its records.



## Ownership and evidence



Seven Auction modules own math/preferences, recipes, price integration, potion

discovery, session, locale and lazy UI.

Existing changes are TOC loading, options entry, merchant memory/settings fan-out,

plus built-in Mail publication/Auctions startup and typed merchant supply.

Potion upgrades intentionally extend Best.Persist and the existing Tiers settings/

count owners; default vendor count behavior is preserved. The new

Builtin.AuctionPurchases receipt observer never buys or wraps native APIs.

Shared cells, professions, inventory adapters and consumable buttons are reused

without follow-up edits. Guild-bank/void-storage callbacks remain out of scope.

Saved Restock.auctionRestock retains maxUnitPrices, allowExcessStacks,

preferCrafting, potionLimitSources and pending[itemID] receipt/count baselines.

Unacknowledged older attempts are pruned; accepted purchases remain reconcilable. Recipe/price decisions are session-only. The existing

Inventory mail/profession listener is attached only while the tab is active;

provider snapshots and the current-character persisted mail fallback are reused.



Price books are reused for at most30seconds; plans retain pending/spent budget.

One cancellable timer handles bounded300ms throttle retry or search/quote/response

timeout, plus bounded potion metadata batches/retries using that same timer. Foreign queries yield until explicit scan/tab reopen; bag pulses do not

fight another addon's search. No idle polling or automatic spending retry exists.



Source pins resolved12November from Gethe/wow-ui-source:



| Client | Commit | Source version |

|---|---|---|

| Retail/live | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 |

| Forever | `4cd0ab752a77164f654ccbca9d0c1fe8dafceebe` | 1.60.1.70888 |

| MoP/classic | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | 5.5.4.70631 |

| Era/classic_era | `4192ac60067fc55566182291bc67c85dd9b6794d` | 1.15.9.70576 |

| Anniversary/classic_anniversary | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | 2.5.6.70577 |



226 upstream Git blobs verify against those pins. External recovery checkpoints:

`C:/Users/mario/.codex/visualizations/2026/11/12/01a1cf21-878c-7ce1-9715-68986a154712/auction-restock`

and its `tab-crafting-followup` and `tab-crafting-followup/builtin-incoming`

and `tab-crafting-followup/screenshot-reconcile` directories. They retain

2,587/2,595/2,598/2,602 source files,

verified Git bundles at main26f886e3ea5371b196ab235d2dace0c156002285 and47 WTF

metadata entries each. Private settings were not copied while clients may run.



Six focused suites execute actual UI/shared cells, planner, session, target math,

built-in mail publication and Best.Score/Persist/Tiers owners:16,525 checks across

20 restock and15 receipt/provider models. Final control/full-suite results and

candidate identities are in

[current stall evidence](validation/auction-restock-potion-stall-2026-11-12.json).

[Earlier grid/potion evidence](validation/auction-restock-dense-potions-2026-11-12.json) predates this correction.

[Follow-up evidence](validation/auction-restock-followup-2026-11-12.json) and

[initial evidence](validation/auction-restock-2026-11-12.json) are historical and

cannot certify this later candidate or superseded recipe/zero/two-press behavior.



## Remaining native checks



After the user's normal sync and reload, test each client sequentially: open

Restock, verify automatic search, price editing/icons; buy one cheap quantity

with one mouse press, then another with a distinct press. Check changed quotes/

caps, pending/mailbox arrival/collection, craft toggle on/off, a known equal/cheaper recipe, Direct/Craftable routes and default/allowed excess

stacks. Verify plain partial potion searches find prefixed stronger usable tiers,

update both shared tiers, fill the stronger target and preserve caps. Compare

limited/unlimited merchant sightings, all-listed scans and Auctionator price history. Compare tab alignment with the supplied

screenshot and with Auctionator enabled/disabled.



No Witchcraft/UIForever tools are available. Native transactions/quote permission,

addon coexistence, persistence/reload, localized layout, pixels, taint and CPU/FPS

are NOT RUN for this candidate. Earlier Forever failure remains unresolved until

a successful native retest. English fallback is complete; translations pending.



Controller plan: native cursor reaches tabs/cells, primary/secondary actions,

bank toggle, page buttons, three inputs, craft/excess toggles, refresh and buy. Native

page buttons cover the full item grid. Native highlights and cell selection

show focus. Tab cycles currency fields; Escape restores text or uses the auction

window's close behavior. No bindings/CVars/input mode changed. First acquisition,

Back handoff, text editing and directional navigation need native tests; cursor

reachability alone does not prove directional integration.
