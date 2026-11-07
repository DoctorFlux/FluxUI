# Reproduce this audit without editing addon code

Use the existing repository on `main`. Read `README.md`, `REQUIREMENTS.md`,
`SOURCES.md`, `SCENARIOS.md` and `CONTINUITY.md` first. Keep the game in the
background and issue no game, keyboard, mouse, clipboard or profiler actions.
Do not run a sync script, doc generator, `--sync-docs`, commit or deployment as
part of these checks. Python 3.10 and Lua/luac 5.4.6 were available for this run.

From the addon root in PowerShell:

```powershell
python -B 'Stress test doc/run_canonical_snapshot.py'
python -B 'Stress test doc/build_scope.py'
python -B 'Stress test doc/input/run_input_stress.py'
python -B 'Stress test doc/security/run_security.py'
python -B 'Stress test doc/performance/run_performance.py'
lua 'Stress test doc/input/instance_gates.lua.txt'
python -B 'Stress test doc/performance/extra_instance_mount.py'
python -B 'Stress test doc/security/run_surface_lifecycle.py'
python -B 'Stress test doc/security/run_user_001.py'
python -B 'Stress test doc/build_ledgers.py'
python -B docs/tools/validate_docs.py
python -B 'Stress test doc/check_preservation.py'
python -B 'Stress test doc/validate_audit.py'
```

Run sequentially if you want interpretable desktop elapsed times; elapsed process
time is still not native addon CPU or FPS. Every script receives an independent
process/model; errors should be retained and testing should continue. Individual
input scripts also run with `lua 'Stress test doc/input/<name>.lua.txt'`.

Input scripts for the two reproduced bugs deliberately exit nonzero when the
expectation is violated. Their runner labels those exits `FINDING`, preserving
the failed expectations and raw logs. Security/performance experiments can exit
zero while confirming a known bad observation: read their findings/status fields,
not only process exit codes. Do not convert a finding to a pass by weakening its
expectation. A future fix must reverse the bad observation and retain controls.

Some legacy tests require the sibling `__AddonsForRef` trees and backup fixtures.
They are not included in this documentation folder. Missing fixtures are test
dependency errors, not confirmed addon regressions. `SOURCES.md` records which
current remote files were compared and which other fixtures remain dated.

Rerunning these commands replaces evidence files inside this folder. Preserve a
prior run externally or choose a new dated report directory first if you need an
immutable comparison. Do not recreate `baseline.json` after a code change and
then claim that the original source passed. Per-run production hashes and the
external source checkpoint identify this run's bytes.

`check_preservation.py` compares 1,778 pre-existing files and separately reports
runtime/test source, documentation drift and 45 private settings identities.
It writes only its public summary here. Other chats and an active game can change
documentation or settings independently; retain that evidence and never revert
their work. Source drift requires a fresh affected-test run before reusing results.

This audit retains `existing-suite.json` for the initial source,
`existing-suite-final.json` for the intermediate full rerun, and
`existing-suite-latest.json` for the last full run after four concurrent Lua changes.
The report/validator selects latest when present. `run_canonical_snapshot.py`
calls the original runner without changing it, while recording all885 Lua hashes
before/after. Preserve old latest evidence externally before refreshing on a
later revision; the command replaces only its named evidence files here.

New user errors go through `ERROR_INTAKE.md`. Keep account/character settings and
private raw logs outside AddOns. Fix proposals belong in the findings backlog;
implementation needs the later fix request described by the user.
