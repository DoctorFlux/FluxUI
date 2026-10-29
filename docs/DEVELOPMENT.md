# Development tasks

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Continue skipping auction, guild-bank and void-storage callback audits until
   explicitly requested. Do not infer permission from unrelated vendor work.
3. Read [recovery](RECOVERY.md). Eight external verified checkpoints retain source,
   history and private settings. Latest at 11:14 UTC covers baseline 9e17e28; retired
   originals remain outside the addon. Make a fresh checkpoint before another
   runtime batch if source/settings differ.
4. Latest runtime `e02139ab1c6b8099b02fb4506ff150a50d6555ef`, tree
   `0a23a38a04809c0a087089586cb5842496fb5c64`: BUG-007/PERF-004 reuses reliable
   unchanged junk availability, retaining native precedence and existing invalidation.
   Seven client-labeled API fixtures pass 265 checks; five matched pairs show Era cold/reopen
   slot reads 300/5,000 to 200/zero. Full suite: 87 scripts/728 syntax files pass.
   This removes a measured contributor; the user's native Era hitch remains unverified.
5. Next priority: [native vendor-open procedure](VENDOR_OPEN_WORK.md), first on Era,
   then each available target. The user has tested only Era; first/repeated-open
   distinction and automation settings are unknown. Capture exact runtime builds,
   loaded addons, settings and frame-time evidence. Do not sync/launch another
   installation automatically. If native testing is unavailable, independently
   reproduce/measure cold classification, index rebuild, Already Known or layout
   work before selecting another change. None is yet proven to explain the hitch.
6. BUG-001 through BUG-006 and editorial cleanup are already complete in desktop
   scope. Merchant stock reservations are not native acknowledgement. Unchanged-ID
   prices, external stock changes and delayed/rejected requests remain separate
   unmeasured candidates. Event-dispatch mutation is latent with no production
   unsubscribe trigger found; avoid speculative shared-service redesign.
7. Native acceptance remains pending for every target. Follow [client validation](CLIENT_VALIDATION.md)
   and [performance protocol](PERFORMANCE_PROTOCOL.md). Desktop mocks do not certify
   pixels, input, combat/taint, secrets, native CPU or FPS. Modern Wrath fixtures do
   not certify original Wrath 3.3.5.

Reproduction from the addon root:

```powershell
lua tests/vendor_open_work.lua --source tests/fixtures/vendor_open_junk_before.txt --measure
lua tests/vendor_open_work.lua
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure mode exits zero with seven expected failures. Candidate requires
265 passes. Stock/identity controls retain 837 passes. Verify all current Lua hashes
against `docs/validation/vendor-open-full-2026-10-29.json` before reusing its full
baseline (Lua/luac 5.4.6, Python 3.10.6). Some legacy tests need adjacent reference
trees; missing fixtures are not addon failures. Use --sync-docs only alongside a
fresh validation run.

Update status, decisions, work log, affected ledgers and these tasks when completing
a change. No client sync/deployment, push/merge to main, settings reset, second addon,
rename or release is authorized.
