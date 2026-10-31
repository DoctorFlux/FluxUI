# Decisions

## 2026-10-31 - place nameplate school artwork behind native chrome

- Parent nameplate backdrop textures to a Flux host at the plate's frame
  level. Follow plate parent/level changes during active casts. Keep the
  Blizzard cast bar as the fill/progress owner and retain higher edge, halo
  and particle effects.
- Preserve unit-frame artwork geometry, opacity, controls and timing. Native
  pixels, combat taint and matched frame time remain pending.
  [Evidence](NAMEPLATE_BACKDROP_LAYER.md).

## 2026-10-31 - tint conjured combat items from live usability

- Treat death/ghost as unusable for combat mana gem and healthstone faces,
  even when the native item API reports an owned item usable.
- Once bag data is reliable, let the live item usability result darken these
  faces for other situational blocks. Keep the existing empty-charge rule,
  loading-screen hold, visibility policy, secure actions and bindings.
- Use the existing life-event paint lane. Native all-client tint, input,
  taint, pixel and frame-time acceptance remains pending.
  [Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

## 2026-10-31 - restore cast fill geometry and school-colored tip

- Create the school texture on the actual `TimerBar` for both Flux unit bars
  and Blizzard nameplates. Hide and restore the native source texture only
  while school colors are active, preserving progress geometry and native
  cast ownership.
- Tint the native Spark to the school color alongside the Flux leading-edge
  glow; restore its prior vertex color when the theme clears. Keep interrupt
  feedback and all existing options. Native pixels/taint remain pending.
  [Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

## 2026-10-31 - style Blizzard nameplate casts with shared school themes

- Reuse `CastBarThemes` and the existing observed-school/metadata resolver for
  target, focus and nameplate appearance. Keep Blizzard's nameplate status bar,
  cast lifecycle, text, shield and important-cast indicators as owners.
- Attach a Flux visual host and a fill region to the native status bar. Hook
  each native nameplate bar's cast transitions after Blizzard runs; never replace its
  methods or persist secret identity. Restricted/unknown identities leave the
  native bar visible. Retain the existing appearance controls and add one
  nameplate toggle in unit-frame settings. Native taint, pixels and frame time
  remain pending. [Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

## 2026-10-30 - clear Blizzard MicroMenu children before native callbacks

- Reparent selected buttons and stage unused layout children before any
  Show/Hide path in Flux's rebuild. Finish hiding staged children after Flux
  layout. This prevents Blizzard `MicroButton_OnShow` from finding hidden,
  unpositioned children in `GetEdgeButton`.
- Keep Blizzard `Layout` and `GetEdgeButton` untouched, preserve button order,
  settings and the existing combat/Edit Mode deferral. Native post-fix
  validation is pending. [Evidence](17-micromenu.md).

## 2026-10-30 - retain pending loot sources through delayed chat

- Keep each loot session's cursor origin and captured slot identities for 30
  seconds after close, capped at 32 sessions. Match item link and stack count,
  currency ID or money slot before using a source position. Reconcile a late
  slot/chat pair by source so it displays once.
- Allow one item fallback for a window whose slots were emptied before
  capture. Linkless currency keeps the one-second close grace. Source
  attribution is ambiguous when multiple uncaptured sources remain pending;
  native ordering and placement require five-client checks.
  [Evidence](LOOT_CURSOR.md).

## 2026-10-30 - pin each loot batch to its opening cursor position

- Capture the cursor once when a loot window first becomes ready/open, and
  carry that origin through slot and delayed chat rows. Keep each row's own
  UIParent coordinates so another loot window cannot relocate it.
- For bonus/group rolls without a loot window and Preview, use the cursor at
  that alert event. Preserve three-row capacity, 3-second default, controls
  and source filtering. Native click-to-event timing and pixels remain to be
  checked. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - restrict cursor alerts to loot sources

- Exclude crafted and pushed/rewarded chat forms. Require a current or
  just-closed loot window for ordinary self-loot chat and currency chat;
  keep direct slot clears, bonus rolls and group-roll wins. Do not infer loot
  from bag changes.
- Keep a one-second close grace for chat arriving after LOOT_CLOSED. This is
  a bounded event-order compromise and needs native confirmation. Keep the
  existing fast pickup, money format and settings. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - register FluxLoot profile callbacks with the AceDB receiver

- Use `FluxOptions.db.RegisterCallback(FluxLoot, event, FluxLoot.Refresh)`,
  following the established FluxOptions call shape. The receiver is FluxLoot;
  the event is a string; the method refreshes event ownership after profile
  changes, copies and resets.
- Keep loot settings, alert appearance and pickup behavior unchanged. The
  user's stack trace is pre-fix native evidence; post-fix native validation
  is still pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - show looted money with denomination coin art

- Parse only the client's own received-money messages using its localized
  money templates. Show white numbers and MoneyFrame gold/silver/copper
  symbols, with a leading copper/silver/gold icon selected at 100 and 10,000
  copper. Skip unparsed or zero messages rather than repeating raw chat text.
- Reuse the coin art already used by Flux vendor chat. Keep item and currency
  alerts, timing, settings and fast pickup unchanged. Native client checks
  remain pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - default cursor alerts and fast pickup on

- The user clarified that both switches should default on for all five
  supported clients. Keep the separate FasterLoot ownership guard while it is
  loaded, so two addons do not call LootSlot for the same LOOT_READY event.
- Name the existing duration control **Disappear after (seconds)** and keep
  its 3-second default. Preserve saved values; do not reset profiles.
  [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - add profile-scoped cursor loot and optional fast pickup

- Keep the installed FasterLoot addon independent; Flux skips its fast pickup
  path while FasterLoot is loaded. Both switches now default on by user
  follow-up. Avoid changing the user's addon list or Auto Loot preference.
- Use existing AceDB and item services, a three-row visible-only display,
  and loot-slot/chat reconciliation for alerts. Keep loot roll positioning and
  auction, guild-bank and void-storage callbacks untouched.
- Treat desktop event fixtures as limited evidence; native acceptance on each
  supported client is still required. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - use the native negated Sticky Targeting setting on Retail

- The linked GitHub main file is the same pre-fix source. A 13 August local
  snapshot uses `Settings.GetSetting("deselectOnClick"):SetValue(false, true)`.
  Restore that route only for this uncoupled Controls setting, verify raw
  CVar `1`, and retain raw-CVar fallback when the setting is unregistered.
- Keep the general modern `Settings.SetValue` guard for protected raid and
  nameplate callback ownership. Avoid the historical repeated raw `0`
  writes and leave the camera fallback at 2.6 without an engine maximum.
  [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - audit native Sticky Targeting and use a writable Retail camera fallback

- Use `deselectOnClick=1` as the authoritative unchecked Sticky Targeting
  value. Include it in the first-load audit; keep the Retail Settings API
  taint guard and avoid repeated writes when already correct.
- When the engine gives no camera maximum, use 2.6 on Retail rather than
  assuming 4 from its major version. Give accounts with a prior failed
  first-load audit one settings-only retry; do not repeat binding setup.
  [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - complete first-load settings after world entry

- Apply first-account and new-character nonbinding defaults after the first
  world entry, then audit supported values after startup can settle. Keep the
  existing safe-write queue and the protected raid CVar guard.
- Limit mismatch repair to the armed first-load audit, with three attempts.
  Existing completed accounts keep later changes. Report completion once;
  manual reset completion and specific failures remain visible.
  [Evidence](NONBINDING_FIRST_LOAD.md).

## 2026-10-30 - use the item service for Hearthstone selector hover

- The user's native stack trace shows `GetItemInfo` is nil when the selector
  hover handler runs. Use the already-loaded `Flux.Item.GetInfo` and the Toy
  Box name for an uncached toy. Retain the existing help text and fallback.
- Do not install or enable deprecated globals for this panel. The focused
  fixture removes `GetItemInfo` and reproduces the prior failure.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - gate Hearthstone editor on the earlier core capability

- The user's Toy Box still showed no Hearthstone panel. The editor loads at
  TOC line 145; `FLUX_API` is initialized only at line 204. Its original guard
  always returned during normal loading. The prior fixture incorrectly
  supplied that later API at the earlier point.
- Use `Flux.Cap.hasToyBox`, available from `Core/Capabilities.lua` at TOC line
  22. Keep the separate later `FLUX_API` flag for its existing consumers.
  Use the current item icon API before deprecated globals while building the
  panel, so icon lookup cannot abort creation on modern clients.
- Verify the actual load order in the regression, with `FLUX_API` absent.
  Native visibility and secure use remain pending.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - make Toy Box capability independent of journal opening

- The first diagnosis treated the journal-toggle condition in
  `FLUX_API.hasToyBox` as the registration cause. The later TOC audit showed
  `FLUX_API` itself did not exist when the Hearthstone editor loaded.
- Define Toy Box capability by the toy query and ownership APIs. Keep journal
  opening separate, using the available modern or legacy Blizzard loader and
  native Toys-tab opener. Preserve the existing choice store and UI gestures.
- This change alone did not make the panel appear; the earlier core-capability
  decision above completes registration. Native toy selection, reload, secure
  click and performance checks remain pending.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - finish first-account bindings in one native transaction

- The user saw native assignment/verification fail, then default keys return
  after reload. Blizzard's modern keybinding UI passes an action-specific
  context to binding APIs; Flux omitted it.
- Use that context where available, validate resulting actions rather than a
  single API return, retry only wrong keys up to three times, and complete
  clear/assign/save/load in the same call. Keep rollback and the one-account
  marker; do not add an automatic polling loop.
- Native performance, secure input and disk persistence remain pending.
  [Evidence](BINDING_ATOMIC_CONTEXT.md).

## 2026-10-30 - complete bindings only after native save/load verification

- The version-5 attempt gate claimed completion while the Retail account
  binding cache contained no key bindings.
- Remove SaveBindings from the PLAYER_LOGIN combat-settings pack. Apply the
  keyboard at first world entry to the account binding set, then verify
  SaveBindings, LoadBindings and the supported template before marking
  account version 6 complete after the next real login confirms the saved keys.
- Repair older version-4/5 accounts once if native bridge keys are missing.
  Preserve unmarked accounts and already bound accounts. Roll back failures
  and resume only an interrupted unsaved pass.
  [Evidence](BINDING_PERSISTENCE_REWRITE.md).

## 2026-10-30 - consume the automatic attempt before its first binding write

- The user observed full keyboard replay after reload, including accounts that
  had already loaded Flux. A final save/verification failure can leave the old
  `"pending"` marker behind after native keys were changed.
- A new account gets one automatic pass at first world entry; version 5 claims
  that pass before the first `SetBinding`. Failed partial passes do not replay.
  No-write unavailability may retry within the bounded first-login path.
- Treat old pending/completed markers and existing four bridge bindings as
  evidence to skip a repeat. Ignore overlapping full-reset requests while a
  batch is active. Manual `/fluxdefaults keybinds` remains available.
  [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - apply automatic bindings once for the whole account

- The user clarified that automatic keybindings must run on first account
  load only. Keep one account-wide pending/completed state, independent of
  Blizzard's account or character binding-set selection.
- Migrate any successful version-4 character marker to account completion;
  leave existing accounts with no pending first-account setup untouched.
  A failed first-account attempt may retry until its one successful save.
- Remove Flux keyboard replay from Blizzard Settings reset callbacks. Keep
  explicit Flux keyboard reset commands and the batched eight-write limit.
  [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - complete the full binding reset after one successful save

- Apply the full reset once for each active native account or character
  binding set. Mark version 4 complete immediately after verifying and saving
  that set; accept prior version-4 pending saves without another clear.
- Remove automatic replay on `UPDATE_BINDINGS` and cross-login verification.
  A failed or unavailable attempt may retry until one successful save, with
  the existing three-attempt login cap. Explicit user reset commands remain.
- Scan the binding registry once per reset, cap writes at eight per frame and
  separate clear, apply and save phases. Confirmed scopes do no further
  registry scans. Native FPS/latency remains unmeasured.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - reset the active native binding set before Flux defaults

- The user explicitly requested a full clear before applying the complete
  template on all clients. This supersedes the general no-forced-reset rule
  for the one-time first-load repair and replaces custom keys in unconfirmed
  account/character binding scopes.
- Require all Flux XML commands to be registered before clearing. Skip native
  template commands missing from that client. Clear all active keys in batches,
  apply the supported template, verify it, then save that active set.
- Upgrade old markers to version 4, verify across login sessions, and react to
  late `UPDATE_BINDINGS` while pending. Bound retries to three per scope per
  login; confirmed scopes preserve later edits. Native acceptance is pending.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - reset the active native binding set before Flux defaults

- The user explicitly requested a full clear before applying the complete
  template on all clients. This supersedes the general no-forced-reset rule
  for the one-time first-load repair and replaces custom keys in unconfirmed
  account/character binding scopes.
- Require all Flux XML commands to be registered before clearing. Skip native
  template commands missing from that client. Clear all active keys in batches,
  apply the supported template, verify it, then save that active set.
- Upgrade old markers to version 4, verify across login sessions, and react to
  late `UPDATE_BINDINGS` while pending. Bound retries to three per scope per
  login; confirmed scopes preserve later edits. Native acceptance is pending.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - verify default grid bindings across login sessions

- Keep post-batch and post-combat bridge binding seeds provisional until a
  delayed active-set check. A completed seed must survive a following login.
- Recheck earlier completion markers. Repair lost assignments only when their
  target is free or still has a known stock action; preserve custom target
  actions and intentional unbinds after confirmation.
- Preserve account/character binding scope and existing secure override
  refresh. Native first-load/reload checks remain pending.
  [Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - use Flux-owned raid settings on protected clients

- The user chose to retain the Retail/Forever native compact-frame taint
  guard. Do not write native raid CVars or trigger Blizzard Settings/CUF
  callbacks from Flux on these clients.
- Use the existing account/character Flux raid options for live unit chrome,
  status text and preview. Preserve Classic native profile/CVar behavior and
  existing Flux frame dimensions. Keep Blizzard Interface values native-owned.
- Require native first-account/new-character, combat and Edit Mode acceptance
  before claiming game behavior or taint safety. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - use Flux-owned raid settings on protected clients

- The user chose to retain the Retail/Forever native compact-frame taint
  guard. Do not write native raid CVars or trigger Blizzard Settings/CUF
  callbacks from Flux on these clients.
- Use the existing account/character Flux raid options for live unit chrome,
  status text and preview. Preserve Classic native profile/CVar behavior and
  existing Flux frame dimensions. Keep Blizzard Interface values native-owned.
- Require native first-account/new-character, combat and Edit Mode acceptance
  before claiming game behavior or taint safety. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - complete Classic raid profiles and use Medium nameplates

- Keep missing/late Classic active raid profiles pending, then apply the full
  native raid pack after profile load through the existing writer queue.
  Bound the first-world-entry fallback and leave successful profiles alone.
- Set `nameplateSize` to `2` in both defaults sources. Migrate an existing `3`
  once; preserve any other chosen size and retry a failed or deferred write.
- Retain the Retail/Forever compact-frame write guard. Its protected callback
  ownership remains unresolved for automatic Blizzard raid-setting writes;
  native client acceptance remains pending.

## 2026-10-30 - finalize grid bindings after first world entry

- Use the first `PLAYER_ENTERING_WORLD` after login to write the active native
  binding set, then verify it again shortly afterward before persisting the
  completion marker. Queue behind full-template work or combat and retry an
  unavailable set or failed write within the same login.
- Recheck the old `true` marker once using version `2`; permit the known stock
  achievement action on `Y` to yield to smart mount. Preserve custom target
  actions and later intentional unbinds after version `2` is recorded.
- Refresh labels from `Flux.EBS.buttons`, the loaded grid registry, with a
  legacy fallback. Iterate only loaded modules in the bulk secure rebind pass
  so nil optional modules cannot truncate combat refresh.
- Native first-load input and all-client acceptance remain pending.

## 2026-10-30 - seed missing Flux keys on the active binding set

- Continue the full template on first account setup. Once per native binding
  scope, seed only missing Flux commands into free target keys; allow stock
  action buttons 6–8 to yield to the existing grid defaults. Preserve custom
  target actions and commands already bound elsewhere.
- Save the active account/character set and refresh secure button overrides.
  Defer through the existing combat and bulk-binding lifecycle. Persist a
  scope marker only after save succeeds, so a user unbind later is respected.
- Include previously seen characters because the earlier new-character path
  marked them seen without assigning per-character Flux keys. Native clicks
  and other clients remain pending.

## 2026-10-30 - first-login defaults by client CVar scope

- Keep the established full account-first setup and keyboard template. For later
  new characters, apply only CVars the active client reports as character-stored,
  plus the existing raid/chat setup. Unknown scope cannot authorize an account
  preference write; existing custom bindings remain untouched.
- Route character CVar and bitfield writes through the existing Blizzard Settings
  write queue and retain Retail/Forever compact-frame restrictions. Deferred or failed
  character CVar work does not mark the character seen before completion.
- Leave the unreachable post-login three-sentinel/four-mismatch check unchanged
  until a repair can avoid replaying all CVars over user preferences. Native
  fresh-character acceptance is pending for each client.

## 2026-10-30 - vendor chat coin amounts

- Keep existing vendor net accounting and repair/junk messages. Format their chat
  amounts into full gold/silver/copper denominations with native coin texture paths.
- Use the shared merchant formatter when the junk/repair module is loaded, while
  keeping standalone vendor loading capable of the same output.
- Desktop string checks do not establish native texture rendering; verify in-game
  chat on each client when background-safe access is available.

## 2026-10-30 — portrait and strip scale correction

- Treat `SetPoint` offsets as frame-local. Do not multiply portrait center
  offset by the frame scale again. Normalize chat/aura positions by effective
  scale before moving focus.
- Convert the action strip top to UIParent units, then the player/side-by-side
  target bottom offset to frame-local units. Keep a four-unit clearance when
  scale differs from 100%; preserve the original 100% anchor.
- Refresh a 3D portrait after an actual scale change through the existing
  display-metrics helper. [Evidence](UNIT_FRAME_SCALE.md).

## 2026-10-30 — whole unit-frame scale

- Give player and target one multiplier, and focus a separate multiplier, in
  their existing Unit Frames tabs and account/character scope. Keep saved
  width/height and class-power size controls independent.
- Scale root frames so their children inherit it. Match detached separators,
  atlas borders, target placeholder and Blizzard-owned class resources explicitly.
  Clear the action strip edge at changed scales. Avoid a
  second scale on ToT when it is parented to target.
- Use existing combat-deferred sizing refresh. [Behavior and pending native
  checks](UNIT_FRAME_SCALE.md).

## 2026-10-30 — vehicle seat corner and scale

- Reserve a seat-width slot to the left of equipment durability. When the
  visible micro menu or status strip occupies the top-left, keep the chrome
  fixed and put both indicators below whichever extends lower. Otherwise start
  the pair at the screen top-left, preserving PvP-widget clearance.
- Scale the parent indicator to 0.7 so native art and seat buttons keep their
  proportions and hit areas. Keep stock indicator mute and vehicle events intact.
- Existing combat deferral and the status owner's anchor refresh continue to
  apply. Focused desktop layout checks pass; native pixels, clicks and taint are pending.

## 2026-10-30 — empty unit resource bars

- Use maximum power, never current power, to classify an absent main resource.
  Compare only nonsecret numeric values. On Live/Forever, layer resource over
  full-height health and forward max power to the secret-accepting alpha sink.
  This also hides a secret zero without branching on it in Lua.
- Apply the behavior to Flux-owned unit frames and raid cells. Existing
  health-only satellites and Blizzard-owned frames keep their respective layouts.
- Use existing power events and partition code. Raid max-power changes now
  trigger updates; combat reanchoring waits for regeneration. Preserve the raid
  hide-power setting, overlays, profile data and frame sizes. Keep text/raid-icon
  anchors in their original upper area while health extends underneath.
- After user feedback, center health text across full HP when resource presence
  is absent/restricted, and retain the original split text area for a known
  positive maximum. Keep power text parented under the alpha-controlled bar.
  The Flux separator starts transparent and follows max-power alpha.
- [Desktop evidence and native limits](UNIT_POWER_VISIBILITY.md). Earlier main
  branch holds below are historical; 29 October main-only authorization applies.

## 2026-10-29 — teleport counts/interrupted casts

- User confirms Retail. Native display text, including empty, owns this preset's
  count. Inaccessible tooltip text cannot establish Classic rune costs.
- Reuse filtered spell actions for eligibility, skipping reagent/restock rows.
  Restore macro/face/tooltip on unlock; keep complete updates for list/options/
  favorites changes, existing combat deferral and success delay.
- Preserve saved state, known legacy rune counts, click paths and popup styling.
  Other custom flyouts remain unconfirmed; no speculative shared-effect rewrite.
- Verified external source/history/on-disk Retail settings before edits. No live
  game/profile/diagnostic changes or publication. Desktop counts are not native
  hitch-resolution/FPS/taint acceptance. [Evidence](TELEPORT_CAST_WORK.md).

## 2026-10-29

- Modernize the existing `_FluxUI` and repository in place. User's current request
  supersedes fresh-project/no-old-code/separate-repository/rename instructions in
  older specs. Product requirements remain inputs; conflicting current behavior
  is recorded, not silently removed or redesigned.
- Use the current change branch; leave `main` untouched until explicitly
  authorized. Keep the same TOC, public commands, saved roots and profiles. No push
  or merge is part of the first batch.
- Preserve all actual files and Git history outside AddOns before changes, including
  original untracked package/log and ignored local work. Relevant private settings
  remain outside Git. Exact hashes and recovery procedure are in `RECOVERY.md`.
- Reuse the existing source/reference collector, Lua validation runner, performance
  diagnostics and service architecture. Append ledgers, not a competing framework.
  Refresh generated indexes because the baseline references were stale; their larger
  diff is an audit correction, not thousands of runtime changes.
- Select BUG-001 before general lifecycle restructuring: production Currency/Store/
  Adapter replay proves stale builtin snapshot writes after external Ready. Four
  execution-time guards use the existing authoritative provider flag. Keep four
  shared-bus subscriptions inert after handoff; full provider retirement is separate.
- Preserve standalone startup, immediate money updates, token/warband cadence,
  saved ledger and provider callbacks. No appearance/secure-input code changes.
  Deliberate correction: provider-owned money must not be overwritten by a stale
  builtin event; the regression checks this exact failure.
- Runtime fix/test/fixture are a separate commit from requirements/audit/generated
  references. The supplied package is retained verbatim; no user log or settings is
  staged. Commit-only author configuration follows existing repository attribution.
- Desktop deterministic counters are valid operation evidence, not native CPU,
  memory or FPS. Requests are not executed scheduler passes. Historical native
  samples retain original context and cannot certify this candidate.
- PE versions and source version files are recorded separately from native
  GetBuildInfo. Retain original Wrath, modern Wrath and Cata as distinct rows;
  unavailable or unsupported cases are explicit. No TOC compatibility changes yet.
- Correct documentation when direct source evidence resolves it (`OptionalDeps`,
  Ready handoff, native item identity APIs, `/fluxui bliz`). Preserve unresolved
  product differences/defaults until a focused decision or reproduced defect.

## 2026-10-29 continuation — deferred provider work

- Followed the next-step event audit rather than assuming a historical finding was
  an active gameplay bug. Production dispatch reproduces skipped callbacks during
  removal, but the only active removal owner is Context.DisarmEvents and no current
  production call to its unsubscribe path was found. Keep this latent API defect
  documented in `EVENT_DISPATCH_AUDIT.md`; defer a hot-path redesign until a concrete
  consumer or lifecycle migration requires it.
- Prioritize BUG-002: queued/partial builtin mail and auction scans can outlive
  Syndicator readiness and overwrite the provider snapshot. Execution-time ownership
  checks belong at the beginning of each existing StepScan, before debounce/time
  checks. Cancel its data and OnUpdate work, preserving mailbox/auction open state,
  standalone scan budgets, close behavior and incomplete-data retries.
- Keep mail-send/return completion and auction/guild query ownership as separately
  tracked follow-ups. This scan fix does not claim complete builtin-provider teardown.
- Reuse the earlier complete 82-test/723-file baseline only after verifying every
  tested Lua hash matches current bytes. Capture the new focused failure before
  runtime edits and run full candidate validation after the change.
- The next controlled replay proved BUG-003 for both SendMail and ReturnInboxItem:
  completion after Ready mutates the exact character table returned by Syndicator.
  Treat loss of ownership like existing failure cleanup before resolving the
  recipient; clear the pending operation and its subscriptions. Keep this separate
  from scan cancellation, with its own checkpoint, baseline and regression.

## 2026-10-29 continuation — disabled Windows lifecycle

- User explicitly deferred auction, guild-bank and void-storage callback audits.
  Redirected independent inspection to the documented WindowMover disable behavior.
- Production Catalog/Engine/Init/options replay reproduced disabled attachment and
  polling, plus public SetEnabled(false) retaining an active scale gesture that
  changes saved scale. Fix BUG-004/PERF-003 using the existing Scan and Refresh.
- Gate discovery before native hook setup; hide/show the existing panel watcher
  through Refresh; call Refresh on both public enable outcomes. Keep enabled
  cadence, frame reuse, native protection guards and saved positions/scales.
- Retain existing permanent guarded hooks, startup proxy/driver, two discovery
  event subscriptions and two bounded startup callbacks. Their disabled Scan now
  returns before catalog access. Do not claim complete module teardown.
- Reused the 84-script full baseline only after verifying all 725 Lua source hashes.
  Captured a new verified external source/history/private settings checkpoint before
  edits. Matched desktop counters establish removed work; native input/pixels/taint/
  performance remain pending.

## 2026-10-29 — editorial maintenance

- Use conventional contribution guidelines and development tasks instead of editor
  workflow files. Archive original prompts/templates, planning Word file, old handoffs,
  local backup trees and sync log outside the addon before removing active copies.
- Rewrite conversational comments as technical explanations. Preserve every executable
  Lua token/string, native restriction invariant, license and third-party attribution.
- Retain technical specifications, tests, measurement values and revision identities.
  Use factual descriptions of the recorded procedure. Preserve
  original records in the verified checkpoint and omit optional branch metadata.
- Do not rewrite Git history or alter main as part of a working-tree cleanup.

## 2026-10-29 — queued merchant purchase identity

- BUG-005 is an active queue correctness issue: production replay buys a replacement
  merchant item or submits an empty slot after listings change. Index refresh alone
  cannot repair retained task references. Protect the operation, not just index build.
- Reuse ResolveMerchantSlotItemID in RunBuyPass's invalid-task condition. Discard a
  missing/mismatched listing before quantity calculation, purchase, wallet debit or
  reporting. Continue valid tasks at the original eight-call budget and cadence.
- Do not relocate stale tasks or restart the session automatically: a fresh normal
  request uses current index/remaining counts. This avoids resubmitting earlier
  purchases while inventory acknowledgements may still be settling.
- Record the extra identity lookup per valid purchase as correctness overhead.
  No native performance improvement is claimed. Unchanged-ID price/stock changes
  and purchase acknowledgement are separate unmeasured candidates.

## 2026-10-29 — finite merchant stock budget

- BUG-006 reproduces two related capacity defects: zero availability was uncapped,
  and repeated tasks reused the same finite snapshot count. Treat zero as a cap and
  reserve submitted quantities on the existing shared index entry.
- The shared remaining value is a reservation budget until index refresh, not proof
  of native acceptance. Do not introduce another transaction service or live polling.
  Unrelated rejections, external stock changes and acknowledgement remain separate.
- Preserve unlimited/nil helper semantics, gold/alternate-cost math, eight-call pass
  budget, UI/defaults/settings and normal refresh/new-request recovery. Extend the
  existing merchant harness with focused stock/identity groups rather than duplicate it.
- Exact read-only Blizzard source hashes support API shape/zero-stock interpretation;
  the 12.1.0.69283 snapshot predates installed clients and does not advance native rows.

## 2026-10-29 — vendor-open availability work

- Prioritize the user's idle vendor-open hitch, reported only on Era so far. Do not
  assume first-open/repeated-open behavior or automation settings, and do not claim
  native resolution from a desktop reduction.
- BUG-007/PERF-004 reproduces repeated fallback bag walks in the real availability
  path. Cache its exact boolean result under the existing junk owner using reliable
  bag generation and existing rule/item/list/slot invalidation. A classified count
  of zero alone is insufficient for cold gray-item data. Retain native-positive
  precedence, live retry when unready/unreliable, and all callback timing.
- Reuse the junk-smoke boot fixture and production buyer events plus unmodified UI
  availability sections. Document excluded rendering/layout/integrations. Seven API
  fixtures are regression coverage, not native client certification or original
  Wrath support. Keep cold and repeated-open counts separate.
- Retain the buyer frame and native count-query controls; add no timers/subscriptions,
  settings or generic cache service. Native query overhead, CPU/frame times and the
  remaining classification/index/Already Known/layout candidates need live evidence.

## 2026-10-29 — Quick Join anchor ownership

- Prioritize the user's concrete native SetPoint error. The column already anchors
  Channels to Quick Join; the old social callback reverses that edge. Existing
  isolated column/retry fixtures did not run the two owners together.
- BUG-008 returns before the fallback reanchor while either button belongs to the
  Flux column. Check both to survive a native reparent of either one. The enclosing
  callback still reconciles through PlaceColumnButtons; unmanaged fallback remains.
- Add parent/anchor cycle detection and correct bottom-point geometry to the existing
  column fixture, then execute real social/hook/retry callbacks there. Retain its
  five-branch controls. No competing owner, global API replacement or broad runtime
  error suppression is needed; preserve column geometry and the three deadlines.
- The baseline combat exception never reaches its existing waiter. The candidate
  reaches that deferral and reuses one waiter; it does not add a new runtime frame
  service. Native geometry, input/taint and performance remain pending.

## 2026-10-29 — repeated vendor tier candidates

- User confirms Era spikes on every same-vendor reopening. Read-only hashes showed
  the preceding junk/buyer/chat fixes already installed; do not assume a stale copy.
  Saved scriptProfile=1 is an observation requiring matched unprofiled validation,
  not proof of causality or permission to change the user's preference.
- Preserve merchant discovery/reference seeding. A blanket lazy-index skip can
  suppress that feature. PERF-005 instead filters actual tier matches before live
  usability in best selection and status; non-improving best contenders also skip
  the gate. Matching contenders retain fresh level/skill checks without a new cache.
- Reuse the existing buyer fixture and actual Score/Match/Vendor modules. Extend
  measurement to 25 reopenings with retained food/water refs and unoffered families
  after the user's cadence clarification; retain the source fix and test extension
  as separate reviewable commits.
- Ready-classification calls remain equal in measured runs. Classification now
  precedes level rejection, so cold tooltip cost can differ and needs native checks.
  Service call reductions are not native cache-miss, CPU, latency or FPS results.

## 2026-10-29 — native tier count attribution

- The clean Era 1.15.9.70576 four-reopen pilot reproduces a 333 ms UI interval;
  GetRestockTargetItems spends about 320 ms per call. Inclusive bag/bank count and
  tooltip rows identify a measured target; do not sum overlapping timings.
- PERF-006 filters tier membership before live usability in existing bag and cached
  personal/warband count owners. Keep live gates on matches, accounting, caches,
  fallback and protections. No new lifecycle resources or generic service.
- Five alternating native background getter pairs return identical quantities;
  median CPU is 132.199 to 15.237 ms for five bag kinds, 118.897 to 22.517 ms for
  cached-bank kinds. Bank outputs are zero on this character; positive/warband
  parity is desktop-only. Candidate bodies ran as source-derived local functions;
  no public/native API replaced. This is not full-window after acceptance.
- Honor the user's background PC use: no further game activation. Background local
  slash diagnostics preserved focus; original automation values and profiler=1
  restored, temporary exports removed and sampler/namespaces cleared by reload.
  The user's normal sync delivered source; no separate addon or sync job created.
- Native foreground repeated opens, unprofiled FPS, matched pixels, cold work,
  security/taint and other clients remain pending. Keep auction, guild-bank and
  void-storage callbacks deferred. [Evidence](TIER_COUNT_WORK.md).

## 2026-10-29 — whole-addon Retail resource audit

- Cover all 26 loaded source domains through current ownership/recurring-driver
  maps. Native idle execution does not exercise every lifecycle or prove leak-free
  operation; keep pending interaction/client scenarios explicit.
- BUG-009/PERF-007 reuses loot combat/readiness frames after production replay proves
  203 allocations across repeated world/combat cycles. Keep 50-update timeout,
  six-pixel anchor, native show hook and no protected writes in combat.
- BUG-010/PERF-008 explicitly releases full requested-capture snapshots and handle
  cycles. Retained-callback replay proves 20 -> 0 snapshots and 10,000 -> 0 frame
  rows per model. Retain the compact report, schema, deadlines and dormant behavior.
- Native Retail baseline has stable frame/public-cache counts but memory increases
  during diagnostics. Attribute requested capture retention before accusing the
  normal HUD. Native CPU ranks nameplates and assisted painting; do not disable
  features or slow update cadence without matched evidence.
- Discard the incomplete long-upload native comparison; no result for its missing
  candidate. Use normal file-loaded API calls for follow-up. Original profiler=0
  must be restored; no game activation, global API replacement or restriction bypass.
- Preserve the existing uncommitted tracker source/test/docs. Keep its changes out
  of the new runtime commits and record actual-file identities separately from HEAD.
  Main and excluded auction/guild-bank/void callbacks remain untouched.

## 2026-10-29 — common Social offset and dock ownership

- User-authorized intentional position correction: one eight-unit inset from the
  tab/menu top across client paths, preserving other layout/feature behavior.
- Use existing tab height as a relative offset. An absolute future top against a
  provisional login chat rectangle goes stale after the final pin; no timer/hook
  is needed to follow that movement.
- Anchor the column to primary ChatFrame1 on all tabs. Combat Log/custom native
  rectangles may differ; selected-tab identity remains solely for Copy/action data.
- Preserve Classic ownership/overflow handling, other menu-position fallback,
  scale conversion, combat restrictions and current retry deadlines. No framework.
- Native seven-selection Retail pass plus untouched reload image supports this
  scope. Five desktop branch models are not other-client native certification.

## 2026-10-29 - original stage tracking and countdown work

- Continue the supplied original plan through explicit stage gates; inventories
  and passing desktop checks do not complete all native acceptance.
- PERF-009 keeps the existing NamePlates owner/driver/cadence and removes repeated
  FontString discovery plus per-aura level tables. Reuse only within one poll;
  changing/opaque labels and native digit fallback remain fresh.
- Keep real unprotected native-widget results separate from actual combat aura
  rendering/taint/FPS. Background whole-addon scene changed, so that comparison
  is inconclusive even though errors remain0 and per-window frame counts stable.
- The user again explicitly requested root working rules and next-session records;
  restore those concise files alongside existing contribution/development docs.
  Do not restore retired prompt templates, narrated comments or private artifacts.
- Preserve the separate tracker work and current branch; main and excluded
  callback audits remain untouched. Keep WoW in the background and profile0.

## 2026-10-29 - action batch facts and native player auras

- Sample activation once within an existing bar paint batch. Pass explicit false;
  retain fresh standalone queries and the API helper's independent guard. No
  cross-frame cache, generic framework, animation suppression or slower cadence.
- Keep top-right player aura data/handlers/styles native. Short-idle measurements
  do not justify a competing aura painter or prove dense/restricted churn safe.
- Treat source-derived real-painter matched runs separately from complete-addon
  CPU/FPS. Both native clients use inactive highlight settings; real active combat
  input still requires acceptance. Preserve failed/inconclusive scope honestly.
- The user authorizes normal reconnect/warning dismissal and named character
  selection for testing. Same-account sessions displace each other: run serially,
  validate each executable/window and preserve foreground PC use. No credentials.
- Leave the user-owned mirror job unchanged. Verify each source transition; when
  delayed, copy only the known test file into the existing authorized client.
  Restore each original profiling preference and prior diagnostic report.

## 2026-10-29 - authorized main publication

- The user explicitly authorizes uploading the whole current addon and updating
  main. Preserve the current development branch and complete existing history.
- Include the formerly pending, already-tested objective-tracker change and its
  records; do not leave part of the authorized addon unpublished.
- Fetch/check remote main, fast-forward only when ancestry permits, and push
  ordinary refs without force. Preserve newer remote work if it appears.
- Keep private backups/settings/captures and ignored local helpers out of Git.
  Native pending checks retain their scope despite publication authorization.

## 2026-10-29 - local files authoritative, main only

- User requests no other branch and explicitly authorizes uploading all current
  local addon files. This supersedes the earlier retained-branch decision.
- The development branch equals main at b45eb5e, so remove both local/remote refs
  without losing commits. Keep normal pushes and all existing history.
- Include the newer local teleport fix and its complete tests/docs; do not reset
  the workspace to the previously published revision or omit uncommitted work.
- Keep private recoveries/settings/captures and ignored local helpers outside Git.
  Publication does not change native acceptance results or live game preferences.

## 2026-10-30 - resource separator and text refresh

- Reapply the main separator's maximum-power alpha after partition and border
  color paint; both paths can repaint its alpha aspect after a power update.
- Keep restricted-maximum health text in the health section. Only a known zero
  maximum selects the full-height text area. Do not test secret maxima for
  truth in Lua; pass them directly to `SetAlpha`.
- Include target-of-target loss and return in focused desktop regression checks.
  Native pixel and combat acceptance remain pending.

## 2026-10-30 - expanded HP text and ToT split

- For a known zero maximum, keep player/target HP labels at their existing
  horizontal sides but center them vertically in the expanded health area.
  On resource return, refresh health text anchors so nested placement returns.
- Keep ToT's UIParent separator container ten levels above the ToT button after
  side-by-side placement changes the button's frame level. Restore the original
  button level when returning to the stacked layout.
- Restricted maximum values cannot select a text layout in addon Lua; retain
  the upper HP placement until a nonsecret zero maximum is available.

## 30 October 2026 - attached stance scale

30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).

Match effective parent scales at the existing stance anchor/layout entrypoints.
Refresh only the anchor after a player whole-scale change; avoid rediscovery
and binding work for this geometry correction. Source/history/settings recovery
and exact before/after hashes are in [the scale record](UNIT_FRAME_SCALE.md).
No game/settings interaction or competing framework; excluded callbacks unchanged.
