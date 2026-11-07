"""Verify documentation artifacts and original test identities; no game actions."""
from pathlib import Path
from urllib.parse import unquote, urlsplit
import ast
import csv
import hashlib
import json
import re
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent
errors = []
counts = {'python': 0, 'luaHarnesses': 0, 'json': 0, 'csv': 0, 'localLinks': 0}
for p in OUT.rglob('*.py'):
    counts['python'] += 1
    try: ast.parse(p.read_text(encoding='utf-8-sig'), filename=str(p))
    except Exception as e: errors.append(f'{p.name}: {e}')
for p in OUT.rglob('*.lua.txt'):
    counts['luaHarnesses'] += 1
    r = subprocess.run(['luac','-p',str(p)], capture_output=True, text=True)
    if r.returncode: errors.append(f'{p.name}: {r.stdout}{r.stderr}')
for p in OUT.rglob('*.json'):
    counts['json'] += 1
    try: json.loads(p.read_text(encoding='utf-8-sig'))
    except Exception as e: errors.append(f'{p.name}: {e}')
for p in OUT.rglob('*.csv'):
    counts['csv'] += 1
    with p.open(encoding='utf-8-sig', newline='') as f:
        r = csv.reader(f); header = next(r)
        if len(set(header)) != len(header): errors.append(f'Duplicate CSV header: {p}')
        for i,row in enumerate(r, 2):
            if len(row) != len(header): errors.append(f'CSV width: {p}:{i}')
for p in OUT.rglob('*.md'):
    for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', p.read_text(encoding='utf-8')):
        target = target.strip().strip('<>')
        parsed = urlsplit(target)
        if parsed.scheme or target.startswith('#'): continue
        path = (p.parent / unquote(parsed.path)).resolve()
        counts['localLinks'] += 1
        if not path.exists(): errors.append(f'Broken local link: {p.name} -> {target}')
        elif parsed.fragment.startswith('L') and parsed.fragment[1:].isdigit():
            if int(parsed.fragment[1:]) > len(path.read_text(encoding='utf-8-sig',errors='replace').splitlines()):
                errors.append(f'Invalid source line: {p.name} -> {target}')

suite_path = OUT/'applied-fixes/full-suite.json'
applied_phase = suite_path.exists()
if not suite_path.exists(): suite_path = OUT/'evidence/existing-suite-latest.json'
if not suite_path.exists(): suite_path = OUT/'evidence/existing-suite-final.json'
if not suite_path.exists(): suite_path = OUT/'evidence/existing-suite.json'
suite = json.loads(suite_path.read_text())
if suite_path.name=='existing-suite-latest.json':
    latest = json.loads((OUT/'evidence/latest-corpus-check.json').read_text())
    if not latest['pass'] or latest['sourceDrift']: errors.append('Latest full suite had source drift or failed')
if (not applied_phase and suite['pass'] != 222) or suite['fail'] != 0 or suite['syntaxFailures']:
    errors.append('Canonical suite result differs from recorded 222/222, zero syntax failures')
if not applied_phase and suite['syntaxFiles'] != 885: errors.append('Canonical syntax scope differs from 885')
if applied_phase and (suite['pass'] != len(suite['tests']) or suite['syntaxFiles'] != len(suite['manifest'])):
    errors.append('Applied suite summary differs from recorded scripts/manifest')
for rec in suite['manifest']:
    p = ROOT / rec['path']
    if not p.is_file() or hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest() != rec['sha256']:
        errors.append('Tested Lua identity drift: '+rec['path'])
if applied_phase:
    actual_lua = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*.lua')
                  if not any(part.startswith('.') for part in p.relative_to(ROOT).parts)
                  and p.name != '_tmp_striplines.lua'}
    if actual_lua != {r['path'] for r in suite['manifest']}:
        errors.append('Applied Lua corpus membership drift')
performance = json.loads((OUT/'performance/performance-results.json').read_text())
if not performance['all_processes_passed'] or performance['production_source_drift']:
    errors.append('Performance replay failure/source drift')
if not all(performance['deterministic_metrics_across_repetitions'].values()):
    errors.append('Performance count variation')
security = json.loads((OUT/'security/security_results.json').read_text())
if security['status'] != 'COMPLETED_WITH_EXPECTED_DEFECT_REPRODUCTIONS':
    errors.append('Security reproducer failed unexpectedly')
inputs = json.loads((OUT/'input/input-stress-results.json').read_text())
if inputs['unexpected_errors'] or inputs['source_drift_paths'] or any(r['status']=='ERROR' for r in inputs['runs']):
    errors.append('Input stress unexpected error/source drift')
latest_input=json.loads((OUT/'input/secure-input-latest-results.json').read_text())
for key in ('source_drift_paths','changed_sources','consumed_source_drift','consumed_drift_during_runs'):
    if latest_input.get(key): errors.append('Latest targeted input source drift')
if not latest_input['all_pass'] or not latest_input['semantic_counters_deterministic']:
    errors.append('Latest targeted input failed or varied')
for path in ('input/instance-gates-results.json','performance/extra_instance_results.json','security/surface_lifecycle_results.json'):
    data = json.loads((OUT/path).read_text())
    for key in ('changed_sources','source_drift','production_source_drift'):
        if data.get(key): errors.append(path+': source drift')
    for key in ('samples','runs'):
        for sample in data.get(key,[]):
            if sample.get('exit',sample.get('exit_code',0)) != 0: errors.append(path+': failed sample')
fade=json.loads((OUT/'security/user-001-fade-results.json').read_text())
if fade['status'] != 'CONDITIONAL_MODELED_FAILURE_REPRODUCED' or fade['changed_sources']:
    errors.append('USER-001 conditional fade reproducer failed/drifted')
if not fade['source']['local_matches_fresh_pin']: errors.append('USER-001 source identity mismatch')
findings = list(csv.DictReader((OUT/'FINDINGS.csv').open(encoding='utf-8')))
expected_findings = 24 if applied_phase else 16
if len(findings) != expected_findings or len({r['id'] for r in findings}) != expected_findings:
    errors.append(f'Finding index must contain {expected_findings} unique entries including USER-001')
for row in findings:
    p = ROOT / row['source']
    if not p.is_file() or int(row['line']) > len(p.read_text(encoding='utf-8-sig').splitlines()):
        errors.append('Invalid finding source: '+row['id'])
report = {'scope': 'Artifact syntax/links/result consistency and original tested Lua identities; does not rerun gameplay',
          'checks': counts, 'existingLuaIdentitiesCompared': len(suite['manifest']),
          'suiteEvidence': suite_path.name,
          'findingRows': len(findings), 'errors': errors, 'pass': not errors}
(OUT/'evidence/audit-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(bool(errors))
