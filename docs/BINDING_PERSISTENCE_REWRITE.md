# Native keybinding persistence rewrite, 30 October 2026

The user reported that first-load Flux bindings disappeared after `/reload` and
the game returned to default keys. The closed Retail account snapshot had
`accountDefaultsApplied=true` and binding marker `5`, yet its account binding
cache contained only one modified-click row (29 bytes) and its character
binding cache was empty. An earlier protected account cache had 129 binding
rows (3,044 bytes), including all four reported bridge commands. These are
observations, not a native execution trace.

The previous code called `SaveBindings` from the combat-settings pack during
`PLAYER_LOGIN`, before its deferred keyboard setup. That ordering is consistent
with the nearly empty cache and could overwrite loaded keys. The version-5
marker also meant only that the pass had *started*, so it could falsely claim
completion even when verification or saving failed. This explains the observed
state more directly than another retry or a longer startup timer.

## New binding transaction

1. Combat defaults set modified clicks without saving an unloaded keyboard.
   If they need a separate save later, the addon waits for world entry, a
   nonempty native binding set, no active binding batch and a closed Settings
   panel. The first-account keybinding save includes those modified clicks.
2. A genuinely new account starts on the first world-entry frame. The automatic
   pass selects Blizzard's account binding set with `LoadBindings(1)`, following
   Blizzard's own account-binding selection sequence in
   [Blizzard_Settings.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua).
   An existing version-4/5 marker is inspected once. If all four bridge
   bindings are already present it completes without another clear; a missing
   native set receives one migration repair. Existing unmarked accounts keep
   their current bindings.
3. One registry scan checks Flux command availability and captures the old
   keys. The pass clears all keys, applies the supported template and verifies
   every template command. `SetBinding` is checked as a true/false result, as
   [Blizzard_Keybindings.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua)
   does. Writes remain limited to eight per frame.
4. Only after successful assignment does the addon call `SaveBindings(1)`,
   reload that native saved set with `LoadBindings(1)`, and verify the template
   again. It first records `saved6`. On the next actual login, four restored
   bridge bindings confirm disk persistence and seal account marker `6`. A
   missing disk save receives one bounded repair; a second loss records
   `failed6` without another reset. Action-bar and grid hotkeys refresh after
   each completed native transaction. A failed pre-save pass reloads the old
   set. A failed save/load round trip restores the captured old keys and records `failed6`; it does
   not loop automatically after login. An interrupted unsaved batch resumes
   on the next login, but existing saved bridge keys prevent another clear.

An explicit `/fluxdefaults keybinds` remains available for manual repair.
Blizzard Settings reset callbacks still do not reapply the Flux keyboard.
This is a source-level transaction and desktop simulation; in-game disk
persistence, secure key presses, hotkey labels, taint and frame time remain
pending native verification.

## Evidence

The external dated `binding-persistence-checkpoint-20261030` preserves the
pre-edit source SHA-256
`224b5f789d28e0f9c33b0e13256b41082eabd2b2ce5f7c943e6338632ff379de`,
the focused tests, Git history and private Retail account/character binding
cache and settings files outside AddOns and Git. Candidate source SHA-256 is
`5750d2877c03f6cd99ec0a9b6fa3973246eb18239da27801369131e15f5f1d60`.

The [focused production-source regression](../tests/default_flux_grid_bindings.lua)
passes 501 checks across Retail, Forever, Era, Anniversary and MoP models. It
simulates native account/character saved sets, first-load save and reload,
version-5 empty-cache repair, existing-key preservation, missing command,
failed or nil native writes, failed save/load, native set changes, interrupted
setup, one reload-time disk repair, rollback and the eight-write frame bound. The
[full desktop report](validation/binding-persistence-rewrite-2026-10-30.json)
passes 105 scripts and 747 Lua syntax files. No native performance samples
were collected.
