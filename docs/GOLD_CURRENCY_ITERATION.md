# Gold-strip currency iteration — 5 November 2026

## Failure and correction

The gold-strip update walked modern watched currencies until the API returned
nil. A repeated non-nil reply therefore grew the display string indefinitely.
The production-function fixture reproduces that failure by returning the same
valid-looking currency record at every index. Its test-only API budget stops the
old function at query65; this is not an in-game query or execution limit.

The existing modern branch now keeps currency IDs seen during that one update.
It stops before rendering a repeated ID or an invalid, nonpositive, nonintegral
or unreadable ID. A valid prefix remains visible. The set is local to the call;
it adds no global cache, event, timer, frame or polling service.

All distinct valid currencies still display in their original order and format,
including lists longer than three, six or the current backpack width. There is no
arbitrary currency-count limit. Nil remains the normal end of enumeration. The
legacy currency-list branch is unchanged. Money formatting, PvP/item tracking,
layout, accent refresh and unchanged-display fingerprint behavior remain.

This is a defensive termination correction, not proof of the user's native
freeze cause. No actual Forever repeated/default currency reply has been
captured. The user reported no freezes with FluxUI unloaded, but that does not
isolate this function. Native mail/auction performance and rendering acceptance
remain pending; FluxUI stays unloaded at the user's request.

## Client contracts and sources

The task's pinned generated schemas for Forever1.60.1.70790 and
Retail12.1.5.70783 define `BackpackCurrencyInfo.currencyTypesID` as a non-nil
number, without a secret-field annotation. The getter may return nothing.
The check for an unreadable value prevents using one as a table key or comparing
it; it does not attempt to reveal restricted values.

- Forever `eac30af597e5aaa43a60f6675ef5fdcea100375f`:
  [generated currency contract](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua),
  [loaded Camelot token implementation](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_TokenUI/Camelot/Blizzard_TokenUI.lua#L666).
- Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`:
  [generated currency contract](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua),
  [native token implementation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_TokenUI/Blizzard_TokenUI.lua#L614).

Those native UI loops use their geometry-derived `GetMaxTokensWatched()` limit.
That establishes a bounded native caller, not the behavior of an invalid index.
The native cached visible-count helper and current frame width are not used to
truncate FluxUI's valid watched-currency display.

The exact Era `4192ac60067fc55566182291bc67c85dd9b6794d`, Anniversary
`68e0a2ec559d9761dfc4e7f864c3944f9d758a49` and MoP
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` generated currency schemas were
also read. They do not declare the modern getter or its structure; their native
token UI uses the older global tuple API. This is not five-client certification
of the modern structure. FluxUI's existing legacy branch is covered separately
by the fixture and has no runtime changes in this phase. No reference code or
assets were copied.

## Recovery and desktop evidence

Baseline main is `b664bb0b93ac566a34744aec5895e927a7a1ffff`. Before the change,
external `Builtin-inventory-20261105T152153Z` preserved1,488 actual source files,
75 on-disk settings and verified all-ref history. Source ZIP SHA256 is
`c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`.
The archived `StatusBars/FluxStatusBar.lua` SHA256 is
`b8254e6e10d01cb2f09d27197dad85d3181f78a8ebab7d06e6032dbadbab00ed`.
Backups/settings stay outside AddOns and Git; unsaved game memory is excluded.

Run the actual update-function fixture with optional alternate baseline source:

```powershell
lua tests/gold_currency_iteration.lua
lua tests/gold_currency_iteration.lua '<external-baseline>/FluxStatusBar.lua'
```

Candidate512 checks pass; baseline376 of512 fail. The modeled200 repeated-reply
pulses perform13,000 queries and never complete under the baseline fixture
budget; candidate400 queries complete all200. No native operation rate or
latency is inferred from these counts. Valid-list API reads are unchanged, with
one small per-update set added. No general CPU/FPS or allocation reduction is
claimed for valid data.

The fixture uses the production function with native widgets/APIs mocked. It
checks ordinary and96-entry lists, ordering, zero quantities, nil/end gaps,
repeated IDs with changed contents, invalid and unreadable IDs, valid-prefix
preservation, cross-update identity reuse, unchanged text/layout/ledger skips,
accent refresh, tracked-item/width/money changes, PvP text, legacy branches and
clients with no currency APIs. Client labels are capability models, not native
emulators. The unreadable-value model cannot certify the native secret VM.

Five alternating pairs and three currency mutants are recorded in the shared
comparison; final whole-addon validation passes143 scripts/798 Lua syntax files.
Desktop wall times include startup/assertions; they are not game latency.

## Native checks pending

The user initially unloaded FluxUI, then reported re-enabling it and continued
whole-game freezes. Separate read-only native checks at17:35/17:37 CET found the
active Forever client reporting `_FluxUI` unloaded, no Flux namespace/revision
and scriptProfile0; Syndicator was also unloaded. This differs from the reported
enabled state. No enable flag was changed. The new code has not received native
acceptance. Confirm revision `20261105.1` after an agreed reload before treating
subsequent observations as candidate results.
CPU profiling remains0; existing diagnostic roots and preferences are preserved.
For agreed native testing, capture real watched currencies
and equivalent gold-strip appearance before/after. Check money updates, mailbox
open/close, selected/Open All and final-message collection, auction buys,
cancellations and naturally observed buyer sales. Retain the initiating error
before reporter warnings and use a narrower diagnostic than the failed full
frame-enumeration capture. A successful display update alone is not proof of
freeze removal, taint safety, pixel parity or FPS improvement.

[Five matched pairs per change, raw samples, candidate hashes and12 rejected mutants](validation/builtin-inventory-comparison-2026-11-05.json).
[Final143-script/798-Lua verification and whole-source manifest](validation/builtin-inventory-2026-11-05.json).
