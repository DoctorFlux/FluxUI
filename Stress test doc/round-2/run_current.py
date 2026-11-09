"""Current suite with explicit stable pre/post source fingerprints, not intent."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

OUT=Path(__file__).resolve().parent
ROOT=OUT.parent.parent
def sources():
 return {p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
  for p in ROOT.rglob('*')if p.is_file()and not any(x.startswith('.')or x=='__pycache__'for x in p.relative_to(ROOT).parts)
  and(p.suffix.lower()in {'.lua','.xml','.toc'}or p.relative_to(ROOT).as_posix().startswith('tests/fixtures/'))}
before=sources();stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
old=OUT/'current-suite.json'
if old.exists():(OUT/('current-suite-before-'+stamp+'.json')).write_bytes(old.read_bytes())
r=subprocess.run(['python','-B','tests/run_validation.py','--output',str(OUT/'current-suite.json')],cwd=ROOT,capture_output=True,text=True,timeout=600)
after=sources();changed=sorted(k for k in set(before)|set(after)if before.get(k)!=after.get(k))
(OUT/'current-suite-run.txt').write_text(r.stdout+r.stderr,encoding='utf-8')
record={'capturedUTC':datetime.now(timezone.utc).isoformat(),'exit':r.returncode,'sourcesBefore':before,'sourcesAfter':after,
 'sourceDriftDuringRun':changed,'pass':r.returncode==0 and not changed,'scope':'All current production/validation Lua/XML/TOC+fixture bytes captured before and after the suite; docs-only mutations excluded.'}
(OUT/'current-suite-stability.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'exit':r.returncode,'sourceDriftDuringRun':changed,'pass':record['pass']},indent=2))
raise SystemExit(not record['pass'])
