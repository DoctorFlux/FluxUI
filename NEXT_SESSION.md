# Resume FluxUI modernization

Read `AGENTS.md`, `docs/STATUS.md`, `docs/DECISIONS.md`, `docs/WORK_LOG.md`, then the
relevant feature/ownership/client/performance records. Stay in this existing addon.

1. Inspect Git status/HEAD/main/remotes. Continue on
   `codex/modernization-audit-20261029`; main remains `7436820`. Preserve the original
   untracked `FluxUI_Sync_Log.txt`, ignored work and any newer user edits.
2. Read `docs/RECOVERY.md`. Three external verified checkpoints cover the initial
   tree and each runtime batch, including actual dirty files and private settings.
   Freeze a new dated checkpoint if current source/settings differ before edits.
3. Latest runtime is `ab4e658a98a7ce3ee6688ac6170e7e0991325af0`, tree
   `67b4890083fe13e242ffbc47c36ff6037a172f82`. BUG-001 currency callbacks, BUG-002
   queued/partial mail/AH scans and BUG-003 pending send/return completion are fixed
   and desktop-tested. Do not reapply them. Native acceptance remains pending.
4. Next bounded investigation: trace `Inventory/Builtin/Auctions.lua` SHOW callbacks,
   `Inventory/Builtin/Guild.lua` OpenVault and `Inventory/Builtin/Void.lua` callbacks
   after Store.UsesSyndicator becomes true. Reproduce query/request counts with real
   provider handoff before choosing one small correction. Preserve standalone
   native queries, open-state semantics and supported client gates.
5. `docs/EVENT_DISPATCH_AUDIT.md` already reproduces the dispatcher mutation defect
   and traces its consumer. No production unsubscribe trigger was found. Defer that
   shared-service redesign until a real teardown consumer or native trace requires
   it; define ordered removal/addition/nesting semantics and measure overhead first.
6. Native checks can proceed independently using `docs/CLIENT_VALIDATION.md`,
   `docs/PERFORMANCE_PROTOCOL.md` and `docs/PROVIDER_HANDOFF_LIFECYCLE.md`. Record
   exact builds/settings/addons and matched screenshots/captures. Local Blizzard
   source snapshots are older than installations; desktop mocks are not acceptance.

Reproduce latest fixes and validation from the addon root:

```powershell
lua tests/deferred_inventory_handoff.lua --mail-source tests/fixtures/mail_scan_provider_before.txt --auction-source tests/fixtures/auction_scan_provider_before.txt --measure
lua tests/deferred_inventory_handoff.lua
lua tests/pending_mail_provider_handoff.lua --source tests/fixtures/pending_mail_provider_before.txt --measure
lua tests/pending_mail_provider_handoff.lua
python tests/run_validation.py --output docs/validation/next-session.json
python -B docs/tools/validate_docs.py
```

Baseline `--measure` deliberately exits zero with 42 scan-test or 8 completion-test
failures. Candidates require 210/410 checks with zero failures. Final recorded suite:
84 scripts, 725 syntax files, zero failures; Lua/luac 5.4.6 and Python 3.10.6.
Some old tests require adjacent reference/backup trees. Missing fixtures are not
addon failures. Verify identities in `docs/validation/continuation-identities-2026-10-29.json`.
Regenerate indexes with `python -B docs/tools/build_reference.py` after code changes;
use `--sync-docs` only alongside a fresh validation run.

Before stopping, update status, decisions, affected ledgers, raw evidence, work log
and this handoff. No automatic sync to other clients, merge to main, settings reset,
second addon, rename or release is authorized by this continuation.
