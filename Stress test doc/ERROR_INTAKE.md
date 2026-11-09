# Errors reported during or after this audit

User report USER-001 was received while the audit continued. Continue independent tests
when an error arrives; add it as a new row and retain the exact original stack in
an appropriately private external location if it contains account/character data.

For each report record:

- Stable ID, time, client version/build/interface and addon source hash.
- Exact message/stack and first taint attribution if available; the blocked action
  alone does not identify the first taint source.
- Combat state, world/dungeon/raid, group size, current target/mouseover and held
  Shift/Ctrl keys; last action and expected/actual behavior.
- Enabled integration versions, whether repeatable, and whether it existed before.
- Minimal standalone reproduction if feasible; retain native-only restrictions
  as pending rather than treating an ordinary Lua mock as the secure VM.
- Proposed feature-preserving fix and a regression case. Implementation is later.

| ID | Received | Message | Reproduction | Status |
|---|---|---|---|---|
| USER-001 | 7 November 2026;12:31:53×2,12:32:26×1,13:05:58×2,13:09:17×2,13:17:27×2,13:19:19×2,13:21:18×2 | FrameUtil.lua:427 startAlpha secret-number arithmetic while tainted by _FluxUI; thirteen consolidated reported entries | User confirms Forever and does not know triggering action; exact build/frame/combat/instance unknown | Native reports and conditional desktop reproduction retained; related secret-value paths reviewed; no fix applied |

User errors should supplement the audit rather than replace its remaining scope.

Exact user-supplied stack, repeated twice at the same displayed timestamp:

```text
12:31:53 ...nterface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua:427: attempt to perform arithmetic on field 'startAlpha' (a secret number value, while execution tainted by '_FluxUI')
[C]: ?
[Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua]:427: in function <...nterface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua:410>
```

This is user-observed native runtime evidence, not a native reproduction by the
audit. The user selected Forever when asked about the client. The first taint
source, affected frame, preceding action and combat/instance state remain unknown.
Do not assign the root cause to a particular fade caller from this stack alone.

See [source trace and proposed fix/regressions](security/USER-001-FADE.md) and
[conditional reproduction evidence](security/user-001-fade-results.json).
The user answered "dont know" when asked about the preceding action; do not ask
them to guess or infer that a cast/swing occurred from the shared callback stack.

Follow-ups add12:32:26 once,13:05:58 twice,13:09:17 twice,13:17:27 twice,13:19:19 twice and13:21:18 twice with the identical message/stack.
[Recurrence data](security/secret-value-followup/recurrences.json) preserves all
thirteen consolidated entries. Previously pasted12:32:26 and13:05:58 entries in later
messages are not counted again. Treat these as one recurring signature until evidence distinguishes
frames or first taint sources; the timestamps do not prove a continuously running
fade or uninterrupted errors between reports.
