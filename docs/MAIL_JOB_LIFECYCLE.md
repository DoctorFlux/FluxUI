# Mail job ownership and cancellation — 5 November 2026

Two defects were reproduced through the real Settings, Select and OpenAll modules.

- When the last eligible content disappeared while its native command was still
  pending, clicking “In Progress” returned from the empty eligibility scan without
  reaching the worker's existing stop toggle.
- Disabling the running job's module, directly or through a profile switch/copy,
  restored Blizzard's Open All button while Flux's worker remained active. A later
  acknowledgement let the disabled worker issue another take action. An initial
  foreign-command wait also kept polling after disable.

These are confirmed control/lifecycle failures. They do not identify the cause of
the reported whole-game auction/mail freezes or establish a native lag cure.

## Correction and preserved behavior

An active Open All click reaches the existing worker stop path before rebuilding
the eligibility list. Its final header can be empty or gone. Module notifications
now stop a worker only when its owning module is disabled; this includes existing
profile notifications and bulk module settings. A step checks its owner's current
flag before issuing work, covering a saved-flag change without a notification.

Stop cancels native timer handles or invalidates After callbacks through the
existing wake identities. It clears the addon job and updates its existing
controls. The already-issued native command remains untouched. Disabling Select,
DoNotWant or Copy does not stop a still-enabled Open All job; disabling Open All
does not stop a still-enabled Select job. Selected return/delete jobs remain
owned by Select.

Reenable/reopen starts a fresh job with the existing immediate first action,
configured retrieval delay and server/native-command confirmation. Existing
default speed, filters, bag reserve, timeout, button labels/positions, profiles
and saved-variable roots remain. No new event, timer, frame, recurring poll,
public service or native API replacement is introduced.

## Recovery and desktop evidence

Baseline main is `e860ce6de499a7702b91e8a8d74f115fbc9e0293`.
External checkpoint Mail-auction-lifecycle-20261105T171132Z preserves 1,496 actual
source files, 75 on-disk settings files and verified all-ref history. ZIP integrity
passed; source ZIP SHA256 is
`38c16e1f0d1d928ffb6015a89ad10e78f991dc038d0d738f7d3483ace86a0e5e`.
Private settings/archives remain outside AddOns and Git; unsaved game memory is
not covered.

Exact baseline file SHA256 values:

- Select.lua: `277425766d4703de6e74a9730b2cff88b502e0e877203054aaee8485e280d0a0`
- OpenAll.lua: `99342498ad5cf506d0419d8fd4287a36640a6560900302bda623d612606291b6`

The regression uses native command, frame and timer mocks with real settings and
worker modules. Five client labels and both timer variants exercise shared code;
they do not emulate native client behavior. Baseline and candidate execute the
same 880 checks.

| Measured fixture result | Baseline | Candidate |
| --- | --- | --- |
| Failed checks | 330 | 0 |
| Native requests issued by disabled jobs | 90 | 0 |
| Readiness reads after disabling a waiting job | 810 | 0 |
| Final-mail cancellation attempts leaving the job active | 20 | 0 |

Controls cover direct disable, profile switch/copy, bulk settings, delayed flag
changes, the last letter/empty inbox, pending native commands, cancelled/stale
wakes, independent modules, return/delete and fresh reopen cadence. Existing
native-command, scheduling, Select and Open All regressions pass 14,800, 3,140,
21 and 18 checks respectively. Full validation passes 145 scripts and 800 Lua
syntax files. Five alternating pairs per scenario and eight rejected mutations
across the mail/auction changes are in the
[raw comparison](validation/mail-auction-lifecycle-comparison-2026-11-05.json);
the [whole-addon report](validation/mail-auction-lifecycle-2026-11-05.json)
contains the exact normalized Lua source manifest. Desktop checks pass;
native performance remains inconclusive.

```powershell
lua tests/mail_job_lifecycle.lua
lua tests/mail_job_lifecycle.lua '<baseline>/Select.lua' '<baseline>/OpenAll.lua'
```

These are desktop request/read counts, not native CPU, allocation bytes, frame
time or operation latency. No game input or profiling was used for this slice.
Matched native source identity, last-mail cancellation, disable/handoff, profile,
reopen, taint and mail/AH latency checks remain pending on each available client.
