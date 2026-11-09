# Party and raid frames

8 November combat numeric-color capability audit
(COMBAT-NUMERIC-TINT-CAPABILITY-20261108; REQ-RF-96): user again requests actual
HP/resource values and percent to match the native border during combat on
player/target/focus/party. Latest branch heads re-resolved for all five clients;
Retail12.1.5.70783 and Forever1.60.1.70862 retain texture-only private dispel-color
sinks. SetDispelTypeText replaces values with a symbol/static label; it does not
color arbitrary live numeric text. Descendant/object-type/access restrictions
prevent registering external numeric fonts or reading private texture colors.
106pinned callback/validator probe checks plus13230existing lifecycle checks pass;
this does not implement the requested restricted-combat text change. Unrestricted
combat coloring remains available; native private border coloring remains. No
runtime changes, new polling/caches, game input or profiler/settings writes.
Exact all-client restricted numeric coloring remains unavailable through verified
exposed APIs and must not be marked complete. [Evidence](COMBAT_NUMERIC_TINT.md).

8 November group roster performance (GROUP-ROSTER-PERFORMANCE-20261108;
REQ-RF-95): ordinary invites now reconcile prepared membership without hiding/
reconfiguring all headers or reapplying party/extra layouts. Retry incomplete party/optional-driver setup; keep full startup,
settings and readiness recovery, with combat visibility owned by native drivers.
Reuse the raid paint batch; combine party/pet show+roster paints, cast resampling
and range wake; coalesce optional pet/target paints and hover discovery. Roster
changes skip stable binding-data rebuilds; Edit Mode, settings/routing changes and
deferred combat registration still refresh. Aura checkbox/type/unit isolation stays.
Five matched pairs on five client models have invariant counts:213direct header
attribute writes->0;60hover discovery passes->1;920extra rebinds->0;5520extra protected
writes->0;800raid paints->40;168normal-party/pet paints->8. These are20-event replay
counts, not native FPS or latency measurements.163focused checks and twelve harmful
controls pass/reject; benign redundant-guard removal stays safe via inner guards.
Fresh35pinned upstream blobs verify; native source replays pass255908secure and58
member-order checks in desktop models. Full257/257scripts and922Lua syntax pass;
owned hashes and five installed copies match. New paints use bounded coalesced
After queues; no new ticker/event frame/OnUpdate. Source/history98files and47settings
metadata retained outside AddOns; no game input/profiler/settings writes/publication.
Actual client invite latency, rendering, protected VM/taint and performance pending.
[Evidence](GROUP_ROSTER_PERFORMANCE.md).

8 November friendly aura checkbox policy (FRIENDLY-AURA-POLICY-20261108;
REQ-RF-94): supersedes only RF93's unconditional dispellable-only rule. Checkbox
off now allows known typed harmful debuffs; on restricts to HARMFUL|RAID. Keep RF93
per-unit ownership, event routing and same-token target/focus refresh. Explicit
frame/Flux checkbox false wins over unrelated native CVars; use the relevant
Blizzard preference only without a Flux override. No combined global OR state.
One native owner per chrome part switches its public slot filter in place;
includeDispelTypes skips unknown candidates. Public/legacy bounded scans skip
unknown types too, so an untyped first entry cannot mask a later known one.
Portrait backdrop/fills and saved values remain unchanged. Native private border
colors/public-only numeric tint remain; real game pixels/taint/performance pending.
13270 focused checks pass across five clients/two providers, including both toggle
directions, conflicting settings, known-after-unknown and independent live-unit
palettes. Baseline plus eight controls rejected; five matched correctness pairs
retained. Full256/256scripts and921Lua syntax pass; owned hashes match tested source.
External source/history plus47settings metadata retained; all five installed
copies match via user sync. No game input/settings/profiler writes or publication.
[Evidence](validation/friendly-aura-policy-2026-11-08.json).

8 November friendly dispel isolation (FRIENDLY-DISPEL-ISOLATION-20261108;
REQ-RF-93): supersedes RF92's ordinary-debuff tint fallback. A known type alone
cannot trigger frame color: live chrome/numbers now use only HARMFUL|RAID, the
client player-dispellable filter, even when other debuff icons are visible. Unknown
or non-dispellable effects leave normal colors. Native SetUnit skips unchanged
unit tokens and has no target/focus identity event: explicitly refresh the public
owner on target/focus swaps, roster/world/show/options invalidation. UNIT events
only queue the matching unit or a verified alias; no shared color/strict state.
Regression now gives player, target, focus and party different simultaneous aura
data; covers alias swaps without UNIT_AURA, target=self, hostile/roster changes and
combat no-allocation. 9686 focused checks pass across five clients/two providers;
exact native SetUnit replay, baseline plus six rejected controls and five matched
correctness pairs retained. Full255/255scripts and920Lua syntax pass. Up to three
native owners/frame replace six; addon driver/timers unchanged. Native private
border colors/public-only numeric tint remain as documented; actual game pixels,
secret data, protected VM/taint and CPU/memory/FPS still pending. External verified
source/history plus47settings metadata retained; owned source hashes and all five
installed copies match. No game input/settings/profiler writes or publication.
[Evidence](validation/friendly-dispel-isolation-2026-11-08.json).

8 November friendly debuff chrome (FRIENDLY-DEBUFF-TINT-20261108; REQ-RF-92):
known debuff types tint portrait and HP/resource border overlays plus numeric
value/percent text on friendly player, player-style party and friendly target/focus.
Portrait backdrop and HP/resource fills remain unchanged. Missing/unknown types
keep normal colors. Prefer dispellable types; honor Blizzard showDispelDebuffs and
raidFramesDisplayOnlyDispellableDebuffs plus the party strict option; refresh on
CVAR_UPDATE. Restore on hide, hostile transition, option disable or removal.
Native descendant Texture slots handle private border colors on Retail/Forever;
existing HP/resource FontStrings have no native private dispel-color binding, so
text uses readable known types and restores normal color while restricted. Classic
uses its client display table and guarded public aura data. No private-child reads,
new settings or protected combat construction. Preview uses the same public color
path. 8632 focused checks across five client models/current and legacy providers,
six rejected controls, 255/255 scripts and 920 Lua syntax files pass. Owned hashes
match tested source; all five installed copies match through user sync. One event
driver/coalesced batch; up to six native slot owners per eligible frame; their
native update cost is not measured. Real pixels, secret data, protected VM/taint
and performance acceptance remain pending. External source/history and 47 read-only
settings metadata entries retained; no game input, manual sync or publication.
[Evidence](validation/friendly-debuff-tint-2026-11-08.json).

8 November native combat unit menus (UNIT-COMBAT-MENUS-20261108; REQ-RF-91):
unit-frame hit rectangles now use Blizzard's secure menu action and direct
native callback, including party/pet/vertical targets, raid and MT mini cells.
Target/focus retain their specific native menu; generic slots follow their
current secure unit attribute through combat group changes. Prepare attributes
OOC; defer optional menu edits through the existing queue. Keep native click-
cast and explicit Flux hover-program precedence. No addon popup dispatcher,
new event/frame/polling or saved-data change. Ten source blobs fetched across
Retail, Forever, progression, Era and Anniversary; exact pinned native replay
passes 680 checks and rejects three controls. Existing 1010 party, 182 raid
binding and 310 party hover checks pass; 252/252 scripts and 916 Lua syntax files pass.
Owned final hashes and five installed copies match. Actual hardware/protected
VM/taint/native menu input remains pending. Dated source/history and 45 read-only
settings metadata entries retained. [Evidence](validation/unit-combat-menus-2026-11-08.json).

