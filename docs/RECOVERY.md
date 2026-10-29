# Recovery checkpoint 2026-10-29

Before repository edits, the checkout was `main` at
`7436820453d2248c84c99fff71507553efc47c19`, tree
`6e3af8d646a09ce2182ffd6d2cc287890584825a`. Remote:
`https://github.com/DoctorFlux/FluxUI.git`. There were no tracked modifications.
`FluxUI_Sync_Log.txt` and the entire `new docs/` package were untracked.
No repository contribution guidelines existed at the original checkpoint.

Private recovery directory, outside every active addon folder:

```text
FluxUI-recovery-20261029T0910Z
```

| Artifact | Coverage | SHA-256 |
|---|---|---|
| `source.zip` | 1,177 actual files, 32,278,732 uncompressed bytes; includes all untracked/ignored files and assets, excludes only `.git` | `a8c275bad5d165833d4fe55ba00223aab200b8930ada0029539a706251a19f4c` |
| `history.bundle` | All Git refs/history before branching; `git bundle verify` passed | `73631632a11ba0bdae516a5167c6330f9d925646820a38ecdd73c1886809587e` |
| `settings-private.zip` | 403 accessible WTF files, 6,333,743 bytes across installed client directories | `19c36051db161b05c680e155a24e1738aad8d6bf5a1d18ce4403beec07fbad64` |

Every ZIP entry was read back and compared to its SHA-256 manifest; source files
were reread during capture to detect concurrent writes. Capture completed at
2026-10-29 09:10:49 UTC. WoW process count was zero immediately before capture.
Settings selection includes Flux, TrinketMenu, Baganator and Syndicator saved data,
their backups, bindings/config caches and Config.wtf. It is not a whole-WTF backup.
Private manifests and `checkpoint.json` remain beside the archives, outside Git.

For recovery, close WoW, first archive any newer work, verify the hashes above,
and inspect the per-file manifest. Restore selected files into this same `_FluxUI`
folder. Restore settings to their recorded client-relative paths only if needed.
Do not restore old WTF over newer settings without reviewing the change. Use the
history bundle to recover Git history if necessary; ordinary rollback should use
the change branch and the verified source archive. Do not extract a second active
addon or overwrite the checkpoint. No recovery or settings reset was performed.

`main` remains at the original SHA; development uses the current change branch.

## Continuation checkpoint 09:32 UTC

Before the second runtime batch, a new checkpoint preserved branch commit
`201bc8382f9fa6b5d9906200e3331a4ad90c2f13`, tree
`6976189ef0843924e081d89cd47c83001f8d150f`. The only untracked file was the original
`FluxUI_Sync_Log.txt`. The first checkpoint remains intact.

```text
FluxUI-recovery-20261029T0932Z
```

| Artifact | Coverage | SHA-256 |
|---|---|---|
| `source.zip` | 1,202 actual files; 33,815,972 uncompressed bytes, including untracked/ignored files | `a04a1143ed95e27d5db1a99f70ea2cde9cc496af6ad1c1110154c431bf7cfef1` |
| `history.bundle` | All current Git refs/history; bundle verification passed | `d40afdd3df99dfd2c950459087d8d3ae59fcb5268f77ac04a20b88fc3d39e954` |
| `settings-private.zip` | 403 relevant WTF files; 6,333,742 uncompressed bytes | `e4edce07740b65a59a6077513a94a95f454559595043e56bd7a4053f61bb8e48` |

Capture completed 2026-10-29 09:32:07 UTC after confirming zero WoW processes.
Every ZIP entry and its original file were hash-verified again. The settings archive
is a fresh snapshot; no private data was changed by this work or committed to Git.
Use the same recovery precautions above and preserve newer work before any restore.

## Mail completion checkpoint 09:41 UTC

