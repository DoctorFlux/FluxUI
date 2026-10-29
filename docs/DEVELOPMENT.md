# Development tasks

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Keep skipping auction, guild-bank and void-storage callback audits. The current
   cached personal/warband count change does not authorize those callbacks.
3. Read [recovery](RECOVERY.md). Eleven verified external checkpoints retain source,
   history and private settings. Latest 12:35 UTC / 13:35 Copenhagen covers d3bce5b,
   1,234 actual files and 403 WTF files. Both clients were running: on-disk settings
   only, not quiescent in-memory state. Preserve a fresh checkpoint before another
   runtime batch if source/settings differ; retired originals stay outside AddOns.
4. Current runtime/test `013bf40db1d5b57c238ac3ac377e8ced98446fd1`, tree
   `4f0d827bb26bba3ee8b20e21de891596fad0e98b`. PERF-006 filters bag/cached-bank tier
   matches before live usability; quantities, live gates/protections/fallback remain.
   1,710 focused checks and full 89 scripts/730 syntax pass. Five alternating native
   Era getter pairs return identical results with lower CPU. Personal-bank native
   outputs are zero; positive/warband parity is desktop-only.
5. **Leave WoW in the background while the user uses the PC.** Do not activate it,
   take keyboard/mouse focus, or repeat the foreground controller without renewed
   coordination. Cleanup is complete: original three automation flags true and
   profiler=1 retained, temporary sampler/namespaces/exports cleared. Edit the normal
   addon folder; the user's existing sync delivers files. No new sync/deployment job.
6. The clean Era 1.15.9.70576 pilot reproduced a 333 ms UI interval across four opens
   and about 320 ms per target build. Getter CPU medians per five kinds fell from
   132.199 to 15.237 ms bags and 118.897 to 22.517 ms cached bank. Whole-vendor after
   remains pending. When foreground testing is convenient, use [exact procedure](TIER_COUNT_WORK.md):
   five matched alternating four-open/20-second windows, same NPC/profile/resolution/
   scale/inventory/addons, 30-second warm-up, separate cold and steady work, profile
   on/off with preference restored. Compare screenshots/input/taint and normal
   allowed transactions separately. Do not infer native FPS from getter CPU.
7. BUG-001 through BUG-008, PERF-005/006 and editorial cleanup retain their documented
   tested scope. Other classification, Already Known, reagent-name or layout work
   needs attribution before edits. Reservations are not native acknowledgement;
   unchanged-ID price/stock changes and delayed/rejected requests remain separate.
   Event mutation is latent with no production unsubscribe trigger; do not redesign
   the shared dispatcher speculatively.
8. Complete [client validation](CLIENT_VALIDATION.md) separately on available targets.
   Era gains only partial native count evidence; pixels, security/taint, unprofiled
   FPS, external providers and other clients remain pending. Desktop mocks do not
   certify real secret values or original Wrath 3.3.5.

Reproduction from the addon root:

```powershell
lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure
lua tests/tier_count_work.lua
lua tests/idle_tiers.lua
lua tests/vendor_tier_work.lua
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Count measure mode exits zero with ten expected failures among 1,710 checks;
candidate passes all. Verify all current Lua hashes against
`docs/validation/tier-count-full-2026-10-29.json` before reusing the full result
(Lua/luac 5.4.6, Python 3.10.6). Some legacy tests need adjacent reference trees;
missing fixtures are not addon failures. Use --sync-docs only with a fresh full run.
Native probe/source hashes and samples are in the focused evidence; its local
candidate bodies are not a replacement for complete addon foreground acceptance.

Update status, decisions, work log, ledgers and these tasks before stopping. No
push/merge to main, settings reset, second addon, rename or release is authorized.
