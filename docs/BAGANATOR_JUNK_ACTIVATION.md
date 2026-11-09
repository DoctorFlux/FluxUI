# Baganator junk detector activation

9 November 2026, BAGANATOR-JUNK-ACTIVATION-20261109. The user requested an
addon change after the initial configuration diagnosis. Baganator's selected
detector was RXPGuides in the sampled saved DEFAULT profile. Registering FluxUI
left that valid detector active, so Baganator did not call FluxUI's consumable
junk rules. This follow-up supersedes the manual-selection remedy in the
[initial diagnosis](validation/baganator-junk-detector-2026-11-09.json).

The existing junk bridge now adopts FluxUI once per active Baganator profile.
It retains the previous detector in that profile's additive
`fluxui_junk_detector = { version = 1, previousPlugin = ... }` record. This
intentional first adoption also replaces an initial `none` selection, as required
to activate the requested integration. Subsequent manual detector choices survive
bag reopen and reload. Inactive profiles are untouched; opening bags after a
profile switch adopts an unconfigured profile independently. Existing flat
profiles and the normal DEFAULT fallback are supported.

After a changed selection, the bridge emits Baganator's existing
`SettingChanged("junk_plugin")` notification and requests widgets, searches and
layout refresh through its public refresh API. This updates cached item callbacks,
the ignored-plugin list and category classification. An already selected FluxUI
detector only receives the migration record; no extra refresh is requested.
Missing settings or notification access defer adoption. One existing `BagShow`
callback retries late configuration and later profiles. There is no new frame,
timer, ticker, polling service or Blizzard API usage. Repeated opens after
adoption do not rebuild or override settings.

The junk callback still uses the shared classifier and protection checks.
Consumable rankings, rule switches, manual Useful/Junk marks, manual restock,
gear protection, conjured exceptions, vendor actions and appearance are unchanged.
No external addon code or artwork was copied. Installed Baganator846 reference
files were read only; their exact identities and All Rights Reserved notice are
recorded in the initial diagnosis. The change uses its existing profile and
callback surfaces, matching the other FluxUI Baganator integrations.

The verified external checkpoint preserves 2,389 actual source files and all-ref
Git history; 56 available settings metadata entries were inspected read only.
No unsaved-memory or quiescent settings backup is claimed. No game input, native
reload, settings-file edit, profiler change, manual client synchronization or
publication was performed. The migration changes the in-memory Baganator profile
when this code next initializes in the game.

Desktop checks execute the production bridge with a modeled single selected
detector and cached item callback. Five alternating old/new pairs reproduce
162 failures in the old source and pass all 403 candidate checks. Coverage includes
all five consumable verdict routes, protected slots, RXPGuides/poor-quality/none/
FluxUI initial choices, separate profiles, repeat opens, reload persistence,
missing/late config, unavailable notifications and ordinary refresh reasons.
Existing real tier/junk/seller and metadata checks also run in the full suite.
These fixtures do not execute native Baganator rendering or establish CPU/FPS.
The full runner passes all 269 scripts and 936 Lua syntax files; its source
manifest still matches. The bridge is the sole changed pre-existing Lua source
since the checkpoint. All five existing client copies match through the user's
continuous synchronization; no manual copy was performed.

Native acceptance remains pending through the existing user reproduction route;
no connected Witchcraft/UIForever tool is available. After a normal out-of-combat
reload, open bags and check that Junk detection became FluxUI automatically.
Carry lower and strictly better usable potions, bandages, food and water; verify
the existing rules' coins and category placement, including Useful/restock and
conjured exceptions. Confirm a later manual detector change survives reopen and
reload. Record the actual build, profile, item IDs and any Lua errors. Other
installed clients retain separate pending native results.

- [External checkpoint](validation/baganator-junk-checkpoint-2026-11-09.json)
- [Matched source identities and focused checks](validation/baganator-junk-activation-comparison-2026-11-09.json)
- [Full validation](validation/baganator-junk-activation-full-2026-11-09.json)
- [Source guard and installed copies](validation/baganator-junk-activation-source-guard-2026-11-09.json)

Reproduce the focused checks with `lua tests/baganator_junk_detector.lua`.
