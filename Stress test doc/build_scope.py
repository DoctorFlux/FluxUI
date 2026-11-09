"""Read-only scope/load/test-reference index. Writes only beside this script.

Literal test references are discovery aids, not executed-line coverage.
"""
from pathlib import Path
import csv
import hashlib
import json
import sys
from collections import Counter

sys.dont_write_bytecode = True
OUT = Path(__file__).resolve().parent
ROOT = OUT.parent
sys.path.insert(0, str(ROOT / 'docs/tools'))
from source_inventory import load_graph

graph = load_graph()
baseline = json.loads((OUT / 'evidence/baseline.json').read_text(encoding='utf-8'))
suite_path = OUT / 'applied-fixes/full-suite.json'
if not suite_path.exists(): suite_path = OUT / 'evidence/existing-suite-latest.json'
if not suite_path.exists(): suite_path = OUT / 'evidence/existing-suite-final.json'
if not suite_path.exists(): suite_path = OUT / 'evidence/existing-suite.json'
suite = json.loads(suite_path.read_text(encoding='utf-8'))
tests = {r['path']: (ROOT / r['path']).read_text(encoding='utf-8-sig', errors='replace').replace('\\\\', '/').replace('\\', '/')
         for r in suite['tests']}
targets = {'Era': 'vanilla', 'Anniversary': 'tbc', 'Retail live': 'mainline', 'Forever': 'camelot'}
rows = []
for rel, rec in sorted(graph['reachable'].items()):
    refs = [p for p, text in tests.items() if rel in text]
    row = {'source': rel, 'kind': Path(rel).suffix, 'sha256LF': hashlib.sha256((ROOT / rel).read_bytes().replace(b'\r\n', b'\n')).hexdigest(),
           **{client: ('TOC selected' if gate in rec['clients'] else 'TOC excluded') for client, gate in targets.items()},
           'literalTestReferences': len(refs), 'testPaths': '; '.join(refs),
           'executionCoverage': 'UNKNOWN: literal references do not prove execution or branch coverage',
           'nativeTaintPerformance': 'NOT RUN: desktop-only scope'}
    rows.append(row)
with (OUT / 'SOURCE_COVERAGE.csv').open('w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys()); writer.writeheader(); writer.writerows(rows)
summary = {'scope': 'Current TOC/XML union selected paths; implementation phase recorded separately in applied-fixes', 'head': baseline['head'],
           'suiteEvidence': suite_path.name,
           'reachable': len(rows), 'missingLoadReferences': graph['missing'],
           'sourceFilesByTopLevel': dict(sorted(Counter(r['source'].split('/')[0] for r in rows).items())),
           'selectedFilesByTarget': {client: sum(r[client] == 'TOC selected' for r in rows) for client in targets},
           'reachableWithLiteralTestReference': sum(r['literalTestReferences'] > 0 for r in rows),
           'reachableWithoutLiteralTestReference': sum(r['literalTestReferences'] == 0 for r in rows),
           'note': 'No literal match may still be indirectly exercised. A literal match may only be a static assertion. This is not line or branch coverage.',
           'savedVariableDeclarations': graph['saved_variables']}
(OUT / 'evidence/scope.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v for k, v in summary.items() if k != 'savedVariableDeclarations'}, indent=2))
