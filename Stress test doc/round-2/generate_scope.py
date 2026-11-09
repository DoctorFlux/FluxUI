"""Read-only complete source/load screening; write only round-2 indexes."""
from pathlib import Path
from collections import Counter
import csv
import hashlib
import json
import re
import sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / 'docs/tools'))
from source_inventory import collect, tokens, literal

inventory = collect()
(OUT / 'source-inventory.json').write_text(json.dumps(inventory, indent=2) + '\n', encoding='utf-8')
suite = json.loads((OUT / 'existing-suite.json').read_text())
tests = {r['path']: (ROOT / r['path']).read_text(encoding='utf-8-sig', errors='replace').replace('\\', '/') for r in suite['tests']}
def owner(path):
    if path.startswith('tests/') or '/_tmp_' in path:return 'canonical-validation'
    if path.startswith('ExtraButtonSystem/') or path.startswith('Core/ButtonFX/') or path == 'Bars/BadgeHost.lua': return 'extra-buttons'
    if path.startswith('Bars/') or path.startswith('Binding/') or path in ('Core/Engine/Restricted.lua','Core/Engine/MouseoverCast.lua'): return 'action-binding'
    if path.startswith(('Core/','AddonOptions/','Respec/','libs/')): return 'core-and-integrated-review'
    return 'remaining-domains'
rows = []
for rec in inventory['files']:
    path = rec['path']; text = (ROOT / path).read_text(encoding='utf-8-sig', errors='replace')
    ts = tokens(text) if path.endswith('.lua') else []
    code = ' '.join(t.value if t.kind != 'string' else 'STRING' for t in ts)
    strings = [literal(t.value) for t in ts if t.kind == 'string']
    refs = [p for p, body in tests.items() if path in body]
    rows.append({'source': path, 'classification': rec['classification'], 'sha256LF': rec['sha256'],
        'reviewOwner': owner(path), 'lines': rec['lines'], 'loaded': 'TOC/XML reachable' if path in inventory['graph']['reachable'] else 'Not in selected load closure',
        'clients': '; '.join(rec.get('clients', [])),
        'onUpdateStringSites': strings.count('OnUpdate'),
        'timerNameSites': len(re.findall(r'\b(?:After|NewTimer|NewTicker)\b', code)),
        'hookNameSites': len(re.findall(r'\b(?:HookScript|hooksecurefunc)\b', code)),
        'protectedWriterNameSites': len(re.findall(r'\b(?:SetAttribute|RegisterStateDriver|RegisterUnitWatch|SetOverrideBindingClick|SetBindingClick)\b', code)),
        'nativeValueGetterNameSites': len(re.findall(r'\b(?:GetAlpha|GetEffectiveAlpha|GetVertexColor|GetFrameLevel|GetWidth|GetHeight|GetSize|GetValue|GetMinMaxValues|GetText)\b', code)),
        'combatGuardNameSites': len(re.findall(r'\b(?:InCombatLockdown|InLockdown)\b', code)),
        'secretGuardNameSites': len(re.findall(r'\b(?:issecretvalue|canaccessvalue|IsSecretValue|CanAccessValue|CanRead)\b', code)),
        'literalTestReferences': len(refs), 'testPaths': '; '.join(refs),
        'coverageMeaning': 'Lexical screening/load inventory only. Guard proximity and literal test references do not prove branch execution, permissions or safety.'})
with (OUT / 'SOURCE_SCREEN.csv').open('w', encoding='utf-8', newline='') as f:
    w=csv.DictWriter(f, fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
groups=[]
for module in sorted({r['source'].split('/')[0] for r in rows}):
    members=[r for r in rows if r['source'].split('/')[0]==module]
    groups.append({'module':module,'classifiedSources':len(members),'reachableSources':sum(r['loaded']=='TOC/XML reachable' for r in members),
        'assignedOwners':'; '.join(sorted({r['reviewOwner'] for r in members})),
        'sourceScreen':'Complete lexical/load screening; see SOURCE_SCREEN.csv',
        'branchCoverage':'Unknown; use focused owner reports and existing suite for their stated branch scope',
        'nativeAcceptance':'NOT RUN; true secrets/protected VM, instances, pixels and CPU/FPS remain separate roadmap gates'})
with (OUT / 'MODULE_MATRIX.csv').open('w', encoding='utf-8', newline='') as f:
    w=csv.DictWriter(f,fieldnames=groups[0].keys());w.writeheader();w.writerows(groups)
summary={'classifiedSources':len(rows),'reachableSources':len(inventory['graph']['reachable']),
         'missingLoadReferences':inventory['graph']['missing'],'moduleGroups':len(groups),
         'classificationCounts':dict(Counter(r['classification'] for r in rows)),
         'scope':'Whole source/load screening plus explicit domain review; not whole-client or branch emulation',
         'savedVariables':inventory['graph']['saved_variables']}
(OUT / 'scope.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k!='savedVariables'},indent=2))
