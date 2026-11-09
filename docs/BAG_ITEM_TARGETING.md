# Native bag item targeting investigation

9 November 2026 · BAG-ITEM-TARGETING-20261109 · **Runtime fault unresolved**.

The user reports Forever's native bags, with the bag addon disabled, refusing
an item resembling a Waylaid crate that starts a cursor to target another item.
The exact item ID, whether the failure occurs before the cursor appears, and
combat/vendor state are not yet known. This investigation covers the general
source-item → targeting cursor → destination-item flow, not an item whitelist.
Existing gear protection, salvage, modifiers, vendor/bank/mail actions and native
click handlers must remain functional.

The user subsequently confirmed the original items are no longer available, so
that exact reproduction cannot currently be performed. Do not require obtaining
another crate. The diagnostic can be used if any item-targeting case naturally
recurs. The available new 13:00 verbose log contains no matching bag-use/targeting
or forbidden-action trace, and no bag diagnostic snapshot is saved yet; startup
taint messages alone do not establish this fault's cause.

## Evidence and source boundary

The available Forever BugTabs save contains the supplied 12:44:34 entry with
count 3 attributed to `_FluxUI`. Its 00:53:20 FocusUnit entry has count 1 and
matches the earlier recorded report. That timestamp does not establish a new
focus regression; ordinary-menu user acceptance and the dependent-menu limitation
in [focus routing](FOCUS_SECURE_VISIBILITY.md) remain separate.

The current public Forever branch resolves to
`9dc84f0d3bbae1768ac3405b3716000bd93eda06` (1.60.1/70862).
[ContainerFrame.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua)
line 1611 calls `C_Container.UseContainerItem` on the ordinary right-click path.
The left-click item-target path uses the same API at line 1510. The template
in [ContainerFrame.xml](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.xml)
binds native mixin input. The generated
[Container contract](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)
declares bag, slot, optional unit/bank type and reagent-bank state. None of this
identifies the first taint writer or certifies protected engine execution.

Source inspection found a native refresh call in the legacy junk repaint path,
but Forever's normal unified-bank repaint bypasses that branch. It is not proven
to cause this report and was not changed. Header geometry, input handlers,
item-use APIs and feature gates remain as inspected. A host-level process check
verified a running Forever executable and exact window; no client command,
foreground change, physical input or clipboard access was performed. There is no
connected Witchcraft/UIForever tool. Native reproduction remains user-owned.

## Bounded opt-in evidence

The existing `/fluxinput` command now accepts `bags`. It reads client build,
combat and cursor/item-targeting predicates; field security for native bag
buttons, their mixin, item-use helpers and bank-type helpers; visible bag-slot
identities and hovered buttons. Secret/inaccessible values stay marked/omitted.
It does not call item actions, bag refreshes, native click handlers or active-bank
type helpers, and does not alter logging, profiling, input or gameplay settings.

One immediate capture and one ten-second capture are retained under the existing
`FluxPerfCaptureDB.bagInputDebug` root. The latest run retains its before state;
one previous run is preserved without an unbounded history chain. Other diagnostic
roots remain intact. Sampling is capped at 256 visible buttons, 14 container
frames and eight mouse foci. There is no permanent frame, polling or native hook.
The timerless fallback captures immediately. Normal gameplay remains unchanged
until this diagnostic is explicitly requested.

If a suitable item-targeting case becomes available, with the native bags in use:

1. Load the diagnostic with `/reload`. Record the current logging mode with
   `/dump GetCVar("taintLog")`, then run `/console taintLog 2` and `/reload`.
2. Open the bags, enter `/fluxinput bags`, use the crate/item, and hover the
   intended target within ten seconds. Reproduce the ordinary failing input;
   do not substitute `/run UseContainerItem(...)` for the native click.
3. After the capture acknowledgment, restore the recorded logging value
   (`/console taintLog 0` if it was 0), then `/reload` to save. Report that it is
   saved and the exact item name if available. The task can read the local
   Forever taint log and saved scalar evidence; private settings/logs stay external.

Keep these native acceptance cases open: source use/cursor entry, applying to
the intended destination, cancel/retry, incompatible/empty targets, bag moves,
ordinary consumables/equip, existing gear and salvage protections, native versus
alternative bags, and applicable combat behavior. Do not deliberately consume
or destroy unrelated items just to run controls. Focus menus are a separate case.

## Recovery and verification

The [checkpoint](validation/bag-item-targeting-checkpoint-2026-11-09.json) verifies
2,395 actual source files, all-ref history and 120 read-only settings metadata
entries outside AddOns. Every ZIP entry hash/CRC and bundle verification passed.
Live/unsaved settings were not copied or edited. Existing main and concurrent
Baganator work were preserved; no branch, commit, push or manual sync was made.

[Focused evidence](validation/bag-item-targeting-2026-11-09.json) records source
hashes, pinned references, the old-source rejection and current checks.
The new diagnostic regression checks read-only ownership, backpack zero, true/
false and secret targeting predicates, restricted getters/tables, visible-only
bounded sampling, timerless/older API fallback, deduplication and retained roots.
The existing input diagnostic regression also passes. These checks exercise
metadata collection only; **the item-use fault is not fixed or accepted**.
Full current validation passes all 270 scripts and 937 Lua syntax files.
All five installed diagnostic copies match through the existing user sync.
Native first-writer trace, actual targeting actions, pixels and CPU/FPS remain
pending. No performance benefit is claimed.
