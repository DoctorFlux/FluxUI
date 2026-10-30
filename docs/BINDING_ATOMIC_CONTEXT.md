# One-pass native binding transaction — 30 October 2026

The user observed `Applying keybindings...` followed by `native assignment or
verification failed`, with no bindings retained after reload. The prior
transaction spread clearing and assignment over frames and treated any false or
nil `SetBinding` result as fatal, even if the native key had the requested
action. It also omitted the action-specific binding context used by Blizzard's
[Retail keybinding UI](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua).
That is a source-level explanation for the reported generic failure, not a
captured native failure trace.

The first-account pass now clears all registered keys, assigns every supported
template key, checks the native action for every key, saves the account binding
set, loads it and checks again in the same call. On modern clients it passes
`C_KeyBindings.GetBindingContextForAction(action)` to the native binding APIs;
older clients use their existing two-argument calls. Incorrect keys get up to
three immediate attempts, with no polling or repeat timer. A failure reports
the exact unresolved key and action and restores the old native set. The
account marker still prevents automatic replay after a new failed attempt; a
verified save is confirmed once on the next actual login. An existing
`failed6` account gets one corrected-context attempt, and an older completed
version-6 account gets one read-only bridge check before being accepted or
repaired. An explicit `/fluxdefaults keybinds` remains the manual repair
command.

This intentionally concentrates roughly one registry scan, one clear pass,
one template pass and one save/load round trip into the first account login.
It has no recurring update loop. Native frame time and FPS have not been
measured, so a first-login hitch cannot be ruled out.

The dated external checkpoint
`binding-native-failure-checkpoint-20261030` preserves pre-edit source and
history outside AddOns. Baseline source SHA-256:
`5750d2877c03f6cd99ec0a9b6fa3973246eb18239da27801369131e15f5f1d60`.
Candidate source SHA-256:
`58e5f4c53c3b487aaf0ec7fbc41d90b161b12a5d5f96c547b01b8801e9f9e326`.
The [focused production-source model](../tests/default_flux_grid_bindings.lua)
passes 507 checks across Retail, Forever, Era, Anniversary and MoP, including
context-required modern writes, transient rejection, nil successful returns,
one-call save, old failure/version-6 migration, reload persistence and rollback. The
[full desktop report](validation/binding-atomic-context-2026-10-30.json) passes
105 scripts and 747 Lua syntax files.

Native validation on Mariosuper (Classic Era) and Pandasans (Retail) remains
pending: the workspace process listing exposed no WoW process or window.
The client `WTF` folders were initially absent, then briefly appeared; a
read-only Era snapshot had 117 account binding rows, four bridge rows and
marker `6`, while the named character cache was empty. These changing files
do not establish the in-memory client state or a post-change reload. The user
asked that WoW remain in the background, so no foreground input was attempted.
Verify each client
and window before any later native test. Confirm the exact bridge keys,
combat/noncombat grid labels, account binding selection, reload persistence,
no automatic second pass, taint and first-login frame time.
