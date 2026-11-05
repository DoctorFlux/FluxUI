# Mail command readiness — 5 November 2026

## Reproduced failure and intended behavior

FluxUI's selected/Open All worker treats a changed header, reduced money/item
count or removed message as confirmation of its previous action. A client command
can still be pending when that data changes. The reproduced desktop scenario
separates those two states: the prior worker requests the next money/item,
return or delete action while the native command flag remains true, or reports
completion before that command finishes. It also starts a job during a command
owned by another mailbox action.

The pinned native implementations for Forever, Retail, MoP, Era and Anniversary
check `C_Mail.IsCommandPending()` before advancing their Open All state machine.
Its public boolean declaration and exact source pins are recorded in
[the native reference review](NATIVE_MAIL_AUCTION_REFERENCE.md). This established
contract discrepancy justifies a small readiness correction. It does not identify
the cause of the user's live freezes or the initiating BugGrabber warning.

## Change and limits

Before confirming or advancing a worker step, FluxUI now waits while that native
API reports a pending command. It leaves header/item confirmation in place.
The existing configured OpenSpeed wake remains the minimum before this check;
when the client is already ready, the first action stays immediate and subsequent
actions keep their configured delay. API absence retains the previous behavior.
The supported clients supply the native GetTime clock used by the deadline.

Only a busy worker schedules 0.1-second readiness retries, using the existing
coalesced progress slot alongside configured inbox-event wakes. The existing watchdog
slot enforces eight seconds from the worker's own pending action start, or from
its first observation of an initially foreign pending command. It stops with an
explicit pending-command notice at that deadline; it does not poll indefinitely.
The timer/command identity guards and stop/close cancellation remain in force.
When an initially foreign command finishes, its watchdog is invalidated so it
cannot accelerate a subsequent missing-metadata retry with no own pending action.
With After-only timers, invalidated callbacks can remain physically scheduled but
perform no work. NewTimer handles are cancelled where supported.

No native action, global API, third-party source, mailbox feature, setting,
saved-variable root or frame is replaced. No idle polling, event, frame or new
scheduler is added. Retry latency while genuinely busy can be up to the next
0.1-second check; native lag/CPU/frame-time impact remains unmeasured.

## Exact baseline and desktop regression

This phase's baseline is the current working Mail/Select.lua **after** the earlier
mail wake correction, rather than plain commit 8681672. Its exact archived SHA256
is `7f51dfbd8d9df743ad9519a41a7354bb8a39c1ea0b4d0d139d3d1db8ca246754`.
The external `native-command-baseline` checkpoint holds Select.lua, 1,484 actual
source files, 27 available on-disk settings and the previously verified all-ref
history. Its source archive SHA256 is
`fc4fcd81fb3397d61b3671bfb90b4f0605c975604d7c9edfcdf6169c5758007e`.
Settings and archives remain outside AddOns/Git; unsaved memory is not a backup.

The new regression loads the production worker with native frames/actions/timers
mocked. Its five client labels, four provider/bag labels and cancellable/After
paths exercise the shared code; they are not native emulators or provider
certification. Header state and native command completion are independently
controlled. It checks money-to-item progression, final completion, initial foreign
commands, return/delete sequences, event bursts, eight-second deadlines, stop,
close/reopen, the foreign-watchdog/metadata-retry edge, idle work, missing APIs and
ready delays of 0, 0.3, 0.5, 2 and 5 seconds.

Run from the repository root:

```powershell
lua tests/mail_native_command.lua
lua tests/mail_native_command.lua '<external-baseline>/Select.lua'
lua tests/mail_loot_scheduling.lua
lua tests/flux_mail_select.lua
lua tests/flux_mail_open_all.lua
```

The archived working baseline produces 880 failures from 7,080 dynamic checks,
360 modeled overlapping requests and 40 premature completions. The candidate
passes 14,800 dynamic checks with zero overlapping requests and zero premature
completions. Dynamic check totals differ because the fixture also checks each
created timer: the deliberately delayed native commands now perform bounded
readiness retries. Candidate aggregate native-flag reads are 8,800 and created
timers 10,560 across all scenarios; baseline reads are zero and timers 2,840.
These aggregate mock counters are not observed in-game event rates, allocations
or operation latency. No reduction in timer count is claimed for this correction.

[Five alternating pairs, raw samples and three rejected mutants](validation/mail-native-command-comparison-2026-11-05.json).
[Final140-script/795-Lua validation and exact source manifest](validation/mail-native-command-2026-11-05.json).
Wall ranges include startup/assertions and cannot be interpreted as native latency.

Existing regressions still pass: coalesced mail scheduling 3,140 checks, selected
mail 21 and Open All 18. Matched repetitions, mutation checks and the final full
validation report are recorded by the parent batch; do not reuse the earlier
139/794 result as full-suite acceptance of this additional runtime change.

## Native acceptance pending

The earlier Forever reload/read-only diagnostics established the running build
and disabled Syndicator state before this guard was added. They do not test it.
After the next authorized reload, verify money and item collection, selected and
Open All, return/delete, server-delayed commands, timeout, close/reopen and every
configured speed with and without supported bag/provider integrations. Repeat on
each available client; retain errors before reporter warnings and matched
performance samples. Combat/protection, rendering and resolution of the reported
freezes remain unverified. Keep warnings, diagnostics and profiling preferences
intact.
