"""Repeat matched production-owner regressions and retain raw desktop evidence."""
from pathlib import Path
import hashlib,json,subprocess,time
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
record=json.loads((OUT/'checkpoint.json').read_text());baseline=Path(record['externalCheckpoint'])/'baseline'
sources=['Core/Engine/Modifier.lua','Core/Engine/Context.lua','Core/Engine/Range.lua','Bars/Paint.lua','Bars/ProgramFace.lua','ExtraButtonSystem/Engine/Action.lua','ExtraButtonSystem/Engine/Paint.lua','AddonOptions/AceGUIWidget-FluxRestockPanel.lua']
def fingerprints(root):return {p:hashlib.sha256((root/p).read_bytes().replace(b'\r\n',b'\n')).hexdigest()for p in sources}
before=fingerprints(ROOT)
jobs=[['lua','tests/range_usability_stress.lua'],['lua','tests/restock_panel_timer_ownership.lua'],['lua','Stress test doc/roadmap-fixes/modifier_bus.lua.txt'],['lua','tests/context_program_face_stress.lua']]
results=[]
for trial in range(3):
 for cmd in jobs:
  began=time.perf_counter();r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
  results.append({'trial':trial+1,'command':cmd,'exit':r.returncode,'wallSeconds':round(time.perf_counter()-began,4),'stdout':r.stdout,'stderr':r.stderr})
  print('candidate',trial+1,cmd[1],r.returncode,flush=True)
controls=[]
for cmd,marker in zip([jobs[0],jobs[1],jobs[3]],['same-frame invalidation refreshes memo','one scheduled operation for burst 10','indexed same-slot face receives final']):
 r=subprocess.run(cmd+[str(baseline)],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
 controls.append({'command':cmd+[str(baseline)],'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr,'expectedFailureMarker':marker,'markerFound':marker in r.stdout+r.stderr})
after=fingerprints(ROOT)
out={'scope':'Desktop actual production owners with simulated APIs/frames; no native secure VM, real secrets, rendering, keyboard, CPU or FPS acceptance.',
 'before':before,'after':after,'sourceStable':before==after,'baseline':fingerprints(baseline),'candidate':results,'baselineRejections':controls}
(OUT/'root-results.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
assert before==after,'consumed source drifted during repeated evidence'
assert all(r['exit']==0 for r in results),'candidate regression failure'
assert all(r['exit']!=0 and r['markerFound']for r in controls),'baseline must fail meaningful new acceptance'
print('ROOT EVIDENCE PASS:12 candidate executions;3 baseline rejections;stable consumed sources')
