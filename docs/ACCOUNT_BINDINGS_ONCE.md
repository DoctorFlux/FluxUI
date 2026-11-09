# One automatic binding setup per account, 30 October 2026

Current persistence behavior is documented in [the binding rewrite](BINDING_PERSISTENCE_REWRITE.md); the version-5 attempt-only flow below is historical.

The user clarified that Flux should apply its full keybinding template **once
on the first load of the whole account**. Subsequent character logins must not
clear or reapply bindings. The linked
[FluxUI repository](https://github.com/DoctorFlux/FluxUI) has a first-account
defaults gate in the local `main` history; the newer per-character binding
marker and Blizzard Settings reset callbacks had introduced extra automatic
full-keyboard passes.

`PLAYER_LOGIN` prepares an account-wide bootstrap state before the first-account
defaults flag is set. A truly new account starts the binding pass on its first
world entry, on the first available frame of that login. The pass records
`defaultFluxBindingsChecked.account = 5` **before its first native binding
write**. Later reloads, characters and binding-set changes cannot replay it.
An unavailable native set or missing Flux binding registration may retry
without writing. A failed write, verification or save does not cause another
automatic full clear; the user can explicitly run `/fluxdefaults keybinds`.
Overlapping requests during a batch do not queue a second reset. A manual
full reset during first-account startup also consumes the pending automatic
pass, so it cannot run again after reload.

Version-4 successful markers and the older `"pending"` account marker migrate
to version 5 without another reset. Existing accounts with no marker also
migrate without a reset. If an account SavedVariables marker was lost, all four
existing Flux bridge bindings in the active native binding set are independent
evidence that the account was previously configured; the automatic pass then
skips all writes. This cannot recover if both SavedVariables and native
binding data have been lost.

Automatic Blizzard `Settings.Defaulted` and keybinding-category callbacks no
longer reapply Flux keybindings. Explicit Flux keyboard reset commands still
work. The first-account pass is capped at three no-write startup attempts per
login while native bindings become available. The application happens once
for the account, regardless of whether Blizzard's active binding set is
account or character scoped.

The one-time pass retains one native registry scan and at most eight
`SetBinding` calls per frame, with clear/apply/save separated across frames.
Completed accounts do no binding scans or writes. No native frame-time or FPS
claim follows from these desktop bounds.

## Source identity and checks

The dated external `binding-repeat-checkpoint-20261030` preserves the pre-edit
source SHA-256
`cd341ba7a6c08500a21425d77ff6320300da836a1143e2cf5c9581cde0f6ee7a`,
focused test and verified Git history. Candidate source SHA-256 is
`224b5f789d28e0f9c33b0e13256b41082eabd2b2ce5f7c943e6338632ff379de`.
The closed Era account settings snapshot had `accountDefaultsApplied=true`
and an empty binding marker table before this edit; its native account
binding cache was preserved privately outside AddOns and Git. The earlier
Retail snapshot contained all four bridge commands, but the current local
Retail installation had no accessible WTF directory for a fresh comparison.
No private settings were changed.

The [focused regression](../tests/default_flux_grid_bindings.lua) passes 544
checks across five modeled clients, covering first-account startup,
same-login application, old-marker migration, a lost marker with native
bridge keys, failed-save no-replay, late registry availability, overlapping
requests, manual-before-bootstrap and eight-write batches. The
[full desktop report](validation/account-binding-attempt-once-2026-10-30.json) passes
105 scripts and 747 Lua syntax files. Native first-account loading, bridge
keys, hotkey labels, persistence and frame time remain pending on the actual
clients. Desktop tests cannot prove secure input or taint safety.
