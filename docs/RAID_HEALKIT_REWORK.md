# Party and raid frame rewrite — 6 November 2026

User requirements: fully rework party/raid frames to behave and look like the
installed Era HealKit, retain Flux positions, sizes and group ordering, support
all existing clients, and integrate Flux Binding unit-frame casting. User chose
**Implement directly**. This record is the implementation matrix and checkpoint.

Reference: HealKit 0.65.0 by Ozwald at the supplied `_classic_era_` installation.
Its all-rights-reserved license prohibits vendoring its implementation or custom
art. Implementation is independently authored using public Blizzard capabilities
and Flux services. Do not load HealKit, migrate its settings or copy its assets.

Baseline `main` `582d868e23c2513ef63251dd0b294df073cfd5c5`, initially clean.
Verified external `Raid-rewrite-20261106T114645Z` contains 1,596 actual source files,
143 available settings files and all-ref Git history. ZIP entries are SHA256
verified; bundle verification passes. Source archive SHA256:
`ece77a7fe0bd41b076ed89241cbd641436eab978b8478cae2626a59f7201e005`.
Settings represent disk state; live unsaved state and a closed client are not
asserted. No game input, preferences reset or profiler changes are authorized by
this checkpoint.

## Requirements and implementation matrix

| ID | Observable acceptance | Owner / implementation | State |
|---|---|---|---|
| REQ-RF-01 | Existing account/character outer dimensions, chat dock, reverse groups, five-member columns and MT/MA mini targets remain; latest user changes horizontal gaps to0 and vertical spacing to−4px | Root; existing Compat/Layout services | Implemented; native pending |
| REQ-RF-02 | Bronze cell chrome, dark background, dimmed flat class health, bottom power, smaller full-line names, role beside percentage and health/status | Visuals/Preview | Implemented; final desktop suite passes; native pending |
| REQ-RF-03 | Health/power, own/other incoming heals, absorb/heal-absorb, overflow/overheal and supported power cost indicators | Unit/prediction | Implemented; final desktop suite passes; native pending |
| REQ-RF-04 | Blizzard-eligible buffs and priority debuffs, including helpful boss/role auras on the debuff side, in right/left3×2 blocks; cooldowns/counts; native secret ownership | Aura service + native category containers | Updated by aura follow-up; private flag limitation and native checks recorded below |
| REQ-RF-05 | Threat, target, hover and dispel highlights; offline/dead, resurrection, summon, ready-check and raid marks | Unit/Visuals | Implemented; final desktop suite passes; native pending |
| REQ-RF-06 | Range fades content without changing secure hit region; inactive work stops; bursts coalesce | Compat/Unit | Implemented; final desktop suite passes; native pending |
| REQ-RF-07 | Flux unit-frame casts work on main and mini cells; configured mouse/modifier, keyboard and wheel routes; hide/leave/removal clears routes | FluxMouseoverKeybind + Unit | Implemented; final desktop suite passes; native pending |
| REQ-RF-08 | Retail, Forever, Era, Anniversary and Classic progression capability adapters, preserved saved roots and optional integrations | All; source pins below | Implemented; final desktop suite passes; native pending |
| REQ-RF-09 | Preview represents actual new chrome and representative healer states; original preview command remains | Preview | Implemented; final desktop suite passes; native pending |
| REQ-RF-10 | Optional pets/friendly target, missing-buff helpers and Forever HoT estimates; existing group ordering remains authoritative | Extras/HoTs; optional features off by default | Implemented with limits below; native pending |
| REQ-RF-11 | Static/desktop checks separated from native visual, secure casting, taint and performance acceptance on each client | Root + all agents | Final desktop suite passes; native not run |
| REQ-RF-12 | Reported13:01:05 Binding secret mouse-state failure must not recur | Binding native aura subtree exclusion and secrecy-first mouse getter policy | Desktop regression passes; native pending |
| REQ-RF-13 | Complete left border, no black exterior box/dark overlay; small separate leader marker | Visuals resolved edge anchors, raised trim, inset backing, white sheen; Unit/XML leader11px | Earlier screenshots rejected; corrected native comparison pending |
| REQ-RF-14 | Show class buffs currently present outside combat; user explicitly declined missing reminders | Aura native/readable class filter, existing scoped options | Implemented; class buffs on, missing reminders off; native pending |
| REQ-RF-15 | Join/leave/switch party and raid mid-combat must appear/disappear and retain reverse packing | Secure native state/attribute handlers; precreate40 group+40MT children even from solo | Source/desktop checks pass; native pending |
| REQ-RF-16 | Horizontal gap0, vertical overlap4px; resource bar20% shorter while keeping saved scale | Compat/Layout/Preview native yOffset+4; power base multiplier0.8 (default rounds6→5px) | Implemented; native pending |
| REQ-RF-17 | Up to six buffs and six debuffs, visible compact durations, strict dispellable-only across every debuff slot | Aura fixed row hosts and native duration text sinks/readable clocks | Implemented; final desktop suite passes; native pending |
| REQ-RF-18 | Smaller name with full line; role icon immediately left of percentage | Visuals SetUnitName/SetUnitStatus + Unit/Preview;10px name and12px role | Desktop checks pass; native pending |
| REQ-RF-19 | Native member order inside every group, retaining reverse group columns | INDEX/ASC headers; native source comparison | Implemented; native pending |
| REQ-RF-20 | Scoped aura transparency0–100%, initially70%, timers/swipes retained | Existing raid settings scope; legacy fallback preserved | Desktop callbacks pass; native pending |
| REQ-RF-21 | Native target/ready-check ghosts suppress and restore safely | Whitelisted exposed overlays; readable alpha snapshots | Desktop/native-source handlers pass; native pending |
| REQ-RF-22 | Manager smaller; original X; one Y matching expanded reference across hidden/shown/collapsed/expanded | Layout; scale×0.85, invariant full-panel bottom | Source/desktop geometry passes; final screenshots pending |
| REQ-RF-23 | Connected HealKit-style bronze grid, one shared seam; complete shared borders retained with the later raised aura layer | Unit neighbor graph, texture-only edge updates | Resolved geometry/static model passes; REQ-RF-24 supersedes the earlier aura-below-trim order; native pending |
| REQ-RF-24 | Auras above frame visuals; buff/debuff selection follows Blizzard raid frames | Native ProcessAura categories/order; readable classifier; raised complete aura content; public hidden-buff preference events | Follow-up implemented; native private hideOnPartyFrames exclusion unavailable to custom containers; native checks pending |
| REQ-RF-25 | Clear cooldown swipe over each timed buff/debuff with remaining text above it; permanent slots have no timer | Native sinks/owned compact formatter; raised readable countdown; matching preview |Initial193/855 desktop candidate USER FAIL for ellipsis/no swipe; corrected under REQ-RF-26 |
| REQ-RF-26 | Replace native ellipsis with fitting small numbers and make timed swipes visible |7px preferred/6px public-sample fit; native numeric rules; explicit initial visibility/opaque swipe base |Previous display USER FAIL;193/855 frozen correction desktop PASS; actual native correction pending |
| REQ-RF-27 | Duration font scales with buff/debuff icon bounds, including glyphs too wide at6px |Public sample metrics; proportional SetTextScale before native binding; no6px minimum; shared readable/preview policy |193/855 frozen desktop PASS; user-owned widget probe recorded; actual scaled aura display pending |
| REQ-RF-28 | Aura-size control changes actual native/readable/preview dimensions; inside-frame cap by user choice; separate live buff/debuff limits1–6; strict dispellable-only retained | Canonical shared geometry; public owner scale; lazy clipped tail owners for exact4/5; scoped options/defaults | 200 scripts/862 syntax frozen desktop PASS; native inside-fit/count/clip scheduling acceptance pending |
| REQ-RF-29 | Normal aura slider offers visibly responsive fitted sizes; main frames30% taller; text fits; limits/strict filter retained | Numeric dynamic range metadata; cached native row refresh; frame height multiplier1.3; canonical10x19.5 aura base | 203 scripts/865 Lua syntax PASS for tested feature sources; user accepted new height and normal-aura scaling; other native scope pending |
| REQ-RF-30 | All size sliders1.00 use actual Blizzard default sizing, including outer frames; no toggle; scoped Reset sizes preserves filters/counts/opacity | Publicdefaultpreset/sourceequations; nativecanonical11/16.5; native-relative scales; five-key reset | 206 scripts/868 Lua syntax frozen PASS; user native acceptance afterreset |
| REQ-RF-31 | Offline/health/status font must stay proportional over repeated refreshes | Font-object baseline and absolutefontassignment; locale/sourceflags; TextScale1 |50-cycle/all5source models +five rejecting pairs PASS; user accepted correctedfonts |
| REQ-RF-32 | Aura scale 1.00 uses Blizzard sizes; 0.50..2.50 resizes only auras, allowing larger blocks outside fixed frames | Direct requested scale; physical fit is diagnostic; native owner and preview share geometry | 206 scripts/868 Lua syntax PASS; five baseline/candidate pairs; new native visual check pending |
| REQ-RF-33 | Separate aura X scale and duration text size controls | Scoped 0.50..2.50, default/reset 1.00; immediate preview; native settings apply after reload | 206 scripts/868 syntax PASS; native normal/large initialization and pending-width consistency checks; visual acceptance pending |
| REQ-RF-34 | Preview and live frames must share appearance and sizing rules | Shared visual XML, aura bounds/clipping, canonical timer scaling, health formatter and indicator dimensions/layers | 206 scripts/868 syntax PASS; five old-preview rejection pairs; user confirmed after reload: Looks consistent now |
| REQ-RF-35 | Duration-text scale updates existing live aura timers | Shared public Font attached at native initialization; OOC refresh and combat deferral | Native user answer: Both work; modeled forbidden-descendant regression PASS |
| REQ-RF-36 | Buffs right and debuffs left, up to 3 columns/2 rows with zero spacing | Shared canonical gap0 for native/readable/preview layouts | Native user answer: Both work; six-slot/partial-row/filter checks PASS |
| REQ-RF-37 | Black timer outline/shadow and optional numbers only below1minute | Shared public Font/NumericRuleFormatter; defaultoff; blank text at60seconds and above, keep swipes/stacks | 206 scripts/868 syntax PASS; formatter boundary/toggle regression PASS; user confirmed threshold/shadow: Yes, all work |
| REQ-RF-38 | Aura X width updates live icons without losing visibility | OOC native access guards, stored initializer heights, public flow width updates and pending geometry when denied | 206 scripts/868 syntax PASS; allowed/denied/combat regressions; user: Live icons resize correctly |
| REQ-RF-39 | Raid manager at slider1.00 must be30percent smaller | Manager baseline0.70; saved relative scale and native X/physical Y/collapse behavior retained | Five pinned manager/native sizing models PASS; user: Both fixed |
| REQ-RF-40 | Hidden Blizzard raid/party highlights must stay hidden | Alpha inheritance plus existing alpha suppression; late setup/selection hooks; restore native flags on disable | Anonymous/opaque/combat/restore regressions PASS; user: Both fixed |
| REQ-RF-41 | MT target shows name and percentage on HP only, without a resource bar | Target-specific power/status guards; one-row name/percent bounds; shared mini target preview | 208 scripts/870 syntax PASS; unit/chrome regression pairs; user: Yes, looks right |
| REQ-RF-42 | In-range MT target must not be incorrectly transparent | Use base opacity for target in-range/unknown checks; fade only for confirmed far result; same preview opacity | 208 scripts/870 syntax PASS; unknown/opaque/checked range cases; user: Yes, opacity looks right |
| REQ-RF-43 | Screenshot values become the sizing defaults everywhere | Both profile/character defaults and scoped/full resets use width0.70, height0.95, power1.00, aura1.82, X0.50, font1.72, manager1.20 and under-minute timers on | 209 scripts/871 syntax PASS; screenshot/default/reset parity in actual scopes; no renderer change |

