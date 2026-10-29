# Development tasks

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Continue skipping auction, guild-bank and void-storage callback audits until
   explicitly requested. Inspect other features for reproduced defects.
3. Read [recovery](RECOVERY.md). Seven external verified checkpoints retain source,
   history and private settings. Latest at 10:54 UTC covers baseline 0d05acc; retired
   originals remain outside the addon. Preserve a fresh checkpoint before another
   runtime batch if source/settings differ.
4. Latest runtime `b505bb880aeefbab414d957d8d7fbee6820c20a8`, tree
   `cc067974b724c82188d52f24a9800ad485ca261e`: BUG-006 caps zero availability and reserves
   finite submitted stock on the existing shared index entry. It is a request budget,
   not native acknowledgement. Stock replay passes 177 checks after 39 baseline
   failures; identity controls pass 660, combined 837. Five pairs remove stock-limit
   rejections and retain unlimited 40-item/five-pass cadence with no info polling.
   BUG-001 through BUG-005 and editorial cleanup are already complete.
5. Next bounded candidates: unchanged-ID price changes, external stock changes or
   delayed/rejected purchase acknowledgement, or another active feature outside
   deferred domains. These are source-audit targets, not proven defects. Reproduce
   production behavior and capture a baseline before selecting a correction.
6. Shared event-dispatch mutation remains latent with no production unsubscribe
   trigger found. Module teardown/cancellation still needs actual consumer evidence.
   Avoid speculative shared-service redesign.
7. Native acceptance remains pending for every target. Follow [stock native steps](VENDOR_STOCK_BUDGET.md),
   [client validation](CLIENT_VALIDATION.md) and [performance protocol](PERFORMANCE_PROTOCOL.md).
   Desktop mocks do not certify pixels, input, combat/taint, secrets or FPS.

Reproduction from the addon root:

```powershell
lua tests/vendor_slot_identity.lua --stock-only --source tests/fixtures/vendor_stock_before.txt --measure
lua tests/vendor_slot_identity.lua --stock-only
lua tests/vendor_slot_identity.lua --identity-only
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure mode exits zero with 39 expected failures. Stock candidate requires
177 passes; default candidate requires 837. Latest full suite: 86 scripts/727 syntax
files, zero failures, Lua/luac 5.4.6 and Python 3.10.6. Verify current Lua hashes against
`docs/validation/vendor-stock-full-2026-10-29.json` before reusing that full baseline.
Some legacy tests need adjacent reference trees; missing fixtures are not addon
failures. Use --sync-docs only alongside a fresh validation run.

Update status, decisions, work log, affected ledgers and these tasks when completing
a change. No client sync/deployment, push/merge to main, settings reset, second addon,
rename or release is authorized.
