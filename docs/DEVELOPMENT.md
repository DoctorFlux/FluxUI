# Development tasks

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Continue skipping auction, guild-bank and void-storage callback audits until
   explicitly requested. Do not infer permission from unrelated vendor work.
3. Read [recovery](RECOVERY.md). Ten verified external checkpoints retain source,
   history and private settings. Latest at 12:04 UTC / 13:04 Copenhagen covers
   baseline af5eee0. Preserve a fresh checkpoint before another runtime batch if
   source/settings differ; retired originals remain outside the addon.
4. Latest runtime `17628269f0e3b7fbeb1b8c2d7f9c7196829e67f3`, tree
   `0c681c46987fc5b136274bba59e5e5bb3dd90990`. PERF-005 filters tier candidates
   before live usability, retaining discovery, references, levels/skills and retries.
   Validation candidate `e7ec46a4070c132ff8bf6033d6bef5e2c92f90aa`, tree
   `4507ccd1456e42f9acdea0e2be4aaad073ff72ae`, adds the clarified repeated-open
   scenario. 340 focused checks and full 88 scripts/729 syntax files pass.
5. User confirms the Era spike on EVERY reopening of the same vendor. Follow
   [native tier procedure](VENDOR_TIER_WORK.md), prioritizing repeated opens and
   recorded actual builds/addons/profile. Previous fixes matched Era source before
   edits. Saved Config.wtf has scriptProfile=1; compare profiling on/off separately
   with original preference preserved. Five desktop pairs remove 15,000 info and
   ownership lookups each across 25 large-vendor reopens; classification remains.
   Native spike resolution is unverified. Remaining classification, Already Known,
   reagent-name harvesting and layout candidates need actual attribution. Avoid
   skipping the index wholesale: it preserves consumable reference discovery.
6. BUG-001 through BUG-008, PERF-005 and editorial cleanup are already complete in desktop
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
lua tests/vendor_tier_work.lua --baseline --measure
lua tests/vendor_tier_work.lua
lua tests/idle_tiers.lua
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Tier baseline measure mode exits zero with 12 expected failures among 340 checks;
candidate passes all 340. Verify all current Lua hashes against
`docs/validation/vendor-tier-full-2026-10-29.json` before reusing the full baseline
(Lua/luac 5.4.6, Python 3.10.6). Some legacy tests need adjacent reference trees;
missing fixtures are not addon failures. Use --sync-docs only alongside a fresh
validation run.

Update status, decisions, work log, affected ledgers and these tasks when completing
a change. No client sync/deployment, push/merge to main, settings reset, second addon,
rename or release is authorized.
