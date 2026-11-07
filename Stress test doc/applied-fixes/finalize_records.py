"""Reconcile the applied-fix evidence into existing repository continuity/ledgers."""
from pathlib import Path
import csv
import hashlib
import json
import subprocess
import zipfile

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
DOCS = ROOT / 'docs'
CHANGE = 'STRESS-FIXES-20261107'
checkpoint = json.loads((OUT / 'checkpoint.json').read_text(encoding='utf-8-sig'))
suite = json.loads((OUT / 'full-suite.json').read_text(encoding='utf-8'))
assert not suite['fail'] and not suite['syntaxFailures']
assert suite['pass'] == len(suite['tests'])
original = {r['path']: r for r in checkpoint['files']}
changed, missing, added = [], [], []
for rel, old in original.items():
    path = ROOT / rel
    if not path.is_file():
        missing.append(rel)
        continue
    current = hashlib.sha256(path.read_bytes()).hexdigest()
    if current != old['sha256']:
        changed.append({'path': rel, 'beforeSHA256': old['sha256'], 'appliedSHA256': current})
concurrent_paths = ['Core/ButtonFX/Click.lua', 'ExtraButtonSystem/Engine/Action.lua',
                    'ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua', 'tests/utility_secure_input.lua']
for row in changed:
    if row['path'] in concurrent_paths:
        row['attribution'] = 'Concurrent utility-key work observed and preserved; not issued by this stress-fix team'
for path in ROOT.rglob('*'):
    rel = path.relative_to(ROOT)
    if not path.is_file() or any(x in ('.git', 'Stress test doc', '__pycache__') for x in rel.parts):
        continue
    if rel.as_posix() not in original:
        added.append({'path': rel.as_posix(), 'appliedSHA256': hashlib.sha256(path.read_bytes()).hexdigest()})
drift = [r['path'] for r in suite['manifest']
         if hashlib.sha256((ROOT / r['path']).read_bytes().replace(b'\r\n', b'\n')).hexdigest() != r['sha256']]
current_lua = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*.lua')
               if not any(part.startswith('.') for part in p.relative_to(ROOT).parts)
               and p.name != '_tmp_striplines.lua'}
recorded_lua = {r['path'] for r in suite['manifest']}
assert current_lua == recorded_lua, sorted(current_lua ^ recorded_lua)
assert not drift, drift
assert not missing, missing
art_suffixes = {'.tga', '.blp', '.png', '.jpg', '.ttf', '.otf', '.ogg', '.mp3', '.wav'}
art_changes = [r['path'] for r in changed + added if Path(r['path']).suffix.lower() in art_suffixes]
assert not art_changes, art_changes
with zipfile.ZipFile(Path(checkpoint['externalCheckpoint']) / 'source.zip') as archive:
    before_toc = archive.read('_FluxUI.toc').decode('utf-8-sig').splitlines()
current_toc = (ROOT / '_FluxUI.toc').read_text(encoding='utf-8-sig').splitlines()
toc_metadata_unchanged = [s for s in before_toc if s.startswith('##')] == [s for s in current_toc if s.startswith('##')]
assert toc_metadata_unchanged
shared_library = 'libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua'
assert hashlib.sha256((ROOT / shared_library).read_bytes()).hexdigest() == original[shared_library]['sha256']
manifest = {'checkpoint': checkpoint['externalCheckpoint'], 'head': checkpoint['head'],
            'branch': checkpoint['branch'], 'originalFiles': len(original), 'changed': changed,
            'added': added, 'missing': missing, 'postSuiteLuaDrift': drift, 'postSuiteLuaMembershipMatches': True,
            'artChanges': art_changes, 'tocMetadataIncludingSavedVariablesUnchanged': toc_metadata_unchanged,
            'sharedLibCustomGlowUnchanged': True,
            'concurrentPreservedSourcePaths': [p for p in concurrent_paths if any(r['path'] == p for r in changed)],
            'scope': 'Exact raw pre-edit/current identities. Existing dirty work retained; no commit/push or settings copy. Documentation changes are intentional.'}