HealKit binding profiles/macros are replaced by the explicitly requested Flux
Binding integration. Flux saved roots, commands, ready checks, raid marks and
BigDebuffs are retained. Native private aura owners must keep their attribute
handlers. No native CompactUnitFrame data-update writer is introduced.

## Current upstream source identities

The user named [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source).
Resolved once for this task; exact downloaded file hashes remain in the external
`raid-upstream-20261106` cache. Existing reference trees are older and must not be
represented as the following revisions.

| Client | Branch / commit | Source build / interface |
|---|---|---|
| Retail | `live` `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 / 120105 |
| Forever | `forever` `5987a8e2304c1331346dc861d5ccacf4c510cf0f` | 1.60.1.70840 / 16001 |
| Classic progression | `classic` `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | 5.5.4.70631 / 50504 |
| Era | `classic_era` `4192ac60067fc55566182291bc67c85dd9b6794d` | 1.15.9.70576 / 11509 |
| Anniversary | `classic_anniversary` `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | 2.5.6.70577 / 20506 |

Pins establish source contracts, not installed/native execution. PTR/beta and
private-server derivatives are not silently certified by shared source names.

## Checkpoint

Implementation is complete as a source candidate. All runtime files are frozen
at the final validation fingerprints; native acceptance remains pending.
Integration ownership covered Visuals/Preview, Binding input, unit/layout/aura
services and independently pinned API/source review. Read this record, `15-raid-frames.md`, current source diffs and latest
validation before resuming. All native checks and pixel parity remain pending.

## Latest design decisions and intentional changes

The user declined a mock-up, then supplied native screenshots and rejected
earlier appearance/manager candidates. These screenshots are failure evidence, not visual
acceptance. The first exposed the oversized central leader crown; the second
showed oversized duration text. Later feedback identified the incomplete left
trim and dark overlay. The left edge's second anchor originally resolved both
horizontal coordinates to zero; its corrected opposite anchor resolves6px.
Dedicated native duration text keeps timers visible without oversized cooldown
numbers. The bar sheen now uses only white alpha0–0.04.

The user's subsequent sizing answer is **Keep current outer size**. Existing
width/height scales remain. Six-slot rectangular icons, horizontal0 gap and vertical4px overlap,
smaller10px names,12px role beside percentage and resource-base multiplier0.8
supersede the earlier interior typography/spacing. The class-buff choice is
**Buffs currently present**, so reminders remain opt-in/off by default.

Offline cells retain base opacity, gray health and name, matching the requested
reference behavior; connected out-of-range cells retain saved fade values.
Disabling range fade restores the base instead of leaving stale fade.

Optional Forever HoT prediction is an explicitly labeled estimate, default off.
It supports readable Renew/Rejuvenation/Regrowth descriptions in enUS/enGB,
assumes3-second ticks and requires readable successful player-cast identity.
Restricted data, unsupported descriptions/locales and unobservable early removal
cannot be inferred. Native incoming healing remains independent and supported
through native calculators. Four overheal tiers use separate owned calculators
at0%,10%,25%,50% overflow; their additional snapshot cost is not an FPS gain.

Flux Binding preserves existing profiles, spells, ranks and macro conditions.
Only explicit configured primary-click programs override left target/right menu
on Flux-owned cells. Shift/Ctrl/Alt combinations are supported; META/CMD primary
chords remain unavailable rather than activating an unmodified cast.

## Final source checkpoint and acceptance

The latest user choices supersede earlier individual-frame chrome: connected
textured bronze shared borders, one owner per seam,4px vertical overlap and
horizontal0 gap. Both aura blocks are3columns×2rows, buffs right and debuffs
left. Duration text7px and faint cooldown swipes remain visible. Transparency
has a0–100% scoped slider, default70%; existing legacy opacity maps without a
settings reset. Native INDEX/ASC order matches discrete Blizzard group rows.

The manager retains native horizontal anchors and uses one full-panel bottom
reference for identical Y in collapsed/expanded/hidden/shown states. An earlier
toggle-face Y calculation was rejected by the two user reference images.
Native selection and both ready-check ignore-parent-alpha regions suppress
reversibly. Initially opaque alpha remains untouched until readable.

Full desktop validation and source fingerprints are in
[the final record](validation/raid-healkit-rework-2026-11-06.json). Source-level
tests execute pinned native handlers but do not run the protected game VM.
Latest native visual, casting, combat/taint and performance acceptance remains
pending for every target. The source is on main in the existing workspace;
private recovery/settings and distribution artifacts stay outside AddOns.

The final border request restores the original Blizzard bronze artwork used by
HealKit. Cropped native gold bands preserve the textured bevel without the
black/brown padding or additive shine; outer-only native arcs preserve connected
internal seams. Native art availability and final pixels require each client.

The manager also prepares its Y while solo, before members bind, so a native
combat reveal uses the already established full-panel position. Later native
layout reconciliation stays out of combat. A regression covers this path.

Additional intentional fixes: opaque resource maxima no longer become power-
bar opacity; combined health/percent mode displays both values; hidden hover
routes clear securely; secret mouse getters are never boolean-tested; native
aura owners bypass BigDebuffs' legacy queries; a reappearing MT target cannot
retain an alpha-zero wrapper. Focused regressions accompany these changes.

## Aura eligibility and layering follow-up

6 November aura follow-up: the user reported low aura layering and requested
Blizzard raid-frame aura selection. Complete icons, swipes, durations and
counts now sit above names/trim/highlights, with leader/loot/status above
them. Blizzard classifications and priority replace duration/shield rules;
helpful boss/role auras can occupy the debuff side. Public hidden-buff
preferences refresh without protected layout work. The requested strict
six-slot dispel policy and aura transparency remain. Explicit OOC present
class buffs override native hidden-group preferences. The user returned
a Forever stage-b diagnostic showing valid active native binding with15
hidden buff types after reporting no buffs. Stage-c corrects the OOC
class exclusion interaction. The user returned its diagnostic and then
confirmed that it works fully on Forever. This accepts observed aura
behavior only, not combat/taint/FPS or all-client execution. Native owners
still reject ProcessAura.None before supplemental filtering; the126-case
desktop model omits that gate, so complete native assignment is not proven.
Restricted private hideOnPartyFrames parity remains an API limitation.
Final 181 desktop scripts / 843 Lua syntax files pass; source hashes/membership
are unchanged across the run. Five alternating functional pairs per case
reject the old filters/layers and pass the candidate; no native FPS claim.
Native icon pools increase80→120 per full cell for native category ordering;
refresh remains bounded. Other clients and native taint/combat/performance
acceptance remain pending. No further runtime changes follow acceptance.

[Exact follow-up record](validation/raid-blizzard-aura-followup-2026-11-06.json). The earlier complete-suite record remains tied to its own source stage.

## Aura size and independent capacities — 7 November

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

The former width/height clamps and native startup metrics made larger settings
collapse to the same size or depend on what was saved at reload. Canonical native
metrics now stay10x15; only public owners scale. Requested height is
11*1.30*auraIconScale, so new1.00 is30% taller than old1.00's11px before fitting.
The lower0.50 minimum keeps shrinking useful even where12 icons reach the cap.
Existing stored1.4 and scoped settings are retained. A fixed1px center gutter and the
known owned health rectangle bound both blocks. Fewer selected slots can allow
larger icons; six per side at the default outer dimensions already reaches the
inside-fit cap. Names, secure outer dimensions, docking and connected borders
remain unchanged. Normal categories/class supplementation/order are retained.

Native APIs expose per-category budgets, not a shared total, and one rectangular
clip cannot represent five cells in3x2. Original and lazily created tail owners
receive identical filters, sorting and unit; separate own clips show indices1–3
and4–N. The API's shown-aspect visibility contract supports logical visibility
despite geometric clipping; that is an inference from the public contract. Actual
empty-to-populated native scheduling through the tail clip still needs client
acceptance. Extra pools are retained after first4/5 use, never grown on updates,
and unbound/hidden outside that shape. No secret aura data determines addon logic.

Manual native acceptance after reload: move the size slider low/high/low; compare
live and preview; choose1/4/5/6 for each side with mixed categories; check every
visible debuff under strict mode; let an empty row gain/lose timed auras; toggle
class buffs and decorated/plain highlight; join/leave/move groups in combat and
check existing Flux casts. Record actual client/build and new errors/screenshots.

## Responsive live slider and taller frames — 7 November

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

This supersedes preservation of the old outer height in REQ-RF-01/28 following
the user's explicit correction; member width, docking and native group/member
order remain. The old slider's broad numeric range did not imply available room:
full side blocks could already cap near1.05. The final option caps its numeric
range to the pending scoped width/height/power/count layout, down to0.01 steps.
Actual numeric metadata remains compatible with the bundled Ace schema. The
custom renderer rereads that metadata and description on cached row refresh;
its guard prevents native bound clamping from firing an accidental saved change.

Native scale propagation was confirmed by the user's direct0.50 update. The old
layout probe and subsequent confirmation do not certify the final tall frames or
new slider rendering. After reload, drag the Party/Raid Aura icon scale low/high,
check normal timed buffs/debuffs and text, change capacities/scopes/frame size
with the page open, and verify the fit limit updates. Test strict debuffs and
existing combat roster/binding routes separately. No native child gets queried.

7 November final user check: after reload the user confirmed, Yes, height and
normal auras work, for the taller frames and normal aura/duration-text slider.
All five client folders match the tested feature files;20 destination hashes
verified. This task performed no second overwrite because those exact candidates
were already installed. Other-client native execution, combat/taint and FPS
remain pending; this is visual/function acceptance in the selected test client.
[Native acceptance](validation/raid-aura-slider-live-2026-11-07.json).

## Blizzard sizing as1.00 and stable fonts — 7 November

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

Latest sizing instructions supersede the prior30% larger custom frame/icon
baseline and four-pixel overlap. There is no sizing mode or profile migration.
Modern native defaults are98x44 from preset26/8 plus72/36 bounds; the public
default manager/conversion also handles a selected native Classic72x36 preset.
Active native profiles are never copied or changed. UI stock reset uses existing
account/character scope and leaves all nonsize settings intact.

Exact source and locale findings, cache/file/blob identities, commit URLs and
runtime fallback provenance are retained in the record. At tiny custom dimensions
or a small default preset, six native large layout slots may overlap the available
space; native1.00 glyph size wins over the older automatic-shrink request, and the
option description reports that constraint. Increase frame size or reduce counts
when needed. Counts retain the user's3columns/2rows on each side. Additional
Flux indicators/timers without a visible stockcompactcounterpart are preserved.

The final screenshot was corrected without altering opaque aura sinks: both large
Offline and numeric health labels used the same cumulatively scaled status field.
Native source has no proved timer font reset. The user accepted the absolute-font
fix after reload and size reset. That does not certify pixel parity, all-client
native execution, combat/taint safety or FPS. Remaining native ledgers retain those
specific pending checks; no past macro/widget counts are presented as nativeproof.

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

## Party player-style mode and packed aura columns — 7 November 2026



| ID | Requirement | Implementation / acceptance |

|---|---|---|

| REQ-RF-44 | Party-only choice between current compact raid frames and smaller player-style frames, with settings | `partyAsRaid` defaults true in both scopes; alternate scale/portrait/cast controls; shared UF health/power/portrait/atlas/outer factories; desktop checks; native pending |

| REQ-RF-45 | Party pets look like player pets and support combat summon/dismiss | Four preallocated `partypet1..4` cells; existing pet proportions/portrait side; optional pets and relative scale; native state drivers; desktop checks; native pending |

| REQ-RF-46 | New party mode uses the existing compact party location, last member bottom-right unchanged | Existing raid/party header positions untouched. Secure alternate layout derives the compact last-cell corner from current party count, including the compact player row; portrait overlap and effective scale compensated; desktop checks; native pending |

| REQ-RF-47 | Zero-gap auras fill columns first, debuffs left and buffs mirrored right | Two rows then next column; one-to-six cap; normal and boss/role grid icons use the same configured size to remove former boss-sized empty slot padding. Strict filters, X scale, duration and opacity retained; actual native flow projections and preview checks; native pending |

| REQ-RF-48 | Fix reported `FluxRaidSecure.lua:445` nil call | Ordinary cleanup uses addon-owned party frame references. `GetFrameRef` remains restricted-snippet-only. Repeated cleanup tested with an ordinary-access rejection; native follow-up pending |



The current raid-style party mode and screenshot sizing preset remain defaults.

The alternate mode displays the four other party members; the separate Flux player

frame remains the player's own frame. Raid conversion returns to the existing

raid headers. Both unit and pet outer hit rectangles register with Flux bindings

and ClickCastFrames. Style/scale changes defer in combat; preconfigured native

mode/existence states own roster changes and actual protected input visibility.

No new recurring Lua range/roster driver is installed. Alternate frames are

created only on first selection; hidden cells skip the shared paint handler,

unbind native aura subscriptions and stop their active cast display. Eight native

state conditions reuse the raid secure hub. No personal class power, swing,

vehicle or MP5 service is duplicated.



Preview party chooses the five-slot world preview; with compact mode off this

uses the same player/pet component factory, dimensions and options, with isolated

non-secure sample cells and the shared aura preview renderer. Preview cells do

not register live unit events, casts or bindings. Other preview roster sizes keep

the existing raid preview. Visual parity and native combat/input/taint/FPS checks

remain pending separately on every client. Meter layout was explicitly removed

from this turn's scope; no meter files were edited.



[Evidence](validation/raid-party-mode-2026-11-07.json).



Follow-up requirements, same implementation:

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-49 | New party members and pets support Flux hover unit-frame casting, including primary/modifier mouse chords | Actual outer buttons carry the existing owned party/raid marker and register with Flux and ClickCastFrames; actual production binding engine tests keyboard/wheel, primary and modified mouse programs and secure combat hide cleanup; native hardware input/taint pending |
| REQ-RF-50 | Zero spacing between new player-style party members | Secure live layout and preview use exactly member outer height as the vertical step; every one-to-four-member roster tested; unchanged last corner; native visuals pending |

Focused follow-up: 535 party mode checks and 210 production Flux binding checks
on five modeled clients. Combat roster/pet changes reuse prepared buttons;
OnHide clears hover routes securely even without OnLeave. New alternate-mode
member spacing is zero; the original compact/raid overlap remains unchanged.

## Native party follow-up — 7 November 2026

PARTY-NATIVE-FOLLOWUP-20261107. User chose direct implementation and is testing
Forever manually; no foreground, input or clipboard control. Existing all-five
client scope and original raid appearance remain. The following table is the
current contract where it supersedes earlier party notes.

| ID | Requirement | Implementation / acceptance |
|---|---|---|
| REQ-RF-51 | Native party visibility and combat-safe stable tokens | Four prepared party1..4/partypet1..4/party1target..4target; state-visibility; protected changes OOC. Public readiness and $parent contract regression checks; user confirms appearance; final combat/taint pending. |
| REQ-RF-52 | Preview show/hide and shared live geometry | Actual ToggleParty replays; shared member/pet/target factories and aura renderer, meaningful sample values/status colors; user confirms preview works; final pixels pending. |
| REQ-RF-53 | Stable four-row height, zero gap and old full-party anchor | Roster count does not resize or reposition remaining slots. Scale caps the complete four-row stack to current raid column; fourth slot retains the full-party bottom-right. Supersedes partial-roster last-slot relocation in RF46. |
| REQ-RF-54 | Smaller HP-only pets and pet-aware text | 60x28 pet, no portrait/name/resource and percentage only. Secure text hosts use top HP band and pet-width offset with pet, full HP center otherwise. Native pet existence drives both. |
| REQ-RF-55 | Wider HP-only party targets and optional player class HP | Default width30, vertical HP-only party target; independent opt-in HP class tints for own pet target, party targets and focus target. Known player/class only; NPC/opaque keeps usual color. |
| REQ-RF-56 | Class colors for party borders/backdrop independently of HP | Party class chrome toggle recolors owned border/backdrop only; default off. Does not enable class HP. |
| REQ-RF-57 | Larger party auras and portrait-side debuffs | Extra partyAuraScale1.50 default with slider. Harmful block top-right of portrait, helpful right HP. Zero-gap column flow, one-to-six counts, strict dispellable-only, duration/swipe, X and alpha retained. |
| REQ-RF-58 | Larger value/percentage text, fitted name and metadata | HP/resource values/percentages +15 percent; smaller fitted name in dedicated header excludes duplicate pet reserve. Leader/assistant/MT/MA/loot/PVP slots on raised layer; level reserved right; native pixels pending. |
| REQ-RF-59 | Resource height and independent health/resource text choices | Default party resource height80 percent; freed space goes to HP. Values/percent/both/hidden per bar; defaults HP values and resource percent. Power ticks preserve centered single-label layout. |
| REQ-RF-60 | Dead/ghost/AFK/offline status and range appearance | Shared status precedence labels plus desaturated gray HP/resource atlas fills, recover on return. Existing raid range alpha applied to members, portraits and detached chrome; range never hides buttons. |
| REQ-RF-61 | 3D opacity and native unavailable-portrait fallback on all UFs | Portrait/model/2D inherit parent alpha; no secret-alpha comparison. Missing model falls back to SetPortraitTexture, without clearing pending load; OnModelLoaded restores 3D. Final per-client portrait pixels pending. |
| REQ-RF-62 | Native-colored threat border overlay only | Owned transparent no-input overlay recolors border with GetThreatStatusColor and native warning/dead/status rules. No fill, flash or HP tint; opaque threat safely hides overlay. Final native combat/secret behavior pending. |

Native user evidence: preview works; player-style frames appear after replacing
the custom hub visibility snippet. Earlier diagnostics reached a show condition
but no positioned/visible member. The attached log also recorded direct table
creation, invalid inherited-parent handles and a secret-alpha comparison. These
specific paths have desktop regressions; this does not certify native taint.

RestrictedFrames disallows private underscore GetAttribute reads and requires
explicit protection for relative userdata handles. Public roster-layout-ready
and native $parent fix those contracts. Actual native state-visibility bypasses
the custom layout handler. Four rows are fixed even for a smaller roster;
this intentionally supersedes the earlier moving final-member corner.

The selected source pins remain live297d7aaaa736f346b3e036f38ee088eaf7f8c07f,
forever9dc84f0d3bbae1768ac3405b3716000bd93eda06,
classic e5d9b3a22c3f0f6f41ebac0e454f4969594261cf,
classic_era4192ac60067fc55566182291bc67c85dd9b6794d and
classic_anniversary68e0a2ec559d9761dfc4e7f864c3944f9d758a49.
Native portrait/threat evidence is Forever Mainline/UnitFrame.lua at that pin:
SetPortraitTexture and GetThreatStatusColor stay engine/native-owned.

760 party,310 binding,78 native contract and255903 secure checks pass on the
five source models; final217 scripts/880 syntax PASS at the tested snapshot. Party runtime
owners remain unchanged; later unrelated utility/test edits cause global drift. Five fresh
alternating checkpoint/candidate comparisons reproduce the old secret-alpha
branch failure and pass current code, with raw outputs and timing retained.
These are functional outcomes, not native CPU/FPS claims. Alternate mode owns
12 logical live cells,12 visibility conditions,12 pet-text conditions and four
transparent border overlays. Default compact mode creates none of those live
cells. Existing range/cast services retained; no new recurring Lua party driver.

External source/history checkpoint Raid-rewrite-20261107T082357Z and158 on-disk
settings verified; no settings/profiler/game interaction or manual sync. All13
feature files match across allfive installations through existing sync.
Final pixel parity, combat joins/leaves/raid conversion/pets/targets, real secret
values, hardware binding input, taint and FPS remain pending per client.
[Exact evidence](validation/party-native-followup-2026-11-07.json).

Constructor fallback also reports failed SetUnit compatibility attempts to the
engine texture owner; race/generic-human substitutes are removed. Portrait GUID
event comparison guards opaque values before equality; no recurring work added.

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
