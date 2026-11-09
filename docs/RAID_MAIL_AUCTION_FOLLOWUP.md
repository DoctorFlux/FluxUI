# Raid readiness, mail and auction follow-up — 5 November 2026

Baseline main is `8681672ef364677477b48ce8c255d68ee9c9e326`. The user requested
remaining UNKNOWN header errors, mailbox open/close/loot, then renewed the
own-auction-sale lag report with 20 BugGrabber execution-limit warnings.
These are separate paths; the reporter stack does not identify the first fault.

The later [native command readiness phase](MAIL_NATIVE_COMMAND.md) adds a fifth
correction and final140/795 validation. This document's139/794 comparison preserves
the earlier measured tree; it is not silently relabelled as the later candidate.

## Reproduced failures and corrections

**Raid readiness.** The previous change correctly detected failed child
precreation, but its caller still marked setup ready and showed all headers.
When UIParent was hidden, revealing it during combat could request missing
children. Actual capacity now determines readiness. Incomplete custom headers
remain hidden, native fallback remains available and the existing combat queue /
layout coalescer completes setup before handoff. A once-only observer on the
owned container handles ancestor reveal. No UIParent/native-header hook or new
frame is added; normal startup remains the same bounded 80-child pool.

The new retry respects an installed owned pet-battle driver's hide state. A
capability-gated close event and after-only observer on that owned driver handle
late state changes through the existing coalescer. Native driver updates may
follow the close event by its existing 0.2s throttle; no custom polling was added.
The original restricted attribute handler remains intact. Already-ready visibility
behavior and the inherited capability predicate are not redesigned. Native
availability of that predicate's global XML-template check remains unverified.

**Mail looting.** Each duplicate inbox update previously created another progress
timer. The run-only guard also let an earlier action's eight-second watchdog
resume a later action before its configured opening delay. The worker now has
two logical wake slots, matching the current run, pending action and request.
Duplicate updates retain the earliest requested deadline; an earlier OpenSpeed
preference can supersede it. Native cancellable timers are used when available;
After-only fallback callbacks can remain scheduled but become inert after token
invalidation. Close/stop cancels or invalidates both slots. No native mail action
or timeout policy was removed. Default speed stays 0.5s; actual actions remain
one-at-a-time and server-confirmed.

**Mail details.** Copy/Forward availability used to build full copy strings and
invoice text even for hidden or disabled controls, and reread the same header.
It now exits for effectively hidden/disabled mail, reads one header/body while
visible and expands invoice text only when Copy is requested. Full copy text,
empty/bodyless invoice behavior, forward restrictions, controls and settings
remain. Visible native GetInboxText cost is not eliminated.

**Auctions.** Installed Syndicator 289 clears an owned-list cache, then emits
AuctionsCacheUpdate after every appended row in both modern and legacy paths.
Flux rebuilt every growing prefix. Its unchanged-snapshot guard did not cover
that quadratic path. The adapter now queues one function in the existing inventory
scheduler bucket. It rebuilds the final available provider list before inventory
listeners and adds the auction token only for changed facts. Existing publications
were already coalesced: their count and tier remain unchanged. With a busy bucket,
the existing work budget can defer its function to a later inventory flush.

The appropriate native owned-list event joins that same queue after provider
readiness, covering zero-row refreshes that emit no provider callbacks. Event
order, foreign characters and ownership handoff are guarded. Public direct rebuilds
remain synchronous; mail cadence, guild-bank and void callbacks are unchanged.
Asynchronous metadata can publish further available facts on later flushes, as
the provider completes them. No external addon code was copied or edited.

A formatted sale notification alone emits one provider callback and was linear.
The large cost above concerns full owned-list refreshes. The reported live sale
spike is not yet proven to take that route or originate in FluxUI.

## Reference comparison with Syndicator

The latest failing setup is **Syndicator unloaded**, confirmed in game after
reload, with FluxUI loaded. The external-provider optimization above therefore
does not establish a fix for that setup. The user also supplied mail-loot and
close notices during the freezes. Those notices perform bounded completion/UI
work and simple earnings arithmetic; source review found no full inventory scan
initiated by printing them. This does not measure their native cost.

Installed Syndicator289 is All Rights Reserved and was inspected read-only. Its
modern sale/cancel handlers remove the matching auction ID in place; cancelled
or expired items join cached mail, sold items do not. Its initial modern query
waits for native throttle readiness. Its full owned-list refresh still processes
all rows synchronously, and its next-update mail scan walks the entire inbox and
attachment links. It is not evidence that every reference path cannot lag.

FluxUI's built-in auction/mail provider already quiet-debounces updates, yields
near a 1ms budget and caps reads at32/48 per frame. Existing
`lua Inventory/_tmp_inventorylag_smoke.lua` passes1,732 checks for batching,
close/reopen, last-item removal and bounded missing-data retries. A possible
currency header expansion/event feedback needs a native causality probe; no
speculative currency or query-policy change was made. No code/assets from the
reference addon were copied or edited.

