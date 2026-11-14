# Action, badge and extra-button count refresh

13 November 2026, ACTION-COUNT-REFRESH-20261113. The reported reproduction is
19 Light Feathers followed by acquiring one through loot, a merchant, a trade or
mail. A visible spell or macro must show 20 without pressing/releasing a modifier
or changing its conditional face. Existing item counts and spell charges share
the acceptance scope across Retail, Forever, MoP progression, Era and Anniversary.

| Requirement | Behavior | Implementation |
|---|---|---|
| ACR-01 | Published bag counts update normal action bars immediately, including light inventory notifications and both providers | Bars' existing synchronous inventory listener uses the instant count tier |
| ACR-02 | A later native spell-use update refreshes reagent counts and empty/refill tint on bars, extra buttons and badges | Validated SPELL_UPDATE_USES subscriptions request the existing count and usable lanes |
| ACR-03 | Item quantities, charges, macro identities, modifier/reverse badges and parked visibility retain their existing behavior | Shared painters and API adapters remain authoritative; no count-result cache or identity rewrite |
| ACR-04 | Bursts coalesce; no timer, poller, bag scan or protected write is added | Existing scheduler and FormStorm held-count/usability replay |
| ACR-05 | Preserve client-specific APIs and secret-value handling | Event payload is an invalidation hint; handlers do not read spell IDs or count values |

The action-bar listener previously requested scan-tier notifications with
`sync=true`. Synchronous delivery controls when an eligible listener runs;
it does not admit scan listeners to a light notification. Inventory intentionally
skips that combination, so a light count publication could leave the action bar
stale until a later modifier or full update. Extra Buttons already subscribe at
the instant tier, including the shared badge painter.

Both watch modules handled SPELL_UPDATE_CHARGES but omitted SPELL_UPDATE_USES.
The new handlers cover native cast/display counts that settle after the bag
publication, including changes without a different item identity. They request
only count/usability painting. Cooldowns retain the existing charge/cooldown
events. During a form/vehicle settle window, existing held flags replay once.
The central event service validates availability, so an unsupported event does
not create a module-specific fallback or polling loop.

Extra Buttons' existing bag path refreshes spell reagent faces on every relevant
bag publication, even when changed item IDs are supplied. Ordinary item filtering,
charged consumables, native display text, Classic reagent mappings and hidden-face
retirement remain owned by their current services. No extra inventory requests
are issued from a listener. No options, user-facing strings, defaults, saved data,
art, bindings or controller input paths are introduced. Counts are passive display;
existing controller reachability and activation remain unchanged.

## Sources and preservation

The user supplied [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source).
[Source evidence](validation/action-count-sources-2026-11-13.json) records exact
commits, versions, Git blob identities, loaded files, API restrictions and event
declarations for all five targets. Retail/Forever display and cast counts may be
secret; the existing native text write-through is preserved. Native ActionButton
handles charge changes; visible native SpellFlyout buttons update counts/usability
on bag events. SPELL_UPDATE_USES is declared in all five selected source builds;
source declarations do not prove native delivery or addon registration.

Before runtime edits, the [checkpoint](validation/action-count-checkpoint-2026-11-13.json)
verified 2,712 source files, an external source ZIP and history bundle, and
47 available settings files through read-only metadata/hashes. No private values
or backup archives are in AddOns. Work continues directly on main and preserves
the pre-existing working tree. No client control, private settings/profiler write,
manual synchronization or publication is part of this change.

## Bartender4 and installed ButtonForge comparison

The follow-up comparison is read-only and records exact source identities in
[comparison evidence](validation/action-count-comparison-sources-2026-11-13.json).
No third-party code is copied and all existing licenses remain intact.

| Reference | Count refresh strategy | Implication for Flux |
|---|---|---|
| Bartender4 master `2ced21c0415ce50374ec6c38283a20a284616d25` | Delegates button painting to external LibActionButton; its package dependency is floating | Keep the action-button owner distinct from bar layout; inspect the library's own identity |
| LibActionButton master `bc1da7a581d21dad5d7da114263c6a513f448f32`, minor168 | One shared event frame; SPELL_UPDATE_CHARGES updates counts on action-bearing buttons; no count polling or BAG_UPDATE/USES handler in the inspected upstream library | Event-driven count lanes suffice; upstream's source is not evidence of native reagent delivery for Flux |
| Installed ButtonForge 1.3.5.0, interface120100 | BAG_UPDATE and SPELL_UPDATE_CHARGES mark text dirty; bag updates mark usability dirty; one shared next-frame refresh consumes the flags | Coalesce bag-driven count/tint refresh instead of parsing a macro or rebuilding a button |

ButtonForge's active set includes allocated hidden buttons, and its BAG_UPDATE
path also walks carried slots for its separate bag cache. Those broader owners
are not needed by this fix. Flux keeps its existing inventory service, parked-face
skipping, ordinary item filtering, shared scheduler, and native secret display
adapters. The bundled modified LibActionButton already has its own coalesced
charge/bag-delayed route and is unchanged. Neither reference inspection nor
desktop work counts certify lag-free native performance.

## Validation and remaining native acceptance

The regression executes the real inventory tier dispatcher and bar/EBS/badge
painters: 666 checks pass across five client models and both providers, with
optional missing-event fallbacks. Three alternating exact checkpoint/candidate
pairs reject 224 baseline failures and pass the candidate; all seven harmful
controls fail as intended. A modeled 100-use-event burst queries six visible spell
faces once and writes three changed EBS count strings, with zero added timers.
The count-held form replay also restores badge tint at 0 and 1. The full suite
passes 343 scripts and syntax checks 1,031 Lua files; its complete source manifest
matches the current files. Concurrent auction/minimap work is preserved.

Focused regression and full-suite results are recorded in
[validation evidence](validation/action-count-refresh-2026-11-13.json).
Desktop execution establishes modeled event routing, painting and bounded work;
it cannot certify native event delivery, combat/taint, pixels, controller input,
CPU or FPS. Existing direct implementation and user-managed native testing
preferences are retained. No UI design changes require a new mock-up.

After reload out of combat, reproduce separately on each client with the built-in
inventory and Syndicator. Put the reagent spell and a modifier macro on normal
bars, badge faces and extra/minimap buttons. Gain and consume reagents through
loot, merchant, trade and mail; check 19→20 and 1→0→1 without changing modifiers.
Repeat with stacked items, a charged spell, an item with charges, a visible flyout,
reversed badges, modifier-held combat, a form transition and hidden/revealed faces.
Confirm usability tint, secure activation, bindings and existing controller input;
check Lua and taint logs separately. Native results and matched native CPU/FPS
measurements remain NOT RUN until captured. Profiling stays optional.
