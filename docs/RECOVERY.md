# Recovery checkpoint 2026-10-29

Before repository edits, the checkout was `main` at
`7436820453d2248c84c99fff71507553efc47c19`, tree
`6e3af8d646a09ce2182ffd6d2cc287890584825a`. Remote:
`https://github.com/DoctorFlux/FluxUI.git`. There were no tracked modifications.
`FluxUI_Sync_Log.txt` and the entire `new docs/` package were untracked.
No applicable ancestor/root AGENTS file existed; the package's context template
was read and merged into the new root instructions.

Private recovery directory, outside every active addon folder:

```text
C:\Users\mario\.codex\visualizations\2026\10\29\01a186ea-e332-79a1-9cdc-8e340df7e22b\FluxUI-recovery-20261029T0910Z
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

The working branch is `codex/modernization-audit-20261029`. `main` remains at the
original SHA. Creating the branch required sandbox escalation for `.git` writes;
automatic review approved it. No push or merge is implied.

## Continuation checkpoint 09:32 UTC

Before the second runtime batch, a new checkpoint preserved branch commit
`201bc8382f9fa6b5d9906200e3331a4ad90c2f13`, tree
`6976189ef0843924e081d89cd47c83001f8d150f`. The only untracked file was the original
`FluxUI_Sync_Log.txt`. The first checkpoint remains intact.

```text
C:\Users\mario\.codex\visualizations\2026\10\29\01a186ea-e332-79a1-9cdc-8e340df7e22b\FluxUI-recovery-20261029T0932Z
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
