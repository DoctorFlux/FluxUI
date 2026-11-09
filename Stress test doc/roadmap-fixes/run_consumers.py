"""Rerun existing active Extra/badge/VFX and native fade-manager regressions."""
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
SCRIPTS=['Stress test doc/round-2/extra-buttons/modifier-followup/'+n+'.lua.txt'for n in ['utility_matrix','vfx_matrix','badge_matrix']]
baseline=Path('C:/Users/mario/.codex/visualizations/2026/11/07/01a1b5b8-1789-7050-b49c-88d0a742e874/apply-fixes-20261107T125749Z/before')
native=ROOT.parent/'__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua'
data=native.read_bytes().replace(b'\r\n',b'\n')
assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()=='a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d'
paths=['Core/Engine/Modifier.lua','Core/ButtonFX/Cast.lua','Core/ButtonFX/Charges.lua','ExtraButtonSystem/Engine/Action.lua','ExtraButtonSystem/Engine/Paint.lua','ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua','ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua','ExtraButtonSystem/Shared/HotkeyUtil.lua','Bars/BadgeHost.lua','UnitFrames/FluxCastBar.lua','UnitFrames/FluxSwingTimer.lua']
def manifest():return {p:hashlib.sha256((ROOT/p).read_bytes().replace(b'\r\n',b'\n')).hexdigest()for p in paths}
before=manifest();results=[]
for trial in range(1,4):
 for script in SCRIPTS:
  r=subprocess.run(['lua',script],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
  results.append({'trial':trial,'script':script,'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
  print(trial,script,r.returncode,flush=True)
 cmd=['lua','Stress test doc/fix-proposals/fades/verify.lua.txt',str(baseline),str(ROOT),str(native)]
 r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
 results.append({'trial':trial,'script':cmd[1],'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
 print(trial,'fade ownership',r.returncode,flush=True)
after=manifest()
(OUT/'consumer-results.json').write_text(json.dumps({'scope':'Desktop actual owner/controlled API replays; no native input/secure VM/pixels/FPS acceptance','before':before,'after':after,'sourceStable':before==after,'results':results},indent=2)+'\n',encoding='utf-8')
assert before==after,'source drift during consumer evidence'
assert all(r['exit']==0 for r in results),'consumer regression failure'
print('CONSUMER EVIDENCE PASS:12 repeated candidate executions;stable sources')
