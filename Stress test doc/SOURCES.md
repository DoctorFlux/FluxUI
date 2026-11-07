# Source identities and evidence boundaries

Read-only Gethe branch resolution and commit metadata retrieved through the
connected GitHub tools on 7 November 2026. Branches were resolved once for this
audit; all subsequent source reads use these commits. The initial web API and
sandbox DNS paths failed; the GitHub connector succeeded.

| Requested client | Branch | Pinned commit | Source version | Commit UTC | Derived interface |
|---|---|---|---|---|---|
| Retail live | live | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 | 2026-11-04 00:46:01 | 120105 |
| Forever | forever | `9dc84f0d3bbae1768ac3405b3716000bd93eda06` | 1.60.1.70862 | 2026-11-07 04:46:13 | 16001 |
| Classic Era | classic_era | `4192ac60067fc55566182291bc67c85dd9b6794d` | 1.15.9.70576 | 2026-10-26 23:16:08 | 11509 |
| Classic Anniversary | classic_anniversary | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | 2.5.6.70577 | 2026-10-26 23:16:20 | 20506 |

Versions are read from each pinned `version.txt`: [Retail](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/version.txt),
[Forever](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/version.txt),
[Era](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/version.txt),
[Anniversary](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/version.txt).
These are source-mirror builds; installed/in-memory `GetBuildInfo()` was not
queried. TOC interface membership and function existence do not certify gameplay.

[upstream-pins.json](evidence/upstream-pins.json) keeps commit and Git blob IDs.
[reference-comparison.json](evidence/reference-comparison.json) compares seven
targeted local reference files with current pinned remote bytes. All seven match
after CRLF normalization, despite older local directory version labels.
Anniversary's raw Git blob differs because of line endings; normalized content
was compared explicitly. This accepts those files only, not entire old trees.
Other existing tests that depend on sibling reference trees retain their dated
fixtures and are not silently promoted to current-source certification.

The verified files include all four `SecureStateDriver.lua` implementations,
Forever project selection/constants, and Forever's generated SimpleFrame API.
The latter declares a strided sequence of frame returns from `GetChildren` and
notes hierarchy-related secret returns. Native hierarchy access remains separately
unverified. [Pinned declaration](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L323).

Addon baseline: `main`, HEAD `75cf2bcba83adfea0501934f4eeb2a980c46fdf8`, with
the user's uncommitted working files. HEAD alone does not describe the tested
addon; use [baseline.json](evidence/baseline.json), the suite's normalized Lua
manifest, and each stress report's production hashes.

Fresh source archive, working diff/history and targeted remote snapshots are
retained outside AddOns at the external checkpoint recorded in `baseline.json`.
The same location contains private settings metadata for 45 files; their values
and account/character paths are not included here. No settings backup was taken
from the running game and no profiler settings were changed.

Reference files are inspected under their existing ownership and licenses.
No third-party implementation/art or license text has been copied into the addon.

USER-001 added a current Forever FrameUtil source verification after the initial
seven-file set: Git blob `a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d`, same Forever
commit, normalized external reference match. Its source identity, generated Alpha
return contract and conditional reproducer are retained in
[user-001-fade-results.json](security/user-001-fade-results.json). This is separate
from knowing the user's actual runtime build or identifying the failing frame.
