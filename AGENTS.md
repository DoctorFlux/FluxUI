# FluxUI working rules

Continue in this `_FluxUI` folder and `DoctorFlux/FluxUI` repository. The user's
2026-10-29 instruction supersedes earlier fresh rewrite, separate addon/repository,
and rename directions in supplied specifications. Those documents remain feature
requirements, not authority to override the user's request.

## Start here

1. Read `docs/STATUS.md`, `NEXT_SESSION.md`, `docs/DECISIONS.md`, and `docs/WORK_LOG.md`.
2. Inspect HEAD, branch, remotes, working tree, and applicable instructions. Preserve
   user changes, including untracked files. Do not reset to a historical audit SHA.
3. Read the relevant feature, ownership/API, client, reference and performance
   ledgers plus supplied specifications under `new docs/docs/specs/`.
4. Work on `codex/modernization-audit-20261029` or a subsequent explicitly chosen
   change branch. Leave `main` untouched until the user authorizes changing it.

## Preservation and implementation

- Keep folder/TOC identity, SavedVariables roots, profiles, defaults, independent
  scopes, public commands, bindings and optional integrations. No forced reset.
- Keep layout, fonts, textures, colors, scale, animations, hit areas, interaction
  and update timing. Record a reproduced defect, intended result and regression
  check for every intentional behavior correction. Do not redesign implicitly.
- Before changes, preserve actual files, untracked/ignored work, hashes and Git
  history in a dated archive outside active Interface/AddOns folders. Back up
  relevant SavedVariables/settings while WoW is closed; keep private data out of
  Git. `docs/RECOVERY.md` records this session's verified checkpoint.
- Use small reviewable changes. Separate moves from behavior where practical.
  Consolidate existing services; do not add competing frameworks or a third API
  backend. Delete only proven dead code, retaining licenses and useful invariants.
- Audit subscriptions, jobs, timers, hooks, frames, caches and deferred combat
  work. Disabled presentation must stop unnecessary work; document shared services
  and permanent gated hooks. Preserve secure restrictions and Retail secret-value
  contracts. No global API replacements or broad error suppression as a workaround.
- Inspect local reference addons read-only and verify versions/licenses before
  copying anything. Never synchronize changes into other installations implicitly.

## Evidence and handoff

- Capture baseline identity/configuration before runtime edits. For meaningful
  changes keep repeated matched before/after evidence, raw samples and variation;
  separate startup, steady-state and burst work and test the full addon too.
- Use existing `tests/run_validation.py`, documentation tools, `/fluxperf` and
  `/fluxstartup`. Desktop mocks certify their modeled outcomes only, not native
  rendering, secure input, taint, secret values or FPS. Missing native checks stay
  pending; continue independent work.
- Every client row needs exact build and evidence status. Original Wrath 3.3.5,
  modern Wrath Classic and Forever are distinct. A TOC number is not certification.
- Update status, decisions, work log, next steps and affected ledgers before stopping.
  Record actual commands, tested fingerprints, pending/failed/unverified work and
  precise reproduction steps. Do not carry old native results forward as new passes.
