# Party and raid frames

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
