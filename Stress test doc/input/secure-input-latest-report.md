# Targeted secure-input refresh after concurrent source changes

The addon manager and existing utility fixture changed outside this audit after the original input report. The original `input-stress-results.json` and all original raw logs are preserved. Only `secure_input_stress.lua.txt` was rerun, three times, against the newer consumed files. Other harnesses were not rerun by this refresh.

The [new results](secure-input-latest-results.json) and `secure-input-latest-run-1.txt` through `secure-input-latest-run-3.txt` show **201,401 assertions passing per repetition**, **604,203 across three repetitions**, with identical semantic counters. Each repetition retains 4,096 chord selections and 12,288 press/release pairs per client model: 20,480 selections and 61,440 pairs across the five models. Repeating these definitions does not triple unique coverage. The newer existing fixture adds ranked/bare-spell/item cases, so its assertion total differs from the earlier 197,024-check result.

| Consumed file changed since original record | Latest byte SHA-256 |
|---|---|
| `ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua` | `01aa78a28e9ceee770e9c5363206f06fe6dd30c73539a322ca3ec59683e9ee10` |
| `tests/utility_secure_input.lua` | `8d01153c8ac3f883b717b92ead2149f9fb2d66a61a750eab9dc78ebaeb63765d` |

Before/after byte hashes match for the original harness, fixture, all six consumed addon source modules and all ten consumed local Blizzard dispatcher/slash-handler files. The original fixture injection anchor remains unique, and the unchanged harness verifies it before loading the extended fixture. No harness adaptation or addon edit was necessary. Harness syntax passes.

This is acceptance only for the precise targeted desktop input model and consumed identities in the new JSON. It neither replaces earlier results for other modules nor certifies the whole addon at its latest state. Further concurrent edits require their own identity check. It does not prove native secure execution, taint propagation, real secret values, pixels, actual input timing or CPU/FPS. This audit did not modify addon code/existing tests, write settings/profiler preferences or control the game.