Before the separate outgoing-mail correction, checkpoint
`FluxUI-recovery-20261029T094131Z` was created beside the earlier archives. It preserves
commit `05e9f79160ac641f842f5aba8eabd21f1fe0c1fe`, tree
`6e612fa6b27282f5e535b361f5cf93ac17d250ba`, and the actual uncommitted audit/evidence
files and original sync log. No WoW process was running.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| `source.zip` | 1,212 files; 34,104,932 uncompressed bytes | `33964c2ec52c2d06a75e129b07368c73e57fcab1c60e110eda2c13a3eabb9c4d` |
| `history.bundle` | All refs/history; verified | `62162606f8519ac6b2972e269db6641c043a14cb514e9ea0c1fe26419bd91765` |
| `settings-private.zip` | 403 WTF files; 6,333,742 uncompressed bytes | `3414146ddf5e7849d5e0c149c323ee7353a7187a8c74ba576daa653ed882728d` |

Capture and ZIP/hash verification completed 2026-10-29 09:41:35 UTC. ZIP archive
hashes can differ across captures because entry timestamps differ; per-entry hash
manifests identify file contents. Private archives/manifests remain outside Git.

## Windows lifecycle checkpoint 10:07 UTC

Before the current runtime batch, verified external checkpoint:

```text
FluxUI-recovery-20261029T100747Z
```

It preserves baseline commit `f1a3bc7488a904e075264794e080a00c8fceba23`, tree
`8dbef40c11d122a47d238c0445e936d1894d28a8`, all actual ignored/untracked files and
all Git history/refs. No WoW process was running. Capture completed 10:07:52 UTC.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| `source.zip` | 1,219 files; 34,412,547 uncompressed bytes | `0c31e5bed7902f2299cc4cb4dfd0f901e62220bc1c8b85254b7162224f67d9ff` |
| `history.bundle` | All refs/history; verified | `5d83c0c28dc66191be8b99f1a2601d5ca0189f01be4a4fcf4cc4307e14338ab7` |
| `settings-private.zip` | 403 WTF files; 6,333,742 uncompressed bytes | `17ef1b66c266895d92d6d2660aff50544d7b9e886ebc0cc1dffef29c9f95e8ba` |

Every ZIP entry was reread and hash-verified against its source manifest. Private
settings/manifests remain outside Git. All earlier archives remain intact. No
restore/reset was performed; preserve newer work before any future recovery.

## Editorial cleanup checkpoint 10:19 UTC

External archive: `FluxUI-recovery-20261029T101942Z`. Absolute private paths are
stored in its checkpoint metadata outside the addon. Baseline commit:
`f57fc79b536d23a87666d751135304865571d738`, tree
`9876bb52f688dba175d2b867be038aea0e5cfcb1`. WoW was closed.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| source.zip | 1,228 actual files; 34,672,776 bytes | `876d8a2fa9d71a37958b836e67f2ceec50925e52e4c696103bf3591cafb4d0c9` |
| history.bundle | All refs/history; verified | `3cfc06ae442e2affe28e2e2edc881cb7b5c380ea41e7c650bb3ca029e53d8652` |
| settings-private.zip | 403 files; 6,335,941 bytes | `8759f2dc598d33bf8df1b4fb2a5d4af93d9603b713f396c462635f1ed6c9d75b` |

ZIP entries were reread and hash-verified. The checkpoint also retains the retired
editor plans, prompts/templates, original Word plan, former handoff files, local
backup trees and sync log as ordinary files under `retired/`. The current Markdown
plan, specifications, tests and factual validation evidence remain in the repository.
No addon identity, settings or Git history was reset or rewritten.

## Merchant identity checkpoint 10:40 UTC

