"""Record the final combined candidate without changing runtime or private settings."""
from pathlib import Path
import csv,hashlib,io,json
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
cp=json.loads((OUT/'checkpoint.json').read_text());suite=json.loads((OUT/'full-suite.json').read_text())
assert suite['fail']==0 and not suite['syntaxFailures']
for row in suite['manifest']:
 assert hashlib.sha256((ROOT/row['path']).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==row['sha256'],row['path']
changed=[];unchanged=0;missing=[]
for row in cp['files']:
 p=ROOT/row['path']
 if not p.is_file():missing.append(row['path']);continue
 after=hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()
 if after!=row['sha256LF']:
  changed.append({'path':row['path'],'beforeSHA256LF':row['sha256LF'],'afterSHA256LF':after})
 else:unchanged+=1
assert not missing,missing
runtime=[r for r in changed if Path(r['path']).suffix.lower()in{'.lua','.xml','.toc'}and not r['path'].startswith('tests/')and not Path(r['path']).name.startswith('_tmp_')]
preserved=['ExtraButtonSystem/Engine/Action.lua','ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua','AddonOptions/FluxOptionsUnitFrames.lua','Minimap/FluxMinimap.lua','RaidFrame/FluxRaidSecure.lua','UnitFrames/FluxCastBar.lua','UnitFrames/FluxHealthLossOverlay.lua','UnitFrames/FluxUnitFrames_Auras.lua','UnitFrames/FluxUnitFrames_AurasEngine.lua','UnitFrames/FluxUnitFrames_Focus.lua','UnitFrames/FluxUnitFrames_FocusTarget.lua','UnitFrames/FluxUnitFrames_OptionsBridge.lua','UnitFrames/FluxUnitFrames_Party.lua','UnitFrames/FluxUnitFrames_PetTarget.lua']
changedPaths={r['path']for r in changed};assert not changedPaths.intersection(preserved),changedPaths.intersection(preserved)
assert not any(Path(r['path']).suffix.lower()in{'.toc','.xml','.tga','.blp','.png','.ttf','.otf'}for r in changed)
source={'capturedUTC':datetime.now(timezone.utc).isoformat(),'checkpoint':cp['externalCheckpoint'],'head':cp['head'],'branch':cp['branch'],'normalization':'CRLF to LF only','unchangedPreexistingFiles':unchanged,'missingPreexistingFiles':missing,'runtimeChanges':runtime,'allChangedPreexistingFiles':changed,'preservedNewerRuntimeFiles':preserved,'settings':'No settings/game/profiler/input write; metadata only outside AddOns','suiteSourceMatchesCurrent':True}
(OUT/'source-changes.json').write_text(json.dumps(source,indent=2)+'\n',encoding='utf-8')
groups=json.loads((ROOT/'Stress test doc/round-2/FINDINGS.json').read_text())['findings']
for r in groups:
 r['status']='IMPLEMENTED; current desktop regressions pass'
 r['nativeStatus']='Pending native acceptance; original reach/evidence qualifications retained'
 r['implementationEvidence']='binding/REPORT.md'if r['id'].startswith(('R2-BIND','R2-MOD'))else'domains/REPORT.md'if r['id'].startswith('R2-DOM')else'RANGE_USABILITY.md'if r['id']in{'R2-CORE-02','R2-CORE-06'}else'ebs-respec/REPORT.md'
(OUT/'finding-status.json').write_text(json.dumps({'scope':'All25 qualified roadmap groups implemented; dormant/API-edge/injected/performance/native classifications remain distinct','findings':groups},indent=2)+'\n',encoding='utf-8')
count,syntax=suite['pass'],suite['syntaxFiles']
block=f'''7 November roadmap implementation (ROADMAP-FIXES-20261107): all25 qualified
round-2 groups now have source fixes and focused desktop acceptance. Bindings
retain distinct punctuation/minus chords, exact modifier truth and latest held
tint; cancellation/reentrant completion belongs to the latest request. Owned
timers/retries/proxies are bounded, salvage defers protected combat writes and
public frame-level/color facts avoid opaque arithmetic. Vendor mount lookup is
localized/cached; disabled optional reticle work stops scanning faces. Range
uses unit-scoped fresh memo answers, action-scoped unknown state and independent
usable/red/pressed layers, retaining existing palette/art/features/saved data.
Full combined validation: {count}/{count} scripts PASS, {syntax} Lua syntax files PASS;
exact final suite hashes match. Rapid core/binding/EBS/utility/badge, same-slot
Context and range/usability/darkening replays pass with matched baseline rejects.
Prior Forever startAlpha fade-manager replay passes again. These are desktop
models; native secure VM/real secrets/input/pixels/taint/CPU/FPS remain pending.
Newer consumable, aura, vertical target health, PvP and minimap work is preserved.
External source/history checkpoint plus45 settings metadata entries retained;
no settings reset, foreground/game/profiler/WTF writes, branch, commit or push.
'''
for path,link in [('docs/STATUS.md','../Stress%20test%20doc/roadmap-fixes/README.md'),('docs/DECISIONS.md','../Stress%20test%20doc/roadmap-fixes/README.md'),('docs/WORK_LOG.md','../Stress%20test%20doc/roadmap-fixes/README.md'),('NEXT_SESSION.md','Stress%20test%20doc/roadmap-fixes/README.md'),('docs/CLIENT_VALIDATION.md','../Stress%20test%20doc/roadmap-fixes/README.md')]:
 p=ROOT/path;text=p.read_text(encoding='utf-8');header,rest=text.split('\n',1)
 if '7 November roadmap implementation (ROADMAP-FIXES-20261107)'not in text:
  p.write_text(header+'\n\n'+block+'[Evidence]('+link+').\n\n'+rest.lstrip('\n'),encoding='utf-8')
def prepend_csv(path,row):
 p=ROOT/path;rows=list(csv.reader(io.StringIO(p.read_text(encoding='utf-8-sig'))));assert len(row)==len(rows[0]),(path,len(row),len(rows[0]))
 if any(r and r[0]==row[0]for r in rows[1:]):return
 s=io.StringIO(newline='');w=csv.writer(s,lineterminator='\n');w.writerow(rows[0]);w.writerow(row);w.writerows(rows[1:]);p.write_text(s.getvalue(),encoding='utf-8',newline='')
evidence='Stress test doc/roadmap-fixes/README.md; Stress test doc/roadmap-fixes/source-changes.json; Stress test doc/roadmap-fixes/full-suite.json'
prepend_csv('docs/FEATURE_PARITY.csv',['ROADMAP-FIXES-20261107','All25 qualified groups plus range/usability/darkening','User roadmap implementation request2026-11-07',cp['externalCheckpoint'],'Existing values/scopes preserved','Existing Binding/Bars/Core/EBS/Respec/domain owners','ROADMAP-FIXES-20261107','Owned callbacks,public presentation,stable frames/cache; originalpalette/art/cadence',f'{count}/{count}scripts;{syntax}Lua syntaxPASS;repeatedstress/baseline rejects','Pending four native clients/combat/world/dungeon/raid','Desktop readable-state controls pass; native pixels pending',evidence])
prepend_csv('docs/PERFORMANCE_RESULTS.csv',['ROADMAP-FIXES-20261107','R2-MOD-01;R2-DOM-02/05/06;R2-EBS-03/05/06;R2-CORE-02/06;RANGE-USABILITY','Repeated production-owner modifier/lifecycle/range stress','Four pinned source/client models; supplementary progression',cp['externalCheckpoint'],'Stress test doc/roadmap-fixes/source-changes.json','No settings reset or profiler preference writes','Desktop operation counts only','Three repeated root/consumer/owner trials; detailed raw scope retained','Calls/frames/hooks/queue depth/modeled time; not native ms/FPS','Starvedfullcontext0/1200frames;After/metadatafanout;repeatedmountscan','Fullcontext1200/1200frames;boundedownedtimers/cache;19rangesweeps/10smouseover','Raw repeated samples retained; no FPS inference',f'Combined{count}/{syntax}PASS;source stable;existingpalette/art/saveddata preserved','Source fixes and desktop acceptance complete; native performance/taint/pixels pending',evidence])
prepend_csv('docs/PERFORMANCE_AUDIT.csv',['ROADMAP-FIXES-20261107','Existing599 loaded paths plus new regressions','','','','','','Current production-owner replays; operationcounts not nativeFPS','All25qualifiedgroups implemented; range/tint/usability same-frame/cursorcatchup. Native acceptance pending; see Stress test doc/roadmap-fixes/README.md'])
pins=json.loads((OUT/'source-pins.json').read_text())['pins']
names={'live':'Retail live','forever':'Forever','classic_era':'Classic Era','classic_anniversary':'Classic Anniversary'}
for pin in pins:
 prepend_csv('docs/CLIENT_MATRIX.csv',[names[pin['branch']]+' ROADMAP-FIXES-20261107','','','','','Existing project/capability contract preserved','Not captured','Gethe/wow-ui-source '+pin['branch'],pin['version'],pin['sha'],'Qualified current owner/API contracts; native return/permission models',f'{count}/{count}scripts;{syntax}Lua syntaxPASS; focused4client modifier/range/cancel testsPASS','Current native candidate not run; secureVM/real secrets/input/pixels/taint/CPU/FPS pending','Source pin is not installed/runtime build evidence; supplementary progression labels retained',evidence])
print(json.dumps({'scripts':count,'syntax':syntax,'runtimeFilesChanged':len(runtime),'newerRuntimeFilesPreserved':len(preserved),'preexistingFilesUnchanged':unchanged},indent=2))
