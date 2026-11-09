"""Documentation-only continuity/ledger additions for the completed audit."""
from pathlib import Path
import csv
import json

OUT=Path(__file__).resolve().parent
ROOT=OUT.parent.parent
DOCS=ROOT/'docs'
ID='AUDIT-R2-20261107'
baseline=json.loads((OUT/'baseline.json').read_text())
summary=('7 November second addon audit ('+ID+'): documentation/proposals only; no audit-issued runtime, existing-test, TOC, art, settings or profiler edits. '
 'Fresh main/source snapshot, four Gethe pins and current232-script/896-Lua pass retained.929 classified sources/599 loaded paths screened. '
 '25 qualified groups:15 active-source behavior/contract reproductions,4 conditional models,2 API edges with ordinary reach unproved,3 work candidates and1 dormant helper. '
 'Prioritize punctuation pool-name collisions, cancelled gear work, and the conditional visible-salvage combat path; preserve all features and saved data. '
 'Explicit rapid Shift/Ctrl/Alt work includes over10million core state edges per run plus separate actual Binding/EBS/badge consumer matrices. '
 'Core bus settles in isolated storms; mixed mouseover can starve full display context; stale press ownership and actual combat index work remain recorded. Large fallback setter counts are an unsupported-paging countermodel, not ordinary repaired Forever. '
 'Independent Party/PvP source and fixture edits were preserved and revalidated by the current232/896 suite plus affected probe; initial snapshots remain. '
 'New fixes remain OPEN. Native taint/input/pixels/instances/CPU/FPS are not accepted by desktop results; previous USER-001 attribution/recurrence is still unknown.')
start,end='<!-- AUDIT-R2-20261107 -->','<!-- /AUDIT-R2-20261107 -->'
def insert(path,text):
 raw=path.read_bytes();nl='\r\n'if b'\r\n'in raw else'\n'
 s=raw.decode('utf-8-sig').replace('\r\n','\n');block=start+'\n'+text+'\n'+end+'\n\n'
 if start in s:
  a=s.index(start);b=s.index(end,a)+len(end)
  while b<len(s)and s[b]=='\n':b+=1
  s=s[:a]+block+s[b:]
 else:
  at=s.find('\n')+1
  while at<len(s)and s[at]=='\n':at+=1
  s=s[:at]+block+s[at:]
 path.write_bytes(s.replace('\n',nl).encode())
link='../Stress%20test%20doc/round-2/README.md'
for name in ['STATUS.md','DECISIONS.md','WORK_LOG.md','CLIENT_VALIDATION.md']:
 insert(DOCS/name,summary+' [Audit and roadmap]('+link+').')
insert(ROOT/'NEXT_SESSION.md',summary+' [Start here](Stress%20test%20doc/round-2/README.md). Continue in audit-only mode until the user authorizes another code phase.')
insert(ROOT/'Stress test doc/README.md','A newer audit and implementation roadmap is available in [round 2](round-2/README.md), including explicit rapid Shift/Ctrl/Alt testing. '
       'Round 2 applies no fixes; earlier applied-fix results below retain their original source scope.')
def upsert(name,key,items):
 p=DOCS/name
 with p.open(encoding='utf-8-sig',newline='')as f:
  reader=csv.DictReader(f);fields=reader.fieldnames;rows=list(reader)
 keys={r[key]for r in items}
 rows=[{k:r.get(k,'')for k in fields}for r in items]+[r for r in rows if r[key]not in keys]
 with p.open('w',encoding='utf-8',newline='')as f:
  w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
