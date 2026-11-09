# Concurrent source review and modifier scope correction

This is a bounded read-only review of four files changed independently during
round2. The audit issued no addon/runtime/test/TOC/settings changes and did not
replace the other actor's work. Earlier whole-addon byte-preservation claims
apply to their recorded window only. The current repository has moved since
the initial round-2 snapshot.

[results.json](results.json) records exact before/after hashes, four initial-to-
current patches, consumed dependency hashes and focused test output. The four
reviewed identities were stable through this probe window:

|File|SHA-256|
|---|---|
|Shared|`001c9471de765d1a87d112a81210890754c93e0e2c6e9225633e29d9ace66312`|
|Party|`ac0f1b747d7281852a8c2bf7fa9059a073f600869bffd047fa5f55a8feedabbc`|
|raid_party_frames fixture|`b8af0cfde2f043d14d2e868e6ca8f6a43f7c8aaf8fc98d0e798877d92ce96129`|
|unit_indicator_layout fixture|`ef558111e9363c5e14618640e905c333d44f66255b01be7c8d5aaf5db7451c69`|

The executable delta introduces shared CreatePvpBadge/UpdatePvpBadge formatting,
routes normal party through it, places native prestige/faction art behind the
level, and removes native PvP visibility/width reads from compact status/name
packing. Party reuses the shared prestige textures instead of another copy.
There are also unrelated comment-encoding changes in Shared; they are preserved
in the patch, not silently normalized back into the source.

No new reproducible fault was established in that bounded PvP delta. The new
probe executes the **current addon factory/formatter and the complete reference
UnitFrameUtil.lua**, using the actual Camelot/Mainline style tables.192 scenarios
and888 assertions cover player/target/focus/party, ordinary PvP/FFA/unflagged,
prestige and mercenary combinations, modeled secret visibility sinks, option
hide, layout-only query suppression and contextual game-rule suppression.
No native visibility getter is read by the formatter, and repeated updates
allocate no additional textures in this model.

The actual reference helper deliberately supplies no prestige art on Camelot;
Mainline prestige displaces the plain faction icon when supplied. Player-only
mercenary checking matches native PlayerFrame's call convention. The API is
explicitly documented in its source as safe for addons to call. Its internal
secret wrapping is **modeled**, not a simulation of native untainted execution
or proof of combat permissions/pixels.

The complete reference file and both style paths have these local Git blobs:

|Reference path under Blizzard_UnitFrame|Git blob|
|---|---|
|Shared/UnitFrameUtil.lua|`60d5da8b429c3ac397a39fa576ab939b1a6b08ab`|
|Camelot/UnitFramePvPIndicatorStyle.lua|`8ff587eea815a5aa2cdbbfa6f11977b630ccf074`|
|Mainline/UnitFramePvPIndicatorStyle.lua|`e5a493a35b1c3f70af9587618ae0d8d3fb5d11b7`|

These came from the Forever reference at pin
`9dc84f0d3bbae1768ac3405b3716000bd93eda06`. The probe's `live` label exercises
the Mainline style contained in that checkout; equivalence to the current Live
branch helper requires root's separate primary fetch. Native input, rendering,
secret aspects and protected execution remain pending.

Existing current focused tests also pass:299 indicator,905 party,264 restricted
driver and206 identity checks. R2-DOM-04's current11-check opaque-level probe
still reproduces its five conditional arithmetic denials. Its complete portrait
and threat-raise function bodies are unchanged from the initial round-2 snapshot
after line-ending normalization, despite shifted line numbers and unrelated
whole-file changes. It remains a conditional getter-contract risk; the new PvP
work does not prove that those actual frames have secret FrameLevel aspects.

## R2-MOD-01 scope correction

The earlier modifier work fixture declared PagingWorks=false for the Forever
label. That forced the unsupported-paging fallback; it must **not** be described
as ordinary current Forever out-of-combat work. The current source separates
generic Restricted.Works from the repaired secure-paging capability probe.
Bars.Watch only calls ApplySlotsInsecure out of combat when UsesSecurePaging
returns false. The independent Binding reviewer found no ordinary supported-
paging keyer corruption from the previously flagged last-row fallback lead.

The new eight-assertion control varies paging capability independently of the
client label and executes the same actual production functions:

|256 events /57 hosts|Host visits|SetAttribute calls|
|---|---:|---:|
|Supported paging, out of combat|0|0|
|Unsupported paging, out of combat|14,592|379,392|
|Combat, either capability|14,592|0|

The retained R2-MOD-01 headline is raw **combat** host walk/reindex work before
display coalescing. Its normalized priority is P3, an optimization candidate
requiring input/cadence regressions and native measurement. Historical raw
evidence remains unchanged; [scope-correction.json](scope-correction.json)
supplies the correction for the unified roadmap. No native paging capability
capture or FPS benefit is asserted.

Run the bounded review again with:

```powershell
python 'Stress test doc/round-2/concurrent-review/run_review.py'
```

A later source change invalidates a claim about these exact identities. Root's
fresh coherent current full-suite validation and preservation reconciliation
remain separate requirements; this focused report is not a current whole-addon
pass or a completion claim for the larger audit.