(OUT / 'source-changes.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')

fixed = ['SEC-01', 'SEC-02', 'SEC-03', 'INPUT-001', 'INPUT-002', 'LOGIC-01', 'LOGIC-02',
         'PERF-01', 'PERF-02', 'PERF-03', 'PERF-05', 'PERF-06', 'PERF-SEC-01',
         'ALPHA-01', 'ALPHA-02', 'ALPHA-03', 'ALPHA-04', 'ALPHA-05', 'ALPHA-06', 'GEO-01', 'GEO-02']
statuses = {key: {'status': 'APPLIED; desktop regression PASS; native acceptance pending'} for key in fixed}
statuses.update({
    'USER-001': {'status': 'APPLIED public cast/swing fade ownership; model regression PASS; actual native failing owner and recurrence pending'},
    'PERF-04': {'status': 'APPLIED hidden-watch suspension; visible native-state polling retained to preserve input behavior; native cost pending'},
    'PERF-07': {'status': 'APPLIED bounded retry churn; coherent final publication after quiet retained; continuous native-list mutation has no safe freshness guarantee'},
})
extras = [
    ('ALPHA-01', 'Bars/Blizzard.lua', 'Secret quiet-grid alpha comparison', 'Public zero skips writes; opaque/denied getters retain the previous repair write'),
    ('ALPHA-02', 'UnitFrames/FluxSwingTimer.lua', 'Redundant cast-priority alpha comparison', 'Remove getter while preserving every priority return'),
    ('ALPHA-03', 'Core/ButtonFX/Charges.lua', 'Secret bling alpha comparison', 'Keep public threshold policy; opaque/denied getter retains prior appearance and retries on normal paints while timer/clear lifecycle continues'),
    ('ALPHA-04', 'Core/ButtonFX/Cast.lua', 'Secret cast/badge visibility alpha comparison', 'Treat unreadable alpha as unknown/possibly visible after shown checks'),
    ('ALPHA-05', 'ExtraButtonSystem/Engine/Button.lua', 'Restricted effective-alpha readiness checks', 'Narrowly contain denied getter and retain existing animation readiness'),
    ('ALPHA-06', 'Core/ButtonFX/ThreatGlow.lua', 'Shared winning glow library and threat alpha arithmetic', 'Private MIT-attributed owned renderer/public state; foreign shared libraries and overlays untouched'),
    ('GEO-01', 'UnitFrames/FluxUnitFrames_Shared.lua', 'Secret health width comparison and prediction arithmetic', 'Owned public dimensions and original full-width/max-health normalization; positive-heal/antiheal path included'),
    ('GEO-02', 'UnitFrames/FluxUnitFrames_Shared.lua', 'Secret fill-size striped texture arithmetic', 'Owned clipping canvases preserve physical 32px phase without deriving dimensions from opaque native fill widths'),
]
additional = [{'id': key, 'classification': 'conditional desktop secret-value failure', 'priority': 'P1' if key.startswith('ALPHA') else 'P2',
               'clientScope': 'Capability-specific shared paths; native secret behavior not emulated', 'source': source, 'line': 1,
               'title': title, 'observation': 'Historical conditional reproducer and guarded controls retained in security follow-up reports',
               'futureFix': fix, 'regression': 'Applied focused regressions plus combined canonical suite',
               'report': 'applied-fixes/README.md'} for key, source, title, fix in extras]
anchors = {'ALPHA-01': 'function Blizzard.QuietGrid(', 'ALPHA-02': 'local function CastBarIsBusy(',
           'ALPHA-03': 'local function SetBling(', 'ALPHA-04': 'local function WidgetShown(',
           'ALPHA-05': 'local function PublicCooldownAlpha(', 'ALPHA-06': 'local function OwnerSize(',
           'GEO-01': 'local function PredictionGeometry(', 'GEO-02': 'clip:SetClipsChildren(true)'}
