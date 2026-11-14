# Combat invite power partition fix

10 November 2026 — POWER-PARTITION-COMBAT-JOIN-20261110. The user reported blocked `StatusBar:SetHeight` and `StatusBar:Show` at 15:13:28 when inviting someone during combat.

The shared partition updater tried to resize/reveal protected child bars after the native party owner revealed a prepared member. Existing anchors did not establish permission. The same branch also performed additional-power, text-anchor, prediction, border and portrait layout work; the health-only branch had its own unsafe combat writes.

## Correction

[Shared unit frames](../UnitFrames/FluxUnitFrames_Shared.lua) now stop structural partition work before text-anchor sizing or applied-geometry/prediction cache updates during combat. The existing deferred combat owner coalesces one latest partition per frame. The existing regeneration subscription remains a fallback; party frames retain their permanent regeneration listener after the partition is applied. The separate vertical-strip layout already has its own combat guard.

Live power values, text/color/allowed alpha sinks and native secure roster reveal continue immediately. No update interval is slowed. Ordinary layout reconciliation uses current state after combat; repeated changes do not enqueue duplicate per-frame closures.

An absent future party/watched unit reporting zero power no longer establishes “no resource.” It retains unknown capability and a power-capable prepared layout outside combat. Consequently a newly joined member's resource can paint immediately instead of staying hidden until regeneration. Existing units with a readable zero capacity retain their no-resource behavior outside combat. A genuine protected geometry change during combat retains its last legal layout until regeneration; addon Lua does not gain permission by catching an error.

No settings, defaults, bindings, saved-variable roots, assets, XML or TOC/load order changed. Only the shared runtime file changed, plus the corrected existing resource test and one new regression. Other performance optimizations remain byte-identical to the pre-fix checkpoint.

## Requirements and evidence

| Requirement | Acceptance |
| --- | --- |
| PWRJOIN-01 Reproduce the reported invite path | Actual Party OnShow/roster queue → Paint → actual Shared UpdatePower/partition; exact baseline reproduces both reported methods |
| PWRJOIN-02 Reject combat structural writes | Protected mutators count attempts before throwing; candidate makes zero attempts, including health-only/text-anchor/additional/portrait paths |
| PWRJOIN-03 Keep the joining resource visible/live | Absent OOC slot prepares a shown resource; native reveal and current/max/secret sinks continue in combat |
| PWRJOIN-04 Apply latest layout once legal | One deferred owner per affected frame; queue-before-event and event-before-queue orders, repeated invalidations, missing-helper fallback and persistent Party regen tested |
| PWRJOIN-05 Cover all supported families | Retail, Forever, progression, Era and Anniversary models plus fresh pinned native source evidence |
| PWRJOIN-06 Preserve unrelated behavior | Full regression suite, unchanged source/assets/defaults and exact checkpoint/candidate hashes |

The new [production-path regression](../tests/power_partition_combat_join.lua) passes **675 checks** over five clients and 15 permission cases. It executes actual Shared power/partition/regen, actual Party wrappers and the actual lifecycle defer adapter. Native frames, value sinks, headers and unrelated FX helpers are modeled; it is not a native taint/FPS emulator.

| Per-client scenario | Exact baseline | Fixed candidate |
| --- | --- | --- |
| Strict protected descendants | 9 protected attempts / 9 blocked errors; first SetHeight on party1.Health | 0 attempts / 0 errors |
| Show-only failure isolation | 32 structural attempts / 7 blocked errors; first blocked Show on party1.Power | 0 attempts / 0 errors |
| Regeneration fallback without shared defer helper | 1 protected attempt / 1 error | 0 attempts / 0 errors |

Full validation passes **288 scripts and 960 Lua syntax checks**. Documentation validation also passes: 993 classified sources, 607 reachable files and 16,131 local links. Three matched pairs pass; eight harmful controls are rejected. Ordinary strict/show-isolation candidate runs retain 14 modeled value-sink updates and four deferred partition owners despite repeated capacity/type/secret/additional invalidations. The prior [unit power test](../tests/unit_power_visibility.lua) now rejects protected StatusBar/Frame mutations in combat instead of explicitly expecting the illegal resize.

The earlier party/roster fixtures had stubbed the power or partition painter, and the old resource fixture allowed all child mutations. Those passes established their narrower scope and did not cover this native failure. This correction supersedes any interpretation of the earlier combat lifecycle audit as proof that ordinary post-reveal painting was fully safe.

## Native sources and identity

Fresh branch heads remain Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever `9dc84f0d3bbae1768ac3405b3716000bd93eda06`, progression `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`, Era `4192ac60067fc55566182291bc67c85dd9b6794d`, Anniversary `68e0a2ec559d9761dfc4e7f864c3944f9d758a49`. The exact 44 source records / 31 unique Git blobs cover resize/status-bar/region declarations, native UnitFrame loading and secure parent XML, and native value updates.

All five source families explicitly mark SetHeight/anchor setters protected. Native compact frames prepare health/power geometry and update values separately. Follow-up method-ownership research also verifies that SimpleFrameAPI overrides generic region Show/Hide and explicitly marks both protected on all five clients. The earlier generic-only inspection was incomplete inheritance evidence; the user's native failure remains direct evidence on these bars. No inspected source grants special authority to the C UpdatePartition callback. See the [resource-effects follow-up](RESOURCE_EFFECTS_PERFORMANCE.md) for the additional pinned declarations and adjacent helper work.

The external `checkpoint-20261110T141810Z` contains all 2,536 current files, a SHA256 manifest and verified Git history before this correction. Available settings metadata was inspected read-only; no closed-client/quiescent settings backup is claimed.

[Raw before/after results, source identities and validation](validation/power-partition-combat-join-2026-11-10.json) retain the exact commands, failures, controls and candidate hashes.

## Native acceptance

No client input/focus/clipboard operation, reload, settings/profiler write, manual synchronization or publication occurred. The user-managed synchronization program was not operated.

Native invitation/leave, secret values, pixels, actual secure operation permissions and FPS remain **NOT RUN** after the fix. The supplied native failure is reproduced in the stated permission models; unrelated resource-effect helpers remain mocked and are not certified by this regression. Existing broader FX permission/secret-geometry concerns require their own native evidence and are not silently labeled fixed.

Reload outside combat, then invite a member while fighting with player-style party frames. Check immediate health/resource/text, roster reveal, no new blocked calls and the final layout after combat. Repeat for the supported clients and health-only/additional-power variants. The existing native testing preference and pending broader party/raid sessions remain unchanged.
