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
