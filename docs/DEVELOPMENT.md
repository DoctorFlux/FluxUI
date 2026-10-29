# Development tasks

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Continue skipping auction, guild-bank and void-storage callback audits until
   explicitly requested. Do not infer permission from unrelated vendor work.
3. Read [recovery](RECOVERY.md). Nine verified external checkpoints retain source,
   history and private settings. Latest at 11:47 UTC / 12:47 Copenhagen covers
   baseline 7465e36. Retired originals remain outside the addon. Preserve a fresh
   checkpoint before another runtime batch if source/settings differ.
4. Latest runtime `5198ded001dde5bbc3fc5d6011239652cbe79dac`, tree
   `ffeca6fce85ff9606c7dab3f38b065bdbfdfeb70`: BUG-008 leaves Quick Join anchoring
   to the existing column while either button belongs there. The old callback
   reversed Channels-below-Quick-Join and caused the reported SetPoint cycle.
   The combined regression passes 1,819 checks; full 87 scripts/728 syntax files
   pass. Five matched pairs retain three retry deadlines with zero cycle failures.
5. Next priority: [native chat checks](CHAT_QUICKJOIN_ANCHOR.md) on the affected
   Quick Join clients; their exact builds/triggers are unknown. Verify reload,
   native alerts/side hooks, tab switches, Social/Channels visibility, Edit Mode
   exit, combat deferral and matched geometry/input/taint. Then continue the
   [vendor-open procedure](VENDOR_OPEN_WORK.md): the Era hitch remains unverified
   and first/repeated behavior/automation settings remain unknown. If native tests
   are unavailable, reproduce another independent source candidate before editing.
6. BUG-001 through BUG-008 and editorial cleanup are already complete in desktop
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
lua tests/chat_column_layout.lua --source tests/fixtures/chat_quickjoin_before.txt --measure
lua tests/chat_column_layout.lua
lua tests/idle_layout_retries.lua
lua tests/vendor_open_work.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Chat baseline measure mode exits zero with 448 expected failures among 508 added
ownership checks; original 1,311 column checks pass. Candidate passes all 1,819.
Verify all current Lua hashes against `docs/validation/chat-quickjoin-full-2026-10-29.json`
before reusing the full baseline (Lua/luac 5.4.6, Python 3.10.6). Some legacy tests
need adjacent reference trees; missing fixtures are not addon failures. Use --sync-docs only alongside a
fresh validation run.

Update status, decisions, work log, affected ledgers and these tasks when completing
a change. No client sync/deployment, push/merge to main, settings reset, second addon,
rename or release is authorized.
