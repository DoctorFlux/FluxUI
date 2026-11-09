# Test fidelity and remaining coverage

The current 232-script suite passes, while the additional round-2 probes
reproduce faults. This is not contradictory: a test establishes only the paths,
API return contracts, state transitions and assertions it actually executes.

| Gap exposed by this audit | Stronger future acceptance |
|---|---|
| Pending fields assume `After` returns a cancellable object. A fixture that returns one can conceal the bug. | Test native nil-return `After` explicitly; use a labelled handle-return countercontrol only to isolate the mechanism. Exercise cancellation, replacement and callback ownership. |
| Gear pipeline tests commonly substitute a successful Equipment leaf. | Load the complete Equipment, Inv, EquipmentSets, Includes/Compat and orchestrator together. Include missing/partial gear and both pending and active cancellation. |
| Bar/key cases favor letters and isolated key holds. | Include valid punctuation/locale keys, distinct pool identities, literal minus, overlapping presses, duplicate payloads and every release order. |
| Modifier-only and target/mouseover ordering tests settle between bursts. | Keep mouseover continuous while full modifier/target/combat requests arrive. Assert a bounded delivery deadline during the storm, not only a correct final quiet state. |
| A visible-state or byte/hash check does not establish an owner lifetime. | Enter→leave before callback, disable→enable repeatedly, replace a frame/owner, invoke old callbacks afterward and count retained hooks/drivers. |
| Salvage combat fixture begins from an already hidden overlay. | Add visible→combat, secure-driver show, modifier and OnUpdate branches under a strict protected-write guard; verify actual native visibility/protection later. |
| Widget mocks usually return plain dimensions/levels/colors. | Use documented nil/unknown/opaque return controls, verify guards before arithmetic, and keep aspect activation/native provenance unconfirmed unless captured. |
| Performance tests count final paints but miss raw-event work beforehand. | Instrument the actual event consumer, host indexing and setter calls as well as the downstream coalescer. Preserve same-frame execution semantics when proposing reductions. |
| Locale tests use English provider display names. | Keep the same modeled mount identity with a localized name; verify real stable per-client identities before implementation and native locale behavior later. |
| A fixture declares a capability outcome without running the actual repair/probe. | Separate actual current policy from a forced unsupported fallback. Current repaired Forever uses secure paging; the large fallback setter count is a countermodel, while the combat scan remains an actual code path. |

The audit's [source screen](SOURCE_SCREEN.csv) contains lexical names and literal
test references. It does not prove guard dominance, callback reachability,
statement execution or branch coverage. Unloaded files include validation
harnesses and dormant source; they are not all dead addon code to remove.

The domain matrices distinguish broad screening from bounded manual review and
production-code execution. The remaining-domain owner manually reviewed 44
bounded file paths in a 304-file screen; it did not claim all 304 files were
semantically exhausted. Similar limits apply to the other owner reports.

Consumer tests deliberately isolate some boundaries. The badge follow-up calls
an explicit paging/refresh bridge; the core bus uses modeled event, timer and
display leaves; the input tests execute restricted snippets in a mock secure
environment. Their passing assertions cannot certify the actual native pipeline
or erase a separately reproduced scheduling issue.

All raw repeat logs and source identities are retained. Repeated workloads are
not distinct scenarios, and independent consumer dispatch counts must not be
summed into a whole-addon benchmark. Binding timer counts varied between runs;
the reports retain that variation. Native matched timing and actual event
delivery remain roadmap gates, not fabricated performance results.
