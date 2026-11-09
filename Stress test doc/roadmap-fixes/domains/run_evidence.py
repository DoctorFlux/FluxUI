"""Matched checkpoint regressions and repeatable desktop production-owner evidence."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, subprocess, time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
checkpoint = json.loads((OUT.parent/'checkpoint.json').read_text())
BASELINE = Path(checkpoint['externalCheckpoint'])/'baseline'
OWNED = ['MicroMenu/FluxMinimapToMicro.lua','Salvage/FluxSalvage_Overlay.lua',
         'UnitFrames/FluxUnitFrames_Shared.lua','Core/ButtonFX/ThreatGlow.lua',
         'Inventory/Restock/Junk/FluxVendorJunkPanel.lua','Inventory/Restock/Vendor/FluxVendorRestockPanel.lua',
         'StatusBars/FluxStatusBar.lua','StatusBars/FluxInfoFrame.lua',
         'Battlezonemap/FluxDetails.lua','Other/FluxEquipSlotFlyout.lua']
TESTS = ['tests/domain_lifecycle_fixes.lua','tests/native_timer_ownership.lua',
         'tests/public_frame_level_safety.lua','tests/alpha_reader_safety.lua',
         'tests/portrait_camera.lua','tests/unit_portrait_combat_restore.lua',
         'tests/salvage_overlay.lua','tests/prediction_public_geometry.lua',
         'tests/unit_vertical_health.lua']
# The existing vertical test filename is resolved explicitly below, not guessed.
TESTS[-1] = next(p.relative_to(ROOT).as_posix() for p in (ROOT/'tests').glob('*vertical*.lua'))
REJECTIONS = [
    ('R2-DOM-01/02','micro','departed broker tooltip cannot reappear'),
    ('R2-DOM-03','salvage','visible combat tick issues no protected mutation'),
    ('R2-DOM-04','levels','private portrait getter retains permitted level without arithmetic'),
    ('R2-DOM-04-glow','glow','private glow start/recolor handles public/changed/private/missing levels'),
    ('R2-DOM-05-junk','junk','250 tab/query entries retain one metadata retry'),
    ('R2-DOM-05-restock','restock','250 tab/query entries retain one metadata retry'),
    ('R2-DOM-06-status','status','layout storm owns one pending timer with either native API'),
    ('R2-DOM-06-info','info','layout storm owns one pending timer with either native API'),
    ('R2-DOM-06-details','details','Details resize burst retains one timer even with After fallback'),
    ('R2-DOM-06-flyout','flyout','cancel/replace retains exact60ms show delay'),
]
CONSUMED = OWNED + TESTS + ['tests/salvage_overlay.lua','MicroMenu/FluxMicroMenu.lua',
    'UnitFrames/FluxUnitFrames_Pet.lua','UnitFrames/FluxUnitFrames_TargetOfTarget.lua',
    'Core/FluxBorder.lua','Stress test doc/roadmap-fixes/domains/checkpoint_replay.lua.txt']
CONSUMED = sorted(set(p for p in CONSUMED if (ROOT/p).is_file()))
def hashes(root, paths):
    return {p:{'sha256':hashlib.sha256((root/p).read_bytes()).hexdigest(),
               'sha256LF':hashlib.sha256((root/p).read_bytes().replace(b'\r\n',b'\n')).hexdigest()}
            for p in paths if (root/p).is_file()}
def run(args):
    began=time.perf_counter()
    r=subprocess.run(['lua',*args],cwd=ROOT,capture_output=True,text=True,timeout=120)
    return {'command':['lua',*map(str,args)],'exit':r.returncode,
            'desktopWallSeconds':round(time.perf_counter()-began,6),'stdout':r.stdout,'stderr':r.stderr}
before=hashes(ROOT,CONSUMED)
rejections=[]
for finding,selection,marker in REJECTIONS:
    script='Stress test doc/roadmap-fixes/domains/checkpoint_replay.lua.txt'
    old=run([script,str(BASELINE),selection]);new=run([script,'.',selection])
    matched=old['exit']!=0 and marker in old['stdout']+old['stderr'] and new['exit']==0
    rejections.append({'finding':finding,'selection':selection,'marker':marker,
                       'oldRejectedNewAccepted':matched,'checkpoint':old,'current':new})
    print(f'{finding}: {"PASS" if matched else "FAIL"}',flush=True)
records=[]
for repeat in range(1,4):
    for path in TESTS:
        record=run([path]);record['repeat']=repeat;records.append(record)
        print(f'{repeat}: {record["exit"]} {path}',flush=True)
after=hashes(ROOT,CONSUMED)
report={'capturedUTC':datetime.now(timezone.utc).isoformat(),
        'checkpoint':checkpoint['externalCheckpoint'],'head':checkpoint['head'],'branch':checkpoint['branch'],
        'scope':'Actual production owners in desktop Lua fixtures. No native secure VM, secret-value reachability, pixel parity, taint safety, CPU or FPS certification.',
        'ownedRuntimeFiles':OWNED,'sourceBefore':before,'sourceAfter':after,'sourceStable':before==after,
        'baselineSources':hashes(BASELINE,OWNED),'rejections':rejections,'records':records,
        'uniqueScripts':len(TESTS),'repeats':3,'executionCount':len(records),
        'pass':sum(r['exit']==0 for r in records),'fail':sum(r['exit']!=0 for r in records)}
(OUT/'results.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(OUT/'source-freeze.json').write_text(json.dumps({'capturedUTC':report['capturedUTC'],
    'ownedRuntimeFiles':OWNED,'before':before,'after':after,'sourceStable':before==after},indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:report[k]for k in ('executionCount','pass','fail','sourceStable')}))
raise SystemExit(bool(report['fail']or before!=after or not all(r['oldRejectedNewAccepted']for r in rejections)))
