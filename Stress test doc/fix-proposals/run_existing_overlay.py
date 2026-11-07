"""Run unchanged existing tests against frozen baseline/candidate-only overlays.

Reads supplied external fixtures and assets in place. Source writes are blocked
by the standalone Lua launcher. No WoW, settings, profiler or source write occurs.
"""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import time

HERE=Path(__file__).resolve().parent
LIVE=HERE.parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('mode',choices=('baseline','candidate'))
parser.add_argument('--focused',action='store_true')
args=parser.parse_args()
w=json.loads((HERE/'workspace.json').read_text())
base=Path(w['baselineRoot'])
roots=[Path(p)for p in w['candidateRoots'].values()]
overlay={}
for root in roots:
 for p in root.rglob('*.lua'):
  rel=p.relative_to(root).as_posix()
  if rel in overlay:raise SystemExit('Conflicting proposed source: '+rel)
  overlay[rel]=p
all_lua=sorted(p.relative_to(base).as_posix()for p in base.rglob('*.lua')if p.name!='_tmp_striplines.lua')
scripts=[rel for rel in all_lua if rel.startswith('tests/')or(Path(rel).name.startswith('_tmp_')and'smoke'in Path(rel).name)]
if args.focused:
 changed=set(overlay)
 text={rel:(base/rel).read_text(encoding='utf-8-sig',errors='replace').replace('\\\\','/').replace('\\','/')for rel in scripts}
 selected={rel for rel,s in text.items()if any(path in s for path in changed)}
 while True:
  expanded=selected|{rel for rel,s in text.items()if any(path in s for path in selected)}
  if expanded==selected:break
  selected=expanded
 scripts=sorted(selected)
identities={rel:hashlib.sha256((overlay[rel]if args.mode=='candidate'and rel in overlay else base/rel).read_bytes()).hexdigest()for rel in all_lua}
results=[]
for rel in scripts:
 command=['lua',str(HERE/'overlay.lua.txt'),str(base),args.mode,rel,str(LIVE),*map(str,roots)]
 started=time.perf_counter()
 try:
  r=subprocess.run(command,cwd=LIVE,capture_output=True,text=True,timeout=90)
  code,output=r.returncode,r.stdout+r.stderr
 except (OSError,subprocess.TimeoutExpired)as e:code,output=-1,str(e)
 results.append({'script':rel,'exit':code,'output':output[-18000:],'desktopSeconds':round(time.perf_counter()-started,4)})
 print(('PASS 'if code==0 else'FAIL ')+rel,flush=True)
after={rel:hashlib.sha256((overlay[rel]if args.mode=='candidate'and rel in overlay else base/rel).read_bytes()).hexdigest()for rel in all_lua}
report={'scope':'Unchanged existing desktop tests routed to frozen baseline and external candidate overlays; native secure VM/taint/pixels/FPS NOT RUN',
        'mode':args.mode,'focused':args.focused,'overlayPaths':sorted(overlay),'tests':results,
        'pass':sum(r['exit']==0 for r in results),'fail':sum(r['exit']!=0 for r in results),
        'sourceSHA256':identities,'sourceDrift':[rel for rel in identities if identities[rel]!=after[rel]]}
dest=HERE/('existing-'+args.mode+('-focused'if args.focused else'')+'.json')
dest.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'mode':args.mode,'pass':report['pass'],'fail':report['fail'],'sourceDrift':report['sourceDrift']}))
raise SystemExit(bool(report['fail']or report['sourceDrift']))