8 November Blizzard party debuff borders (PARTY-BLIZZARD-DEBUFF-BORDER-20261108; REQ-RF-90):
latest user clarification replaces the custom red/black rim in REQ-RF-89 with
Blizzard's own type border. Retail/Forever use native colored border atlases;
Classic preserves and tints UI-Debuff-Overlays through client AuraUtil. Native
owners handle restricted types, including the default untyped harmful border.
Readable icons and preview use the same client helpers; type colors remain
independent of the whole-frame dispel-highlight toggle. Layout/opacity/timers/
strict filters/input remain. One border texture replaces the custom edges.
12776 aura, 1010 party, 2944 layout and 1580 native-style routing checks pass;
250/250 scripts and 914 Lua syntax files pass. Final owned hashes and five installed copies
match. Native appearance/taint/performance remain pending. Source/history and
45 read-only settings metadata entries retained. [Evidence](validation/party-blizzard-debuff-borders-2026-11-08.json).

8 November party debuff borders (PARTY-DEBUFF-BORDER-20261108; REQ-RF-89):
normal party debuffs now have a solid dark-backed rim on their existing text
host above the cooldown swipe, including plain/non-dispellable categories.
Native dispel colors remain native-owned; readable and preview edges share
styling. Preserve icon sizes, zero gaps, opacity, timers, filters and input.
12776 aura, 1010 party and 3310 external style/ownership checks pass; full
249/249 scripts and 913 Lua syntax files pass. Final source hashes match the
suite and all five installed copies. Native contrast/pixels/taint/performance
remain pending. Eight textures per prepared party debuff; no new frame,
event, polling or timer. Dated source/history checkpoint and 45 read-only
settings metadata entries retained. [Evidence](validation/party-debuff-borders-2026-11-08.json).

7 November name/ToT fitting replays final public text/font after refresh, measures unclipped width and sends restricted current names/surnames to native text sinks. Party cast state resets on hide/roster rebind and refreshes on show; routed stops with missing identity complete. 681 name/215 cast/1010 integration checks; full 249/913 pass. Native appearance/taint pending. [Evidence](validation/unit-name-party-cast-2026-11-07.json).

7 November vertical target strips share the HP/status/class-color and health-loss path across party, compact focus and pet targets. The red trail uses height, resets on identity/layout lifecycle changes, and uses native sinks for restricted values. 1243 targeted checks and full 236/900 pass; native visuals/taint/performance pending. [Evidence](validation/vertical-target-health-2026-11-07.json).

<!-- STRESS-FIXES-20261107 -->
7 November applied stress fixes: Raid paint driver arms once per outstanding merged batch and preserves next-frame category paints; nested events and rebind/hide lifecycle remain covered by focused fixtures. [Evidence](../Stress%20test%20doc/applied-fixes/README.md). Native taint/pixels/performance acceptance remains pending.
<!-- /STRESS-FIXES-20261107 -->

The current healer-frame rewrite follows the installed HealKit0.65.0 behavior
with Flux's existing outer dimensions, chat dock, reverse group columns, saved
profiles, commands and Flux Binding programs. The user's later design changes
require connected HealKit-style bronze borders, four-pixel vertical overlap, zero horizontal
gap, smaller names, role beside percentage, a shorter power bar and two3×2 aura
blocks. See [requirements and evidence](RAID_HEALKIT_REWORK.md).

## Ownership and layout

[FluxRaidFrame.xml](../RaidFrame/FluxRaidFrame.xml) declares Flux-owned secure
unit templates, mini/pet variants, aura display sinks and the protected grid
container. [Compat](../RaidFrame/FluxRaidCompat.lua) retains reverse-column math
and display-safe health/power/range helpers; [Layout](../RaidFrame/FluxRaidLayout.lua)
owns chat docking, native-grid handoff and deferred configuration.

[Secure](../RaidFrame/FluxRaidSecure.lua) prepares every roster mode and80 group/
MT children out of combat, including solo startup. Native secure callbacks follow
joins, departures, party/raid transitions and subgroup moves, pack active columns
in Flux's reverse order, and keep MT target attributes current. Shared target-
existence conditions hide actual protected target rectangles, rather than merely
making them transparent. Disabling ownership releases those conditions. An
incomplete secure setup retains native fallback and retires partial controllers.

## Appearance and healer feedback

[Visuals](../RaidFrame/FluxRaidVisuals.lua) owns plain content, aura, text, shared
border, focus and indicator layers. Each cell owns its top/left separator; the
outermost visible cells close the bottom/right edges. [Unit](../RaidFrame/FluxRaidUnit.lua)
refreshes neighbor ownership and exterior corner flags on roster/visibility changes without protected
geometry writes. Smaller names use their own line; the12px role icon precedes
the percentage. Leadership, master-loot and raid marks use a separate raised
layer; resurrection/summon and ready checks retain center status.

[Prediction](../RaidFrame/FluxRaidPrediction.lua) uses owned native calculators
for incoming healing, absorbs, heal absorbs and four overheal tiers. Restricted
results go directly to native display sinks. Readable fallbacks clamp ordinary
values. Active-cast power cost is optional feedback on supported public data.

[Auras](../RaidFrame/FluxRaidAuras.lua) displays at most six buffs in a right-side
3-column/2-row block and six debuffs in a left-side3×2 block. Rectangular icons
fit existing cell dimensions. Compact duration text and cooldown swipes remain
visible. Retail/Forever native aura containers classify restricted data and own
their handlers; readable clients use fixed Flux icon pools. Settings never
inspect or resize forbidden native children. Native pool batches can exceed the
twelve visible icons; visible capacity is not an allocation count.

The aura follow-up replaces the earlier HealKit-specific duration limits and
shield exclusions with Blizzard's raid-frame classification and ordering.
Boss debuffs, boss/role buffs displayed as debuffs, priority effects, raid
dispels and ordinary debuffs share Blizzard's priority order. Normal buffs use
Blizzard's spell/spec visibility rules; present class buffs remain an optional
out-of-combat supplement after normal raid buffs. Public hidden group-buff
preferences apply to normal raid buffs immediately, including combat changes,
without layout work. The explicitly enabled out-of-combat class-buff supplement
overrides those hidden preferences so current class buffs can still appear.

The full aura layer now sits above names, borders and highlights. Counts and
duration text have a separate display host above the cooldown swipe. Leadership,
loot, marks, resurrection and ready checks retain higher layers. Preview follows
the same order, and configured aura transparency remains unchanged.

The duration follow-up uses a full-icon reverse swipe with intrinsic black
opacity0.75, replacing the earlier0.3. Centered9px white outlined text with a
black shadow stays above the swipe; stack counts remain7px at the top right.
Native duration sinks use one owned compact, single-unit formatter when
available, without querying restricted remaining time. Readable countdown text
is prepared on the same raised host and explicitly clears/hides when a timed
slot becomes permanent. Permanent effects have no invented countdown. Existing
transparency still applies to icon, text and swipe together.
[Duration evidence](validation/raid-aura-duration-2026-11-06.json).

The user rejected that duration display: the9px label produced ellipsis and
short effects had no swipe. The correction prefers7px and measures public
sample labels on a separate unanchored FontString to choose a6px fallback,
without measuring bound native text. A native numeric rule formatter emits
plain seconds then m/h/d. The cooldown is explicitly shown before native sink
registration because its template starts hidden, and uses an opaque white
base texture with the existing swipe color. The own-widget diagnostic tests
literal times without querying aura widgets. Actual C-widget/display acceptance
is tracked separately from source/style checks in the
[correction record](validation/raid-aura-clock-fix-2026-11-06.json).