## Recovery, measurements and regressions

External `Raid-mail-followup-20261105T132922Z` preserves 1,476 actual source files,
verified all-ref history and 127 on-disk Flux settings files. ZIP integrity passes.
Source SHA256: `7e93c0389e49c00c6e7d44c6130f22836fe81894cabcdfb36898a2cff18c619b`.
Archives/private settings remain outside AddOns. Unsaved game memory is excluded.

[Source hashes, five alternating pairs per scenario and eight rejected mutants](validation/raid-mail-auction-followup-comparison-2026-11-05.json).
[Four-fix stage full validation and Lua manifest](validation/raid-mail-auction-followup-2026-11-05.json).
[Earlier mail/raid-only validation](validation/raid-mail-followup-2026-11-05.json).

| Desktop workload | Baseline | Candidate |
| --- | --- | --- |
| Hidden-ancestor combat reveal, per raid contract model | 9 modeled denied missing-child creations; no recovery | 0; 80 children after safe recovery |
| Normal raid startup | 80 children | 80 children |
| 100 duplicate mail updates across 40 worker models | 4,000 timer creations / pending header checks | 40 / 40 |
| Visible mail availability, 100 updates across 20 models | 4,000 header / 2,000 body / 2,000 invoice reads | 2,000 / 2,000 / 0 |
| Hidden availability / disabled availability reads | 6,000 / 3,000 | 0 / 0 |
| 500 progressively published auction rows across 10 models | 5,000 rebuilds; 1,252,500 row writes; 5,000 maps; 5,000 requests | 10; 5,000; 10; 10 |
| Auction inventory publications | 10 | 10 |

All count results repeat identically over five matched fresh-process pairs.
Measured bursts exclude initialization/control checks. Real production modules
run with native frames/mail actions mocked; the auction regression also uses the
real scheduler. Client/provider/bag labels exercise shared contracts, not native
client or provider emulation. Server confirmation, 20-action watchdog overlap,
opening-speed changes, close/reopen isolation, disabled features, current copy
contents, UI fallback, combat recovery, late pet state, zero auctions, metadata,
sale/removal and startup/handoff controls pass.

Focused candidates pass 290 raid, 3,140 mail-worker, 380 mail-availability and 365
auction checks. Baselines fail 85, 940, 100 and 75 respectively; the auction
baseline executes 350 checks because registration checks run conditionally.
Full validation passes 139 scripts / 794 Lua syntax files. Existing startup
assertion sites are retained; its mock now models real child attributes, so
completed pools skip redundant operations and fewer dynamic guard calls occur.
Existing auction fixtures now execute scheduler functions before notification.

Raw wall-time ranges include startup/assertions and are not native latency.
Native CPU, allocations, frame time and leak acceptance remain unavailable.
Snapshot writes are counted Lua records, not measured native memory bytes.
The desktop runs do not change profiler settings or force GC. A later optional
native profiling attempt and verified cleanup are recorded below; settings and
prior diagnostic roots were preserved.

## Actual native observations and limits

The first process checks were sandbox-limited and incorrectly appeared to show
no client. That conclusion is withdrawn. Read-only host inspection confirmed
Forever, executable 1.60.1.70790, running since 13:05 CET. A background PrintWindow
capture at 14:57:35 CET shows its auction and bag UI at 1906 by 1032 window pixels;
foreground handle stayed unchanged. The private screenshot is outside Git.
This is a real UI observation, not a reload, transaction, raid/combat test,
matched pixel comparison or performance measurement.

The saved UNKNOWN header event is 13:51:46 CET, before commit 868 at 14:20:13 CET.
The later disk-save time does not make it a post-fix reproduction. A fresh user
report at 14:53:50 CET contains 20 reporter execution-limit warnings, with no
preceding underlying error recovered. BugGrabber v12.1.1 publishes its error
callback from the shown stack. BugTabs v1.4.9, visible as loaded in chat, subscribes
and updates display work even on duplicates. Those source observations do not
prove which addon initiated the warning or which component exhausted the budget.
Error capture, third-party files and settings are unchanged.

The user approved brief foreground/reload/read-only checks. Initial activation
checks refused input, with a transient DWM "World of Warcraft (Not Responding)"
window observed. Forever reported responsive at15:30:35CET. A split chat-focus
attempt subsequently lost its target and activated game shortcuts instead of
running the diagnostic. That path was stopped and replaced by one short
Escape/Enter/command sequence. No mouse or clipboard control was used.

