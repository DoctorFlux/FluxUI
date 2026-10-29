# Next session

Continue the original [modernization plan](new%20docs/docs/FluxUI_Modernization_Plan.md)
in the existing addon and branch. Main stays untouched. Read the current
[stage tracker](docs/MODERNIZATION_PROGRESS.md), [status](docs/STATUS.md) and
[development tasks](docs/DEVELOPMENT.md) for exact evidence and pending checks.

Preserve the separate uncommitted objective-tracker source, test and records.
Inspect Git status before staging; avoid blanket staging of generated/shared docs.
Keep auction, guild-bank and void-storage callbacks excluded. Leave WoW in the
background and retain the user's settings and profiling preferences.

Next priorities:

1. Validate the nameplate countdown optimization natively on exact builds using
   [matched steps](docs/NAMEPLATE_COUNTDOWN_WORK.md), including aura reuse and
   restricted-display cases. Desktop fixtures do not certify these checks.
2. Attribute assisted-action paint and same-fact glow/checked updates before
   changing their cadence or ownership. Preserve paging and animation continuity.
3. Stress options/map/inventory/binding/unit/raid resources through repeated
   enable/disable/open/close cycles and long sessions. Quantify private-cache growth
   before changing eviction. Continue the stage gates in the original plan.

Reproduction from the addon root:

```powershell
lua tests/nameplate_countdown_work.lua --source tests/fixtures/nameplate_countdown_before.txt --measure
lua tests/nameplate_countdown_work.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure mode intentionally exits zero while reporting unmet optimization
budgets. Candidate mode must pass. No release, settings reset or merge is authorized.
