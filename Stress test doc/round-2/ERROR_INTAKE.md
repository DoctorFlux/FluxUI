# Error intake for follow-up

Keep this round's source identity and error reports separate from earlier
captures. Add new logs without treating repeated pasted timestamps as new events.
Do not guess the caller from a shared native error sink.

| Field | Record when known |
|---|---|
| Exact error and full stack | Preserve field names, native file/line and addon attribution. |
| Client/build | Era, Anniversary, Retail live or Forever plus actual GetBuildInfo when supplied. A source pin alone is not a runtime capture. |
| Loaded revision | Source hash/checkpoint and whether a normal reload loaded the changed files. |
| Action/context | Press/release order, hovered UI/unit, target, combat transition, world/dungeon/raid, panel visibility and active feature. Unknown is valid. |
| Timing | Distinct timestamps and multiplicity; keep duplicate paste accounting explicit. |
| Candidate finding | Link a qualified R2 ID or create a new entry only after tracing/proof. |
| Evidence class | Native observed error, strict protected model, opaque-return model, source-only risk or measured work count. |
| Next safe check | Smallest reproduction/trace that separates competing causes without losing features or altering native APIs. |

The prior USER-001 record consolidates 13 Forever `FrameUtil.lua:427/startAlpha`
entries at seven timestamps through 13:21:18. The preceding action is unknown;
do not ask the user to invent it. Prior public fade fixes passed their desktop
models, but native caller attribution and recurrence remain unconfirmed.
No new native error was observed during this simulation-only round.
