"""Pre-edit source/history checkpoint and private settings metadata only."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess,zipfile
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent.parent
if (OUT/'checkpoint.json').exists():raise SystemExit('Checkpoint already exists; preserve it')
external=Path('C:/Users/mario/.codex/visualizations/2026/11/07/01a1b5b8-1789-7050-b49c-88d0a742e874')
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ');target=external/('roadmap-fixes-'+stamp);target.mkdir()
files=[]
for p in sorted(ROOT.rglob('*')):
 rel=p.relative_to(ROOT)
 if not p.is_file()or any(x in ('.git','__pycache__','.cache')for x in rel.parts)or rel.parts[:2]==('Stress test doc','roadmap-fixes'):continue
 data=p.read_bytes();files.append({'path':rel.as_posix(),'sha256':hashlib.sha256(data).hexdigest(),'sha256LF':hashlib.sha256(data.replace(b'\r\n',b'\n')).hexdigest(),'bytes':len(data)})
with zipfile.ZipFile(target/'source.zip','w',zipfile.ZIP_DEFLATED)as z:
 for r in files:
  p=Path(r['path'])
  if p.suffix.lower()in {'.lua','.xml','.toc','.py','.txt'}or p.name.lower().startswith('license'):
   data=(ROOT/p).read_bytes();assert hashlib.sha256(data).hexdigest()==r['sha256'];z.writestr(r['path'],data)
def git(*a):return subprocess.check_output(['git','-c','core.safecrlf=false',*a],cwd=ROOT,text=True,encoding='utf-8',stderr=subprocess.DEVNULL)
(target/'working.diff').write_text(git('diff','--binary'),encoding='utf-8');(target/'git-history.txt').write_text(git('log','-15','--format=%H%n%aI%n%s'),encoding='utf-8')
old=external/'apply-fixes-20261107T125749Z/private-settings-metadata.json'
prior=json.loads(old.read_text(encoding='utf-8-sig'));settings=[]
for r in prior:
 p=Path(r['path'])
 if p.is_file():
  data=p.read_bytes();settings.append({'path':str(p),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'mtimeNS':p.stat().st_mtime_ns})
(target/'private-settings-metadata.json').write_text(json.dumps(settings,indent=2)+'\n',encoding='utf-8')
record={'capturedUTC':stamp,'head':git('rev-parse','HEAD').strip(),'branch':git('branch','--show-current').strip(),'externalCheckpoint':str(target),'files':files,'settingsMetadataFiles':len(settings),
 'settingsPolicy':'Existing available on-disk settings hashed read-only; no values copied into AddOns, no native/WTF/profiler operation or settings reset.',
 'authorization':'User now requests all roadmap fixes plus rapid modifiers and range/usability/darkening; prior audit-only restriction superseded for this implementation.'}
(OUT/'checkpoint.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8');(target/'checkpoint.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in record.items()if k!='files'},indent=2))