The approved `/reload` succeeded at15:32:54CET (loading capture15:32:56). All five
changed runtime files were byte-identical in the synced Forever folder before
reload. The15:34:12 read-only command returned GetBuildInfo **1.60.1,70790,
Nov3 2026,interface16001**, `_FluxUI=true`, `Syndicator=false`. At15:35:48 the
read-only error/setup check returned session23,11 historical error objects,
scriptProfile0 and secureConfigured=true, with no current-session messages
printed. These are native startup/read-only observations, not combat or lasting
error-free acceptance. Normal crafting/mail activity visible in chat is not a
controlled transaction test or latency measurement.

The reload saved the prior error history: reporter-only counter50 in session22,
last15:32:51CET; BugTabs entries14:53:50/15:03:09/15:27:44/15:32:51. No initiating
fault was recovered. The original UNKNOWN remains historical. Four freshly saved
settings/error files were privately archived outside AddOns; hash and integrity
are in the comparison, contents excluded from Git. No diagnostic roots were
reset, warnings disabled or profiler settings changed. Successful checks restored
the prior window when different; if Forever was already foreground, it remained
there. Background-only operation resumes after this brief exception.

Native mail/AH lag attribution, timings, complete addon list and all-client
acceptance remain pending. The absence of new errors in this short snapshot
cannot establish that the user-reported freezes stopped.

## Subsequent native failure and capture cleanup

The user confirmed the same freeze **after** the15:32 reload, so the current
Syndicator-unloaded lag remains unresolved despite the startup sanity above.
An optional CPU-profiled capture was attempted: profile1/reload15:41:45CET,
60-second capture started15:42:20. The client became unavailable before the
report could be saved. The user reported a crash while opening much auction
mail; host inspection confirmed originalPID38964 exited and newPID33872 started
15:48:36. No new crash report was found in the inspected ForeverErrors/Logs.
The capture is **lost/inconclusive**, not a completed benchmark or proof of which
addon caused the exit. Profiling and endpoint enumeration add overhead.

On the restarted, verified client, profile0/reload succeeded15:50:55 and native
readback15:51:34 printed FLUXCLEANUP0 true false (FluxUI loaded, Syndicator not).
The previous capture root was nil before/after, checked with a literal-only
parser against the private archive; SavedVariables Lua was never executed. The
previous foreground was restored. Cleanup is complete. No further heavy capture
is run; future attribution should use a narrower diagnostic and retain raw data
before optional profiling overhead or a client exit can invalidate it.

The [pinned native mail/auction comparison](NATIVE_MAIL_AUCTION_REFERENCE.md)
records source/load paths across all five clients. Source review is separate
from testing actual runtime or identifying the crash.

## Client evidence and remaining checks

Source pins remain Forever `eac30af597e5aaa43a60f6675ef5fdcea100375f`
(1.60.1.70790), Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783), MoP `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`
(5.5.4.70631), Era `4192ac60067fc55566182291bc67c85dd9b6794d`
(1.15.9.70576), Anniversary `68e0a2ec559d9761dfc4e7f864c3944f9d758a49`
(2.5.6.70577). The relevant native group-header gate was verified in all five
branches during the preceding correction. Current Forever
[MailFrame](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua#L781)
uses the fifth GetInboxText return for invoices. The
[state driver](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua)
uses a throttled native update. Installed Syndicator/Baganator and external logger
source hashes are in the comparison. No original/modern Wrath certification is
implied. Active Forever GetBuildInfo was captured as above; profile/UI scale, hardware
and complete enabled-addon list remain uncaptured.

With the approved Forever reload complete, keep these scenarios separate on each available client
and supported provider/bag combination:

1. Mailbox open and close without taking anything; open text/invoice messages;
   Copy/Forward enabled/disabled; selected/Open All loot; delayed items, full bags,
   timeout, stop/reopen and configured speed. Preserve actual transaction semantics.
2. Native owned-list refresh at several listing counts, last-listing removal,
   posting/cancellation and naturally observed sales. Retain full errors preceding
   reporter warnings. Match source/config/hardware and warm-up, capture duration,
   repetitions and profiler overhead before interpreting timing.
3. Raid setup with UI hidden, ancestor reveal in/out of combat, native fallback,
   regen, party/raid/solo, MT/MA growth, feature toggle and pet battle. Check the
   inherited XML-template capability predicate natively; XML declarations alone
   do not establish a Lua global. Capture actual header/taint provenance if UNKNOWN
   remains. Do not infer that this modeled capacity path identifies its writer.

Screenshots/secure behavior/FPS and actual lag removal remain pending. Keep
diagnostic roots and preferences intact; do not disable warnings to obtain a pass.

## Latest isolation

The user subsequently fully unloaded FluxUI and reports no freezes in that state.
This supports a FluxUI-dependent path or interaction, without identifying the
module. External Syndicator had already been confirmed unloaded during failure.
FluxUI stays disabled while the built-in provider, shared inventory consumers and
mail/auction hooks are audited. The final guard reload attempt was refused by
the foreground check; no native presence/transaction pass is claimed for it.
