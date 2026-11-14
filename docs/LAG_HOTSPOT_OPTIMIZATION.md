# Casting and inventory lag optimization

14 November 2026 — `LAG-HOTSPOTS-20261114`. This is the current broad task,
not completion of the older passive-only passes. The user requests finding and
fixing lag and spikes throughout casting, restock, auction, pending actions,
crafting, buying/selling, inventory providers, banks, mail, loot and bag updates.
Features, appearance, update speed, integrations, commands and saved data must
remain. Newer source recovery, r27 shortage preparation, minimum potion restore,
independent upgrade choices and explicit per-purchase input are the baseline.

## Requirements and acceptance matrix

| ID | Required path and preserved behavior | Owner / current evidence | Remaining acceptance |
| --- | --- | --- | --- |
| LHO-01 | Cast start, delay, channel, interruption, rejection, success, stop and completion; player/party/raid/nameplate/button consumers; unchanged live progress and fade timing | 34 owners mapped; three changed owners have 10,362 focused checks, 24 compiled controls and three pairs each; 14 existing scripts pass; native food interruption/receipt observed | Native matched CPU/frame-time attribution, channels/pet/secure contexts remain unverified |
| LHO-02 | Bag bursts, receiving/looting items, live zero and charges, deferred metadata/loading completion, grid and non-combat consumers | Provider audit: 43 existing scripts pass; baseline shared fanout and provider identities captured | Audit all fanout paths and measure remaining costs; provider switching and native receive/loot |
| LHO-03 | Built-in inventory and FluxUI's bridge to installed Syndicator, with and without the external addon | Both paths replayed; all 41 external files unchanged; 55 owned installed copies match across five clients; native food count updated with Syndicator loaded | Native provider-disabled performance/coexistence remains unverified |
| LHO-04 | Bank open/close, character/reagent/account banks, partial updates, moves, final-copy removal, persistence and provider publication | Production bank replay: 34,770 checks, 20 controls, three matching pairs; fresh-map, read errors and both independently reproduced publication failures pass | Native bank lifecycle, moves and timings remain unverified |
| LHO-05 | Mail show/close, inbox changes, receive/take, attach/send, Open All, pending restock reconciliation and command ownership | 550 attachment checks/170 scenarios, seven controls, three pairs and 19 existing mail/loot scripts pass; native food item receipt/count observed | Empty-inbox native getter/context observation only; populated/cold mail and interaction remain unverified |
| LHO-06 | Vendor open/close, restock lists, buy/sell/Junk, limited supply, price caps, metadata and transaction acknowledgement | 56 existing commerce scripts pass; bulk lifecycle 181 checks/seven controls; known merchant 262 checks/seven controls; three pairs each; independent reviews pass | Native non-transaction merchant timings remain unverified; actual buys/sales/deletes prohibited |
| LHO-07 | AH open/close/search/refresh, modern and legacy paths, shortage preparation, prices, receipts, independent upgrades and no automatic purchase | Current r27 retained; data reduction passes 800 checks, six controls and three pairs; slower native paint experiment rejected and UI bytes restored | Native whole-AH timing/interaction remains unverified; no native purchase attempted |
| LHO-08 | Pending/follow-up button, stages, readiness, count/tint/disabled state, mail/vendor/craft consumers and idle stop | Actual follow-up/craft/Init/HUD replay: 380 checks/120 scenarios, three pairs and exact work/semantic traces; no owner change needed | Native pending-stage timings/interaction remain unverified |
| LHO-09 | Crafting open/close, legacy/modern recipe facts, saved closed-profession recipes, start/cancel/finish and reagent/output updates | Existing recipe/craft checks plus 120-scenario integration replay preserve partial/final output, duplicate STOP, cancellation orders, delayed metadata and completed idle state | Native material-consuming crafting not performed; user requested simulation |
| LHO-10 | All five existing client families, appearance/features/cadence/input/settings/defaults/commands/integrations preserved | All existing client gates retained; exact source guards pass for 1,044 other Lua files, 257 assets/XML/TOCs, 85 options/binding files, seven defaults/settings owners and five license files | Native other-client secure VM, input/controller and pixels remain unverified |
| LHO-11 | Test before addon Lua edits; current exact source/history checkpoint and available settings inspection | Verified external 2,781-file checkpoint/all-ref bundle and 125 accessible settings metadata entries; no private contents copied. Full pre-edit baseline: 367 scripts / 1,055 syntax files pass; all Lua stable throughout | Keep every causal baseline/candidate identity, raw work traces, commands and errors |
| LHO-12 | Before/after simulation and meaningful regressions; do not replace functionality with slower updates or omitted work | Eight slices × three matched pairs; 46,925 focused checks/set; 71 compiled controls; full 375 scripts/1,063 syntax checks pass with stable sources | Documentation finalization; native work attribution remains separate from simulated counts |
| LHO-13 | Background Forever performance testing without prohibited item operations | Exact client/build/window verified; one bounded watch and three-pair native widget tests; specific foreground cast exception and post-reload food test observed; profiler preferences untouched | Whole-workflow native performance acceptance remains limited; no real buy/sell/delete testing |

