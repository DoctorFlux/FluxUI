# Built-in inbox snapshot preparation — 5 November 2026

The native inbox scan already limited each update to 48 header/attachment reads
or approximately 1 ms. Its completion then fingerprinted every captured row and,
on change, cleared and rebuilt the entire normalized snapshot in one update.
A real-module replay of 100 messages with 16 attachments each reproduced 1,600
normalized-row constructions in that final update. Five unchanged scans still
formatted 8,000 fingerprint fields. This is measured Lua work outside the scan
budget; it does not establish the cause of the reported native freeze.

The existing scan now prepares a private index and counts alongside each accepted
attachment, before the same budget check. It compares ID/count/order with the
last completed index and reuses identical normalized rows without modifying them.
Only changed completed jobs publish. Publication swaps the completed maps, updates
the saved list and generation, then notifies once. There is no full-list finish
loop, fingerprint string or additional retained fingerprint array.

The mail snapshot region object stays stable; its internal byIndex map changes
identity when a changed generation completes. This intentional ownership change
allows atomic publication without copying the entire index at completion.
Repository inspection found inventory producers and on-demand Index readers of
the inner map. GetSnapshot exposes bags/bank/warband/equipment, not mail. No live
consumer was found caching a mail index. Readers continue to see a complete map,
counts and generation, never the staged partial inbox.

Original equality remains metadata-insensitive: icon, quality and expiration alone
do not publish. When an ID/count/order change occurs, the full newly captured
saved list retains current metadata. Comparison uses the last completed snapshot,
not the saved mail list: successful outgoing mail can optimistically append to
that list, including self-send, without changing native inbox facts. First empty
refresh still publishes. Missing attachment IDs preserve the old complete
generation through the existing two bounded retries. Sparse sixteenth slots,
force-on-close capture and reopen behavior remain supported.

The replay also reproduced stale-job continuation when a count/header/item getter
synchronously delivered a refresh, close or provider handoff. Local job identity
and provider checks now run immediately after each source getter. A retired job
cannot continue reading or publish into provider-owned data, and cannot cancel a
newer queued generation. Readiness transfer also releases comparison references.

Baseline: `437fda79136582282dde0f3989f3cb70c4411bad`; Mail.lua SHA256
`9e64708892ffbd8a8e00d4ac99f6bd952baf65d313ae07a000b207180a75cf31`.
The verified external Mail-auction-publication-20261105T173546Z checkpoint covers
1,503 actual source files, 122 available on-disk settings and all-ref history.
Source archive SHA256:
`4921e61d4bce4f648bd95b428f7a0acea9eb11dfc99b0c66d1d5b32fd9a31f48`.
Baseline fixtures, source archives and private settings stay outside AddOns/Git.

```powershell
lua tests/builtin_mail_publication.lua
lua tests/builtin_mail_publication.lua '<checkpoint>/mail-publication-baseline.lua'
lua Inventory/_tmp_inventorylag_smoke.lua
lua tests/pending_mail_provider_handoff.lua
```

| Real production operation measured by the desktop replay | Baseline | Candidate |
| --- | ---: | ---: |
| Normalized records for the 1,600-attachment arrival | 1,600 | 1,600 |
| Peak normalized-record constructors in one update | 1,600 | 46 |
| Fingerprint fields on that arrival | 1,600 | 0 |
| Persisted capture rows across five unchanged scans | 8,000 | 8,000 |
| Fingerprint fields across those unchanged scans | 8,000 | 0 |
| Normalized records for one quantity change | 1,600 | 1 |
| Old index rows cleared for that change | 1,600 | 0 |
| Old index rows cleared when only two money mails remain | 1,600 | 0 |

The focused test loads real Store/Mail modules. A Lua debug line hook counts
production record constructors; the isolated concat/wipe implementations meter
fingerprint fields/characters and old-map row clears. It does not count every Lua
instruction, allocation byte or native cost. Zero-cost mocked getters exercise
the 48-read limit; a separate 0.25 ms/getter clock exercises the existing 1 ms
yield. At normal cost the 1,600 rows spread across bounded updates. The final test
passes 8,194 checks. The exact baseline fails 25 of 8,203 checks, including stale
source continuation and provider-generation corruption. Dynamic totals differ
because the baseline incorrectly publishes additional intermediate generations.
Existing inventory pipeline smoke passes 1,732 checks and outgoing-provider
handoff passes 410. The [raw comparison](validation/builtin-publication-comparison-2026-11-05.json)
records five alternating pairs per scenario and eight rejected mutations across
both sources. The [full report](validation/builtin-publication-2026-11-05.json)
passes 147 scripts and 802 Lua syntax checks and identifies the complete corpus.

This trades temporary index/count maps during each scan for removal of the final
preparation burst. Persisted attachment capture rows still allocate on unchanged
scans; a lower total allocation-byte or retained-memory-byte count is not claimed.
Individual native getters cannot be preempted. Store.MarkPending and inventory
listeners retain their existing work outside this scan budget. The same quiet
time, maximum wait, events, retries, frames, settings and public behavior remain;
no new timer, poller, global replacement or framework was added.

This changes built-in observation, not Blizzard buy/post/cancel/loot commands.
Native mailbox opening, closing, delivery and bulk looting; auction buyer sales;
client/provider/bag combinations; frame time, secure behavior, taint and pixel
parity remain pending under [the flow record](MAIL_AUCTION_REWORK.md). Desktop
counts do not establish native rendering, FPS, memory-leak behavior or a freeze
cure. No game input, enable-flag change or profiling was used for this work.