The subsequent user probe measured `59` at15.2 units inside a12-unit field.
The fixed6px lower bound was therefore removed. Timer labels retain a base
font and apply proportional `SetTextScale` from the public sample probe's
maximum width/height, with5% fitting margin. Scale is cached per font and icon
bounds and can grow above1 for larger icons. Native, readable and preview text
use the same calculation; no actual restricted text is measured. The supplied
owned-clock probe also demonstrated automatic positive/zero visibility, so it
does not support the earlier hidden-template explanation for missing swipes.
Actual aura rendering remains separate from that controlled probe.
[Text scaling evidence](validation/raid-aura-text-scale-2026-11-06.json).

On Retail/Forever the public custom-container policy cannot inspect the native
private `hideOnPartyFrames` flag. Readable clients honor it directly. Native
private anchors expose that exclusion but cannot retain this rectangular icon
layout and the configured duration presentation; exact private exclusion parity
is therefore pending/limited rather than claimed. Native group owners also
reject `ProcessAura.None` before class-ID filtering: the OOC supplement overrides
hidden-group IDs, not every native self-only/custom-hidden classification. The
desktop classifier/candidate test omits that owner gate; complete native
assignment remains a recorded test gap. The class-family ID table is bounded,
including incomplete higher-rank Mage armor coverage. See the
[follow-up evidence](validation/raid-blizzard-aura-followup-2026-11-06.json).

The strict **Only dispellable debuffs** preference applies to all six debuff
slots, without boss/priority/own-debuff exceptions. **Class buffs out of combat**
shows buffs currently present, including long class buffs, and defaults on.
Missing-buff reminders are separately optional and default off.

## Options, casting and lifecycle

The raid/party settings retain independent account/character scope. **Aura
transparency** ranges0–100%, initially70%; it covers icons, duration text and
swipes. An unset new preference preserves the scaled legacy opacity. Frame and
range opacity remain separate. Power-bar base height is multiplied by0.8 while
retaining the saved scale (default6px rounds to5px).

[Extras](../RaidFrame/FluxRaidHealerExtras.lua) supplies opt-in pets, friendly
target and missing-buff helpers. [Forever HoT estimates](../RaidFrame/FluxRaidHoTs.lua)
are off by default and explicitly limited to readable supported English spell
descriptions and own successful casts; they are estimates, not native facts.

All real cells register with Flux Binding and optional ClickCastFrames. Explicit
left/right mouse programs preserve Flux profiles, spells and conditions; plain
unassigned clicks keep native target/menu behavior. Keyboard, wheel and modified
mouse hover routes clear on leave/hide. Native aura subtrees are excluded from
mouse inspection and wrapping. Previews never register for casting.

Unit-event bursts coalesce on the next rendered frame. Hidden/unbound cells
release subscriptions and feedback. Current five source targets support native
range events; a bounded fallback ticker exists only for a visible cell whose
range-event registration fails. No permanent repaint sweep is added.

## Preview and verification

[Preview](../RaidFrame/FluxRaidPreview.lua), `/fluxui raidpreview`, remains
session-only and shares the live chrome. It covers injury, healing, absorbs,
dispels, status and range samples while retaining existing outer sizes and
reverse positioning. Synthetic cells establish neither protected input nor
native visual parity.

The current source pins and focused/full desktop results are in the
[rewrite record](RAID_HEALKIT_REWORK.md). User screenshots rejected earlier
appearance stages and supplied a real secret-mouse error; those are failures,
not acceptance for the latest source. Final native checks must cover all five
clients, combat joins/leaves/subgroup moves, live Flux casts, raid manager,
native ghost suppression/restoration, aura filtering/durations, connected pixels
and taint. FPS and frame-time acceptance require fresh matched native captures.

The current border uses the original Blizzard bronze artwork referenced by
HealKit, cropped to its opaque gold bands with normal blending. Rounded native
arcs are confined to outer grid corners, with a single textured separator inside
the grid. An owned bronze fallback is retained for unavailable native art.
Members within each column use Blizzard INDEX/ASC order. The smaller manager
retains native X and one full-panel Y above the active or prepared grid in both
collapsed and expanded states. Final native appearance remains unverified.

## Aura sizing and live limits — 7 November

7 November aura size/count correction: user chose to keep icons inside and
cap their size. Canonical10x15 native creation removes startup-dependent sizing;
live/readable/preview share uniform fitted geometry. User's later x1.30 request
uses the confirmed30%-taller choice:1.00 requests14.3px height vs old11px;
minimum0.50 permits shrinking; inside-fit cap remains. Duration fonts fit the
actual icon rectangle, including m/h/d suffixes at partial clip edges.
New scoped maxBuffs and
maxDebuffs1–6 default6; demo counts remain separate. Strict mode retains only
HARMFUL|RAID on every original/tail owner. Exact4/5 across mixed categories uses
lazy clipped native row copies; no native child inspection or handler replacement.
Default native icon pools stay120/cell; both partial sides can add120 once, reused
and unbound while inactive. No new addon recurring work. 200 scripts/862 syntax PASS,
unchanged Lua corpus; five alternating regression pairs per aura/layout/preview
reject15 baseline runs and pass15 candidate runs. Native pixels, logical-visible
clip scheduling, combat/taint/casts and FPS remain pending on all5 clients.
Preserve unrelated work and profiler preferences; no commit/push or game input.
[Size/count record](validation/raid-aura-limits-2026-11-07.json).

Raid/Party Frame settings now provide independent maximum buffs and maximum
debuffs1–6, initially6. The existing demo count controls remain preview-only and
cannot exceed these live capacities. Icon scale changes both dimensions uniformly
and stops at the room available inside the unchanged cell. Selecting fewer slots
can permit larger icons. Display only dispellable debuffs remains strict for the
whole visible left block, including partial rows. Size/count changes made during
combat use the existing deferred refresh when combat ends.

## Responsive aura scale and taller cells

7 November live aura slider follow-up: user rejected the previous slider
display and clarified that the main frames must be30% taller too. A user-owned
probe at1.45 showed capped12.1px icons; forcing0.50 through the actual scoped
refresh returned public scale0.4767 and the user confirmed normal icons shrank.
That proves prior native scale propagation. New UI exposes the responsive fitted
range with0.01 steps/current dimensions, preserves stored requests until selection,
and refreshes cached bounds without synthetic saved writes. Main heights now
multiply saved scale by1.3 (default43->56; saved1.0:36->47); width remains.
Canonical normal icons10x19.5 fit that height; duration fit and strict1–6 limits
remain. Mini targets stay within their18px reservation. 203 scripts/865 Lua syntax PASS,
with all runtime/aura/renderer sources stable during both complete runs;
20 matched baseline runs rejected/20 candidate runs pass. An unrelated teleport
test changed during both runs, and its runtime owner changed that subsystem
afterward. Both raw manifests remain; the global corpus is not called frozen.
All five delivered feature files match the tested manifest; unrelated work stays.
Final new UI/height/native combat/taint/pixels/FPS acceptance is pending all5.
No agent game input, WTF writes, profiler change, commit or push. The user probe
set aura scale0.50; choose the desired new value after reload.
[Live slider record](validation/raid-aura-slider-live-2026-11-07.json).

## Blizzard baseline and size reset