for row in additional:
    row['line'] = next(i for i, line in enumerate((ROOT / row['source']).read_text(encoding='utf-8-sig').splitlines(), 1)
                       if anchors[row['id']] in line)
(OUT / 'status.json').write_text(json.dumps({'change': CHANGE, 'findings': statuses, 'additionalFindings': additional}, indent=2) + '\n', encoding='utf-8')

evidence = '../Stress%20test%20doc/applied-fixes/README.md'
summary = (f'7 November stress fixes ({CHANGE}): the user authorized implementation after the audit/proposal phase. '
           'Applied public fade ownership, secret-safe alpha/geometry handling, local Forever driver adapters, accurate/cancellable Respec completion, '
           'input invalidation, mutation-safe event delivery, retained FIFO scheduler work, bounded combat drains, raid/nameplate work reduction, hidden-watch suspension, '
           'bounded range freshness and auction retry churn. Settings, saved roots, commands, artwork and foreign library ownership are preserved. '
           f'Combined desktop validation: {suite["pass"]}/{len(suite["tests"])} scripts and {suite["syntaxFiles"]} Lua syntax files PASS; '
           'post-suite Lua hashes match. No game input, WTF/profiler writes, commit, push or manual cross-install copy was performed. '
           'USER-001 actual failing frame/first taint source, native taint, pixels and CPU/FPS remain pending. '
           'Visible character-button polling and coherent auction publication after quiet are intentional safety limits, not claimed eliminated costs.')

def insert_record(path, text):
    raw = path.read_bytes()
    newline = '\r\n' if b'\r\n' in raw else '\n'
    content = raw.decode('utf-8-sig').replace('\r\n', '\n')
    start, end = '<!-- STRESS-FIXES-20261107 -->', '<!-- /STRESS-FIXES-20261107 -->'
    block = f'{start}\n{text}\n{end}\n\n'
    if start in content:
        a = content.index(start); b = content.index(end, a) + len(end)
        while b < len(content) and content[b] == '\n': b += 1
        content = content[:a] + block + content[b:]
    else:
        offset = content.find('\n') + 1
        while offset < len(content) and content[offset] == '\n': offset += 1
        content = content[:offset] + block + content[offset:]
    path.write_bytes(content.replace('\n', newline).encode('utf-8'))

for name in ['STATUS.md', 'DECISIONS.md', 'WORK_LOG.md', 'CLIENT_VALIDATION.md']:
    insert_record(DOCS / name, summary + f' [Applied changes and evidence]({evidence}).')
insert_record(ROOT / 'NEXT_SESSION.md', summary + ' [Applied changes and remaining native checks](Stress%20test%20doc/applied-fixes/README.md). '
              'Load the changed code with a normal user-controlled reload before assessing recurrence; earlier in-memory taint is not cleared by editing files.')
