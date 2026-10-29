# Development tasks

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
making changes. Continue in this existing addon and repository.

1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Auction, guild-bank and void-storage callback audits remain deferred by user
   direction. Inspect other features until that scope changes.
3. Read [recovery](RECOVERY.md). Six verified external checkpoints preserve source,
   Git history and private settings; latest at 10:40 UTC covers baseline 07b11ce.
   Earlier retired originals remain outside the addon. Make a fresh checkpoint
   before the next runtime batch if source/settings differ.
4. Latest runtime `cdd752abd060588bc1602e880d997a60dd0b34a9`, tree
   `d18478f458e670f18931c070a00d53a708387fee`: BUG-005 checks live merchant slot identity
   before queued purchases. All 660 focused checks pass after 36 baseline failures.
   Five matched pairs remove wrong/empty purchases and preserve stable 40-item/five-
   pass behavior, at one added identity lookup per valid purchase. BUG-001 through
   BUG-004 and the editorial cleanup are already complete; do not reapply them.
5. Next bounded candidate: unchanged-ID vendor stock/affordability metadata across
   passes, or another active feature outside excluded domains. These are source
   audit candidates, not established defects. Read relevant requirements/callers,
   reproduce production behavior and record before evidence before choosing a fix.
6. Event-dispatch mutation remains a latent API defect with no current production
   unsubscribe trigger found. Shared Module teardown/cancellation needs actual
   consumers before redesign. Keep generic infrastructure changes evidence-driven.
7. Native parity/performance remains pending for every target. Follow
   [client validation](CLIENT_VALIDATION.md), [performance protocol](PERFORMANCE_PROTOCOL.md)
   and [merchant identity steps](VENDOR_PURCHASE_IDENTITY.md). Desktop checks do not
   certify rendering, real input, secure execution, taint, secrets or FPS.

Reproduction from this addon root:

```powershell
lua tests/vendor_slot_identity.lua --source tests/fixtures/vendor_buy_slot_before.txt --measure
lua tests/vendor_slot_identity.lua
lua Inventory/Restock/Junk/_tmp_junksmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure mode deliberately exits zero with 36 expected failures. Candidate
requires all 660 checks. Latest complete suite: 86 scripts/727 syntax files, zero
failures, Lua/luac 5.4.6 and Python 3.10.6. Verify current Lua hashes against
`docs/validation/vendor-slot-full-2026-10-29.json` before reusing that full baseline.
Some legacy tests require adjacent reference trees; missing fixtures are not addon
failures. Use --sync-docs only alongside a fresh validation run.

Update status, decisions, work log, relevant ledgers and these tasks when completing
a change. No sync to other clients, push/merge to main, settings reset, second addon,
rename or release is authorized.
