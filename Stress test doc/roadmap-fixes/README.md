# Roadmap implementation — 7 November 2026

The user authorized all round-2 roadmap fixes, preservation of features and
appearance, rapid Shift/Ctrl/Alt retesting, and range/usability/darkening checks.
Changes are made directly on existing main, preserving newer local work.
The [pre-edit checkpoint](checkpoint.json) records an external source ZIP,
working diff, history and read-only metadata for 45 available settings files.
No private settings values or archives are stored in AddOns.

All **25 qualified roadmap groups** are implemented and pass desktop acceptance.
The final combined suite passes **247/247 scripts** and **911 Lua syntax checks**,
with no runtime/test source drift during validation. The round-2 audit remains
historical evidence; its probes sometimes assert the defect and are not green
acceptance tests. New regressions reject the captured baseline for the expected
reason and pass the candidate. Native secure execution, actual secret values,
rendering and FPS remain outside these desktop simulations.

[Finding status](finding-status.json), [exact source changes](source-changes.json),
[full suite](full-suite.json), [before](final-before.json) and
[after](final-after.json) source snapshots identify the candidate. Fourteen newer
runtime files are byte-equivalent after CRLF normalization, including consumable,
aura, vertical target, PvP, raid and minimap work. TOCs, XML and assets retain
their pre-edit contents. No branch, commit, push, settings reset or game input
was performed.

## Coverage

| Scope | Implementation/evidence owner |
|---|---|
| BIND-01 through BIND-06; actual combat MOD-01 index churn | Binding, chord parser, prepared frames, press feedback, respec and slot-program owners |
| CORE-01/03/04/05 | Picker/talent timer ownership; equipment cancellation and truthful completion |
| CORE-02/06 | Restock batch/context ownership; bounded full/narrow Context delivery |
| DOM-01 through DOM-06 | Proxy tooltip/hooks, protected salvage writes, public frame levels, metadata retry and layout/flyout timers |
| EBS-01 through EBS-06 | Dormant parser correction, localized vendor identities/cache, cooldown retry, mount timers and disabled reticle work |
| Added range/usability/darkening scope | Shared memo invalidation, exact item/unit ownership, native target payload routing, action-scoped unknown usability, independent usable/range layers and public pressed color ownership |

Existing colors, priority, art, saved data, commands, integrations and ordinary
delays are preservation requirements. Corrected stale state and bounded storm
catch-up are intentional behavior fixes. Group, dungeon and raid labels in
fixtures describe simulated inputs; they are not native client execution.

## Verification and measured scope

- [Binding/press/index report](binding/REPORT.md): distinct punctuation/minus
  payloads, exact masks, callback supersession, public tint ownership, deferred
  combat clears and unchanged-index churn. Native secure paging policy remains.
  Both expanded runs pass 1,938,260 assertions over 8,640 scenarios each, with
  zero orphaned press states or blocked combat writes and a pending timer peak
  of one. [Raw modifier evidence](binding/modifier-results.json) retains counts
  separately from the other consumer layers.
- [EBS/Respec report](ebs-respec/REPORT.md): 57 repeated focused executions and
  11 old-reject/new-accept controls; localized vendor lookup/cache, cancelled
  gear work, truthful recovery, timers, cooldown retry and disabled reticle work.
- [Domain report](domains/REPORT.md): reused proxy/tooltip ownership, strict
  combat salvage guards, public levels, vendor retries and layout/flyout timers.
- [Range/usability/darkening](RANGE_USABILITY.md): three runs of 86,872 assertions,
  including 540,672 modeled key-state changes per run across four requested
  client models. Same-frame memo, unknown states, targets, priority and tint
  recovery pass. Unchanged colors avoid redundant vertex writes.
- [Core repeated evidence](root-results.json): three runs of 96,850 bus checks
  and 10,544,220 modeled physical edges per run, plus 84 Restock checks and
  14,412 actual Context→indexed ProgramFace→Action checks per run. Full mixed
  traffic delivers every frame; narrow-only catch-up is bounded. These counts
  belong to separate scenarios and must not be added as one gameplay benchmark.
- [EBS/badge/VFX/fade evidence](consumer-results.json): three repetitions of
  all three actual modifier consumer probes and the pinned native fade-manager
  replay. The prior Forever `startAlpha` trajectory/ownership checks pass
  1,017 assertions each; [source identity](fade-source.json) is current.

No native FPS improvement, global taint guarantee, full native branch coverage
or pixel-perfect certification is inferred from these passes. The saved Forever
log does not identify the first taint source or prove which caller ran before
each timestamp. Loading this candidate and observing native recurrence remains
a later acceptance gate, along with the four clients' world/dungeon/raid and
combat transitions. The user requested simulations here; no foreground or
hardware input was taken.
