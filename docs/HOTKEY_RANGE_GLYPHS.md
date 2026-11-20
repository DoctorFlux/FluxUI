# Out-of-range hotkeys and mouse glyphs

15 November targeting follow-up: range now follows each action's actual cast
unit independently of its tooltip, idle icon or reverse badge display. The
reported native Frostbolt case is confirmed. [Target rules and evidence](CAST_RANGE_TARGETING.md).

15 November 2026, `HOTKEY-RANGE-GLYPHS-20261115`.

The user confirmed that hotkeys should turn red **only when the action is out of
range**, across the action bar, combat grid, noncombat grid and trinket menu.
Mouse-button artwork must show the same red feedback as text.

| Requirement | Implementation and acceptance |
|---|---|
| HR-01: All four surfaces share range feedback | Existing range flags/native updates feed one Core hotkey presentation service; 48 actual consumer/key cases pass |
| HR-02: Mouse/scroll/space white artwork turns red | Known textures use explicit RGB bytes 255/26/26 and complete native source/crop coordinates; black pixels and alpha remain unchanged |
| HR-03: Return to normal in range or without a usable range result | Original white glyph markup and gray text restore; target loss, empty/placeholder/display-only buttons are covered |
| HR-04: Preserve modifiers, binding refresh, sizing and counts | Existing 14/17px sizes, horizontal squeeze, prefixes, multiple bindings, replacement/unbind and count owners pass |
| HR-05: Preserve range cadence and action behavior | No new probes, timers, events, secure attributes, input hooks or settings; existing item keepLast and native range callbacks retained |
| HR-06: Verify meaningful failures and practical limits | 1,144 independent four-surface checks and 951 Bars checks pass; archived consumer fails and five harmful controls are rejected; native GPU check pending |

[Core/Hotkey.lua](../Core/Hotkey.lua) retains untinted logical text separately
from its rendered string. A range transition changes text color and rewrites only
known inline key glyphs. Unchanged ranges reuse the rendered result. Font setup
explicitly restores range color because the font object can reset it.

[Bars/Paint.lua](../Bars/Paint.lua) updates the main label and its separate modifier
prefix from existing range paths. [HotkeyUtil.lua](../ExtraButtonSystem/Shared/HotkeyUtil.lua)
serves both grids and the trinket menu; EBS Paint feeds its current public range
result. Empty, placeholder and display-only buttons can retain an internal range
cache for icon behavior, but a binding refresh cannot revive a stale red label.
Unusable or low-mana actions alone do not make a hotkey red.

Native texture markup is supported by Blizzard's
[Forever GetMobileEmbeddedTexture implementation](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L143)
and the
[Retail implementation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L143).
The older local Classic 5.5.4.69155 reference has the same RGB contract; fetching
the current pinned Classic file was unavailable, so current native rendering is
not inferred. Source artwork dimensions are read from the unchanged TGA headers:
mouse buttons 32x80, wheels 8x20, space 48x48. No reference-addon code or assets are
copied. Existing glyph placement, scale, black outlines and alpha are preserved.

The dated external checkpoint verified 2,898 source files, ZIP CRC and Git history
on main, plus metadata for five available settings files. No private settings were
copied into the addon. The new display behavior needs no layout, option,
localization label or controller focus owner; the existing direct-implementation
preference applies. Native controller/render/taint/FPS checks remain separate.

The desktop full sweep before final fallback guard refinement reports **411 pass, one unrelated portrait fixture fail,
1,101 Lua syntax checks pass**. The portrait fixture lacks the native
GetUnitClassColor mock. Only unrelated Core/BorderJunctions.lua changed during the
run; this prevents frozen whole-corpus acceptance. Hotkey/routing sources and
their regressions stayed stable. Subsequent border edits leave the global docs
gate open for the new /fluxborders alias, two stale border verification hashes
and two concurrent inventory audit links;
the checker reported no task-specific source or link issue. Final review also
corrected the two helper-absence fallbacks; focused checks cover their inactive
button guards after the sweep. The final focused run passes all ten scripts and
1,101 syntax checks with stable sources. The independent tests verify explicit texture
markup rather than assuming SetTextColor tints inline artwork. Thirty unchanged
range probes per case produce no extra text rewrite. No native timing or FPS gain
is claimed.

Native follow-up: after reload, use an action with a known range result, verify
red text/mouse artwork while out of range and original gray/white appearance when
back in range. No automatic input, targeting, focus or profiling was performed.
[Exact source identities and validation](validation/hotkey-range-glyphs-2026-11-15.json).
