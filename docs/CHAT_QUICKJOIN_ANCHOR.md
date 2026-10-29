# Quick Join anchor cycle — BUG-008

The reported 12:45:27 error comes from QuickJoinToastButton:SetPoint at the baseline
FluxChatFrame.lua line 1248. The affected client/build was not specified. The chat
column already anchors Channels below Quick Join; the older social callback then
tries to anchor Quick Join to Channels. This reverses the dependency and causes
the native error, aborting that layout callback before column reconciliation.

## Correction

[FluxChatFrame.lua](../Other/FluxChatFrame.lua) leaves Quick Join positioning to the
existing FluxCCP column whenever either Quick Join or Channels is parented to that
column. Checking both buttons covers a native reparent of either one. The enclosing
callback still runs PlaceColumnButtons, which owns their final order and geometry.
When neither belongs to the column, the existing native fallback remains available.

The six-line addition changes no dimensions, gaps, artwork, options, defaults,
click scripts, saved roots or retry deadlines. It adds no timers, hooks or frames.
Disabled/missing buttons and Edit Mode/combat deferral retain their existing owners.
No native API is replaced and no runtime error-suppression wrapper was added.

## Identities and regression

- Baseline `7465e36653a279e7276568eb2b90e147a6c38e93`, tree
  `1fadea2a65a083142392a018dedc0060673fee1d`.
- Candidate `5198ded001dde5bbc3fc5d6011239652cbe79dac`, tree
  `ffeca6fce85ff9606c7dab3f38b065bdbfdfeb70`.
- [Baseline identity](validation/chat-quickjoin-baseline-identity-2026-10-29.json)
  verifies the pre-edit archive's 728 Lua hashes against the prior 87-script suite.
  [Recovery](RECOVERY.md) records the verified source/history/private-settings
  checkpoint, captured with WoW closed outside AddOns.
- [Existing column regression](../tests/chat_column_layout.lua) now runs actual
  column and social/hook/retry functions together. Its widget model rejects direct
  and transitive parent/anchor cycles and accounts for bottom-point geometry.
  Earlier fixtures tested those owners separately and missed their interaction.

```powershell
lua tests/chat_column_layout.lua --source tests/fixtures/chat_quickjoin_before.txt --measure
lua tests/chat_column_layout.lua
python tests/run_validation.py --output docs/validation/chat-quickjoin-full-2026-10-29.json --sync-docs
```

The retained baseline passes the original 1,311 column checks, then fails 448 of
508 added ownership checks, including repeated instances of the reported cycle.
Measure mode intentionally exits zero. The candidate passes all **1,819 checks**.
Added coverage includes Quick Join on Live/Forever fixtures, both sides, native
hook bursts, either button reparented, hidden/absent Channels, Social disabled,
Edit Mode, combat/regen, repeated layouts and unmanaged native fallback geometry.
The original five-branch column controls and four rejected mutations remain.
These fixtures model specific inputs; they do not certify native client support.

## Matched observations

Five alternating baseline/candidate pairs run in fresh Lua processes. Original
column controls precede the focused scenario in each run. After column adoption,
100 native hook bursts queue the original next-frame, 0.1-second and one-second
callbacks. Captures use modeled deadlines, defaults and controlled transient
visibility settings; player settings are never changed. All four side/client
cases produce the same counts with zero range across the five pairs:

| Metric per case | Baseline | Candidate |
|---|---:|---:|
| Cycle rejections across three queued callbacks | 3 | 0 |
| Queued hook retry callbacks | 3 | 3 |
| New frames during that burst | 0 | 0 |
| Existing combat waiter created/reused later | 0 | 1 |

The baseline combat exception aborts before the existing waiter can be queued.
The candidate reaches that existing deferral; repeated layouts create no further
frames. This is restored reconciliation, not a new runtime resource owner.

[Raw baseline](validation/chat-quickjoin-baseline-2026-10-29.txt),
[candidate](validation/chat-quickjoin-candidate-2026-10-29.txt) and
[matched samples](validation/chat-quickjoin-comparison-2026-10-29.json) retain commands,
source/configuration hashes, output, counts and process durations. The
[full suite](validation/chat-quickjoin-full-2026-10-29.json) passes **87 scripts and
728 syntax files**. Chat layout/startup/retries and unrelated merchant tests pass.

Environment: Windows 10.0.26200, Lua/luac 5.4.6, Python 3.10.6; i7-12700F/20 logical
processors from prior registry evidence. GPU/RAM and the reported client's exact
build/settings/addon list are unavailable. Profilers are off. Process durations
include fixture startup and are not native action latency. Native CPU, memory,
resource totals, frame times, FPS, pixel parity, input/taint and secrets remain
pending. No performance improvement is claimed from preventing this exception.

## Native acceptance — pending

On each affected Quick Join client, record GetBuildInfo, loaded addons, profile,
resolution/UI scale, chat side and the original error trigger. Compare baseline
and candidate sequentially under the same addon identity and preserved settings.
After reload, exercise login/world entry, native chat alerts/toasts, chat tab changes,
available left/right layouts and Edit Mode exit. Hide/show Social and Channels
through the existing options; verify order, spacing, visibility and click behavior.
Enter/leave combat and check deferred reconciliation, blocked actions and taint.
Capture equivalent screenshots and frame geometry before/after. Repeat normal
startup/idle/layout bursts using the [performance protocol](PERFORMANCE_PROTOCOL.md),
accounting for profiling overhead and retaining raw samples.

Clients without Quick Join retain the native Friends button path; verify those
layouts separately. Original Wrath 3.3.5 remains unsupported/unverified. No client
row advances from this desktop replay. Vendor-open native lag confirmation remains
pending, and auction/guild-bank/void-storage callback audits remain deferred.