Guild-bank and void-storage callback bodies remain excluded by the repository
rules; ordinary bank inventory remains in scope. The external Syndicator folder
must never be edited. No foreground activation, clipboard control, publication,
manual client synchronization, automatic purchase or feature removal is authorized
by this optimization task. Existing background/native testing preference continues;
no mock-up is needed because the accepted UI is being preserved. Existing native
keyboard/controller/input owners remain and need separate operation acceptance.

## Checkpoint and current progress

Main stays at `26f886e3ea5371b196ab235d2dace0c156002285` plus newer local work.
The complete external checkpoint is
`lag-hotspots-20261114/checkpoint-20261114T092731Z` under this chat's visualization
directory. Its source ZIP CRC and SHA256 manifest, all-ref Git bundle and immediate
source stability passed. All Lua baseline copies are external. Settings were
inspected as metadata only; no settings restore or quiescent backup is claimed.

`baseline-full.json` and `baseline-stability.json` record 367 passing scripts,
1,055 syntax files, no failures and unchanged source during the run. A missing
PATH/runtime attempt is retained separately; the successful helper prepended only
its own process PATH with the existing Lua 5.4.6 runtime and records binary hashes.
Desktop Lua results do not certify WoW's secure VM, native secret values, rendering,
FPS, retained memory or input. No runtime Lua was edited before this baseline gate.

