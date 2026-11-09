# Geometry fix proposals: reviewed, with an unsafe experiment rejected

**GEO-01 and GEO-02 remain held. No geometry fix is recommended for application
from this folder.** A concrete native-anchor experiment removes the opaque-width
comparison, but a new counterexample shows a material change in shield pixels.
It has been removed from the selected candidate and preserved separately for
review. No live addon source was edited.

The selected external Shared.lua is **GATED on the matching patched winning LCG
and its ownership/readiness checks; it is not ready for independent application**.
It contains only the requested ALPHA-06 threat-glow cache commit change and a correction to the misleading
claim that secret arithmetic is always safe. These are separate from a GEO-01
fix. [candidate.diff](candidate.diff) is the selected diff;
[candidate.json](candidate.json) records both selected and rejected source paths
and exact hashes. The selected candidate's SHA256 is
`4ccc5fe4059984cd130b34c37143f658efd64981aa37f7aabea29d8fa90540c8`.

## Concrete experiment and why it was rejected

The original modern forward-absorb bar starts at the live health fill's right
edge, has the full health-bar width, and normalizes its absorb amount by maximum
health. That width read can be inaccessible. Simply bypassing the comparison
and forwarding the opaque width to SetWidth is not an authorized fix: the
current resizing contract accepts secret geometry arguments only when untainted.

The isolated experiment instead anchors the bar across the remaining-health
span and normalizes against `healCalc:GetMissingHealth()`. It retains the old
public-width path on calculators without that method and leaves overflow,
antiheal/heal layers, options, timing and ownership alone. Its source/diff is
preserved under the separate external `experiments/geometry-native-span` root,
with SHA256
`9fabb80db04aa999802d9e11c749f8fcf69ac725a33222607f0bf7fff4dddeb6`.
See [rejected-native-span.diff](rejected-native-span.diff).

When the already-painted health fill and the calculator represent the same
health value, the geometry identity holds:

```text
remainingPixels × clampedAbsorb / missingHealth
= fullBarPixels × clampedAbsorb / maximumHealth
```

The first tests covered that condition. Five repeated samples each passed
4,453 assertions, including 300 public and 300 opaque geometry scenarios,
1,000 current-value/rebind updates, and public heal/antiheal/overflow/options/dead
controls. The original source rejects 304 expectations per sample under the
same forward-geometry tests. These conditional results remain useful, but do
not accept the experiment's appearance in every event ordering.

**Counterexample:** the health texture can still show60% while a prediction-only
event sees calculator health40%, maximum100, full width250 and shield amount20.
The original bar renders50 pixels of shield. The proposed remaining span is
100 pixels and the denominator60, producing **33.33333333 pixels**. Both root
and this audit identified the snapshot coupling. The counterexample executes
the actual painter and resolves its native anchor/StatusBar arguments in the
mock engine; it is not a separately hand-coded candidate branch.

The source has prediction-only event routes that call UpdateHealPrediction
without repainting the health bar first, so agreement of those snapshots cannot
be assumed from a synchronous-health test. This is a modeled permitted ordering,
not a claim that the user's native fade error came from it. Adding health writes
on every prediction event would change ownership/cadence and interact with the
health-loss trail, so that was not substituted as an unreviewed fix.

The later test run deliberately preserves the earlier conditional successes
while recording the pixel counterexample as a separate rejection gate.
[results.json](results.json) explicitly sets `GEO-01_ready_to_apply` tofalse.
[initial-matched-epoch-results.json](initial-matched-epoch-results.json) retains
the initial report unchanged; its former candidate bytes are now at the rejected
experiment path recorded in candidate.json, matched by the hash above.

## GEO-01: viable next direction, with explicit unresolved boundaries

A smaller alternative would preserve the existing full-width/max-health
normalization and replace only an inaccessible width read with **known public
layout geometry**. The shared partition owns these anchors:

```text
Health.TOPLEFT  = owner.TOPLEFT  + barAreaLeft
Health.TOPRIGHT = owner.TOPRIGHT + barAreaRight
health width   = public owner width + barAreaRight - barAreaLeft
```