External archive: `FluxUI-recovery-20261029T104042Z`. Capture completed 10:40:48 UTC
with no WoW process running. Baseline commit `07b11ce66c1b9efd70752f70f15a8e3f88fa63eb`,
tree `ddd388fb8c69d8650efb485f1d9b95d0512f7e3e`; working tree was clean.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| source.zip | 1,195 actual files; 33,267,050 bytes | `23811bd6d972ed30af758503190f81486769b344a39b3426f253fffae9a0f0b8` |
| history.bundle | All refs/history; verified | `9d8928ddbf01a71868c89c2610647f1d30ddf367950506659811cb7489960d76` |
| settings-private.zip | 403 files; 6,336,469 bytes | `1478525b853dafcb8a534653792e4ba79b04d1f1ee5bfcf95db39b6dd8a4f6ec` |

All archive entries were reread and hash-verified against their source manifests.
Absolute recovery locations/private manifests stay outside Git. Earlier checkpoints
and their retired original files remain intact. No restore/settings reset occurred.

## Merchant stock checkpoint 10:54 UTC

External archive: `FluxUI-recovery-20261029T105442Z`. Capture completed 10:54:48 UTC
with no WoW process running. Baseline `0d05acc3f56235d34dfa8dd699155a9e9f40147e`, tree
`d482d14b17a63345ceaeea8ea2b5e6be1bed9f19`; working tree was clean.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| source.zip | 1,203 actual files; 33,648,387 bytes | `07a5407e755f8bbd217882f85cf4e146fc42b68a292db64aa1e6d53618ba7bba` |
| history.bundle | All refs/history; verified | `378060052850cfbcc3cac75b62011e92ee28af4be7a2838b98d81a40c2297b39` |
| settings-private.zip | 403 files; 6,336,469 bytes | `174647aa601a528f434b07938eb2c71c7a1cdf33b7451d7b51f2bd1ad912e85d` |

All archive entries were reread and verified against source hashes. Private absolute
locations/manifests remain outside Git; previous checkpoints/retired originals stay
intact. No restore/settings reset was performed.

## Vendor-open checkpoint 11:14 UTC

External archive: `FluxUI-recovery-20261029T111401Z`. Capture completed 11:14:06 UTC
with no WoW process running. Baseline `9e17e28310e14f571208c8ecddfa0e36ae616a13`, tree
`69c039054c7d522a741ca6bb3a72682f1ca04b43`; working tree was clean.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| source.zip | 1,210 actual files; 34,039,922 bytes | `36d80551bc3df8b379f01bf62a06d25fc8d5a0b60368a2bb626fad867e48c62e` |
| history.bundle | All refs/history; verified | `f48725c06b33d1875164ad4beb2bba539c4c93a44e07c691b58076cfc37b50bc` |
| settings-private.zip | 403 files; 6,336,455 bytes | `717ccea2c1a4703f85bb07166c3ffbc3f3474b0dcd6ff958163dafc7ae7111bd` |

Every archive entry was reread and verified against source hashes. Private absolute
locations/manifests stay outside Git; earlier checkpoints/retired originals remain.
No restore/settings reset occurred.

## Chat anchor checkpoint 11:47 UTC / 12:47 Copenhagen

External archive: `FluxUI-recovery-20261029T114702Z`. Capture completed 11:47:07 UTC
with no WoW process running. Baseline `7465e36653a279e7276568eb2b90e147a6c38e93`, tree
`1fadea2a65a083142392a018dedc0060673fee1d`; working tree was clean.

| Artifact | Coverage | SHA-256 |
|---|---|---|
| source.zip | 1,218 actual files; 34,322,656 bytes | `8e9357aeb42208e01350752516dcc7fa910223b7675040339cb8657f5e00fde3` |
| history.bundle | All refs/history; verified | `7b8a75eb390c845d47aa420d0fb85a2b6f67fda8073466f418ec18de832edae6` |
| settings-private.zip | 403 files; 6,337,461 bytes | `a5d52b0b014717f320da57924f21eeb17bbb4af8884bea44114988aa17a78b5c` |

Every ZIP entry was reread and verified against its source manifest; Git bundle
verification passed. Private absolute paths/manifests remain outside Git. Earlier
checkpoints/retired originals remain intact; no restore/settings reset occurred.
