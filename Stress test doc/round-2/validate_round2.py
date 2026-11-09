"""Validate current audit artifacts, source identities and no-code-edit invariant."""
from pathlib import Path
from datetime import datetime, timezone
from urllib.parse import unquote, urlsplit
import ast
import csv
import hashlib
import json
import re
import subprocess

OUT=Path(__file__).resolve().parent
ROOT=OUT.parent.parent
errors=[];counts={'python':0,'luaHarnesses':0,'json':0,'csv':0,'localLinks':0}
(OUT/'validation.json').write_text('{"status":"VALIDATION_RUNNING"}\n',encoding='utf-8')
baseline=json.loads((OUT/'baseline.json').read_text())
allowed=set(json.loads((OUT/'continuity-updates.json').read_text())['authorizedDocumentationPaths'])
old={r['path']:r for r in baseline['files']}
changed=[];missing=[]
for rel,row in old.items():
 p=ROOT/rel
 if not p.is_file():missing.append(rel)
 elif hashlib.sha256(p.read_bytes()).hexdigest()!=row['sha256']:changed.append(rel)
unexpected=[p for p in changed if p not in allowed]
runtime_ext={'.lua','.xml','.toc','.py','.ps1','.bat','.tga','.blp','.png','.jpg','.ttf','.otf','.ogg','.wav','.mp3'}
code_drift=[p for p in changed+missing if Path(p).suffix.lower()in runtime_ext or p.startswith('tests/')]
concurrent_path=OUT/'concurrent-recheck.json'
concurrent=json.loads(concurrent_path.read_text())if concurrent_path.exists()else{}
known={r['path']:r['currentSHA256']for r in concurrent.get('knownIndependentChanges',[])}
unreconciled=[p for p in code_drift if p not in known or not(ROOT/p).is_file()or hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=known[p]]
new_outside=[]
for p in ROOT.rglob('*'):
 rel=p.relative_to(ROOT)
 if not p.is_file()or any(x in ('.git','__pycache__','.cache')for x in rel.parts)or rel.parts[:2]==('Stress test doc','round-2'):continue
 if rel.as_posix()not in old:new_outside.append(rel.as_posix())
new_code=[p for p in new_outside if Path(p).suffix.lower()in runtime_ext or p.startswith('tests/')]
if unreconciled or new_code or missing:errors.append('Unreconciled runtime/test/tool/art/missing-file drift: '+repr(unreconciled+new_code+missing))
if known and (concurrent.get('testsFail')or concurrent.get('knownBeforeAfterCurrentLuaDrift')or concurrent.get('probeExit')):
 errors.append('Independent-source current-suite/probe recheck did not pass')
stable_path=OUT/'current-suite-stability.json'
if stable_path.exists():
 stable=json.loads(stable_path.read_text())
 if not stable['pass']or stable['sourceDriftDuringRun']:errors.append('Current suite source drift during run')
 for rel,digest in stable['sourcesAfter'].items():
  if not(ROOT/rel).is_file()or hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()!=digest:
   errors.append('Current stable integration identity drift: '+rel)
# Unrelated concurrent documentation is retained and reported, never reverted.
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True).strip()
pres={'capturedUTC':datetime.now(timezone.utc).isoformat(),'baselineHead':baseline['head'],'currentHead':git('rev-parse','HEAD'),
 'baselineBranch':baseline['branch'],'currentBranch':git('branch','--show-current'),'baselineFiles':len(old),
 'authorizedDocumentationChanges':[p for p in changed if p in allowed], 'otherObservedChanges':unexpected,
 'observedIndependentCodeTestDrift':code_drift,'unreconciledCodeTestTOCArtDrift':unreconciled,'missingFiles':missing,'newOutsideRound2':new_outside,'newCodeOutsideRound2':new_code,
 'settingsOperations':'None issued; no WTF/profiler/game operations','issuedWriteScope':'New round-2 artifacts/external source snapshot and listed documentation continuity/ledgers only',
 'pass':not unreconciled and not new_code and not missing}
