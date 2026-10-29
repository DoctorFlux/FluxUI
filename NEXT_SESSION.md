# Resume FluxUI modernization

Read `AGENTS.md`, `docs/STATUS.md`, `docs/DECISIONS.md`, `docs/WORK_LOG.md`, then the
relevant feature/ownership/client/performance ledgers. Stay in this existing addon.

1. Inspect `git status --short --branch`, HEAD, `main` and remotes. Work on
   `codex/modernization-audit-20261029`; main must remain untouched. Preserve the
   original untracked `FluxUI_Sync_Log.txt`, ignored work and any newer user edits.
2. Read `docs/RECOVERY.md`. The external checkpoint covers all original files,
   history and relevant settings. Freeze a new dated checkpoint before another
   runtime batch if the current files/settings differ. Do not overwrite the original.
3. Candidate runtime commit is `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`.
   BUG-001/PERF-001 is fixed and desktop-tested; do not reapply it. Native status
   remains pending. The broader plan is `docs/MODERNIZATION_PLAN.md`.
4. Next bounded investigation: inspect `Core/Engine/Events.lua` dispatch/Unregister
   and `rg -n 'Events\.Unregister' Core Inventory Bars UnitFrames`. Build a minimal
   production-dispatch replay where a handler removes itself while later handlers
   remain. Trace real consumers before deciding dispatch semantics. Record baseline,
   current failure and resource cost; implement separately only if justified.
5. Native checks can run independently: follow `docs/CLIENT_VALIDATION.md` and
   `docs/PERFORMANCE_PROTOCOL.md`, recording exact build, settings, addons, screenshots
   and alternating captures. Never use mocked results as native acceptance or launch
   a second working addon. Local Blizzard reference versions are older than installs.

Reproduce the current currency regression and complete validation from the root:

```powershell
lua tests/currency_provider_handoff.lua --source tests/fixtures/currency_provider_before.txt --measure
lua tests/currency_provider_handoff.lua
lua tests/late_inventory.lua
python tests/run_validation.py --output docs/validation/next-session.json
python -B docs/tools/validate_docs.py
```

Baseline replay intentionally prints 50 failures but exits zero with `--measure`;
candidate requires 150 checks / zero failures. Recorded full suite: 82 tests and
723 Lua syntax files, zero failures. Lua/luac 5.4.6 and Python 3.10.6 were used.
Some original tests depend on adjacent reference/backup trees; a missing fixture
is not an addon failure. Rebuild indexes with `python -B docs/tools/build_reference.py`
after source changes; use runner `--sync-docs` only with a fresh actual run.

Before stopping, update status, decisions, affected ledgers, raw evidence, work log
and this file. State exactly what remains unverified. No automatic sync to other
clients, merge to main, settings reset or release is authorized by this handoff.
