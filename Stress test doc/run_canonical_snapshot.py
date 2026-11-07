"""Run the original suite while checking full Lua identity before and after."""
from pathlib import Path
import datetime
import hashlib
import json
import subprocess
import sys

OUT=Path(__file__).resolve().parent
ROOT=OUT.parent
def snapshot():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()
            for p in ROOT.rglob('*.lua') if not any(x.startswith('.') for x in p.relative_to(ROOT).parts)
            and p.name!='_tmp_striplines.lua'}
before=snapshot()
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
target=OUT/'evidence/existing-suite-latest.json'
run=subprocess.run([sys.executable,'-B','tests/run_validation.py','--output',str(target)],
                   cwd=ROOT,capture_output=True,text=True)
(OUT/'evidence/canonical-latest.log').write_text(run.stdout+run.stderr,encoding='utf-8')
after=snapshot()
drift=sorted(k for k in before.keys()|after.keys() if before.get(k)!=after.get(k))
r=json.loads(target.read_text())
report={'startedUTC':started,'finishedUTC':datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'canonicalRunner':'tests/run_validation.py; unchanged; no --sync-docs',
        'result':target.name,'exit':run.returncode,'luaBefore':before,'luaAfter':after,
        'sourceDrift':drift,'pass':run.returncode==0 and not drift,
        'counts':{'scriptsPass':r['pass'],'scriptsFail':r['fail'],'syntax':r['syntaxFiles']}}
(OUT/'evidence/latest-corpus-check.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('luaBefore','luaAfter')},indent=2))
raise SystemExit(0 if report['pass'] else 1)
