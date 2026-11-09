# First-login defaults, 30 October 2026

Current persistence behavior is documented in [the binding rewrite](BINDING_PERSISTENCE_REWRITE.md); the version-5 attempt-only flow below is historical.

The later [account-wide binding correction](ACCOUNT_BINDINGS_ONCE.md)
supersedes this page's binding behavior: first-account setup defers the
keyboard pass until world entry and completes it once for the whole account.
New characters do not run an automatic binding reset. The CVar scope behavior
below remains current.

## Trigger and expected result

Before this change, a new character on an account already marked configured ran
only raid-frame and chat-color setup. Client-stored character CVars in the Flux
default table and nameplate bitfields could therefore retain Blizzard values. On a
new character, those character-scoped recommendations now apply once. Account CVars
and the existing binding set are left alone. The first account login still runs
the full setup, including its existing keyboard template. A failed or deferred
character CVar job no longer marks the character seen before successful
completion; a later login can retry.

The client supplies scope through `C_CVar.GetCVarInfo` or legacy `GetCVarInfo`.
Dynamic UI scale and camera maximum are resolved on the new-character path
before scope filtering. Unknown or missing scope is skipped. Character writes use the existing
`BlizzardSettings.Write.Run` queue for combat, Edit Mode and open Settings, then
`Write.CVar`/`Write.Bit` for the supported client route. The full nameplate pack
is unchanged; its bitfield helper accepts a filter for the new-character path.
Retail/Forever compact raid CVar restrictions in `Write.CVar` remain in force.
AceDB `profile`, `char` and `global` defaults remain owned by AceDB.
The later [grid binding repair](DEFAULT_GRID_BINDINGS.md) supplements missing
Flux commands without replaying the full keyboard template on an existing
character.

## Source identity and reference

Baseline main `efee8006391876687898f7c90f6e0cbd8c22fb1a`. Baseline
`FluxDefaultSettings.lua` SHA-256 `9956821a69cecd565125ce0ab227b74cfc1d9fee0da918c3df34e3444dce7133`;
candidate source SHA-256 `9d8a5831f81392575f9d2a6690684264a6c809f95558c0a94dc3cbc3ac20ec52`.
Candidate `BlizzardSettings/Nameplates.lua` SHA-256
`8b464c2662a93c23e0d020b74ce0a1f43e1cb70659e1aee44c5e821c52868fed`.
The external `defaults-checkpoint-20261030` holds baseline source and a verified
Git history bundle outside AddOns. On-disk WTF availability was checked; no
settings were changed or copied into the repository.

The requested [Gethe UI source](https://github.com/Gethe/wow-ui-source) is a
rolling mirror. Its 30 October branch `version.txt` files report
[Live 12.1.5.70575](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/version.txt),
[Forever 1.60.1.70532](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/version.txt),
[Era 1.15.9.70576](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/version.txt),
[Anniversary 2.5.6.70577](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_anniversary/version.txt)
and [MoP 5.5.4.70631](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/version.txt).
Live [Controls](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Controls.lua)
and [compact raid profiles](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_CUFProfiles/Blizzard_CompactUnitFrameProfiles.lua)
confirm that native Settings/CUF callbacks own their UI updates. These upstream
versions do not establish this addon's native behavior on every installed client.

## Validation and limits

The [focused test](../tests/defaults_first_login.lua) runs 42 checks against
production new-character and nameplate code: modern table, tuple and legacy
CVarInfo shapes; account/missing scope exclusions; character bitfields; retained
raid/chat calls; first-account pack dispatch and failed-setup retry; AceDB
profile, character and global defaults; dynamic scale and camera values. Existing [binding regression](../tests/binding_respec_regression.lua)
passes 110 checks, including custom F5 preservation. The current
[full desktop report](validation/defaults-first-login-2026-10-30.json) passes
101 scripts and 743 Lua syntax files. The previously untracked obsolete
`tests/minecraft_appearance.lua` was removed at the user's direction before
that passing run.

Native first-account and fresh-character setup, exact CVar scope/values on each
client, deferred queue completion, keybind persistence, Settings pages, combat,
taint and pixels remain pending. No WoW process, setting or profiler was touched.
The existing three-CVar post-login sentinel still requires four mismatches;
it cannot repair a later client reset. A separate fix needs a non-destructive
policy for customized values. No performance measurement or FPS claim is made.
