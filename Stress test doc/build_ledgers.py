"""Build stress-record indexes, retaining historical observations and current fix status."""
from pathlib import Path
from collections import defaultdict
import csv
import json

OUT = Path(__file__).resolve().parent
def write_csv(name, rows):
    with (OUT / name).open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys()); w.writeheader(); w.writerows(rows)

# IDs belong to the original subreports and remain stable for later fixes.
catalog = [
('USER-001','user-reported native error; root caller unconfirmed','P1','Forever confirmed; exact installed build/action/frame unknown','UnitFrames/FluxCastBar.lua',1291,
 'Secret startAlpha reaches native OUT fade arithmetic',
 'Thirteen consolidated FrameUtil.lua:427 entries atseven timestamps through13:21:18; cast/swing getter-fed fades remain leading candidates',
 'Identify affected owner; preserve fade duration/completion using public owned alpha endpoints; no secret arithmetic or native manager replacement',
 'Actual cast/swing fade suppliers; readable/restricted alpha; interruption/reuse; current-frame ownership and native separate validation','security/USER-001-FADE.md'),
('SEC-01','reproduced API interference','P1','Forever','Core/Engine/Restricted.lua',430,
 'Global driver replacements reject foreign/unnamed frames',
 'Three foreign registrations reject; original native manager calls fall to zero',
 'Move owned callers to Flux.Restricted; preserve current fallback/paging restrictions and native API provenance',
 'Foreign/owned named/unnamed frames; before/after load order; combat and paging success/failure','security/AUDIT.md'),
('SEC-02','reproduced failure handling','P1','All five stance models; Era/Anniversary/progression action restore','Respec/FluxRespec_Apply.lua',724,
 'Respec reports success after failed or deferred action restore',
 'Injected denial/error/defer can still emit APPLY_DONE(true) and clear checkpoint',
 'Propagate action results; await deferred completion and retain recoverable checkpoint',
 'Success/error/false/deferred/partial restore; combat reentry; one accurate completion','security/AUDIT.md'),
('SEC-03','reproduced cancellation ownership','P1','Era/Anniversary/progression','Respec/FluxRespec_ActionBars.lua',532,
 'Cancelled Respec action work still executes after combat',
 'Cancelled running operation later writes a slot; queued input snapshot is mutable',
 'Detach queued snapshot and bind action work to existing operation generation/cancellation',
 'Cancel while bindings wait; profile edit/delete; A-to-B replacement; no stale writes','security/AUDIT.md'),
('INPUT-001','reproduced refresh signal loss','P2','Shared module; five client labels','Core/Engine/Context.lua',362,
 'Mouseover narrows pending target/modifier/combat invalidation',
 'Full request then mouseover before drain clears wider changed-kind flags; reverse order passes',
 'Merge pending invalidation kinds monotonically using current scheduler and cadence',
 'All event orderings; force/form/peek; repeated release; one delivery per burst','input/README.md'),
('INPUT-002','reproduced fallback error','P2','Shared module; fallback capability/error path','Binding/Input/FluxMouseoverKeybind.lua',1822,
 'Hover fallback treats first GetChildren return as an array',
 'First/later hovered child ignored when modern focus cannot establish descendant context',
 'Safely consume all varargs with hierarchy/forbidden guards and bounded reusable traversal',
 'Zero/one/multiple children; first/last hover; modern control; forbidden/hidden combat routes','input/README.md'),
('LOGIC-01','latent service defect','P2','Shared Scheduler API; ordinary feature trigger unproved','Core/Engine/Scheduler.lua',259,
 'Partial inventory drain overwrites a newly queued request',
 'Eight-old-callback control retains nested request; nine-old-callback case loses callback/token',
 'Merge old leftovers and new pending bucket with stable ordering and complete token/reason sets',
 'Boundary8/9; callbacks and listener reentry; distinct same-token jobs; exactly once','performance/PERFORMANCE_AUDIT.md'),
('LOGIC-02','latent service defect','P2','Shared Events API; ordinary feature trigger unproved','Core/Engine/Events.lua',174,
 'Self-unregistering event listener skips the following listener',
 'A removes itself from A/B/C during dispatch; observed delivery A/C',
 'Define mutation semantics; use stable records/tombstones and outermost compaction',
 'Remove earlier/later/all; add during dispatch; nested delivery and error isolation','performance/PERFORMANCE_AUDIT.md'),
('PERF-01','optimization candidate','P2','Four raid client parameter sets','RaidFrame/FluxRaidUnit.lua',580,
 'Raid burst repeatedly rearms the same paint driver',
 '40 units x100 x7 events:28000 SetScript arms;40 final health paints',
 'Arm once per pending flush while retaining category merging and nested events',
 '0/1/5/40 members; hide/rebind; events during flush; identical next-frame paints','performance/PERFORMANCE_AUDIT.md'),
('PERF-02','optimization candidate','P2','Forever nameplate source slice','NamePlates/Core.lua',610,
 'Stable nameplates repeat native alpha and anchor writes',
 '40 plates x600 frames:144000 SetAlpha;103400 SetPoint;5920 ClearAllPoints',
 'Cache public layout/style revisions and repair native changes through verified ownership',
 'Reuse/style/scale/name-only/cast/CC/LoC; native pixels and taint separately','performance/PERFORMANCE_AUDIT.md'),
('PERF-03','optimization candidate','P2','Retail nameplate source slice','NamePlates/Core.lua',810,
 'Stable hidden level frames receive repeated Hide calls',
 '40 plates x600 frames:48000 native Hide calls',
 'Use verified lifecycle suppression with bounded repair if native restores visibility',
 'Native show/refresh/reuse; option/preview exclusions; instant correct appearance','performance/PERFORMANCE_AUDIT.md'),
('PERF-04','optimization candidate','P3','Forever character microbutton source slice','Other/FluxChatColumnMicros.lua',967,
 'Character-button watcher continues polling while idle/hidden',
 '36000 stationary polls then36000 hidden callbacks in20 modeled minutes',
 'Park when hidden; wake using a safe ownership path preserving native click/close behavior',
 'Press-hide; release; keybind; right-click; combat/gamepad; no unsafe native hooks','performance/PERFORMANCE_AUDIT.md'),
('PERF-05','service hardening candidate','P2','Shared Scheduler API; hostile queue workload','Core/Engine/Scheduler.lua',223,
 'Callback queue copies tails and does not coalesce callback jobs by token',
 '10000 inventory callbacks:1250 flushes;6245000 modeled tail-reference copies',
 'Use head cursor; preserve distinct callbacks; explicitly key only idempotent refresh jobs',
 'FIFO; nested requests; fairness; error isolation; bounded copy count and latency','performance/PERFORMANCE_AUDIT.md'),
('PERF-06','freshness policy investigation','P2','Shared Range service','Core/Engine/Range.lua',316,
 'Sustained hover storm postpones all shared range sweeps',
 '101000 events;zero sweeps over1000 storm frames;one sweep after quiet',
 'If required set maximum staleness without losing cache/range restrictions or final settle',
 'Friend/enemy/missing/secret hover; target-only and item range; no invalid-hover fanout','performance/PERFORMANCE_AUDIT.md'),
('PERF-07','freshness policy investigation','P2','Four builtin-auction parameter sets','Inventory/Builtin/Auctions.lua',194,
 'Auction event stream prevents changed snapshot publication until quiet',
 '20 events/s x10 modeled seconds:zero publications;381/375 discarded row reads for32/1024 rows',
 'Coalesce true duplicates or measure max-age/retry policy while preserving atomic generations',
 'Index shifts/sales/reentry/close/provider handoff; row budget; never mixed generations','performance/PERFORMANCE_AUDIT.md'),
('PERF-SEC-01','burst risk investigation','P2','Shared Combat queue; five models','Core/Engine/Combat.lua',34,
 'Regen drain can run all distinct callbacks in one frame',
 '10000 queued light/heavy jobs execute in one next-frame drain',
 'Measure real producers; coalesce only equivalent jobs or budget distinct expensive work',
 'Ordering; combat reentry; cancellation; exactly-once completion; all features retained','security/AUDIT.md'),
]
keys = ['id','classification','priority','clientScope','source','line','title','observation','futureFix','regression','report']
rows = [dict(zip(keys, values), status='OPEN; no addon fix applied', nativeTaint='NOT RUN', nativeCPUFPS='NOT RUN') for values in catalog]
applied_path = OUT / 'applied-fixes/status.json'
applied = json.loads(applied_path.read_text(encoding='utf-8')) if applied_path.exists() else {}
for extra in applied.get('additionalFindings', []):
    rows.append({**dict.fromkeys(keys, ''), **extra, 'status': 'PENDING', 'nativeTaint': 'NOT RUN', 'nativeCPUFPS': 'NOT RUN'})