7 November final native-size contract: user chose all Blizzard default sizes,
then explicitly required no toggle and1.00 as every size slider's native baseline.
Frame/power/aura/manager scales now use source defaults without the earlier1.3,
power0.8 or manager0.85/MT0.9 multipliers. Reset sizes changes only five size keys;
full defaults also1. Existing stored requests remain until reset. Fonts, normal11
and boss/role16.5 squares, insets/bars/indicators follow pinned native equations;
one-pixel joins and half-height minis preserve the native body. Counts/strict
RAID filters/class buffs/Flux casts/visible fitted timers and bronze theme remain.
The screenshot's oversized Offline/health label reproduced cumulative FontString
scaling; absolute Font-object baselines now pass50-refresh/locale regressions.
User reloaded, used Reset sizes and confirmed: Yes, sizing and fonts look right.
206 scripts/868 Lua syntax PASS with unchanged corpus;20 baseline/20candidate pairs and
five font-specific pairs reject the old failures. All five client folders match;
36 other-copy file hashes verified with no duplicate overwrite. Native acceptance
is limited to the selected test client; other-client/combat/taint/FPS checks remain.
Latest Forever source is5987a8e (70840); other four pins unchanged. Preserve all
unrelated main work and preferences; no agent game input/commit/push/WTF writes.
[Native-size record](validation/raid-blizzard-default-sizing-2026-11-07.json).

## 7 November: independent aura enlargement

7 November aura-only scaling: user explicitly chose to resize only auras,
keeping frame size fixed and permitting larger blocks outside the frame.
Removed the hidden inside-fit cap from actual geometry and the slider;
0.50..2.50 now applies directly, with Blizzard 11px/16.5px at 1.00.
Counts, filters, opacity, swipes, fitted fonts and combat deferral remain.
206 scripts/868 Lua syntax PASS with unchanged sources;
five fresh alternating baseline/candidate pairs reject the old cap. Eight
other-client files already match; no duplicate copy performed. No recurring
resources added. New native visual/combat checks remain pending.

[Evidence](validation/raid-aura-independent-scale-2026-11-07.json).

## 7 November: aura width and duration text controls

7 November aura width/font controls (REQ-RF-33): added Aura width (X) and
Aura duration text size, both 0.50..2.50 with default/reset 1.00 in both
scopes. Preview updates immediately. Live native glyph/text dimensions are
prepared only by their one-time initializer, so these controls explicitly
require /reload; ordinary refresh retains the loaded native width. Normal
and large glyph widths/slots scale together, height stays unchanged, and
duration font size multiplies the fitted text size. Existing overall size,
filters, counts, opacity, swipes and combat deferral remain.
206 scripts/868 syntax checks PASS with unchanged sources;
five alternating baseline/candidate pairs reject missing X scaling. All20
other-client files already match; no duplicate copy performed. No new
pools/events/tickers/timers. Native visuals/combat/CPU/FPS remain pending.

[Evidence](validation/raid-aura-width-font-2026-11-07.json).

## 7 November: shared preview/live rendering

7 November preview/live parity (REQ-RF-34): user reported differences in
both frames and auras. Live and preview now inherit one visual XML template
with separate secure/plain behavior. Shared owned-health aura bounds and
canonical duration-font projection remove independent sizing rules; preview
side hosts clip like live rows. All health-text modes use one formatter;
offline colors, center host/layer/size, overflow atlas/geometry and prediction
sample colors/order now match live. Readable large aura X scale is corrected.
Positions, joins, ordering, bindings, saved scopes, filters/counts/opacity and
swipes remain. X/font native changes still require the documented reload.
206 scripts/868 syntax checks PASS; unchanged final Lua corpus.
Five fresh alternating pairs reject the old preview. All20 other-client
files already match; no duplicate copy. Two public clip hosts per preview,
no new addon event/ticker/timer. User reloaded and confirmed: Looks consistent
now. Acceptance is selected-client visual/function only; other-client native
combat/taint/FPS checks remain pending.

[Evidence](validation/raid-preview-parity-2026-11-07.json).

## 7 November: live timer font and threshold policy

7 November live timer/grid/policy (REQ-RF-35..37): timer-font slider now
updates a shared public Font inherited by already registered native labels,
instead of a size captured at reload. Combat changes defer; X width still
requires reload. Buffs remain right and debuffs left, up to three columns
and two rows with zero icon/row gaps. User reloaded and confirmed: Both work.
Added black OUTLINE plus black shadow, and an optional Show aura timers only
below 1 minute toggle (default off in both scopes). One shared numeric
formatter blanks60seconds and above, retaining icons/swipes/stacks without
reading restricted durations. Native bindings and preview/readable clocks
share that formatter. User also confirmed shadow/threshold behavior: Yes, all work.
206 scripts/868 syntax PASS with unchanged final corpus;
ten alternating pairs reject the earlier grid/options behavior. All20
other-client files match; no duplicate copy. One shared Font/formatter,
no new native aura family or addon event/ticker/timer. Other-client native
combat/taint/FPS checks remain pending.

[Evidence](validation/raid-timer-policy-2026-11-07.json).

## 7 November: guarded live aura width

7 November final live aura width (REQ-RF-38): native width now follows the
slider through scoped refresh. Stored initializer metadata supplies sizes;
out-of-combat styling first checks canaccesstable for all native buttons and
labels. No native size/unit/visibility is read. If native access is denied,
keep the existing icons and geometry and mark pendingWidth for later safe
refresh. Public group layout updates the flow widths. Native source uses
DenyTaintedAccessWhenAurasAreSecret, correcting the earlier blanket assumption
that every styling change needs reload. The external display-sibling attempt
failed native visibility and was rolled back; rejected source/logs remain
external. The guarded replacement was accepted: Live icons resize correctly.
User also accepted preview parity, live timer font, zero-gap side grids,
black outline/shadow and below-one-minute timer policy in earlier checks.
206 scripts/868 syntax PASS, unchanged final corpus; five
fresh alternating pairs reject the old preview-only width callback. Eight
other-client runtime files match; no duplicate copy. Metadata only, no new
frame/pool/event/ticker/timer. Native acceptance is selected-client visual
behavior; other-client/combat/taint/FPS checks remain pending.

[Evidence](validation/raid-live-width-guarded-2026-11-07.json).

## 7 November: compact manager and native overlay suppression

7 November manager/hidden native highlights (REQ-RF-39/40): manager1.00
now uses a70percent native baseline, as explicitly requested; saved values
and physical vertical alignment/native X/collapse behavior remain. Hidden
selection/ready-check layers now inherit ancestor opacity, including when
their own alpha is opaque. Original flags/known alphas restore on disable.
Two secure post-hooks catch late native setup/selection updates, including
anonymous pooled children. Unprotected alpha/inheritance changes suppress
late combat highlights; structural changes still defer. Native events,
scripts, parents, visibility, profiles and restricted aura subtrees remain.
206 scripts/868 syntax PASS with unchanged final corpus;
ten fresh alternating pairs reject the previous size/ghost behavior. Twelve
other-client files already match. No new pool/frame/ticker/event or polling.
Five fresh pinned API sources verify the display methods are unprotected.
User reloaded and confirmed: Both fixed. Native acceptance is selected-client
visual/function only; broader native combat/taint/FPS checks remain pending.

[Evidence](validation/raid-manager-overlay-2026-11-07.json).

## 7 November: HP-only MT target strips

7 November MT target HP strip (REQ-RF-41): target minis now show only the
target name left and plain HP percent right on one centered row, with no
resource bar and the full strip available to HP. Target percent is separate
from the main member health-text preference and contains no role prefix.
Power events cannot re-enable the target resource bar or query its power.
Pets/full members retain their policies; secure target routing/casts and
reserved mini height remain. The MT preview now includes a pooled target
strip using the same chrome; reused roster samples retire old target strips.
Preview minis skip aura construction. User reloaded: Yes, looks right.
208 scripts/870 syntax PASS with unchanged final corpus;
ten fresh alternating unit/chrome pairs reject the old behavior. Sixteen
other-client files already match. No new event/ticker/timer; at most one
reusable plain target preview per displayed MT owner. Source/history/settings
checkpoint verified with these four runtime owners unchanged despite other
workspace edits during collection. Manager/highlight fixes remain accepted.
Native acceptance is selected-client visual/function; broader combat/taint/
other-client/FPS checks remain pending.

