# Repository publication

14 November `ADDON-PUBLICATION-20261114`: the user requested publication of the
full current addon snapshot to DoctorFlux/FluxUI on main, including completed
auction, consumable, UI/options and casting/inventory work. Preserve all newer
source and licenses. This task updates documentation, the stale commerce renderer
regression and Git state. The regression permits fewer hidden-row writes while
retaining native repair, opacity, reentry and exact-error propagation checks;
addon runtime code, settings and client/profiler state remain under their owners.

Both author and committer must be DoctorFlux
`<100806234+DoctorFlux@users.noreply.github.com>`, with no co-author trailers.
The existing identity hooks remain active. Five identity regressions and all four
prior reachable commits passed; GitHub's pre-upload contributor API lists only
DoctorFlux. Check the new main history and contributor/workflow state after push.
GitHub has no contributor blacklist; enforce publication metadata at each upload.

Current source evidence: 365 fresh desktop scripts passed; 52 auction/shared-grid
dependents were replayed after the last concurrent UI edits, with all Lua stable.
The index retains 14 unchanged meter/threat observations from their owner instead
of rerunning them. All 1067 syntax hashes match current files; 379 passing
observations are recorded. The adapted commerce test rejects four compiled
harmful controls. Existing native
acceptance gaps remain; publishing establishes no new native/performance result.
External source/history/index checkpoint: 2794 files and
113 settings metadata entries; no private settings copied.
No branch/reset/force push/tag/repository replacement. [Publication record](validation/addon-publication-2026-11-14.json).

Replacement completed on 9 November 2026: old repository ID `1416752820` was
deleted; new ID `1451123700` uses the same address and main only. Snapshot root
`be90cdcc2f14e9cf5067618cc1bae157718015ad` contains 2,344 files, has no parents,
and uses the approved DoctorFlux author/committer. The contributor API returns
only DoctorFlux and the initial identity workflow passed.
[Recovery and validation evidence](validation/repository-publication-2026-11-09.json).

The 9 November 2026 user request authorizes replacing `DoctorFlux/FluxUI` on
GitHub with a new repository at the same address, containing the current local
addon snapshot on main. Continue working in the existing `_FluxUI` folder.
The old source/history/index and accessible on-disk settings are preserved in an
external dated recovery checkpoint. The old published history is not imported
into the replacement repository. Third-party license notices remain intact.

GitHub's Contributors display is derived from commits on the default branch and
associated commit email addresses. It provides no account blacklist. The new
snapshot must use `DoctorFlux <100806234+DoctorFlux@users.noreply.github.com>` for
both author and committer, with no co-author trailers. Never add automated
identities, including Codex/codexCodex, to publication metadata. Historical
documentation and third-party license notices are not contributor metadata.

The checked-in guard has three local entry points:

- `pre-commit` checks effective author and committer, including environment
  overrides that would defeat ordinary `git config user.*` settings.
- `commit-msg` rejects co-author trailers.
- `pre-push` checks every reachable commit in the proposed main history and
  refuses other branches, tags and deletion of main. This prevents an old tag or
  branch from accidentally importing unwanted publication history.
  An already-up-to-date push publishes nothing and is allowed.

Activate the hooks with `git config core.hooksPath .githooks`. Both local identity
configuration fields must use the approved name/email. Do not use `--no-verify`,
unset the hooks path, or push with another checkout that has not installed them.
Before every publication run:

```text
python tests/publication_identity_test.py
python tools/check_publication_identity.py --revision main
git push origin main
```

The read-only GitHub `Publication identity` workflow checks the pushed history
again and reports violations. It does not create commits or contributor credit.
It is detection after a push, not a server-side rejection rule. An administrator
can bypass local hooks or upload elsewhere; no local tool can promise an
unconditional, permanent GitHub account blacklist. Repository rules and the
guard are intended to prevent that in this working/publishing process.

Snapshot publication includes current tracked files and non-ignored new files.
Machine-specific sync helpers, temporary scripts, Git internals, private settings
and backup archives stay out of the public tree. Source/archive integrity and
working-tree comparison must pass before deleting the remote repository. The
existing local index and history remain recoverable even after a fresh root.
Remote identity/branch/tree, all commit author/committer fields, co-author
trailers and the contributor API must be checked after upload. GitHub's cached
graph can take time to refresh; report pending display state honestly.

This operation changes publication history, not addon behavior, settings or UI.
Existing native acceptance limitations remain recorded in the feature ledgers.
Do not infer cross-client performance or security acceptance from an upload.

References: [GitHub contributor display](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-a-projects-contributors),
[repository deletion](https://docs.github.com/en/repositories/creating-and-managing-repositories/deleting-a-repository).