evidence='Stress test doc/round-2/README.md; Stress test doc/round-2/FINDINGS.json; Stress test doc/round-2/ROADMAP.md'
upsert('FEATURE_PARITY.csv','feature_id',[{'feature_id':ID,'behavior_or_control':'Further whole-addon error/taint/performance audit and explicit rapid modifiers',
 'source_spec':'User active goal7Nov2026; no code edits; Shift/Ctrl/Alt rapid press/release',
 'baseline':baseline['head']+'; '+baseline['externalSnapshot'],'settings_scope':'No audit runtime edits; same saved roots; independent unit-frame delta rechecked',
 'owner':'Whole-addon source screen; Bars/Binding/Badge/EBS focused owners; remainder domain matrix','change_id':ID,
 'implementation':'AUDIT ONLY;25 finding groups; future work unimplemented','desktop_result':'232/896 current suite/syntax pass; qualified additional reproductions and consumer controls',
 'native_result':'NOT RUN; true secret/protected VM,input,instances,CPU/FPS pending','visual_result':'Logical owner/presentation controls only; native pixels pending','evidence':evidence}])
pins=json.loads((OUT/'upstream-pins.json').read_text())['pins'];labels={'live':'Retail live','forever':'Forever','classic_era':'Era','classic_anniversary':'Anniversary'}
clients=[]
for pin in pins:
 clients.append({'client':labels[pin['branch']]+' '+ID,'reference_path':'Gethe/wow-ui-source '+pin['branch'],
 'reference_version':pin['version'],'reference_sha':pin['sha'],
 'adapter_contracts':'Version/source contract only; active-owner/capability gates documented by finding',
 'desktop_result':'Current suite232/896; rapidmodifier and focused source/capability models; not whole-client emulation',
 'native_result':'NOT RUN','exceptions':'Runtime build/actual taint/pixels/FPS not inferred; extra progression fixtures supplement the four requested pins','evidence':evidence})
upsert('CLIENT_MATRIX.csv','client',clients)
upsert('PERFORMANCE_AUDIT.csv','domain',[{'domain':ID,'reachable_files':599,
 'evidence_scope':'929-source lexical inventory+qualified production-owner counts; no native ms/FPS; no fixes',
 'findings_or_next_check':'VoidAfter latch/cancel family; metadata chains; mount enumeration; disabled reticle scanning; rawmodifier host/attribute work. Preserve cadence/click semantics; roadmap gates before implementation.'}])
upsert('PERFORMANCE_RESULTS.csv','change_id',[{'change_id':ID,'feature_ids':'R2-MOD-01;R2-DOM-02/05/06;R2-EBS-03/05/06;R2-CORE-02/06',
 'scenario':'Read-only current-owner lifecycle,API return contracts,rapidmodifier consumer work and mixed-context freshness',
 'client_build':'Four current Gethe pins plus supplementary progression policies; native runtime not captured',
 'before_source':baseline['externalSnapshot'],'after_source':'No audit candidate; independent unit-frame changes preserved/rechecked; concurrent-recheck.json',
 'config_hash':'No live configuration/profiler changes','profiler_mode':'Desktop operation counts only',
 'trials':'Core5,Binding2,EBS3,consumer3; each owner report retains exact repeats/scope/variation',
 'metric_unit':'Calls,callbacks,frames,hooks and modeled time; not native CPU/FPS',
 'before':'Actualcombat57x5120=291840hostvisits; forcedunsupportedfallback7587840setters is notordinaryrepairedForever; voidAfter/metadatafanout',
 'after':'No optimization implemented; countercontrols are not candidate/native benchmarks',
 'spread':'Core/custom consumer deterministic; Bindingtimer counts vary and raw values retained',
 'parity':'Current baseline suite232/896 passes; audit reproduces qualified gaps; no native parity acceptance',
 'conclusion':'Open findings and feature-preserving roadmap; no FPS/taint fix claim','raw_evidence':evidence}])
(OUT/'continuity-updates.json').write_text(json.dumps({'change':ID,'authorizedDocumentationPaths':[
 'docs/STATUS.md','docs/DECISIONS.md','docs/WORK_LOG.md','docs/CLIENT_VALIDATION.md','NEXT_SESSION.md','Stress test doc/README.md',
 'docs/FEATURE_PARITY.csv','docs/CLIENT_MATRIX.csv','docs/PERFORMANCE_AUDIT.csv','docs/PERFORMANCE_RESULTS.csv']},indent=2)+'\n',encoding='utf-8')
print('Updated documentation continuity and four audit ledgers; no addon code touched')
