# Round 2 addon audit — 7 November 2026

The audit found **25 qualified finding groups** in the current source. **No new
addon fixes have been applied.** The [roadmap](ROADMAP.md) orders future work and
defines acceptance without removing features or resetting settings.

The most urgent reviews are punctuation bindings sharing one macro-button
identity, cancelled gear work continuing afterward, and the conditional combat
write path of an already-visible salvage overlay. Other reproduced issues
include misleading missing-gear completion, stale press visuals, uncancellable
popup/spec callbacks, retry/refresh amplification and delayed display context.
These are source/model results; no new native taint incident was captured.

| Evidence class | Groups | Meaning |
|---|---:|---|
| Reproduced active-source behavior/contract | 15 | Current loaded owners produce the recorded result under explicit production-code fixtures. Native UI/input remains separate. |
| Conditional error/recovery models | 4 | Documented nil/secret/protected conditions or injected failure; actual affected native context is not established. |
| API edges with ordinary reach unproved | 2 | Reentrant restore and direct combat-clear contracts; current normal callers are not shown to trigger them. |
| Measured work/optimization candidates | 3 | Counted journal, reticle or raw-modifier work. These are not measured native CPU/FPS diagnoses. |
| Dormant legacy helper | 1 | Reproduced typo in a source file outside the current load closure; not a current macro execution finding. |

Start with [FINDINGS.csv](FINDINGS.csv), [full JSON records](FINDINGS.json) or the
[implementation roadmap](ROADMAP.md). Multiple `After` sites share one mechanism
family and are not counted as separate universal API faults.

## Rapid Shift, Ctrl and Alt simulation

The user's explicit rapid-key request is covered at three distinct layers.
All eight held combinations, taps, overlapping holds, release-order changes,
duplicates, same-frame bursts, combat transitions, cleanup and reuse are included.

| Layer | Recorded workload | Result and limits |
|---|---|---|
| [Core Modifier/Context](CORE_REPORT.md) | Five repeated processes; each has 96,850 assertions, 10,544,220 physical-state edges and 10,883,400 notifications across five labels/two starting combat states. | Isolated bursts release cleanly, one delivery per modeled frame, no driver growth. Mixed mouseover/target/key traffic reproduces full-context starvation until quiet. |
| [Binding, click and press owners](action-binding/MODIFIER-FOLLOWUP.md) | Two processes; each has 1,938,260 assertions, 8,640 scenarios and 1,399,680 modifier payloads. Physical update attempts include duplicates. | The stale press-owner issue reproduces throughout; tested combat write guards, bounded queue ownership and frame/hook reuse hold. Timer call counts vary between the two runs and are retained, not called identical. |
| [Active utilities, VFX and badges](extra-buttons/modifier-followup/REPORT.md) | Three combined repetitions of three probes; 1,508,628 assertions and 327,775 consumer edges per repetition. | Isolated selection, counts, cooldowns, VFX, hotkeys and row/reuse controls pass. Badge delivery uses an explicit refresh bridge, so it does not certify the whole Context deadline. |
| [Consumer work budgets](modifier-storm/CONSUMER_REPORT.md) | Three repetitions; 4,526 assertions and 983,064 consumer-local dispatches each. | Bars can perform work before downstream coalescing; EBS hotkeys retain bounded coalescing and clean final release. These dispatches are separate scenarios, not additive physical keystrokes. |

For a representative 57-host / 5,120-event case, the combat branch performs
291,840 host visits and zero attribute writes. A deliberately forced unsupported
no-secure-paging fallback performs **7,587,840 SetAttribute calls**, including
identical values. **Current repaired Forever uses secure paging, so this is not
ordinary current Forever out-of-combat work.** The actual combat scan remains
the current-path optimization lead. See the [capability/delta correction](concurrent-review/REPORT.md).
Native setter cost, attribute-change side effects and FPS were not measured.

The mixed core scenario delivers zero Context notifications through 10 modeled
seconds of continuous mouseover plus modifier/target changes, then one after
quiet. The strongest traced consumer is a same-slot bar overlay display while
an indexed mouseover-dependent program is active. Utility/EBS/UF-hover paths
have independent bypasses. No whole-addon or secure-click freeze is claimed.

## Reports and evidence

- [Action bars, binding, key capture, pool identities and press state](action-binding/REPORT.md).
- [Extra buttons, mounts, locale-dependent detection, cooldown recovery and reticle work](extra-buttons/REPORT.md).
- [Core/options timers, context delivery and reviewed shared services](CORE_REPORT.md).
- [Complete gear owner and profile pipeline](core-equipment/REPORT.md).
- [Unit/raid/nameplate, inventory/mail/vendor, minimap/microbutton, status and integration review](remaining-domains/REPORT.md).
- [Test fidelity and coverage gaps](TEST_GAPS.md), [all-source screen](SOURCE_SCREEN.csv),
  [module matrix](MODULE_MATRIX.csv) and [scope summary](scope.json).
- [Fresh baseline](baseline.json), [four upstream pins](upstream-pins.json),
  [current full suite](existing-suite.json), [preservation](preservation.json)
  and [final requirement/validation audit](COMPLETION_AUDIT.md).

The complete current runner passes **232/232 scripts; 896 Lua files pass syntax
checks** in the [initial audit suite](existing-suite.json) and the later
[current integration recheck](current-suite.json). Current screening covers **929 classified Lua/XML files and 599
TOC/XML reachable paths**, with no missing load references. These figures include
validation and unloaded sources; they are not counts of fully exercised branches.
Every proposed fix remains open and has its own regression/native gates.

Independent Party PvP badge changes appeared during the audit in two unit-frame
files and two existing fixtures. They were preserved, not made by this audit.
The [original-to-current delta](concurrent-source-drift.json) and
[current suite/affected-probe recheck](concurrent-recheck.json) retain both
identities. Earlier owner reports remain tied to their captured hashes; the
current frame-level probe still reproduces its conditional cases. The later full
suite is stable across explicit before/after source fingerprints, and seven
focused rechecks cover the new shared PvP formatter/delegate model and current
controls. The new PvP
presentation has no native visual/permission acceptance from this audit.

## Boundaries

Era, Anniversary, Retail live and Forever use freshly resolved source commits.
Extra progression models are supplementary. Source versions do not identify the
user's actual running build. The [requirements](REQUIREMENTS.md) retain the
simulation-only preference and explicit no-code-edit constraint.

No foreground input, WoW operation, settings/profiler write or native gameplay
test was performed. Lua mocks cannot establish native taint propagation, secret
permissions, protected action legality, pixels, OS input behavior or CPU/FPS.
World/dungeon/raid labels prove only the actual branches their fixtures drive.
Guild-bank and void-storage callbacks remain excluded.

The previous USER-001 Forever `FrameUtil/startAlpha` report retains its own
evidence. Its affected frame/first taint cause and post-fix recurrence remain
unconfirmed; the new findings do not establish that attribution. Future logs can
be added through [error intake](ERROR_INTAKE.md).