(OUT/'preservation.json').write_text(json.dumps(pres,indent=2)+'\n',encoding='utf-8')
suite_path=OUT/'current-suite.json'
if not suite_path.exists():suite_path=OUT/'existing-suite.json'
suite=json.loads(suite_path.read_text())
if suite['fail']or suite['syntaxFailures']:errors.append('Current baseline suite failed')
manifest={r['path']:r['sha256']for r in suite['manifest']}
actual={p.relative_to(ROOT).as_posix()for p in ROOT.rglob('*.lua')if not any(x.startswith('.')for x in p.relative_to(ROOT).parts)and p.name!='_tmp_striplines.lua'}
if actual!=set(manifest):errors.append('Current tested Lua membership drift')
for rel,digest in manifest.items():
 if hashlib.sha256((ROOT/rel).read_bytes().replace(b'\r\n',b'\n')).hexdigest()!=digest:errors.append('Tested source identity drift: '+rel)
findings=json.loads((OUT/'FINDINGS.json').read_text())['findings']
ids={r['id']for r in findings}
if len(findings)!=25 or len(ids)!=25:errors.append('Expected25 unique qualified groups')
roadmap=(OUT/'ROADMAP.md').read_text(encoding='utf-8')
for r in findings:
 if r['id']not in roadmap:errors.append('Finding missing from roadmap: '+r['id'])
 path=ROOT/r['source']
 if not path.is_file():errors.append('Finding missing source: '+r['id']+' '+r['source'])
 elif r['line']and int(r['line'])>len(path.read_text(encoding='utf-8-sig').splitlines()):errors.append('Invalid source line: '+r['id'])
 if not(OUT/r['report']).is_file():errors.append('Finding missing report: '+r['id'])
 if not r['proposal']or not r['acceptance']:errors.append('Missing proposal/acceptance: '+r['id'])
for p in OUT.rglob('*.py'):
 counts['python']+=1
 try:ast.parse(p.read_text(encoding='utf-8-sig'),filename=str(p))
 except Exception as e:errors.append(str(e))
for p in OUT.rglob('*.lua.txt'):
 counts['luaHarnesses']+=1
 r=subprocess.run(['luac','-p',str(p)],capture_output=True,text=True)
 if r.returncode:errors.append('Harness syntax: '+p.name+' '+r.stderr)
for p in OUT.rglob('*.json'):
 counts['json']+=1
 try:json.loads(p.read_text(encoding='utf-8-sig'))
 except Exception as e:errors.append(p.name+': '+str(e))
for p in OUT.rglob('*.csv'):
 counts['csv']+=1
 with p.open(encoding='utf-8-sig',newline='')as f:
  reader=csv.DictReader(f)
  for row in reader:
   if None in row:errors.append('CSV column mismatch: '+p.name)
for p in OUT.rglob('*.md'):
 for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)',p.read_text(encoding='utf-8-sig')):
  target=target.strip('<>');u=urlsplit(target)
  if u.scheme or target.startswith('#'):continue
  counts['localLinks']+=1;path=(p.parent/unquote(u.path)).resolve()
  if not path.exists():errors.append('Broken link: '+str(p.relative_to(OUT))+' -> '+target)
  elif u.fragment.startswith('L')and u.fragment[1:].isdigit()and int(u.fragment[1:])>len(path.read_text(encoding='utf-8-sig').splitlines()):errors.append('Invalid linked line: '+target)
scope=json.loads((OUT/'scope.json').read_text())
if scope['missingLoadReferences']:errors.append('Missing load references')
if counts['luaHarnesses']<15:errors.append('Focused harness set unexpectedly small')
record={'capturedUTC':datetime.now(timezone.utc).isoformat(),'scope':'Artifact syntax/links/requirements coverage, exact current tested Lua corpus and no-code-edit invariant. Does not certify native behavior.',
 'counts':counts,'suiteEvidence':suite_path.name,'currentScriptsPassed':suite['pass'],'currentSyntaxFiles':suite['syntaxFiles'],'findings':len(findings),
 'classifiedSources':scope['classifiedSources'],'reachablePaths':scope['reachableSources'],'errors':errors,'pass':not errors}
(OUT/'validation.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(json.dumps(record,indent=2));raise SystemExit(bool(errors))