chapters = {
    '08-shared-services.md': 'Events preserve listener delivery during removal; Scheduler retains nested FIFO callbacks and older paused structural batches, invalidates stale timers, and budgets inventory at 8 callbacks per scheduled flush. Combat RegenDefer budgets 16 distinct jobs per frame with combat reentry pause. Sustained mouseover can no longer starve shared range sweeps indefinitely.',
    '11-action-bars.md': 'Quiet-grid, cast/badge and bling alpha readers avoid secret comparisons and handle denied getters with feature-specific public-write or retained-state policies. Native secure driver/watch globals retain their identities; Forever adapters are selected locally by Flux callers.',
    '12-extra-button-system.md': 'Effective-alpha readiness tolerates a denied getter without treating it as declassified data. Classic cooldown-ring alpha uses its existing public write ownership. Ordinary utility execution and saved assignments are preserved.',
    '13-binding-system.md': 'Pending full Context invalidations survive later narrow mouseover requests. Hover fallback consumes all GetChildren varargs with no per-scan child table allocation. Local driver aliases preserve foreign native API provenance.',
    '14-unit-frames.md': 'Cast fades use explicit public endpoints; Swing tracks its owned public fade trajectory and cancels stale completions. Health prediction retains full-width/maxHP normalization with public owned dimensions. Native clipping preserves32px striped texture phase. Threat uses an owned MIT-attributed renderer, preserving other addons\' shared LibCustomGlow winner.',
    '15-raid-frames.md': 'Raid paint driver arms once per outstanding merged batch and preserves next-frame category paints; nested events and rebind/hide lifecycle remain covered by focused fixtures.',
    '19-nameplates.md': 'Public native alpha/anchor/visibility comparisons suppress stable repeated writes. Opaque/unknown cases retain repair writes; no unsafe native hook or permanent assumption about native state is added.',
    '17-micromenu.md': 'The character-button watcher is parented to the owned button so hidden controls stop receiving OnUpdate. Visible per-frame native-state observation remains to preserve native press/release/keybind/close behavior without unsafe hooks.',
    '21-inventory-foundation.md': 'Inventory callback tails use a cursor, retaining nested callback/token/reason requests without quadratic old-tail copying. After two cancelled auction scans, retry waits for the existing quiet interval; final snapshots remain atomic and publish after quiet. Guild-bank/void callbacks are unchanged.',
    '23-respec.md': 'Profile completion awaits synchronous action-slot verification and successful stance saved-state/layout-request acceptance, retaining the recovery checkpoint on failure. Existing deferred UI layout cadence remains; visual completion is not acknowledged here. Queued snapshots detach nested data, support owned cancellation/replacement and ignore stale regen callbacks; one watcher is reused during supersession storms. Native loadout-owned slots remain untouched on Retail/Forever.',
}
for name, text in chapters.items():
    insert_record(DOCS / name, '7 November applied stress fixes: ' + text + f' [Evidence]({evidence}). Native taint/pixels/performance acceptance remains pending.')
insert_record(OUT.parent / 'README.md', f'Implementation is now authorized and applied. [Current fix results](applied-fixes/README.md) supersede the earlier proposal-only status below. '
              f'Current combined suite: **{suite["pass"]} scripts / {suite["syntaxFiles"]} Lua syntax files PASS**. Historical audit/proposal observations and source snapshots are retained with their original scope.')
insert_record(OUT.parent / 'CONTINUITY.md', summary + ' [Current implementation record](applied-fixes/README.md). Earlier no-edit authorization statements below are historical.')
insert_record(OUT.parent / 'REQUIREMENTS.md', 'The later user instruction “fix everything now” authorizes runtime fixes. Earlier no-edit/proposal-only requirements are superseded for this implementation phase. '
              'Preserve simulation-only execution, all features/settings and the captured audit evidence. [Applied requirements and acceptance](applied-fixes/README.md).')
insert_record(OUT.parent / 'fix-proposals/README.md', 'These proposals were followed by explicit implementation authorization. [Applied fixes and current evidence](../applied-fixes/README.md) supersede the earlier no-application status below. '
              'Rejected native remaining-span geometry remains rejected; final public-dimension/clipping design is recorded separately.')

