# Repository working rules

Follow [CONTRIBUTING.md](CONTRIBUTING.md) and the current user instructions.
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[work log](docs/WORK_LOG.md) and [next session](NEXT_SESSION.md) before editing.

- Work directly on main in this existing `_FluxUI` folder/repository. On 29 October
  2026 the user requested main only and publication of the current local files.
  Do not create other branches unless requested later. Preserve history and newer
  user changes; never force-push or replace local work with an older checkout.
- Publication commits use DoctorFlux
  `<100806234+DoctorFlux@users.noreply.github.com>` for author and committer;
  do not add automated co-author trailers. Preserve third-party licenses.
- On 9 November 2026 the user explicitly requested deleting/recreating the
  GitHub repository with the current local snapshot and no automated contributor
  attribution. That exception permits a fresh root on main in the replacement
  repository; old history stays in the external recovery checkpoint. Continue in
  this existing folder. Never publish Codex/codexCodex or other automated author,
  committer or co-author identities. Keep `core.hooksPath=.githooks`, run
  `python tools/check_publication_identity.py --revision main` before publication,
  and do not bypass the identity hooks. GitHub has no contributor blacklist;
  these checks enforce this repository's publication policy, not GitHub's cache.
- Before runtime changes, verify a dated external source/history checkpoint and
  available on-disk settings. Never place backup archives or private settings in AddOns.
- Preserve features, appearance, cadence, commands, integrations and saved data.
  Record intentional bug fixes, exact source identities and meaningful regressions.
- Use the supplied plan/specifications as requirements, reconciled against current
  behavior. Prefer existing services and small, measured changes over new frameworks.
- Auction callbacks are in scope following the renewed November lag requests.
  Keep guild-bank and void-storage callbacks out of scope until requested.
- Leave WoW in the background. Do not take foreground, mouse, keyboard or clipboard
  control while the user uses the PC. Keep profiling optional and restore preferences.
- Normal warning dismissal, Reconnect and named-character selection are authorized
  for these tests. Verify the client/window first and test sequentially when sessions
  displace each other. Preserve prior diagnostic roots as well as profiler preferences.
- Sandboxed process enumeration may hide desktop clients. Verify host process and
  exact window before concluding WoW exited or reporting a closed-client blocker.
- Desktop tests establish their stated scope only. Record native checks as pending
  when unavailable; never infer FPS, taint safety or pixel parity from mock counts.
- Update the existing continuity records and parity/client/performance ledgers.
  Keep licenses and useful restriction/ownership explanations.