[Evidence](validation/raid-mt-target-2026-11-07.json).

## 7 November: MT target opacity

7 November MT target opacity (REQ-RF-42): in-range target minis now use
the configured base opacity directly, without the extra member in-range
dimming factor. Unavailable or opaque checkedRange also keeps base opacity
instead of treating an enemy target as far away. A genuinely checked far
result still uses configured out-of-range alpha. Secret checks precede every
checkedRange comparison. Normal member/pet fading and user base transparency
remain. Preview target strip uses the same base opacity. No new range call,
frame/pool/event/ticker/timer. User reloaded: Yes, opacity looks right.
208 scripts/870 syntax PASS, unchanged final corpus; five
fresh alternating pairs reject the previous in-range mini fade. Eight other
client files already match. Earlier manager/highlight and HP-only target
checks remain accepted. Native acceptance is selected-client visual/function
only; broader native combat/taint/other-client/FPS checks remain pending.

[Evidence](validation/raid-mt-opacity-2026-11-07.json).

## 7 November: screenshot sizing defaults

7 November screenshot default preset (REQ-RF-43): user chose member width
0.70, height0.95, power1.00, aura scale1.82, aura X0.50, timer font1.72,
manager1.20 and enabled under-one-minute timers as the default. Both saved
scopes now use these values. Reset sizes copies these eight fields from the
default table, preserving counts/filters/opacity/positions and unrelated data.
Full raid reset uses the same preset; existing explicit custom values are
not migrated. Scale units/rendering remain unchanged, including manager
1.00=70percent native; new default1.20 is effective0.84. Screenshot preserved
externally with hash. Actual scoped reset/refresh checks verify69x42 cells
and10.01x20.02 normal aura geometry; combat changes still defer.
209 scripts/871 syntax PASS with unchanged corpus; five
fresh alternating pairs reject the old all-one default/reset behavior. Eight
other-client files already match; no duplicate copy. No new resource owners
or recurring driver. Separate new native reset check not performed; prior
native renderer acceptances retain their original scope.

[Evidence](validation/raid-screenshot-defaults-2026-11-07.json).

## Party display mode and column-first auras — 7 November 2026

Party / Raid now includes Show party as raid frames (default on), member scale,
portraits, cast bars, pets, pet scale and Preview party. Turning the first option
off uses the existing player/pet visual factories for four other party members
and their pets. The final member retains the current compact party bottom-right
location; existing compact and raid positions do not move. Mode/scale edits defer
in combat, while prepared existence drivers handle roster and pet transitions.
Buffs and debuffs now fill two rows per column, mirrored right/left, with zero
spacing and uniform configured glyph/slot dimensions. Existing one-to-six counts,
strict dispellable filtering, cooldown/timer, X scale and alpha remain supported.
See [requirements](RAID_HEALKIT_REWORK.md) REQ-RF-44 through REQ-RF-50 and
[evidence](validation/raid-party-mode-2026-11-07.json). Native visual/combat/input/
taint/FPS acceptance remains pending.

Alternate party members have zero vertical layout spacing. Their actual outer
buttons reuse Flux owned party/raid primary/modifier click programs and secure
hover enter/leave/hide cleanup, including keyboard and wheel routes. New focused
checks:535 party mode and210 binding checks on five modeled clients. Full final
suite:213 scripts/876 Lua syntax files PASS; tested corpus unchanged. Native
input, appearance, combat and taint acceptance remain pending.

## Normal party follow-up — 7 November 2026

PARTY-NATIVE-FOLLOWUP-20261107. Normal party mode uses four fixed native unit
slots; their combined height stays inside the current raid column and the full
fourth-slot corner remains unchanged. Show party as raid frames keeps compact
mode available. Player-style settings include member width/height/scale, portraits,
cast bars, class border/backdrop, pets, wider HP-only targets, party aura size,
text size and resource height. Class-colored party target HP is a separate option;
Unit Frames contains equivalent pet-target and focus-target HP toggles.

Default pet is HP-only60x28 with percentage and no name/portrait/resource.
With pet, HP values sit in a top band and both bar texts avoid its width;
without pet, HP text centers. Resource height defaults80 percent, HP text to
values and resource to percentage, with independent values/percent/both/hidden
choices. Value/percentage text is larger; name/level and raised metadata have
separate room. Auras have an extra default1.50 party factor, harmful auras at
portrait top-right, helpful auras right of HP, packed columns and existing rules.

Dead/ghost/AFK/offline HP/resource fills desaturate and gray, then recover.
Range opacity uses the existing raid service and includes all portrait layers
and detached chrome. Threat changes only a transparent outer-border overlay,
using native colors/rules. All UFs use engine SetPortraitTexture for unavailable
3D models; pending model loading can restore3D. Secret alpha is never compared.