def upsert_csv(name, key, new_rows):
    path = DOCS / name
    with path.open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f); columns = reader.fieldnames; rows = list(reader)
    ids = {r[key] for r in new_rows}
    rows = [{c: r.get(c, '') for c in columns} for r in new_rows] + [r for r in rows if r[key] not in ids]
    with path.open('w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=columns); writer.writeheader(); writer.writerows(rows)

raw_evidence = 'Stress test doc/applied-fixes/README.md; Stress test doc/applied-fixes/source-changes.json; Stress test doc/applied-fixes/full-suite.json'
upsert_csv('FEATURE_PARITY.csv', 'feature_id', [{
    'feature_id': CHANGE, 'behavior_or_control': 'Audit findings and related alpha/geometry boundaries',
    'source_spec': 'User7Nov2026 fix everything now; earlier simulations preserved',
    'baseline': checkpoint['externalCheckpoint'], 'settings_scope': 'Same roots/schema/defaults; no settings reset/write',
    'owner': 'Shared services; Bars; Binding; EBS; UnitFrames; Raid; NamePlates; Respec; builtin auction',
    'change_id': CHANGE, 'implementation': '24 finding statuses; public ownership, lifecycle and queue fixes',
    'desktop_result': f'{suite["pass"]} scripts/{suite["syntaxFiles"]} syntax PASS; exact hashes and focused baseline rejects retained',
    'native_result': 'Pending; USER-001 native report remains attributed to unknown frame/action',
    'visual_result': 'Public trajectory/dimension/phase controls only; native pixels pending', 'evidence': raw_evidence}])
pins = json.loads((OUT.parent / 'evidence/upstream-pins.json').read_text())['pins']
client_rows = []
for key, label, interface in [('era','Era',11509),('anniversary','Anniversary',20506),('retail','Retail live',120105),('forever','Forever',16001)]:
    pin = pins[key]
    client_rows.append({'client': f'{label} {CHANGE}', 'flux_toc_interface': interface,
                        'reference_path': 'Gethe/wow-ui-source', 'reference_sha': pin.get('sha', pin.get('commit', str(pin))),
                        'adapter_contracts': 'Preserve native API identity; local capability-gated adapter and public values',
                        'desktop_result': f'{suite["pass"]} combined scripts PASS; targeted five-client models; no whole-client emulation',
                        'native_result': 'NOT RUN: simulations only', 'exceptions': 'Runtime build/frame unknown for USER-001; native secret VM/pixels/FPS not simulated',
                        'evidence': raw_evidence})
upsert_csv('CLIENT_MATRIX.csv', 'client', client_rows)
upsert_csv('PERFORMANCE_AUDIT.csv', 'domain', [{'domain': CHANGE, 'evidence_scope': 'Actual production owner desktop fixtures and exact pre/post identities; no native CPU/FPS',
    'findings_or_next_check': 'Raid arm coalescing; native-state write suppression; hidden watch sleep; inventory head cursor; combat16/frame; bounded range settle; auction abort churn. Visible poll and atomic quiet publication retained. Native matched validation pending.'}])
upsert_csv('PERFORMANCE_RESULTS.csv', 'change_id', [{
    'change_id': CHANGE, 'feature_ids': 'PERF01-07;PERF-SEC-01;LOGIC01-02', 'scenario': 'Repeated production-owner burst/lifecycle/reentry fixtures',
    'client_build': 'Four pinned sources plus extra progression models; native build not inferred',
    'before_source': checkpoint['externalCheckpoint'], 'after_source': 'Stress test doc/applied-fixes/source-changes.json',
    'config_hash': 'No saved settings changes', 'profiler_mode': 'Unchanged; desktop work counts only', 'trials': 'Three repeated shared/alpha checks; focused performance samples retained separately',
    'metric_unit': 'Calls, queue ordering, frame allocation and modeled time; no native ms/FPS',
    'before': 'Raid28000 arms; stable40x600 nameplate144000 alpha/96000 structural anchor writes; live48000 Hide; auction381/375 discarded row reads per200-event10s stream; queue/starvation defects reproduced',
    'after': 'Raid1 outstanding arm; stable public nameplate alpha/structural anchors/Hide0; hidden character watch0; auction52/50; inventory8/scheduled flush; regen16/frame; FIFO and bounded range settle',
    'spread': 'Repeated deterministic counts; raw outputs retained', 'parity': f'{suite["pass"]}/{suite["syntaxFiles"]} combined scripts/syntax; native pixels pending',
    'conclusion': 'Implementation and desktop contracts pass; native performance/taint acceptance pending; quiet auction publication and visible watcher cost retained',
    'raw_evidence': raw_evidence}])
print(f'Reconciled {CHANGE}: {suite["pass"]} scripts/{suite["syntaxFiles"]} syntax; {len(changed)} existing files changed before documentation refresh; {len(added)} added')
