# Default Flux grid bindings, 30 October 2026

Current persistence behavior is documented in [the binding rewrite](BINDING_PERSISTENCE_REWRITE.md); the version-5 attempt-only flow below is historical.

The current [account-wide bootstrap](ACCOUNT_BINDINGS_ONCE.md) applies the
keyboard template automatically only once on the first account load. The
per-character repair history below is superseded.

The later [full binding reset](FULL_BINDING_RESET.md) supersedes this
missing-key seed. The user's explicit request now clears the active native
binding set and reapplies the entire supported Flux keyboard template once
per scope. Version 4 records completion after a successful save; subsequent
logins leave the set alone. The earlier behavior and tests below are retained
as history, not as the current startup policy.

## Persistence follow-up

The user reported that bridge keys still disappeared after the first reload.
The full first-account keybind batch could finish after world entry: its queued
seed then wrote a permanent version-2 marker before the later native binding
set verification. Subsequent logins skipped the repair. The current path keeps
the post-batch and post-combat seed provisional, then checks the active set
later in that login. Version 3 also records the Flux commands that were saved
at their default keys and stays pending until a following login finds them
still bound. If native binding loading loses one, the addon repairs an empty
or known stock key, saves again, and waits for another login. Once verified,
later intentional unbinds are preserved. Old version-2 markers are rechecked.

Gethe's local Retail `Blizzard_Settings_Shared/Blizzard_Settings.lua`
(`3ce23f05b171c12a1a3a71596892def5bc0ee7153bedabc00d153f306d1d85a6`)
uses `LoadBindings` and `SaveBindings` when selecting account or character
sets. This is the specific startup interaction that the pending marker covers.
The external `binding-persistence-checkpoint-20261030` contains the pre-edit
`FluxDefaultSettings.lua` (`15248e8060ecd6f07bce2255c1e9a23fc766165b3b5ea4ec84b88007571d1396`)
and verified Git history. The candidate source SHA-256 is
`5e1e78b8c04d60aac2f6c669068bc4a1196f8daf5830bb0d6ba85a7eaeaff933`.
Available WTF settings were inspected read-only; no game binding cache was
edited. The expanded [binding regression](../tests/default_flux_grid_bindings.lua)
passes 37 checks, including a lost key across two simulated reloads. The
[desktop report](validation/first-load-binding-persistence-2026-10-30.json)
passes 105 scripts and 747 syntax files. Native first-load, reload, account
and character sets, button clicks, labels, and combat remain pending.

## Report and fix

The user reported that first-login defaults left Hearthstone, class teleport,
smart mount and vendor mount grid keys unbound. The template already assigns
`7`, `8`, `Y` and `6` respectively, and the first-account route invokes the
full template. The later new-character route skipped bindings entirely. A
read-only check of the Retail on-disk binding caches found one file containing
all four Flux commands and another containing none; `Y`, `6`, `7` and `8` were
unbound in the latter. These files may lag unsaved in-game state.

The user then reported that the keys appeared only after another reload, and
subsequently that the defaults were not assigning them at all. The first repair
checked at `PLAYER_LOGIN` and wrote a permanent marker immediately. That could
skip a later native binding-set selection in the same login; it also treated
Blizzard's stock `TOGGLEACHIEVEMENT` on `Y` as a custom assignment.

The user also reported that hotkey labels were absent on both grids. The live
Extra Button engine registers grid buttons in `Flux.EBS.buttons`, while the
shared hotkey refresh still walked `FluxButtonEvents.ActiveButtons` from the
unused legacy engine. Its bulk module list also contained nil holes, making
`#modules` stop before some loaded combat modules.

At `PLAYER_LOGIN`, account setup queues the binding check for the first
`PLAYER_ENTERING_WORLD`. `EnsureDefaultFluxBindings` writes missing Flux
template commands when their target key is free or holds the known stock action
for `Y`/`6`/`7`/`8`. A command already bound elsewhere and a custom target
action are preserved. The active set is saved and its secure Extra Button
overrides refresh. A second check shortly afterward catches late binding-set
selection in the **same login**. Version `3` remains pending for cross-login
verification as described above. Old `true` and version-`2` markers are
rechecked. Combat and the full first-account template batch defer the seed;
unavailable sets and failed saves get bounded in-login retries. Later
intentional unbinds remain untouched after version `3` is confirmed.

The named bindings are declared in [Bindings.xml](../Bindings.xml); the live
button owners install `SetOverrideBindingClick` in
[Mount](../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua),
[Hearthstone](../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua) and
[TeleportPortal](../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua).
The existing [HotkeyUtil](../ExtraButtonSystem/Shared/HotkeyUtil.lua) refreshes
those owners after a bulk/default binding change. It now walks the current EBS
button registry for label refresh, retains the legacy fallback, and builds a
dense list of loaded modules so combat and noncombat secure click routes both
refresh. No native API is replaced.

## Source identity and validation

Baseline main is `efee8006391876687898f7c90f6e0cbd8c22fb1a`, with the
previous local defaults candidate SHA-256
`9d8a5831f81392575f9d2a6690684264a6c809f95558c0a94dc3cbc3ac20ec52`.
The first binding candidate SHA-256 was
`50c52f724337c5e3c87a265e0edced4d97c01e4183d302958afea978d3d55d5c`;
the same-login candidate SHA-256 is
`d77cf8b3a67391023a2e6b463c331d35ce43cf33eb8af658b65aef743a86c12a`.
The HotkeyUtil baseline/candidate SHA-256 values are
`8b7ba726e22842fe98c2fd5ebb2938a52a17ba008f24447fcabb1810d8b48a6c`
and `cd00b19b51c9411fa27f2e06805c45d5dae28e2d2b614b88a2e374c1237e210c`.
Two external dated checkpoints preserve the preceding source, HotkeyUtil source
and verified Git history. On-disk WTF was inspected read-only; no game settings
or binding caches were edited directly. The local Gethe Retail source shows
Blizzard Settings [loading and saving account/character binding sets](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings/Blizzard_Settings.lua);
its specific timing relative to this addon remains a native acceptance check.

The [focused regression](../tests/default_flux_grid_bindings.lua) passes 29
checks: all four reported commands and another free Flux key, existing custom
keys and alternate bindings, account/character scope, combat and bulk deferral,
failed-save retry, unavailable binding set, stock `Y`, old-marker upgrade and
provisional/final same-login checks. Prior first-login and binding regressions
pass 42 and 110 checks. The [grid hotkey regression](../tests/grid_hotkey_refresh.lua)
passes 7 checks for live EBS noncombat/combat labels, secure owner refresh and
legacy fallback. The [full desktop report](validation/default-grid-bindings-same-login-2026-10-30.json)
passes 103 scripts and 745 Lua syntax files. Desktop checks establish the
logic and source wiring, not native secure clicks.

Native first-load acceptance on the affected character, each client build and
binding set, actual key clicks, UI labels, combat/taint and late button creation
remain pending. A new addon version requires one client reload to load its code;
the binding setup itself should complete during that login without a second
reload. A custom action occupying a target key remains intact. No timing or FPS
claim is made.