User confirms preview works and normal party frames appear. Final217 scripts/880 syntax PASS at the tested snapshot; party runtime
owners remain unchanged. Later unrelated utility/test edits cause global drift.
Final visual/input/combat/secret/taint/FPS acceptance still pending
per client. [Requirements](RAID_HEALKIT_REWORK.md#native-party-follow-up--7-november-2026)
and [evidence](validation/party-native-followup-2026-11-07.json).

## Compact party indicators — 7 November 2026

7 November compact normal-party indicators (PARTY-INDICATORS-20261107, REQ-RF-63..67):
restored class icon; class/spec/PVP/role/raid marker have dedicated portrait corners,
leader/assistant/MT/MA/master loot use a compact header grid, and level has its own
readable corner. Casts cover the header above both text and metadata, with the
existing Party member cast bars toggle; shared cast lifecycle retained. Pet text
hosts use symmetric left/right margins so percentage-only labels center on X.
Party reuses raid ready-check/center-status helpers for ready, resurrection,
incoming summon, leader/loot/raid markers, plus native role atlas. Ready finish
hides without a new timer. A dedicated divider restores the HP/resource seam
independently of the HUD fill's alpha. Party raid markers bypass the older shared
marker truth-test and use the existing secret-guarded raid helper.

800 party,78 restricted-contract,310 binding and59 indicator checks pass on the
existing source models. Whole run: 218/218 scripts pass; 881 Lua syntax files, 0 failures. No native visuals/combat/taint/FPS certification.
Four textures/member, no new frame/ticker/timer/secure condition. External dated
source/history/settings retained; no game input, settings/profiler write, manual
sync, branch or push. [Evidence](validation/party-indicators-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-63 | Restore and fit class/leader/loot/PVP/tank/level indicators | Implemented; desktop pass, final native pending |
| REQ-RF-64 | Center percentage-only party labels on X with pet present | Implemented; desktop pass, final native pending |
| REQ-RF-65 | Overlay party casts above header text and support on/off | Implemented; desktop pass, final native pending |
| REQ-RF-66 | Party ready check, raid mark, resurrection, summons and raid indicator parity | Implemented; desktop pass, final native pending |
| REQ-RF-67 | Visible HP/resource divider | Implemented; desktop pass, final native pending |

## Player layout for normal party — 7 November 2026

7 November player-layout parity for normal party (PARTY-PLAYER-LAYOUT-20261107; REQ-RF-68):
user supersedes the prior portrait-corner class/spec/raid marker layout and
header-overlay cast variant. Class/spec now retain the shared player factory's
anchors, size, borders and visibility; no forced class show or party reparenting.
Party casts use the unwrapped player cast layout including spell icon. The party
cast toggle remains. Player and party share UF.LayoutRaidMarker: center of HP,
90 percent of HP/text-anchor height; party retains secret-guarded marker updates.
Leader/assistant/MT/MA/loot move onto portrait so class/spec header slots are free.
Spec data availability follows the existing provider; no fabricated spec.

810 party and78 restricted checks pass; 218/218 scripts pass; 881 syntax files/0 failures.
No new frame/event/timer/ticker/condition. Four cast wrappers and OnShow hooks
removed. Native pixels/casting/combat/taint/FPS pending on each client. External
source/history/settings recovery retained; no game input/WTF/profiler write,
manual sync, branch or push. [Evidence](validation/party-player-layout-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-68 | Party class/spec, cast bar and raid marker use player placement/layout | Shared player factories and shared marker helper;810 party checks PASS; native visual comparison pending |

## Cast timer synchronization — 7 November 2026

7 November cast timer synchronization (CAST-TIMER-SYNC-20261107; REQ-RF-69):
party/focus/target text could prefer stale cached value/maxValue while the fill
used its StatusBar or engine DurationObject. Restricted duration also selected
a guessed wall clock for text. Shared countdown now reads the bound engine
remaining duration, or actual bar current/max values for readable/manual casts
and channels. This follows all five native CastingBarMixin timer formulas.
Opaque engine remaining duration forwards unchanged to the native formatted-text
sink; font widths are secret-guarded. Unavailable timing clears stale text rather
than estimating. Cast fill, geometry, lifecycle, options and0.05s paint cadence
stay unchanged; no new frame/event/hook/ticker/timer. Player and pet share the fix.

379 focused checks cover five source families, party1/party4/target/focus/player,
casts/channels/delays/replacement, stale caches, engine duration, restricted text
and font geometry. Full production start/update/delay events replay on each
family, including Retail/Forever engine-owned opaque countdowns. Five alternating
checkpoint/candidate pairs reject old code and pass current; three timer mutants
rejected.13942 existing cast theme checks PASS. 219/219 scripts PASS; 882 syntax files/0 failures.
Native rendering/secret sink/combat/taint/FPS remain pending per client; desktop
models do not certify them. Dated external source/history/settings recovery
retained. No game input, settings/profiler write, manual sync, branch or push.
[Evidence](validation/cast-timer-sync-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-69 | Party/focus/target cast timers match their bars across all five clients, including Retail/Forever | Shared widget/engine clock;379 checks,5 baseline-rejecting pairs,3 rejected mutants; native pending |

## Raid-target marker rendering — 7 November 2026

7 November raid-target marker rendering (RAID-MARKER-RENDER-20261107; REQ-RF-70):
raid/normal-party icons hid every secret GetRaidTargetIndex return. Raid textures
also lacked a base sprite sheet: native SetRaidTargetIconTexture sets coordinates,
not the image. Both are fixed. Retail/Forever opaque indices pass directly to
the AllowedWhenTainted native SetSpriteSheetCell sink; no private comparison or
UV arithmetic. Readable markers retain legacy fallback. Sheet is explicitly set;
nil/invalid/removal hides stale icons. Ordinary player/target/focus marker state
uses the same guarded approach instead of index truth tests. Existing player/party
HP-centered geometry, settings, textures and events stay; no new frame/driver.

2730 checks exercise all eight markers, replacement/removal, readable/restricted
indices, six unit tokens, native and legacy paths across five client models.
Five alternating checkpoint/candidate pairs reject the prior missing-sheet path
and pass current code. Existing428 raid runtime/810 party/59 indicator checks PASS.
220/220 scripts PASS; 883 syntax files/0 failures. No native pixels/combat/taint/FPS certification. External dated
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/raid-marker-render-2026-11-07.json).
Later unrelated source drift: Inventory/Restock/Bank/FluxBankRestockButton.lua, tests/bank_restock_icon.lua.

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-70 | Raid-target symbols render and update on party/raid/normal UFs | Sheet assigned and native secret sprite sink;2730 checks and5 baseline-rejecting pairs; native pending |

## Party cast coverage — 7 November 2026

7 November party cast name/level coverage (PARTY-CAST-COVER-20261107; REQ-RF-71):
latest user correction keeps player-style cast art/icon but requires it over the
party name and level. This supersedes RF68's unmodified cast placement. Shared
cast dimensions/lifecycle remain; shell now anchors across the prepared party
header at owner+110, above name+70 and metadata+80. Name/level alpha conceals
underlying glyphs during casts/holds and restores previous public alpha on hide
or disable. Metadata repaint cannot raise the level over the cast. Show/Hide
callbacks change text alpha only; existing OOC layout prepares geometry.

Party / Raid > Party frames > Show party cast bars retains partyShowCastBar and
combat deferral. Disabling hides an active cast immediately outside combat;
enabling refreshes the current cast through existing CB.RefreshCastForUnit.
840 party/310 binding/379 timer/2730 marker checks PASS; five fresh alternating
baseline/candidate harnesses reject the prior lower/unplaced cast shell and pass
current code. 220/220 scripts PASS; 883 syntax files/0 failures. Markers remain fixed by RF70. No new frame/event/
ticker/timer/secure condition; four layout wrappers and Show/Hide coverage hooks.
Native pixels/toggle/combat/taint/FPS pending per client; no performance claim.
External source/history/settings retained; no game input/WTF/profiler write,
manual sync, branch or push. [Evidence](validation/party-cast-cover-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-71 | Party cast covers name/level with on/off option | Raised shared art/icon; covered alpha/restore; active toggle refresh;840 party checks; native pending |

## Party divider edge — 7 November 2026

7 November party HP/resource divider edge (PARTY-DIVIDER-EDGE-20261107; REQ-RF-72):
user reports divider absent; prior RF67 desktop checks did not validate the HUD seam.
HUD health fills extend behind resource; its bottom is not the seam. The existing
party divider now anchors to Power top with+1 offset, matching the shared two-unit
gap midpoint. Height3, bronze color, opacity, raised layer, bar dimensions, frame
size and existing range/visibility ownership remain unchanged. No new resource
owner/event/hook/timer/ticker or refresh loop; native anchors track resource.

54 checks execute the real shared partition function and production divider
creation across HUD/legacy,35/85/150 height and0.5/0.8/1.5 resource scale. They
resolve divider coordinates against the actual shared separator, and assert no
bar resize. Five alternating checkpoint/candidate runs reject the old HUD edge
and pass current code;840 party checks PASS. 221/221 scripts PASS; 884 syntax files/0 failures. Native seam pixels,
combat/taint/FPS pending per client; no native performance claim. External dated
source/history/settings retained; no game input, WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-divider-edge-2026-11-07.json).
Later unrelated corpus drift: tests/bank_restock_icon.lua.

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-72 | Visible party HP/resource divider at actual seam | Power-top anchored;54 real-partition checks/5 pairs; native pixels pending |

## Party divider style — 7 November 2026

7 November party divider thickness/tint (PARTY-DIVIDER-STYLE-20261107; REQ-RF-73):
user confirms RF72 divider is visible and requests it slightly thicker with the
same color as the other borders. Height increases3 to4; resource-top anchors,
bar/frame dimensions and opacity stay. Divider and outer borders now use the
same appearance accent or party member class override through Party.PaintChrome.
Existing global appearance refresh repaints live and preview party chrome, so
changing accent/class choices cannot leave the divider at its old hardcoded tint.
No new frame/event/hook/timer/ticker/recurring driver; bounded appearance repaint.

Existing54 real-partition/840 party/59 indicator checks PASS; expectations updated
for height4. 222/222 scripts PASS; 885 syntax files/0 failures. This small visual change adds no new tests/benchmark
that mirror its implementation; no native performance claim. User acceptance is
prior divider presence only; new thickness/tint native visual/combat/taint/FPS
checks remain pending. External source/history/settings retained; no game input,
WTF/profiler write, manual sync, branch or push.
[Evidence](validation/party-divider-style-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-73 | Slightly thicker party divider matching frame border tint | Height4; common accent/class paint and appearance refresh; native style check pending |

## Target-style party separator — 7 November 2026

7 November target-style party separator (PARTY-TARGET-SEPARATOR-20261107; REQ-RF-74):
user screenshot rejects the flat party line; user selects the bottom-right target
as reference. Party now calls the exact target/player CreateSeparator factory via
UF.CreateBarSeparator: same battlefieldminimap-border-top atlas, or same legacy
texture/crop, and17 logical height including transparent artwork padding. Tint
uses SetVertexColor so recoloring cannot replace artwork with a solid fill. The
underlying shared health/power separator hides when the owned party divider exists
to avoid a doubled/shiny edge. Resource-top seam and existing bar-height controls
remain. Reference screenshot retained externally with hash; new native comparison
is pending. This supersedes RF73's solid four-unit divider appearance.

144 checks compare the actual party construction with the target constructor
across atlas/fallback, HUD/legacy and multiple heights/resource scales; verify
seam coordinates, no bar resizing and no duplicate separator. Five alternating
checkpoint/candidate pairs reject the former flat artwork and pass current code.
840 party checks PASS. 222/222 scripts PASS; 885 syntax files/0 failures. No new frame/event/hook/timer/ticker/driver;
no native CPU/FPS claim. Native pixels/combat/taint pending per client. External
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-target-separator-2026-11-07.json).
Later unrelated corpus drift: ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua.

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-74 | Party HP/resource separator matches selected target artwork | Shared exact separator constructor;144 art/geometry checks; native image comparison pending |

## Party aura portrait priority — 7 November 2026

7 November party auras over portrait indicators (PARTY-AURA-PORTRAIT-LAYER-20261107; REQ-RF-75):
normal party aura host was owner+60 below portrait indicators+80. It now uses+90
in the shared live/preview factory, above portrait icons and below cast header+110.
Native and readable rows, cooldowns and duration text inherit that host. Existing
positions/sizing, filters/limits, strict dispels, timer policy and opacity remain.
This changes draw order only; no new frame/event/hook/timer/ticker/recurring work.

865 party checks include live ordering above indicators/below casts and matching
preview ordering on five source models;12776 aura-renderer checks PASS. 228/229 scripts PASS; 893 syntax files/0 failures.
Native overlap/opacity, combat/taint/FPS checks pending per client; no native
performance claim or benchmark for this low-impact change. External dated
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-aura-portrait-layer-2026-11-07.json).
Later unrelated corpus drift: Respec/FluxRespec_Consumables.lua, Respec/FluxRespec_PresetBundle.lua, tests/hover_children_varargs.lua, tests/prediction_public_geometry.lua, UnitFrames/FluxUnitFrames_Shared.lua.

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-75 | Party buffs/debuffs draw over portrait icons | Host+90 over indicator+80, below cast+110; live/preview865 checks; native pixels pending |

## Native party PvP badge — 7 November 2026

7 November native party PvP badge (PARTY-NATIVE-PVP-BADGE-20261107; REQ-RF-76):
latest user placement is full client player-frame badge behind level, with timer
slot below level. Badge sits on noninteractive owner+20 layer below level+80 and
auras+90. Modern client UnitFrameUtil.UpdateUnitPvPIndicator owns faction/FFA/
prestige selection and secret-safe texture visibility. Native player XML supplies
prestige50x52/background and30x30 badge; faction atlas uses native size. Classic
uses full64x64 native player UI-PVP faction/FFA texture. No small square packing.
Shared packing/name-budget avoids party icon visibility/width reads, since native
delegates can set private state. Other party role/status icons remain.

Blizzard GetPVPTimer has no unit parameter and native code uses it for player.
User explicitly chose Leave it empty for unsupported member countdowns. Existing
party timer text anchors below level but stays hidden: no guessed timer, copied
player timer, status substitute or new polling. Own player timer is unchanged.
Layout-only calls do not repeat native badge data rendering.

905 party/59 indicator/78 restricted/206 identity checks PASS across existing
five-client models, including legacy faction/FFA/full sizing, restricted fallback,
native delegate routing, prestige dimensions and no foreign GetPVPTimer reads.
232/232 scripts PASS; 896 syntax files/0 failures. New resources: one badge layer/two textures per member; reused icon/
timer; no new event/ticker/timer/global hook. Native badge pixels, secret delegate
execution/combat/taint/FPS pending; no performance claim. Exact source XML/API
blobs and recovery identities retained. No game input, WTF/profiler write, manual
sync, branch or push. [Evidence](validation/party-native-pvp-badge-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-76 | Client-native full PvP badge behind level; timer below, empty when unsupported | Native delegate/art; layer20 below level80;905 checks; user accepts empty party countdown; native pixels pending |

## Shared native PvP badge correction — 7 November 2026

7 November shared unit-frame PvP correction (UNIT-NATIVE-PVP-BADGE-20261107; REQ-RF-77):
user reports no visible unit-frame change after RF76. Root cause: RF76 only
handled normal party; player/target/focus retained the small status-chain icon.
Their shared outer-frame factory/paint now uses the same full native badge as
party: faction/FFA native atlas size (Classic64x64), prestige50x52/background
and30x30 badge. Badge sits behind level; timer sits below level. Only the player
keeps its real existing countdown; others stay empty as explicitly requested.
Native UnitFrameUtil handles private flag/prestige state; player-only mercenary
check matches native PlayerFrame. Status packing and secondary-name fitting no
longer query or shrink native badge regions. Normal party keeps its existing
layer and now reuses the shared prestige textures. Other roles/layout unchanged.

299 indicator/905 party/78 restricted/206 identity checks PASS. Checkpoint source
rejects the new indicator regression. 232/232 scripts PASS; 896 syntax files/0 failures; final owned
hashes match the suite manifest. Actual badge pixels, flag changes, combat/taint
and CPU/FPS remain pending: user has not accepted this correction in-game.
Two prestige textures per shared outer frame; no extra party prestige pair, new
event/timer/ticker/hook or paint driver. External source/history checkpoint and
45 settings metadata entries verified; prior complete recovery retained.
No foreground control, game/WTF/profiler writes, manual sync, branch or push.
[Evidence](validation/unit-native-pvp-badge-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-77 | Full native PvP badge behind level on player/target/focus and party; available timer below | Shared renderer;299 indicator and905 party checks; actual client visual acceptance pending |

## Focus party presentation — 7 November 2026

7 November focus party presentation (FOCUS-PARTY-PRESENTATION-20261107; REQ-RF-78/79):
PvP artwork is another35% larger on a scaled noninteractive host, still behind
level text; native/private atlas rendering and timer-below-level policy retained.
Focus now reuses normal-party portrait-left/body fonts, text/status layers,
textured HP/resource separator and raised cast header. Its target is the narrow
vertical HP-only bar on the right, as selected by the user. It keeps the focus
unit/capability/secure visibility and binding paths; it never becomes a party
slot or uses party in-frame aura filtering. Existing external buff/debuff panels
stay above, with their screen-size settings preserved. Focus sizing uses the
normal-party baseline plus independent saved focus proportions/whole scale;
no saved size is reset. The previous focus positioning function is byte-identical
(after line-ending normalization), including chat and placement2 behavior.

970 party/focus and319 badge checks PASS across five source models;28 scale,
80 public geometry,310 binding and78 restricted contracts PASS. 232/232 scripts PASS; 896 syntax files/0 failures.
Owned final manifest drift: []. Focus target partition changes defer through
the existing protected queue in combat; live secure behavior/taint remains pending.
Native pixels/position/aura sizes/portraits/target/CPU/FPS NOT RUN. One generic
badge host per outer frame is reused by normal party; focus adds four text/status
hosts and existing indicator helpers/events/hooks, with no new timer/ticker/global
hook. Exact sources and fresh external history/source checkpoint retained;45
settings metadata entries read-only. No foreground control, game/WTF/profiler
write, manual sync, branch or push. [Evidence](validation/focus-party-presentation-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-78 | Increase full native PvP badge further | Host scale1.35;319 badge checks; native pixels pending |
| REQ-RF-79 | Party-style focus with right vertical target; previous position and separate top aura panels | Actual focus initializers exercised;970 combined checks; positioning function retained; native placement pending |

## Focus anchor and aura scale correction — 7 November 2026

7 November focus anchor/aura scale correction (FOCUS-ANCHOR-AURA-SCALE-20261107; REQ-RF-80):
user rejects the previous focus position above party/raid and aura-panel layout.
The previous unchanged-anchor-code assertion was insufficient: the new compact
body scale changed its screen result. Raid coordinates now convert UIParent to
focus-local units, preserving the original helper/gap; this branch does not
require chat construction. External buff/debuff panels convert public body
metrics to their own inverse-scaled coordinate space before sizing. Their width
tracks half the visible focus plus original transparent border padding; original
icon sizes/spacing/timers/filters and above-header anchors remain. For260x85 at
body scale.4, each panel is82 units rather than185.5. Original transparent16-unit
border nesting remains. Aura artwork sits above status icons and below casts.

47 scale/anchor,265 actual aura geometry,975 party/focus,36 timer-policy and310
binding checks PASS; old source rejects both physical-anchor and panel-width
regressions. 233/233 scripts PASS; 897 syntax files/0 failures; owned final manifest identities match.
Native screen pixels/position/combat/taint/FPS NOT RUN; the earlier user-visible
regression is recorded as rejected, not accepted by prior mock results.
No new runtime frames/textures/events/hooks/timers/tickers; one panel-scale cache
and constant layout arithmetic. External history/source checkpoint verified and45
settings metadata entries read-only; prior complete private recovery retained.
No foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-anchor-aura-fix-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-80 | Focus remains above party/raid; independent top aura panels fit visible body |47 physical scale/anchor and265 panel checks; user native acceptance pending |

## Exact focus aura width — 7 November 2026

7 November exact focus aura width (FOCUS-AURA-EXACT-WIDTH-20261107; REQ-RF-81):
user clarifies remaining mismatch is aura-panel length. Compact focus no longer
adds13 units per half or a -10 buff offset: the pair spans exactly the focus outer
frame, with/without portrait. Its faint battlefield border follows focus body
scale and the same2-unit/corner offsets as FluxBorder; Classic fallback corners
use matching crops/sizes. Icons/timers/captions keep their existing panel scale;
only border geometry follows body scale. Legacy target/focus aura geometry and
focus screen anchor/vertical target remain. Border-scale/corner writes cache;
no new runtime frames/textures/events/hooks/timers/tickers.577 actual geometry/
border checks,975 party-focus,47 anchor/scale and36 timer-policy checks PASS.
Checkpoint source rejects exact width. 233/233 scripts PASS; 897 syntax files/0 failures; owned hashes match.
Native pixel alignment/combat/taint/FPS NOT RUN; user acceptance pending. External
source/history checkpoint and 45 read-only settings metadata entries verified.
No foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-aura-exact-width-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-81 | Both aura halves match the new focus outer-frame length |577 geometry/corner checks against actual FluxBorder definition; native width acceptance pending |

## Group reveal, focus aura row and portrait restore — 7 November 2026

7 November group visibility/focus row/portrait restore (GROUP-VISIBILITY-FOCUS-ROW-RESTORE-20261107; REQ-RF-82/83/84):
user screenshot shows remaining focus aura mismatch; user explicitly includes the
right target strip and wants more icons per row. Aura halves now cover that full
configured row and attach directly to the compact header (including initial/
re-enable paths), avoiding the old threat-shell reservation. Compact native/Lua
packing uses full width before wrapping. Existing independent icon/caption origin
changes are preserved; native offsets refresh on changes and cache steady writes.
Blizzard SecureStateDriver/SecureGroupHeaders and party/target sources were fetched
at21 exact blobs across5 pins. Native header roster updates require visible parents;
Flux secure group handlers now reveal the prepared parent too. Normal party uses
one added native group driver on the existing hub, removed on disable. Existing
OOC slot preallocation/native leaf visibility remains; no addon combat allocation
or ordinary protected Show/Hide. Party/focus normal portrait paint now hides the
red plate before restoring its theme, including unit-combat exit during lockdown.

1011 aura geometry,995 party/focus,255908 native-source secure-model,1160 pool/
readiness,66 portrait,310 binding,78 restricted,47 scale and36 timer-policy checks
PASS. Old party/portrait source rejects the regressions. 235/235 scripts PASS; 899 syntax files/0 failures;
owned final hashes match. Native current pixels/taint/real combat/input/CPU/FPS
NOT RUN; screenshot is prior user evidence, not current-source acceptance. No new
runtime regions/timer/ticker/global hook; one native driver reuses the hub.
Fresh external checkpoint/history and45 read-only settings metadata entries kept;
independent concurrent edits preserved. No foreground control, game/WTF/profiler
write, manual sync, branch or push. [Evidence](validation/group-visibility-focus-row-restore-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-82 | Full focus/target aura row without reserved gap; use available row width |1011 actual geometry/native contract checks; screenshot follow-up pending |
| REQ-RF-83 | Prepared party/raid appears after joining during combat |Native secure parent reveal; existing preallocation/slot drivers;995 party and255908 secure checks; native taint pending |
| REQ-RF-84 | Party/focus red portrait backdrop clears when combat ends |66 actual shared renderer/Party.PaintChrome checks; old source rejects |

## Focus aura packing without expansion — 7 November 2026

7 November focus aura packing only (FOCUS-AURA-PACKING-ONLY-20261107; REQ-RF-85):
latest user instruction supersedes the target-inclusive width in REQ-RF-82.
Restore original focus body/portrait aura width and remove the right target-strip
extension. Keep full-width native/Lua icon packing so more fit before wrapping;
icon size, spacing, timer/filter controls and corrected header anchor remain.
Target settings no longer resize aura panels. Existing secure combat group reveal
and portrait backdrop restore are retained.1011 geometry/packing,995 party/focus,
66 portrait,47 scale and36 timer-policy checks PASS; 235/235 scripts PASS; 899 syntax files/0 failures.
Owned final hashes match. Native visual acceptance remains pending. No new runtime
resources or saved-data change; unused target-width helper/lookup removed. Fresh
external history/source checkpoint and 45 read-only settings metadata entries kept;
no foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-aura-packing-only-2026-11-07.json).

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-85 | Keep original focus aura width; fit more per row without target-strip expansion |1011 geometry/packing checks; supersedes only the width extension in REQ-RF-82; native appearance pending |
