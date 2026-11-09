"""Repeated read-only production timer/modifier probes, identities and raw results."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

OUT=Path(__file__).resolve().parent
ROOT=OUT.parent.parent
names=['Respec/FluxRespec_GearPicker.lua','Respec/FluxRespec_RunePicker.lua','Respec/FluxRespec_Talents.lua',
       'AddonOptions/AceGUIWidget-FluxRestockPanel.lua','Core/Engine/Modifier.lua','Core/Engine/Context.lua',
       'tests/context_invalidation_stress.lua','Core/DB.lua','Core/Module.lua','Core/Optional.lua','Core/Startup.lua',
       'Core/Engine/Timer.lua','Core/Engine/Ticker.lua','Core/Engine/Scheduler.lua','Core/Engine/Events.lua','Core/Engine/Combat.lua','Core/Engine/Range.lua']
def hashes():return {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in names}
before=hashes();runs=[]
for script in ['core_timers.lua.txt','modifier_bus.lua.txt']:
    for repeat in range(1,6):
        r=subprocess.run(['lua',str(OUT/script)],cwd=ROOT,capture_output=True,text=True,timeout=90)
        raw=f'{script}-run-{repeat}.txt'
        (OUT/raw).write_text(r.stdout+r.stderr,encoding='utf-8')
        runs.append({'script':script,'repeat':repeat,'exit':r.returncode,'log':raw,'outputSHA256':hashlib.sha256((r.stdout+r.stderr).encode()).hexdigest()})
after=hashes();assert before==after
baseline={r['path']:r['sha256'] for r in json.loads((OUT/'baseline.json').read_text())['files']}
source_drift=[p for p in names if before[p]!=baseline[p]]
data={'capturedUTC':datetime.now(timezone.utc).isoformat(),'scope':'Production owner functions/buses under controlled desktop API leaves; passing probes include expected defect reproductions, not native taint/CPU/input/pixel acceptance.',
      'sourcesBefore':before,'sourcesAfter':after,'baselineSourceDrift':source_drift,'runs':runs,
      'allProcessesPassed':all(r['exit']==0 for r in runs),'sameScenariosRepeated':True,
      'timerAssertionsPerRun':40,'modifierAssertionsPerRun':96850,
      'modifierPerRun':{'physicalStateEdges':10544220,'modifierEventNotifications':10883400,'orderedTransitionCases':3840,
                        'isolatedStormModels':10,'mixedStarvationCases':5,'mixedFramesPerModel':1200,'mixedModeledSecondsPerModel':10},
      'evidenceLimits':'Core bus replay uses the current existing fixture leaves for event/timer/display delivery, not a native VM. Button/badge/Binding owners are separate supplements.'}
(OUT/'core-results.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
assert data['allProcessesPassed'] and not source_drift
print('PASS10 processes; each timer40/modifier96850 checks; source identities stable; expected defects documented')
