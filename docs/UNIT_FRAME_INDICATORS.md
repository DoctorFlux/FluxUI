# Unit-frame indicators and player spec icon — 7 November 2026

UF-ICON-01: Player, target and focus share a bounded indicator grid above the
health bar, immediately next to class/spec. Up to five simultaneous indicators
use two rows so master loot has its own slot. Preferred size is 14px (10px
focus), fitted to strip height and the existing gap beside the full name.
No name-strip width is reserved for these indicators. Raid group stays eight
pixels right of the name and cannot anchor to a status icon. Neither names nor
raid-group/class/spec anchors move. User rejected prototypes that shifted the
group label, shortened the player name or put icons inside health; final layout
keeps all indicators above health and beside class/spec.

UF-ICON-02: Available verified native atlases supply PvP, leader and assignments;
legacy files remain fallbacks. Assistant/master loot retain native legacy art.
Atlas dimensions never override our geometry; no blanket crop changes UVs.
Existing group/loot/PvP events and flags remain. Master loot accepts legacy
string methods and native C_PartyInfo.GetLootMethod with
Enum.LootMethod.Masterlooter (2). Raid ownership resolves through UnitIsUnit
against the returned raid token, including target/focus aliases. User's native
Forever dump returned 2,0,1: master loot; player party slot; raid member 1.
That is API evidence, not final candidate visual acceptance.

UF-ICON-03: Player uses Blizzard's 42-frame, 7-row/6-column, 1.5-second resting
flipbook when its atlas exists. Static UI-StateIcon resting art remains on
clients without that atlas. ZZZ sits beside the level; the level stays visible,
as explicitly requested after the first prototype. Combat takes precedence.
Animation stops on leaving rest, disabling the indicator or hiding its host.
One player texture/engine animation and PLAYER_UPDATE_RESTING registration;
no new polling loop/ticker/timer. Existing whole-frame scales apply.

UF-SPEC-01: A matching Respec profile icon takes priority. No profile or a nonmatching
profile restores live talent/spec detection; existing build-match/debounce
behavior in Respec is preserved. Modern clients
use active specialization (global or C_SpecializationInfo namespace). Era,
Anniversary and Forever first use the most-invested committed talent tree,
active group included; Forever falls back to active specialization if no
committed tree icon is available.
Current Classic namespace icon/points are returns 4/7; older tab contracts use
name/icon/points or ID/name/description/icon/points. Hybrid builds now always
choose the largest investment; ties choose the first tree; zero points yields
no invented spec. The local resolver is forward-declared so the lightweight
profile refresh no longer calls a missing global. Numeric texture IDs avoid
string-only fallback operations. Class icon remains beside the spec icon.
Other-player spec inspection retains its existing availability/privacy limits;
unknown or uninspectable target/focus specs are not fabricated.

## Sources and safeguards

Direct implementation chosen by user. All five installed client families are
in scope. Read-only Gethe sources resolved once on 7 November:

- live 12.1.5.70783: [297d7aaaa736f346b3e036f38ee088eaf7f8c07f](https://github.com/Gethe/wow-ui-source/tree/297d7aaaa736f346b3e036f38ee088eaf7f8c07f)
- forever 1.60.1.70862: [9dc84f0d3bbae1768ac3405b3716000bd93eda06](https://github.com/Gethe/wow-ui-source/tree/9dc84f0d3bbae1768ac3405b3716000bd93eda06)
- classic 5.5.4.70631: [e5d9b3a22c3f0f6f41ebac0e454f4969594261cf](https://github.com/Gethe/wow-ui-source/tree/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf)
- classic_era 1.15.9.70576: [4192ac60067fc55566182291bc67c85dd9b6794d](https://github.com/Gethe/wow-ui-source/tree/4192ac60067fc55566182291bc67c85dd9b6794d)
- classic_anniversary 2.5.6.70577: [68e0a2ec559d9761dfc4e7f864c3944f9d758a49](https://github.com/Gethe/wow-ui-source/tree/68e0a2ec559d9761dfc4e7f864c3944f9d758a49)

Native Mainline PlayerFrame.xml defines the rest atlas and exact flipbook;
PlayerFrame/TargetFrame and PvP styles define faction atlases; Classic compact
unit frames define RaidFrame-Icon-MainTank/MainAssist. UnitFrame TOCs establish
Mainline/Classic load paths. Classic FrameXML TalentFrameBase_Shared.lua and
SpecializationInfoDocumentation.lua establish namespace return 4/7 and active
group. Source files, versions, before snapshots and SHA256 identities are in the
external unit-icons evidence folder recorded in identity.json. Existing dated
external source/settings/history checkpoint was rehashed and bundle-verified
before runtime edits; current affected files were separately preserved there.
Available on-disk settings were inspected for existence only. No settings,
profiler, game input, foreground, branches, commits or pushes changed.

## Validation and remaining checks

Focused fixtures execute production art/rest/layout and talent-selection bodies,
including all five simultaneous indicators, all three units, both portrait
orientations, selected profile, modern/legacy/current Classic talent signatures,
active group, hybrid/tie/zero-point cases, level coexistence and raid-group/name
isolation. See tests/unit_indicator_layout.lua and tests/unit_spec_icon.lua.
The full desktop report is validation/unit-indicators-2026-11-07.json.
These checks do not prove native pixels, secure VM/taint, FPS or other-client
execution. No native capture was available; those checks remain NOT RUN on all
five clients. Reload outside combat and inspect: raid leader + master loot +
assignments/PvP together above health beside class/spec; unchanged full player name and raid group; target/focus
indicators; resting level plus animated ZZZ; leave rest/enter combat; choose a
profile then No profile; change the dominant talent tree/active group. Existing
background mirror was left untouched; no duplicate installation copy performed.

Final focused checks: 59 indicator state/art/layout cases and 23 spec cases,
including the native namespace/enum and raid ownership aliases. User provided
Forever loot API output 2,0,1. Final visual acceptance remains pending.

Final full desktop run: 208/208 scripts and 870 Lua syntax files PASS. Both
runtime file identities match the report manifest. Five installed Shared.lua
copies (Retail, Forever, Classic progression, Era, Anniversary) match byte for
byte through the existing mirror; no duplicate copy was performed. These file
checks do not establish native execution or visual acceptance.

## Talent lookup follow-up (UF-SPEC-02)

User reported the spec icon still did not work with talents. Core/Client.lua
exports Flux.Client, not ns.Client. The initial resolver and its mocked client
shape both used the latter, skipping the namespace points path on actual
Forever/Era/Anniversary. Both resolver entry points now consume ns.Flux.Client.
Integration fixtures execute the actual Core/Client.lua with each client-shaped
build and then resolve the icon, including rank changes, matching-profile
priority and no/nonmatching profile fallback. 38 checks pass; five alternating
baseline/candidate pairs reject the old namespace and pass the corrected code.
No UI geometry, profile-match semantics, settings, events, debounce or recurring
resources change. This is a selection bug fix; native pixels/taint/FPS remain
pending. Existing direct implementation and in-game testing preferences apply.
Checkpoint in raid-mt-target-2026-11-07.json was rehashed/bundle-verified before
editing; affected before source/test and raw identity evidence stay in the
external unit-spec-talents folder. See
[paired evidence](validation/unit-spec-talents-2026-11-07.json) and
[full desktop run](validation/unit-spec-talents-full-2026-11-07.json).

UF-SPEC-02 final: 208 scripts/870 syntax PASS; tested runtime unchanged; all five installed Shared.lua copies match through existing sync. Native acceptance pending.

## Forever's actual talent groups (UF-SPEC-03)

The user rejected the UF-SPEC-02 native result: it still showed a class icon.
Native Forever returned spec1482, Mage, icon626001 and zero points; dual spec was
not unlocked. This proves the class specialization record is not a classic
three-tree talent record, despite shared API return fields. Prior mocks modeled
Classic-style points under Forever and could not establish that behavior.

Pinned Forever 9dc84f0d3bbae1768ac3405b3716000bd93eda06 loads
Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua via Blizzard_PlayerSpells.toc
AllowLoadGameType camelot. RefreshTreeHeaders uses
C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupCurrencyInfo;
ClassTalentTreeHeaderMixin.Setup displays displayInfo.icon and the first currency
entry's spent field. The resolver now follows that same policy on the active
spec group's combat config: GetActiveSpecGroup -> GetCombatConfigIDForSpecGroup
-> C_Traits.GetConfigInfo.treeIDs -> group display records/currency records.
It joins groupID to traitNodeGroupID, chooses the icon with largest spent, keeps
the first native header on ties and returns no invented spec for zero investment
or unavailable loading data. This uses the active config's native spent count;
it does not claim a staged/committed distinction that this API does not expose.
Only Forever uses this route. Era/Anniversary retain actual Classic tab reads;
Retail/progression retain specialization reads. Matching-profile override and
existing event/debounce behavior remain. No UI add-on load, new event, ticker,
timer or node-by-node traversal is introduced. Native group API restrictions
remain AllowedWhenUntainted; no restricted-value bypass is attempted.

59 source-executing selection checks model the actual Forever class record and
trait group API shapes, including one unlocked spec, reordered currency groups,
live point changes, matching/nonmatching profiles, ties, zero points, missing
config/API data and the real client-module namespace. Five alternating pairs
reject all five pre-fix sources and pass all five candidates. Existing source,
settings/history checkpoint rehashed/bundle-verified before editing; affected
before source/test and pinned sources remain outside AddOns in the external
forever-spec-source folder. No game input, settings, profiler, profile or talent
writes were performed. Final native icon appearance remains pending.

[Native header source](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua),
[paired evidence](validation/forever-talent-group-icon-2026-11-07.json),
[full desktop report](validation/forever-talent-group-icon-full-2026-11-07.json).

Final rerun: 209/209 scripts and 871 Lua syntax files PASS. The earlier run
caught a concurrent meter-source/test transition; its focused rerun and this
complete rerun pass. The tested unit-frame runtime is unchanged and all five
installed copies match. Native icon/combat/taint/FPS acceptance remains pending.

[Final current-source validation](validation/forever-talent-group-icon-final-full-2026-11-07.json).
