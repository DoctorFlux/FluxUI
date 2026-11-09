# Forever reputation bar routing

The user reported that clicking XP/reputation did not open Reputation on Forever.
The handler explicitly returned on Forever and overlaid both bars with a secure
CharacterMicroButton click, whose native handler selects PaperDollFrame. This was
a confirmed wrong-target route, independent of inventory provider.

## Native probe and implementation

The user now confirms `/run ToggleCharacter("ReputationFrame")` opens Reputation
out of combat after the normal custom-script confirmation. This is user-provided
native API operation evidence, not a test of every addon click or gamepad state.
The correction uses that same API directly in the existing OnMouseUp handlers.
It does not execute a /run macro, call RunScript or introduce a script popup.
Both bars retain their out-of-combat check, left-button-only semantics and native
toggle behavior. Appearance, tooltips, settings and timings remain unchanged.
Only these bars lose the wrong-target overlays; shared secure proxies and other
Forever panel workarounds stay intact. No globals/native handlers are replaced,
no protected restriction is bypassed and no broad pcall is added.

[Pinned Forever CharacterFrame source](https://raw.githubusercontent.com/Gethe/wow-ui-source/aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.lua)
defines ReputationFrame and ToggleCharacter. The local Camelot binding
TOGGLECHARACTER2 uses this same panel argument. The side tab is a Frame using
OnMouseUp, so replacing the old proxy target with that Frame was not a supported
Button-click substitution. The earlier panel-taint workaround in Core/SecureClickProxy.lua
motivated the native probe; this fix does not claim general resolution of those
protected/gamepad/secret-value issues.

## Recovery and desktop checks

Baseline e36c14e5c1cdc442839666de69e3d24cddad2af6. Before editing, verified external
Forever-rep-apply-20261105T091230Z source/history/settings recovery:1,443 actual
files including pending investigation records, verified Git bundle and123 on-disk
settings files, outside AddOns. Source ZIP SHA256:
`3d7b9beb5802a357cf22c7b3fa100b6f4b21c9be58b05f406a6a45e3305ff999`.
Earlier investigation recovery Forever-reputation-20261105T090732Z is retained.
No private settings were committed; no profiler preferences changed.

[Raw matched pairs, exact normalized runtime hash and probe status](validation/forever-reputation-comparison-2026-11-05.json).
[Full source manifest and validation](validation/forever-reputation-2026-11-05.json).
[Behavior regression](../tests/status_reputation_clicks.lua).

Five alternating fresh-process baseline/candidate pairs: baseline18 failures,
candidate0 per180 checks. The real click block is exercised across five client
labels, both bars, closed/PaperDoll/Reputation states, right click, combat and
missing native function. No native secure VM is simulated. Warm-up0, no profiler;
wall times include startup/assertions, not native latency. Initially the full
suite failed two old core-smoke string assertions requiring Character Info and
Forever's early return. Those obsolete assertions were removed, while the gold
bar guards remain; the new behavior fixture replaces their coverage. Final full
suite128 scripts/783 Lua syntax files passes.

No new event, timer, frame, hook, polling, layout scan or dependency. The two
Forever bar-specific proxy attachments are removed; other clients already used
the same native toggle and retain that route. No FPS/memory improvement is claimed.

## Native acceptance still pending

After synced files load with /reload, check XP and watched-reputation bars from
closed CharacterFrame, PaperDoll open and Reputation already open. Left-click
selects Reputation (or toggles it closed when already selected); right-click leaves
panels alone. Check mouse tooltips/hover, UI scale, repeated clicks, combat no-op,
and recovery after combat. Check gamepad enabled/disabled and errors/taint. Other
clients should retain their prior behavior. The current Forever executable was
last observed as1.60.1.70790; the user's probe did not include GetBuildInfo, so that
is not a fresh runtime build capture. Full bar-click/native/pixel/taint acceptance
remains pending. No foreground/input/clipboard control or automatic game test was
performed. Original auction Buy latency remains a separate pending native check.
