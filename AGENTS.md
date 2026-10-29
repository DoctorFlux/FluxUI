# Repository working rules

Follow [CONTRIBUTING.md](CONTRIBUTING.md) and the current user instructions.
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[work log](docs/WORK_LOG.md) and [next session](NEXT_SESSION.md) before editing.

- Work in this existing `_FluxUI` folder and current change branch. Leave main
  unchanged until the user authorizes a merge. Preserve unrelated local changes.
- Before runtime changes, verify a dated external source/history checkpoint and
  available on-disk settings. Never place backup archives or private settings in AddOns.
- Preserve features, appearance, cadence, commands, integrations and saved data.
  Record intentional bug fixes, exact source identities and meaningful regressions.
- Use the supplied plan/specifications as requirements, reconciled against current
  behavior. Prefer existing services and small, measured changes over new frameworks.
- Keep auction, guild-bank and void-storage callbacks out of scope until requested.
- Leave WoW in the background. Do not take foreground, mouse, keyboard or clipboard
  control while the user uses the PC. Keep profiling optional and restore preferences.
- Normal warning dismissal, Reconnect and named-character selection are authorized
  for these tests. Verify the client/window first and test sequentially when sessions
  displace each other. Preserve prior diagnostic roots as well as profiler preferences.
- Desktop tests establish their stated scope only. Record native checks as pending
  when unavailable; never infer FPS, taint safety or pixel parity from mock counts.
- Update the existing continuity records and parity/client/performance ledgers.
  Keep licenses and useful restriction/ownership explanations.
