"""Verify isolated proposals and compare original source identities. No apply."""
from pathlib import Path
from urllib.parse import unquote,urlsplit
import ast,csv,difflib,hashlib,json,re,subprocess

HERE=Path(__file__).resolve().parent
LIVE=HERE.parents[1]
w=json.loads((HERE/'workspace.json').read_text())
base=Path(w['baselineRoot'])
errors=[];rows=[];seen={};patch=[]
for owner,where in w['candidateRoots'].items():
 root=Path(where)
 for p in sorted(root.rglob('*.lua')):
  rel=p.relative_to(root).as_posix()
  if rel in seen:errors.append('Duplicate overlay: '+rel)
  seen[rel]=p
  original=base/rel
  if not original.is_file():errors.append('Unexpected new runtime file: '+rel);continue
  old,new=original.read_bytes(),p.read_bytes()
  rows.append({'owner':owner,'source':rel,'baselineSHA256':hashlib.sha256(old).hexdigest(),
               'candidateSHA256':hashlib.sha256(new).hexdigest(),'candidatePath':str(p),
               'liveStillMatchesBaseline':hashlib.sha256((LIVE/rel).read_bytes()).hexdigest()==hashlib.sha256(old).hexdigest(),
               'applied':False})
  s=subprocess.run(['luac','-p',str(p)],capture_output=True,text=True)
  if s.returncode:errors.append('Candidate syntax: '+rel+' '+s.stdout+s.stderr)
  patch.extend(difflib.unified_diff(old.decode('utf-8-sig').splitlines(keepends=True),new.decode('utf-8-sig').splitlines(keepends=True),
                                   fromfile='FROZEN_BASELINE/'+rel,tofile='RESEARCH_ONLY_NOT_APPLIED/'+rel))
(HERE/'ALL_PROTOTYPES_FOR_REVIEW.diff.txt').write_text(''.join(patch),encoding='utf-8')
(HERE/'candidate-files.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
baseline=json.loads((HERE/'existing-baseline.json').read_text())
candidate=json.loads((HERE/'existing-candidate.json').read_text())
for name,r in (('baseline',baseline),('candidate',candidate)):
 if(r['pass'],r['fail'])!=(222,0)or r['sourceDrift']:errors.append(name+' existing test failures/drift')
for row in rows:
 if candidate['sourceSHA256'].get(row['source'])!=row['candidateSHA256']:errors.append('Combined suite predates current candidate: '+row['source'])
f=json.loads((HERE/'fades/results.json').read_text())
a=json.loads((HERE/'alpha-readers/results.json').read_text())
g=json.loads((HERE/'geometry/results.json').read_text())
if f['verification']!='PASS_WITH_NATIVE_LIMITS'or f['changed_consumed_sources']:errors.append('Fade evidence failure/drift')
if not a['all_runs_exit_zero']or a['consumed_source_drift']:errors.append('Alpha evidence failure/drift')
if not g['GEO-01_native_span_rejected_by_counterexample']or g['GEO-01_selected_geometry_change']:errors.append('Rejected geometry incorrectly selected')
if g['selected_Shared_ready_to_apply_independently']:errors.append('Shared candidate lost renderer gate')
liveDrift=[]
for row in w['files']:
 p=LIVE/row['path']
 if not p.is_file()or hashlib.sha256(p.read_bytes()).hexdigest()!=row['sha256']:liveDrift.append(row['path'])
for p in HERE.rglob('*.py'):
 try:ast.parse(p.read_text(encoding='utf-8-sig'))
 except Exception as e:errors.append(str(p)+': '+str(e))
for p in HERE.rglob('*.json'):
 try:json.loads(p.read_text(encoding='utf-8-sig'))
 except Exception as e:errors.append(str(p)+': '+str(e))
for p in HERE.rglob('*.lua.txt'):
 r=subprocess.run(['luac','-p',str(p)],capture_output=True,text=True)
 if r.returncode:errors.append(str(p)+': '+r.stdout+r.stderr)
for p in HERE.rglob('*.md'):
 for link in re.findall(r'\[[^\]]*\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
  u=urlsplit(link.strip().strip('<>'))
  if u.scheme or link.startswith('#'):continue
  if not(p.parent/unquote(u.path)).resolve().exists():errors.append('Broken review link: '+str(p)+' '+link)
report={'status':'PROPOSALS_ONLY_NOT_APPLIED','scope':'Isolated source-model candidates and unchanged existing mock suite; native frame attribution/taint/pixels/FPS remain unverified',
        'selectedPrototypeFiles':len(rows),'fullExistingBaseline':{'pass':baseline['pass'],'fail':baseline['fail']},
        'fullExistingCandidate':{'pass':candidate['pass'],'fail':candidate['fail']},
        'originalFilesCompared':len(w['files']),'liveSourceDriftSinceProposalSnapshot':liveDrift,
        'candidateFilesNoLongerMatchLiveBaseline':[r['source']for r in rows if not r['liveStillMatchesBaseline']],
        'geometryNativeSpanRejected':True,'geometryGEO02Held':True,'errors':errors,'pass':not errors}
(HERE/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(bool(errors))
