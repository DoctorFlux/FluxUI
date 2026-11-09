# First-load settings completion — 30 October 2026

The first-account and new-character nonbinding defaults now start after
`PLAYER_ENTERING_WORLD`, when native startup has selected the active settings.
An account audit runs after the first pass and checks supported scalar CVars,
including Controls. It reconciles nameplates, Controls, Combat, action bars,
raid frames and chat once before marking the audit done. A new character uses
the client's character-stored CVar scope, including nameplate scalars and
bitfields, plus raid and chat setup. Existing completed accounts without a
pending audit are not changed. Retail and Forever retain the guard against
writing protected native raid CVars.

The audit waits for the existing `BlizzardSettings.Write` safe-write queue.
It makes at most three attempts for a value that reverts, 0.5 seconds apart,
then records failure and names the first unresolved setting. A successful
first-load pass prints one account or character completion message. Manual
full/CVar/category resets print completion once. Progress, chat-class-color
and automatic display-scale messages were removed. Explicit diagnostic
commands and failure messages remain available. The one-time account binding
transaction is separate.

Before edits, the 30 October external checkpoint was saved at
`C:/Users/mario/.codex/visualizations/2026/10/30/01a18c7b-9090-77e3-a5e9-25334cbfe0fe/nonbinding-firstload-checkpoint-20261030`.
It contains source copies and Git history outside AddOns. The pre-edit SHA256
of `FluxDefaultSettings.lua` was
`58e5f4c53c3b487aaf0ec7fbc41d90b161b12a5d5f96c547b01b8801e9f9e326`.
The baseline `BlizzardSettings/Write.lua` SHA256 began `eaebcfc5`; its safe
queue is reused. The nameplate source baseline SHA256 began `fdb469bc`.
The candidate `FluxDefaultSettings.lua` SHA256 is
`0cd7d4e7f4de3b3e9197d56eb393559a5b64a70006a1e7fb7ac21461a904bf89`.
The [validation result](validation/nonbinding-first-load-2026-10-30.json)
records its desktop checks.

The first-load fixture passes 60 checks, including startup Controls revert,
Classic raid CVar reconciliation, character nameplate scope, bounded failure,
deferred completion and no replay on later logins. The binding model passes
507 checks. Full desktop validation passes 106 scripts and 748 Lua syntax
files. These checks do not prove native Settings values, keybinding disk
persistence, Edit Mode taint safety, UI appearance or frame time. Native
first-account and new-character tests on Era, Anniversary, Mists, Retail and
Forever are pending. Mariosuper Era and Pandasans Retail were requested for
native checks, but no WoW process was visible during this work. No window,
input or profiler preferences were changed.

Primary client reference: [Gethe wow-ui-source](https://github.com/Gethe/wow-ui-source).
