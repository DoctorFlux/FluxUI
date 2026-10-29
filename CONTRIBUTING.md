# Contributing to FluxUI

Develop in the existing `_FluxUI` folder and `DoctorFlux/FluxUI` repository. Work
directly on main: the user requested main only and publication of the current
local files on 29 October 2026. Do not create other branches unless requested later.
Preserve existing history and newer local work; do not force-push.

## Preserve behavior and data

- Retain addon identity, saved-variable roots, profiles, options, defaults, commands,
  bindings and optional integrations. Never force a settings reset.
- Preserve layout, fonts, textures, colors, scale, animation and interaction timing.
  Document each intentional bug fix with its trigger, expected result and regression.
- Inspect the working tree before editing and preserve unrelated changes. Create a
  dated source/history checkpoint outside Interface/AddOns; back up relevant WTF
  while WoW is closed. Keep private settings and logs out of Git.
- Make small changes. Separate file moves from behavior changes and remove code
  only after proving it has no live consumers. Retain licenses and attribution.
- Reuse existing services. Keep resource ownership clear for events, timers, hooks,
  frames, caches and deferred work. Disabled features should stop unnecessary work.
- Respect native combat/protected-state and secret-value restrictions. Do not replace
  global client APIs or conceal illegal operations behind broad error suppression.
- Inspect external reference addons read-only and verify versions/licenses before
  copying code. Do not synchronize to other installations without authorization.

## Validation and records

Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[development tasks](docs/DEVELOPMENT.md), relevant feature chapters and product
specifications before changing a subsystem. Use the existing validation runner and
source-reference tools. Update affected documentation, ledgers and the work log.

For meaningful runtime changes, preserve exact baseline/candidate identities and
repeated matched measurements with raw samples and variation. Keep native build,
profile, addon list, hardware, scenario and profiler settings with each capture.
Desktop mocks do not certify native rendering, secure input, taint or FPS. Mark
unavailable checks pending; never report invented results or reuse historical native
measurements as acceptance for new code. See [performance protocol](docs/PERFORMANCE_PROTOCOL.md)
and [client validation](docs/CLIENT_VALIDATION.md).
