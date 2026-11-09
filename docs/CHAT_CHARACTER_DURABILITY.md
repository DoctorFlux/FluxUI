# Chat character durability percentage — 31 October 2026

## Teleport/load-screen follow-up

The user then reported that the percentage disappears after teleporting
through a loading screen. `PLAYER_ENTERING_WORLD` could scan while equipped
durability was temporarily unavailable; the painter hid the label, and the
existing durability/alert events did not necessarily supply another refresh.

World entry now retains the last visible percentage during an empty read.
Player equipment/inventory changes refresh it when gear data arrives. If no
event does, one 0.5-second retry runs; a final retry 1.5 seconds later clears
the label only if durability is still unreadable. A serial token prevents a
retry from an older world entry changing a newer result. A successful read
stops the retry chain. The existing 1–18 slot calculation, text/color,
button geometry, secure clicks and saved options stay the same.

Pre-follow-up source SHA-256: `cdc441443ce6a2e226f7e9a07a2bf0ca2923d113f435e8c023d6fdb2c461168a`.
Follow-up source SHA-256: `0f639f3d71cd2fc4095daaeb96e3f0e69ddf728ff1915c486ddfecac6928e830`.
The focused fixture now models missing gear immediately after world entry,
return on the first timer, return via player inventory event after the first
retry, no-data expiry, non-player event filtering and overlapping teleports.
The full desktop runner passes **112 tests and 757 Lua syntax files**:
[report](validation/chat-character-durability-2026-10-31.json).

## Initial full-durability fix

The user reported no durability percentage under the character button beside
chat. The loaded `Other/FluxChatColumnMicros.lua` painter hid the label whenever
the lowest equipped value was at least 100. Fully repaired gear therefore
produced an invisible percentage even though the option describes a percentage
under the button.

The painter now records whether any equipped slot supplies readable current
and maximum durability. It shows the existing lowest-slot percentage and
color when one does, including `100%`; it hides the label when none does.
At this stage the existing inventory/world events, 1–18 slot scan,
secret-value guard, button geometry, secure click path, option and saved data
remained unchanged. The follow-up above adds player inventory/equipment
events and a bounded world-entry retry.

Source baseline: main `0c197f517c8d0f1cd0f66bdf0152b7a0431a6138`,
`Other/FluxChatColumnMicros.lua` normalized SHA-256
`470ff6192b5a4f512aa673d4c27949ac0f2b28ebcd8044fbf67412d6315c1919`.
Initial candidate normalized SHA-256:
`cdc441443ce6a2e226f7e9a07a2bf0ca2923d113f435e8c023d6fdb2c461168a`.
The dated external `checkpoint-2026-10-29` source/history/settings tree was
present outside AddOns. Its `.git` contents could not be opened from this
sandbox; the repository work log records prior verified source/history
checkpoints through 30 October. Retail on-disk WTF settings were inspected
read-only; no explicit `chat_btn_durability` override was present in the
account SavedVariables. No settings or client state were changed.

`lua tests/chat_character_durability.lua` executes the production painter
with full, 75%, 0%, restricted and absent readings. It passes; the old
`lowest >= 100` condition fails the full-gear case. The full desktop runner
passes **112 tests and 757 Lua syntax files**, zero failures:
[report](validation/chat-character-durability-2026-10-31.json). This includes
concurrent cast-bar working-tree edits, which were left untouched.
The source-derived reference pages and verification index were refreshed;
`validate_docs.py` passes for the current workspace.

Native verification is pending on Retail, Forever, Era, Anniversary and MoP:
check repaired/damaged/no-readable equipment, teleport/load-screen recovery,
event refresh, text position and color, secure clicks, combat taint, and
matched frame-time measurements.
Desktop counts do not establish native pixels, taint safety or FPS.
