# Development status and next tasks

Read CONTRIBUTING.md, docs/STATUS.md, docs/DECISIONS.md and docs/WORK_LOG.md, then relevant
requirements/ownership/client/performance records. Stay in this existing addon.

1. Inspect status/HEAD/main/remotes. Continue on the current change branch;
   main stays `7436820453d2248c84c99fff71507553efc47c19`. Preserve any newer user changes. The former sync log and local backup trees
   are retained in the external recovery checkpoint.
2. User explicitly deferred auction, guild-bank and void-storage callback audits.
   Continue other work until directed otherwise. Keep those domains deferred until requested.
3. Read docs/RECOVERY.md. Five external verified checkpoints cover the original
   source and each runtime batch. Latest at 10:19 UTC preserves baseline f57fc79,
   actual ignored/untracked files/history and 403 private WTF files while WoW closed.
   Preserve a fresh checkpoint if source/settings differ before the next edits.
4. Latest runtime `19c40a0c84212b24fdf221a9653a4116d32f9020`, tree
   `92973edadfdd5ebfc5935621bc2b77f1e0655066`: BUG-004/PERF-003 stops disabled Windows
   discovery/polling and public-disable gestures. All 220 targeted checks pass after
   108 baseline failures. Five matched pairs/100 cycles preserve enabled resources
   and scales. BUG-001/002/003 are already fixed; do not reapply them.
5. Next independent candidate: trace vendor/restock operation-time slot/protection
   validation or another active feature outside excluded domains. This is an audit
   target, not a claimed defect. Read relevant supplied specs/tests, establish an
   actual production-code reproduction and matched baseline before choosing a fix.
6. Event-dispatch mutation remains a documented latent API defect with no production
   unsubscribe trigger found. Core.Module generic teardown/cancellation likewise
   needs actual consumers. Do not redesign either shared service speculatively.
7. Native parity/performance remains pending for every target. Follow
   docs/CLIENT_VALIDATION.md, docs/PERFORMANCE_PROTOCOL.md and
   docs/WINDOW_MOVER_LIFECYCLE.md for precise Windows tests and matched captures.
   Desktop checks do not certify native rendering, input, secure VM, taint or FPS.

Reproduction from this addon root:

```powershell
lua tests/window_mover_disabled.lua --baseline --measure
lua tests/window_mover_disabled.lua
lua WindowMover/_tmp_charactercombatsmoke.lua
python tests/run_validation.py --output docs/validation/next-session.json
python -B docs/tools/validate_docs.py
```

Baseline measure mode deliberately exits zero with 108 expected failures; candidate
requires all 220 checks. Latest complete suite: 85 scripts/726 syntax files, zero
failures, Lua/luac 5.4.6 and Python 3.10.6. Verify its hash manifest against current
bytes before reusing the baseline. Some legacy tests need adjacent reference trees;
missing fixtures are not addon failures. Regenerate indexes with
`python -B docs/tools/build_reference.py` after source changes; use --sync-docs only
with a fresh validation run.

Update status, decisions, work log, affected ledgers/raw evidence and these tasks
when completing a change. No sync to other clients, push/merge to main, settings reset,
second addon, rename or release is authorized.

The editorial cleanup retires obsolete workflow files and keeps ordinary contribution
rules/tasks here. Original files are recoverable externally. All 39 changed Lua files retain identical
executable tokens and strings. Latest validation is in
`docs/validation/editorial-cleanup-full-2026-10-29.json`; current source references
and all six CSV ledgers are refreshed.
