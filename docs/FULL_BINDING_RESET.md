# Full first-load binding reset, 30 October 2026

Current persistence behavior is documented in [the binding rewrite](BINDING_PERSISTENCE_REWRITE.md); the version-5 attempt-only flow below is historical.

The latest [account-wide correction](ACCOUNT_BINDINGS_ONCE.md) supersedes the
per-active-set automatic bootstrap described below. The full clear/template
operation is now automatic only on the first account load; character logins
and Blizzard Settings reset callbacks do not replay it. The earlier behavior
is retained here as change history.

## One-time completion and bounded frame work

The user clarified that the reset must run **once**. A successful full
template check and `SaveBindings` now record version `4` immediately for the
active account or character binding set. Later logins return before scanning
bindings or writing keys, and `UPDATE_BINDINGS` no longer replays the reset.
An older version-4 pending marker means that the earlier build already saved
the template; it is accepted without another clear. Failed or unavailable
sets may retry until one successful save, with at most three attempts per
scope in a login. Explicit `/fluxdefaults keybinds` remains a separate user
command.

The clear and apply phases use one native registry scan and at most eight
`SetBinding` calls in any frame. A zero-delay boundary separates the phases
and defers saving/refresh until after the final apply batch. Once a pass starts,
its completion callback owns the result without a polling timer. This bounds
per-frame work in the desktop model; native frame time and FPS remain
unmeasured. The current source SHA-256 is
`9805322a153f31730e45db69301832f48ad26320c0c2cbf0dda9329d6ecef2b6`.
The external `binding-once-checkpoint-20261030` holds the preceding source
(`b17c5521cc97437c013c2835691b820fa5a5b9a18a6b44d5314998c8ce6485d2`),
focused test, verified Git history and the available binding/Flux settings
from the closed Retail client. Private settings remain outside AddOns and Git.

The user reported that the earlier missing-key seed still did not assign
bindings. They explicitly requested a complete reset: unbind every key in the
active native binding set, then apply the Flux keyboard template on all
clients. This request supersedes the repository's general instruction against
forced resets for this specific first-load repair. It intentionally replaces
custom keys in a scope that has not yet completed this version-4 setup.

`ApplyKeybinds` now enumerates native binding actions and both key slots,
deduplicates every bound key, clears them in batches, then applies every
template assignment supported by that client's binding registry. It checks
the whole supported template and active binding set before `SaveBindings`.
The Flux commands declared in `Bindings.xml` must all be registered before any
clear begins. An unavailable registry, combat, failed assignment, failed
save, or binding-set switch leaves completion unmarked for a bounded retry.

First-account scalar setup defers its keyboard pass until world entry, when
the client has selected the active native binding set. That world entry
schedules the full pass for the active account or character binding set even
when earlier setup markers said complete. It also runs for clients where the
first-account setup flag was not recorded. Version 4 completes immediately
after one successful active-set save, and later user binding edits are left
alone. A distinct
account or character binding set receives its own setup pass when active.
Native action commands absent on a client are skipped; all Flux XML commands
are required.

## Source identity and validation

The external dated checkpoint `full-binding-reset-checkpoint-20261030`
preserves the pre-edit `FluxDefaultSettings.lua` with SHA-256
`5e1e78b8c04d60aac2f6c669068bc4a1196f8daf5830bb0d6ba85a7eaeaff933`,
the prior focused test and a verified Git history bundle. Its earlier candidate
`FluxDefaultSettings.lua` SHA-256 is
`b17c5521cc97437c013c2835691b820fa5a5b9a18a6b44d5314998c8ce6485d2`.
The local Gethe Retail
[binding-set implementation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua)
loads and saves account/character sets. The inspected Retail WTF tree had
only 11 AddOns.txt files and no binding cache to back up; no private settings
or game process was changed.

The [focused test](../tests/default_flux_grid_bindings.lua) passes 521 checks
across five modeled clients, including clear-before-set order, the supported
template, one registry scan, eight-write frame batches, completed-scope
no-scan/no-write behavior, account/character scope, combat, failed saves and
missing Flux registration. The existing binding/Respec regression passes 110
checks. The [current desktop report](validation/full-binding-reset-once-2026-10-30.json)
passes 105 scripts and 747 Lua syntax files. The preceding
[full-reset report](validation/full-binding-reset-2026-10-30.json) records the
superseded cross-login approach. Native first-load/reload, real key presses,
grid hotkey labels, combat, persistence and frame time remain pending on each
client. Desktop tests cannot prove native secure input, taint safety or FPS.