The source uses those insets for ordinary and health-only frames, including
custom ToT insets and party layout. Public owner width plus validated public
insets would avoid the calculator/paint epoch coupling. This direction is
source-supported, but no code implementing it is selected here because the
following behavior still needs a complete design and bounded validation:

1. If both the health width and owner width are inaccessible on first paint,
   the helper has no previous public geometry. It must not manufacture a width,
   hide the absorb, or report success while freezing its geometry.
2. A private public-layout ledger must be populated from the existing layout
   writers, including initial frame construction, party sizing, frame width
   options, health-only/ToT insets and emulated horizontal squeeze. A cached
   width must follow real layout changes rather than becoming a stale fallback.
3. Other prediction bars still pass the health width through the existing
   UpdateFillPosition path. The explicit layered/opaque model still rejects a
   secret geometry write there. Fixing only the later forward-absorb comparison
   would not close that larger boundary when positive incoming heals or antiheal
   layers are active.

These are substantive feature-preservation limits. They are kept visible rather
than replaced by a zero-width, broad pcall, stale-art or unconditional-hide rule.
Native ownership, secret anchoring and public layout input provenance need their
own acceptance; no actual native error frame has been attributed to GEO-01.

## GEO-02: texture tiling remains held

The current overlay helper knowingly allows inaccessible dimensions past its
cache guard, then divides them before SetTexCoord inside pcall. Under the stated
arithmetic-denial model, the update is contained and leaves previous UVs. The
existing art setup already requests native wrap/tiling, so simply deleting the
UV update does not establish that the same32-pixel stripe frequency, phase and
coverage remain on changing fill widths/heights.

The current texture contract permits secret SetTexCoord arguments when tainted;
that does not establish permission for the preceding Lua division. Its public
SetHorizTile/SetVertTile flags do not by themselves specify the pixel-frequency
parity of the atlas/wrap path. A future candidate must demonstrate the same
stripe size, phase, forward/reverse-fill coverage, alpha and clipping across
health changes and scaling, with public→inaccessible→public transitions. Native
texture/atlas pixel verification is pending. No GEO-02 runtime change is present
in either selected or rejected candidate; the runner verifies its helper source
is unchanged.

## Shared.lua selection is coupled to the patched winning glow library

The ALPHA-06 hunk commits `_fluxThreatGlowBand` only after the selected glow API's
pcall succeeds. On a recolor failure it retains the old band, so the next same-band
request retries. A successful API call returning nil is still success; later
unchanged requests retain the existing skip behavior. Library selection/order,
glow frequency, border/frame levels and no-color stop remain.

Five baseline/selected pairs execute the actual threat helper with a failure,
same-band retry, nil-return success, another unchanged request and a stop. The
baseline fails two assertions per sample; the selected candidate passes all six
per sample. This small source hunk is supplied by the alpha-reader task and must
be considered with its separately tested library proposal and readiness gates.
If an external higher-version unpatched LCG wins LibStub selection, retaining
retry behavior after a failed call could increase the number of failing starts.
The hunk is therefore not recommended by itself. It does not certify native
taint safety or fix the geometry findings.

## Reproduce and inspect

```powershell
python 'Stress test doc/fix-proposals/geometry/build_candidate.py'
python 'Stress test doc/fix-proposals/geometry/run_geometry.py'
```

The builder reads the hash-verified frozen external baseline. Selected source
goes only to `candidates/geometry`; the rejected native-span source goes only to
`experiments/geometry-native-span`. The runner alternates five samples for each
comparison, keeps raw outputs, verifies the current source-contract blobs,
checks syntax and confirms that live Shared.lua remains unchanged during tests.
It creates no game input, native client operation, saved settings, profiler
change, event, frame, timer, hook or new addon service.

The four fresh Forever contracts are in [upstream.json](../upstream.json):
GetMissingHealth and absorb clamp enums; StatusBar SetMinMaxValues/SetValue
accepting opaque values when tainted; and texture coordinate/tiling argument
contracts. The external local files match the freshly fetched Git blobs. The
source reference is Forever1.60.1.70862, not a captured user runtime build.
Syntax and desktop/mock count checks do not certify native pixels, CPU/FPS,
taint provenance, secure input or every event ordering.