Fresh source pins resolved once: Retail
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`; Forever
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676`; progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`; Era
`4192ac60067fc55566182291bc67c85dd9b6794d`; Anniversary
`68e0a2ec559d9761dfc4e7f864c3944f9d758a49`.
These are source versions, not the observed running client build.

## Verified implementation checkpoint

The first six measured slices are implemented across eight runtime files:

| Production workload | Exact baseline | Current candidate | Preserved work |
| --- | ---: | ---: | --- |
| 1,000 cast lifecycles: distinct protected callback functions | 9,669 | 9 | 11,001 protected calls, 1,000 native cast reads and 3,000 text/geometry paints |
| 1,000 button-VFX lifecycles: routing callback functions | 2,333 | 1 | 2,333 routing calls, 1,666 native cast reads, 999 channel reads, 3,334 paints |
| 1,000 warm macro metadata resolutions | 2,000 | 1,000 | Fresh resolution on the next invocation; existing cold link retry |
| 100 dirty-bag updates in a 320-slot built-in bank: Lua pairs iterations | 192,787 | 76,307 | 4,000 native slot reads, 32,000 aggregate-copy and 32,000 persistence visits |
| Same bank updates through FluxUI's Syndicator bridge: Lua pairs iterations | 147,987 | 28,307 | Current provider publication/classification, final-copy removal and update cadence |
| 100 genuinely clean bank refreshes: persistent copies | 100 | 0 | Pending publication debt still retries after errors and nested updates |
| 50 potion row refreshes: need/mail calculations | 150 | 100 | Final calculation follows replacement and merge; standalone replacement behavior retained |
| Same row refreshes: live bag reads | 251 | 151 | Charge, receipt, minimum-restore, source and price policies |
| Mail category scan of 200 nonmatching bag slots: capacity reads | 2,412 | 212 | Initial exact free-slot count and fresh per-slot availability; native QuickAttach safety checks |

Each slice has three alternating exact-source comparisons and matching semantic
traces. The six new tests total 46,482 focused checks per set and reject 57 compiled
harmful changes. One existing timer-fixture extraction follows the new hoisted
reader; its functional timing assertions remain. The combined integration passes
373 scripts and 1,061 syntax files with every Lua hash stable throughout that run.
This is an intermediate current checkpoint: later vendor fixes require new checks.
All 252 appearance/XML/TOC files and 80 options/binding sources remain unchanged.

Independent review reproduced two bank publication failures that ordinary work
tests missed: a failed Store/summary/persistence write after scans committed, and
a failed nested publication caught by an outer callback. The candidate retains
publication debt across failures with a revision guard, preserves error propagation
and allows the original nested call order. Both exact counterexamples pass after
correction. A single protected publication call is an explicit added cost; dirty
refresh still copies the existing aggregate and persists current counts.

An external crafting integration replay covers 120 scenarios across five client
families, two providers and two yields. Its three baseline/current pairs pass 380
checks and retain 280 semantic/work rows each. Partial-output storms and unrelated
cast events do not revive completed work; settlement retains five count reads,
one row read and one paint, followed by one completion hide. This replays the
actual follow-up, craft driver, inventory storm owner and HUD with native/provider
seams modeled. It is not native crafting time or permission evidence.

## Native Forever investigation and rejected experiment

The exact Forever process/window was verified from the desktop host without
activation. The running client reports 1.60.1 / build 70938 / interface 16001,
current auction build r27 and external Syndicator loaded. Profiler preferences
remain `scriptProfile=0`, `maxFPS=120`, `maxFPSBk=30`.

A contextual 30.013-second watch observed 2,152 frames, 3,211 Flux service callbacks,
two frame gaps of 52–55 ms, zero observed Flux callbacks over 10 ms and no new Lua
errors. The nearest recorded callbacks were about 2.3 ms; this does not attribute
the frame gaps to them. Focus/activity and concurrent desktop work were uncontrolled,
so this is not an FPS comparison or whole-addon CPU verdict. Original diagnostic
root identity and profiler preferences were restored and the watch stopped.

The proposed AH paint guards were rejected after native testing. The same protected
getter helper on fresh hidden native widgets took roughly 2.29–2.48 ms per 3,000
settled writes, versus 0.47–0.64 ms for direct setters, in three paired trials for
text, texture, enabled, shown and checked states. Fewer modeled setters did not
mean cheaper execution. Original AH UI bytes were restored exactly; no paint gain
is claimed. The failed experiment, including its one mock raw-field failure and
native contract research, remains external. These tests isolate method/helper
cost, not rendered AH FPS.

The user additionally authorized highest-rank Conjure Food starts/cancellations
and one completion to test item receipt, and explicitly allowed the specific cast
test while WoW stayed foreground. Native spellbook/source queries confirm rank 4 /
spell ID 6129. Initial background guards stopped a partial diagnostic setup; the
user then reloaded, clearing temporary probes and loading current Lua files. After
a fresh window observation, the helper sent four normal `/cast Conjure Food(Rank 4)`
requests and three `/stopcasting` commands without changing focus. Native captures
show Interrupted, one completed creation of eight Conjured Pumpernickel, the food
button updated to eight and no cast display remaining afterward. They prove that
observed lifecycle only, not every submitted event or a native CPU/FPS gain.
No additional Lua probes were used after that reload. No buy, sell, delete or
material-consuming craft test is authorized; crafting is simulated. Item moves are
allowed. The foreground exception does not apply to other native operations.

## Merchant lifecycle and final verification

The bulk-buy vendor path reproduced a stale captured-slot purchase loop surviving
merchant close. Its current candidate cancels through the existing native OnHide,
retires the loop before a native purchase and rearms only the same generation.
Three modeled pairs pass 181 checks across ten client/provider labels and reject
seven compiled harmful changes. Closing for ten seconds changes stale purchase
attempts 18 to zero and idle callbacks 200 to zero. Normal 45-unit buying retains
20 units at 0.5 seconds, 20 at 1 second and 5 at 1.5 seconds. Native errors propagate
once with the old loop retired; a same-stack new request keeps its own generation.
All buys and sales in tests are stubs; actual item transactions remain prohibited.

That independent bulk review now passes the 181 checks plus nine additional
argument/return/error/reentry cases. The known-item audit reproduced hidden
merchant scans and changes only the actual merchant paint: `ShouldRun` still runs
first, and only a readable native `IsShown()==false` skips it. Classic visible
callbacks remain synchronous; Retail retains its existing deferred coalescing.
Missing/error/nil/opaque visibility falls back to the original paint. One hundred
closed Classic callbacks change 1,200 link/item/tooltip/paint calls each to zero;
the coalesced Retail path changes 12 each to zero. The added cost is one protected
visibility read per actual paint, including visible paints. Three pairs pass 262
checks/110 scenarios and seven compiled controls; independent review passes.
Full-file reconstruction guards prove auction/guild/shared-known/settings bodies
remain byte-identical. No negative knowledge cache or additional delay was added.

The final source set comprises eleven runtime owners, eight new tests and one
existing extraction fixture. **375 scripts / 1,063 syntax files pass**, with all
Lua source stable throughout the final run. The read-only guard verifies all 55
owned installed copies and external Syndicator's 41 files. Current and backup
Forever saves both serialize the diagnostic root as nil with matching literal
hashes; no temporary spike-watch table was saved. This corroborates those two
saved states without making a claim about older diagnostic history.

The accepted source changes, raw pairs, controls, reviews, native observations,
source guards and final checks are indexed in the
[evidence record](validation/lag-hotspots-2026-11-14.json). Documentation validation
passes 1,096 classified sources, 623 reachable sources, 444 settings, 24 saved roots
and 17,310 local links. Continuity and parity/client/performance ledgers record the
final files. The last vendor changes were written after the user's reload and need
a later reload when ready; installed file identity does not prove a loaded version.

Native bank/mail/vendor lifecycle and timing, provider-disabled/native other-client
checks, pixels/controller and secure-VM acceptance remain unverified. No matched
native FPS gain or completely lag-free addon is claimed. The broader goal remains
active for that acceptance work; the verified implementation pass is not a
substitute for it.

## Empty-mailbox native observation

The user opened an empty inbox on the existing Forever1.60.1.70938 client.
Read-only commands confirmed mailbox shown, inbox0/total0, Flux snapshot0,
Syndicator source, reliabletrue and no native mail command pending. Three native
GetInboxNumItems trials of1,000 calls each took0.0418/0.0405/0.0398ms, including
the Lua loop. They exclude headers, attachments, metadata and publication.

In a separate12.922s passive observation, same-session _FluxUI profiler threshold
deltas for >1/5/10/50/100/500/1000ms were230/0/0/0/0/0/0. These are nested counters;
they cannot be summed or attributed to mailbox processing. The crowded city,
other addons and desktop activity were uncontrolled. This establishes no matched
optimization result, FPS gain or populated/cold-mail latency.

No mail was taken/sent/returned/deleted; no item was bought/sold/deleted/moved.
No activation, system-wide input, clipboard, profiler/FPS preference change,
saved diagnostic-root replacement or persistent Lua probe was used. All commands
used the exact verified background window; a focus change between other desktop
apps is recorded in the raw submission. The user requested native measurement
before accepting a bounded stale-mail validation delay. Empty mail cannot settle
that populated-inbox decision, which remains pending.
[Readouts and limitations](validation/lag-hotspots-empty-mailbox-2026-11-14.json).

## Continuation: recipe scans, output lookup and bulk capacity

The fresh continuation checkpoint contains 2,792 files and all-ref history; 125 settings metadata records were inspected without copying private values. The 375-script/1,063-syntax source set was the new pre-edit baseline. Current three-owner raw hashes match the sealed external candidates exactly. This continuation leaves r27 shortage preparation, saved minimum tiers, explicit purchases, appearance and update cadence under their existing owners.

Profession updates still query native recipe information, schematics, outputs and qualities on every scan. A stateless reagent collector replaces per-recipe closures. Fresh complete records avoid a redundant top-level prior-record copy; missing, partial, reagent or custom inherited facts retain the original merge policy. All craft invalidation and inventory publication pulses occur as before.

Modern output lookup reads the current mutable catalogue on each invocation, identifies matching IDs, ranks every alias of those candidates in the original order and filters the winning record. Global unlearning still applies. Legacy/unknown identities and public catalogue overrides retain the complete path. There is no output index, native fact cache, event suppression or delayed refresh.

Bulk capacity can reuse one warm owned info result for its link and count. Getter overrides are checked before and after the first read; cold links and missing info preserve the original link-then-info sequence, including the second read that may recover a count. Existing GetContainerItemLink return values remain unchanged. Slot capacity, bag-family checks and transaction consent are unchanged.

Three alternating baseline/candidate pairs pass 637 profession checks and 133 capacity checks per set, across five existing client labels and both fixture provider modes. Thirteen compiled harmful controls fail, including inheritance, alias selection, revocation, public overrides, cold recovery, reentry, link arity and specialty bags. Fifteen existing scripts pass against the preview; 61 installed affected scripts pass with all 1,065 Lua hashes stable. An independent review reproduces all 770 checks with no blockers. A new whole-suite acceptance result must be reported separately after all continuation owners are final.

| Production workload | Baseline | Candidate | Preserved work |
| --- | --- | --- | --- |
| 64 modern recipes / 3 profession events | 192 collector function identities; 384 prior-record copies | 1 collector identity; 0 prior-record copies | 192 collector calls; all native scans; 9 craft invalidations; 3 publications |
| 64 legacy recipes / 3 events | 192 prior-record copies | 0 prior-record copies | All scans; 6 craft invalidations; 3 publications; original full output-query path |
| 20 modern output queries / 64 recipes / two aliases | 2,560 alias ranks | 40 matching-alias ranks | Mutable current facts, every candidate alias, revocation, order and output qualities |
| 200 occupied capacity slots | 400 native info calls / 400 normalized rows | 200 calls / 200 rows | Same slot capacity, stack policy, overrides, errors and cold fallback |
| 40 occupied + 160 empty slots | 240 info calls / 80 normalized rows | 200 calls / 40 rows | 160 native link fallbacks; capacity 3,800 |
| 200 empty / cold-link / cold-info slots | 200 / 400 / 400 info calls | 200 / 400 / 400 info calls | Original cold and empty sequence; no read reduction claimed |

Lua 5.4 fixture timing is separate from native WoW CPU/FPS. For 500 recipes and 500 output queries, Retail median changes 0.445s to 0.131s and Forever 0.437s to 0.124s; raw ranges are retained. A 50-query allocation sample with desktop GC stopped changes about 4,756KB to 28KB. These are fixture allocations, not retained WoW heap or GC-pause measurements. Bulk empty/cold cases retain their native reads but add helper/identity dispatch: the modeled empty 200-slot scan is about 18 microseconds slower per capacity call in the first pair. Dense warm work removes actual normalization rows and native-query invocations; raw empty/cold timing regressions remain part of the evidence. Native merchant/profession timing, taint, input/controller and pixel acceptance remain pending.

Prior native food/watch/widget observations do not accept these new profession/capacity changes. The empty-mailbox observation is separate; the populated-mail latency decision remains pending. No child native input, material-consuming craft, purchase, sale, deletion, preference change, manual sync or external Syndicator edit occurred.
[Exact identities, work, regressions and review](validation/lag-hotspots-commerce-continuation-2026-11-14.json).

## Actual producer counterexamples

A continuation replay executes the installed read-only Syndicator producer,
public API and real metadata utility alongside FluxUI's actual bridge, Store,
Sync and Scheduler. Earlier provider fixtures supplied producer facts directly;
this replay covers the producer itself. Three baseline repeats, three isolation
pairs per fault and three extra controls reproduce two unresolved correctness
problems in38 checks/run:

- A cold bank metadata completion after close can re-read an unavailable native
  container, replace a real5-item bank stack with an empty provider row and reduce
  the Flux count5→0. Warm-before-close or readable-after-close controls do not fail.
- An older cold mail job can finish after inbox indices change and overwrite the
  newer result. The simple case counts an actual single attachment twice. Further
  equal-cardinality cases replace the wrong item IDs even when header/row totals
  agree. Legitimate duplicate attachments must remain separately counted.

These are actual-source failures under synthetic native facts, not observed
native bank/mail failures. No producer or mail/bank remedy was applied in this
continuation. A safe bank remedy needs independent tri-state count evidence,
count-only provenance, future-delta ownership and provider-off persistence; an
aggregate cannot establish a slot location. Existing count helpers collapse
unavailable facts to0 and cannot prove an empty bank by themselves.

All five pinned native MailFrame sources use the eighth header return as a numeric
attachment count. Header checking detects some count mismatches but cannot validate
equal-cardinality wrong identities. The provider has no public mail scan generation
or pending-state contract. An external prototype reuses the existing bounded reader;
its100-mail/16-attachment scheduling model takes about0.396–0.75s at144/60fps versus
the bridge's0.2s debounce. These are models, not native measurements. The user chose
in-game measurement before accepting that exceptional delay. An empty inbox cannot
settle the populated/cold case; mail policy remains pending.

The immutable external scanner itself performs6,501 selected native queries in
one modeled100-mail/1,600-attachment update; its metadata utility retries25 times
in10 simulated seconds when data never arrives. FluxUI cannot remove synchronous
producer work or cancel the private external queue within this bridge-only scope.
The external41 files remain unchanged. No duplicate-row removal, blanket closed-bank
suppression, circular snapshot validation or private producer mutation is accepted.
[Exact causal evidence and limitations](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).
