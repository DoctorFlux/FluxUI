"""Validate this focused evidence; retain drift without claiming a full suite pass."""
from pathlib import Path
from urllib.parse import urlsplit,unquote
import ast,csv,hashlib,json,re,subprocess

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
FOLDERS=[HERE,HERE.parent/'alpha_followup',HERE.parent/'related_value_followup']
errors=[];counts={'python':0,'luaHarnesses':0,'json':0,'csv':0,'localLinks':0}
for folder in FOLDERS:
 for p in folder.glob('*.py'):
  counts['python']+=1
  try:ast.parse(p.read_text(encoding='utf-8-sig'))
  except Exception as e:errors.append(str(p)+': '+str(e))
 for p in folder.glob('*.lua.txt'):
  counts['luaHarnesses']+=1
  r=subprocess.run(['luac','-p',str(p)],capture_output=True,text=True)
  if r.returncode:errors.append(str(p)+': '+r.stdout+r.stderr)
 for p in folder.glob('*.json'):
  counts['json']+=1
  try:json.loads(p.read_text(encoding='utf-8-sig'))
  except Exception as e:errors.append(str(p)+': '+str(e))
 for p in folder.glob('*.csv'):
  counts['csv']+=1
  with p.open(encoding='utf-8-sig',newline='')as f:
   r=csv.reader(f);header=next(r)
   for n,row in enumerate(r,2):
    if len(row)!=len(header):errors.append(f'CSV width {p}:{n}')
 for p in folder.glob('*.md'):
  for link in re.findall(r'\[[^\]]*\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
   url=urlsplit(link.strip().strip('<>'))
   if url.scheme or link.startswith('#'):continue
   counts['localLinks']+=1
   if not(p.parent/unquote(url.path)).resolve().exists():errors.append(f'Broken link {p}: {link}')

alpha=json.loads((HERE.parent/'alpha_followup/results.json').read_text())
geo=json.loads((HERE.parent/'related_value_followup/results.json').read_text())
guards=json.loads((HERE/'guard-controls-results.json').read_text())
if alpha['status']!='CONDITIONAL_ALPHA_FAILURES_REPRODUCED' or alpha['changed_consumed_sources']:errors.append('Alpha reproduction failed/drifted')
if not geo['all_processes_passed'] or geo['consumed_source_drift']:errors.append('Geometry reproduction failed/drifted')
if not guards['pass'] or guards['consumedSourceDrift']:errors.append('Existing guard control failed/drifted')
current_drifts=[]
for report,key in ((alpha,'sources_after'),(geo,'sources_after'),(guards,'after')):
 for name,sha in report[key].items():
  if name=='external/Gethe/forever/FrameUtil.lua':
   p=ROOT.parent/'__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua'
  else:p=Path(name)
  if not p.is_absolute():p=ROOT/p
  if not p.is_file()or hashlib.sha256(p.read_bytes()).hexdigest()!=sha:current_drifts.append(name)
if current_drifts:errors.append('Consumed identities no longer current: '+str(current_drifts))
checkpoint=json.loads((HERE/'source-checkpoint.json').read_text())
changed_during=[]
for name,sha in checkpoint['sourceBefore'].items():
 p=ROOT/name
 if not p.is_file()or hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()!=sha:changed_during.append(name)
report={'scope':'Focused artifact/consumed-source validation; expected conditional failures remain findings; native taint and whole-current-addon acceptance NOT RUN',
        'checks':counts,'consumedSourceCurrentDrift':sorted(set(current_drifts)),
        'priorFullSuiteSourceDrift':checkpoint['driftSincePriorFullSuite'],
        'otherLuaChangesDuringFollowup':changed_during,'errors':errors,'pass':not errors}
(HERE/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(bool(errors))
