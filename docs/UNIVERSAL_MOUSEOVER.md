# Universal mouseover targeting

8 November 2026 — UNIVERSAL-MOUSEOVER-20261108.

Default/Target casts use a compatible mouseover first when the universal switch
is enabled, then their normal target. Blizzard's native mouseover option and its
modifier remain authoritative where supported; other clients use Flux's existing
preference. Explicit Focus, Self, cursor and other unit rules retain priority,
as requested. Explicit mouseover bindings also check spell/item compatibility;
free chords without a native bar fallback receive a target fallback.

## Failure and correction

Previously, the binding compiler disabled automatic mouseover on native clients
and on free chords. Adding `/stopcasting` to a native bar spell could therefore
change its targeting. Custom click-time targeting selected any existing
mouseover without checking whether the selected spell/item could assist or
attack it. Multi-cast extras ignored the universal preference, and `/petattack`
could select a friendly mouseover or bypass the native modifier.

The existing [compiler](../Binding/Core/MacroFactory.lua) now emits compatible
mouseover clauses ahead of Default/Target clauses across a shared chord,
including free chords, cold-name fallback, multi-cast extras and native tails.
It retains prefix commands, form/rank rules, explicit targets and fallback.
`/petattack` accepts hostile mouseover units and follows the same modifier.
Equipment-slot extras classify the equipped item but still emit `/use <slot>`.

The existing [click adapter](../Core/Engine/MouseoverCast.lua) classifies the
selected modifier action or standalone spell/item at the protected click, then
clears its temporary unit after the click. Re-enabling the fallback switch
prepares existing widgets again. Standalone spells/items reuse the established
repaired-handler probe on Forever; failed/unavailable probes keep the existing
native fallback. Plain native action buttons retain Blizzard's own resolver.

Automatic clauses remain distinguishable from explicit mouseover rules so the
existing idle display and badge previews can omit automatic world-hover tails.
No artwork, geometry, badge input ownership, paging policy, key-down/up policy,
binding document, settings root or default was changed. Arbitrary user macro
prefixes and their explicit targets are preserved.

## Secure limits

Compatibility means help/harm/exists and the configured macro predicates. A
macro cannot retry another unit after a range, line-of-sight, cooldown, resource
or server rejection. Neutral/unknown actions retain an existence-based choice.
The native bar fallback remains a separate action after binding rules.

Compiled macros bake the native setting/modifier outside combat and use the
existing deferred reconciliation if those settings change in combat. Plain
native action buttons continue reading Blizzard's live setting themselves.
Restricted snippets do not read CVars, replace client APIs, automate casts or
introduce a world-mouseover driver. Existing client macro-length limits remain.

## Evidence

The dated external checkpoint `Mouseover-priority-20261108T185914Z` contains
2,281 source files, uncommitted/untracked work, all-ref history and 188 accessible
on-disk settings files. ZIP and history verification passed before runtime edits.
Unsaved game memory is excluded. Main remains at
`1fd463f4de4bbff659f4e402c6f31138c49765b4` plus the preserved local changes.

[Exact baseline/candidate hashes and raw samples](validation/universal-mouseover-comparison-2026-11-08.json)
record five alternating pairs after one excluded warm-up pair. The archived
source fails 203 assertions on every replay; the candidate passes 916 checks
on every replay. The old engine, compiler and Apply gate each reject as isolated
controls. Baseline has fewer executed checks because its missing Forever
standalone adapter is reported and skipped; this is not a speed comparison.

Matched plain-click subsets make nine clicks per Classic-family model: baseline
0 action/0 polarity queries; candidate 9 action/18 polarity queries. These added
click-time checks provide compatibility validation. No new runtime frame, event,
timer, hook or hover polling registration was added. This is a correctness fix;
native CPU, allocation, latency, frame-time and FPS effects remain unmeasured.
Whole-fixture wall times include harness compilation and are not addon timings.

Full validation: [258 scripts and 923 Lua syntax files pass](validation/universal-mouseover-full-2026-11-08.json),
including 4,984 native-setting checks, 3,210 binding roadmap checks and the bar
suite. The [Lua source guard](validation/universal-mouseover-source-guard-2026-11-08.json)
reports no drift. [Installed copies](validation/universal-mouseover-client-copy-2026-11-08.json)
match all three runtime owners on all five installations. File equality is not
loaded-source or native execution acceptance.

| Client | Installed executable version | Source reference | Status |
|---|---|---|---|
| Retail | 12.1.5.70783 | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | Desktop pass; native pending |
| Forever | 1.60.1.70862 | `9dc84f0d3bbae1768ac3405b3716000bd93eda06` | Desktop pass; native pending |
| Classic progression | 5.5.4.70631 | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | Desktop pass; native pending |
| Classic Era | 1.15.9.70576 | `4192ac60067fc55566182291bc67c85dd9b6794d` | Desktop pass; native pending |
| Anniversary | 2.5.6.70577 | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | Desktop pass; native pending |

[Fifteen fetched primary-source blobs](validation/universal-mouseover-references-2026-11-08.json)
verify native unit resolution, macro execution, mouseover support and restricted
exports. No upstream code or assets were added to the addon. Original Wrath is
not an installed/tested case here.

Forever was verified running and captured read-only. Windows reported it as
foreground, so no commands, reload, casts, focus changes, clipboard access or
profiler/settings writes were attempted. The screenshot is a prior loaded-state
observation, not candidate visual or taint acceptance.

## Native regression still required

1. Out of combat, close transaction windows and `/reload`. Retain the same
   profile, resolution, UI scale and addon list; leave profiler settings unchanged.
2. With mouseover enabled, manually cast a helpful spell/item over friendly,
   hostile and absent mouseover units, then a harmful spell/item. Check fallback
   on the target. Repeat by bar click, bound key and a free Flux chord.
3. Repeat a native bar spell with `/stopcasting`, modified minirows, form/rank
   changes, shared-key badges, multi-cast extras and standalone buttons. Confirm
   Focus, Self and cursor rules retain priority, icons/badges remain correct, and
   an explicit mouseover free chord falls back when incompatible or absent.
4. On Retail/Forever test native modifier None and a held/unheld modifier. Test
   switch off/on and the documented combat deferral; on Classic-family clients
   use the custom switch. Exercise wheel/mouse keys over unit frames, normal
   combat and vehicle/temporary pages. Compare screenshots and fresh BugTabs/
   taint logs. Repeat on each actual client; desktop models do not certify this.