for row in rows:
    row['sourceRole'] = 'Leading candidate only; actual failing owner unconfirmed; native failure is external FrameUtil.lua:427' if row['id']=='USER-001' else 'Reproducer or reviewed implementation location'
    if row['id']=='USER-001':
        row['nativeTaint']='USER REPORTED thirteen entries at seven timestamps; no agent native reproduction; action unknown'
    current = applied.get('findings', {}).get(row['id'], {})
    row.update(current)
write_csv('FINDINGS.csv', rows)
(OUT / 'FINDINGS.json').write_text(json.dumps(rows, indent=2) + '\n', encoding='utf-8')

coverage = list(csv.DictReader((OUT / 'SOURCE_COVERAGE.csv').open(encoding='utf-8')))
groups = defaultdict(list)
for r in coverage: groups[r['source'].split('/')[0]].append(r)
modules = []
for module, sources in sorted(groups.items()):
    literal_tests = sorted({t for r in sources for t in r['testPaths'].split('; ') if t})
    modules.append({'module': module, 'reachableFiles': len(sources),
                    'luaFiles': sum(r['kind']=='.lua' for r in sources),
                    'filesWithLiteralTestReferences': sum(int(r['literalTestReferences']) > 0 for r in sources),
                    'referencingSuiteScripts': len(literal_tests), 'testPaths': '; '.join(literal_tests),
                    'review': 'TOC/load closure + performance driver sites + security triage; test reference index is not branch coverage',
                    'parity': 'Applied source changes documented in applied-fixes; desktop parity controls only; native visual parity NOT RUN' if applied else 'No runtime code/art/settings operations by this audit; native visual parity NOT RUN',
                    'remaining': 'Indirect/unreferenced branches, integration combinations and native boundaries remain unverified'})
write_csv('MODULE_MATRIX.csv', modules)

pins=json.loads((OUT/'evidence/upstream-pins.json').read_text())['pins']
targets=[('era','Era',11509),('anniversary','Anniversary',20506),('retail','Retail live',120105),('forever','Forever',16001)]
write_csv('CLIENT_LEDGER.csv', [
    {'client': label, **pins[key], 'derivedInterface': interface,
     'selectedTOCXMLPaths': sum(r[label]=='TOC selected' for r in coverage),
     'desktopEvidence': 'Existing suite plus targeted capability/source models; not whole-client emulation',
     'combatOOCWorldDungeonRaidNative': 'NOT RUN: user requested simulations only',
     'nativeTaint': 'NOT RUN', 'nativePerformance': 'NOT RUN', 'nativePixels': 'NOT RUN'}
    for key,label,interface in targets])
write_csv('PERFORMANCE_LEDGER.csv', [r for r in rows if r['id'].startswith('PERF')])
print('Indexed',len(rows),'findings/investigations including USER-001;',len(modules),'module groups;4 client pins;8 performance investigations')
