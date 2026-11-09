"""Consolidate qualified round-2 findings; never modifies addon code."""
from pathlib import Path
from collections import Counter
import csv
import json
import re

OUT=Path(__file__).resolve().parent
titles={
 'R2-BIND-01':'Overlapping key presses can leave the previous bar column pushed',
 'R2-BIND-02':'Literal minus key is lost during chord parsing',
 'R2-BIND-03':'Reentrant supersession can overwrite a newer restore without completion',
 'R2-BIND-04':'Press tint arithmetic assumes public non-nil native vertex colors',
 'R2-BIND-05':'Direct combat program clear can leave a protected payload behind',
 'R2-BIND-06':'Distinct punctuation chords collide on one secure pool frame name',
 'R2-DOM-01':'Delayed microbutton tooltip can outlive its hover owner',
 'R2-DOM-02':'Microbutton disable/re-enable accumulates retained native icon hooks',
 'R2-DOM-03':'Visible salvage overlay attempts protected anchor writes in combat',
 'R2-DOM-04':'Portrait/threat callers calculate with potentially secret frame levels',
 'R2-DOM-05':'Repeated vendor tab/query triggers amplify metadata retry chains',
 'R2-DOM-06':'Void After results defeat four owners\' pending/cancellation fields',
 'R2-EBS-01':'Dormant legacy macro usability helper searches for literal percent-bracket',
 'R2-EBS-02':'Vendor mount recognition depends on English native display names',
 'R2-EBS-03':'Active vendor detection repeatedly enumerates the full mount journal',
 'R2-EBS-04':'Injected cooldown setter failure can commit an unapplied cache entry',
 'R2-EBS-05':'Mount refresh pending latch is assigned the void After result',
 'R2-EBS-06':'Disabled legacy cast VFX still scan reticle owner faces',
 'R2-CORE-01':'Gear/rune picker leave and hide cannot cancel delayed show requests',
 'R2-CORE-02':'Restock panel bag refresh pending latch never arms',
 'R2-CORE-03':'Cancelled talent timeout can detach a newer spec-switch watcher',
 'R2-CORE-04':'Missing or partial gear can report complete profile success',
 'R2-CORE-05':'Pending and active gear mutations can continue after profile cancellation',
 'R2-CORE-06':'Continuous mouseover starves pending full display-context delivery',
 'R2-MOD-01':'Raw modifier events perform repeated bar scans and fallback attribute stamps',
}
categories={**dict.fromkeys(['R2-BIND-04','R2-DOM-03','R2-DOM-04','R2-EBS-04'],'conditional'),
            **dict.fromkeys(['R2-BIND-03','R2-BIND-05'],'API edge / ordinary reach unproved'),
            **dict.fromkeys(['R2-EBS-03','R2-EBS-06','R2-MOD-01'],'measured work / optimization candidate'),
            'R2-EBS-01':'dormant legacy'}
paths=['action-binding/findings.json','remaining-domains/findings.json','extra-buttons/findings.json',
       'core_findings.json','core-equipment/findings.json','modifier-storm/consumer-findings.json']
records=[]
for rel in paths:
    doc=json.loads((OUT/rel).read_text(encoding='utf-8-sig'))
    items=doc.get('findings') or [doc['finding']]
    report=str(Path(rel).parent/'REPORT.md').replace('\\','/')
    if rel=='core_findings.json':report='CORE_REPORT.md'
    if rel.startswith('modifier-storm/'):report='modifier-storm/CONSUMER_REPORT.md'
    for raw in items:
        key=raw['id'];priority=raw.get('priority',raw.get('severity','P2'))
        if key=='R2-MOD-01':priority='P3 current-path optimization candidate; forced fallback separate'
        if isinstance(priority,int):priority='P'+str(priority)
        elif not priority.startswith('P'):
            priority='P1' if priority.startswith('high') else('P3'if priority.startswith('low')else'P2')
        source=raw.get('source') or (raw.get('sources')or[''])[0]
        line=raw.get('line','')
        if not source and raw.get('locations'):source=raw['locations'].split(';')[0]
        match=re.match(r'^(.*\.(?:lua|xml)):(\d+)$',source)
        if match:source,line=match.group(1),int(match.group(2))
        category=categories.get(key,'reproduced active-source behavior / contract')
        proposal=raw.get('futureFix',raw.get('proposal',''))
        acceptance=raw.get('acceptance',raw.get('regression_gate',''))
        if not acceptance:
            acceptance='See the '+key+' row under Proposed fixes and acceptance gates in '+report+'.'
        if isinstance(acceptance,(dict,list)):acceptance=json.dumps(acceptance)
        if acceptance=='REPORT.md':acceptance='See '+report+' for concrete positive, failure and lifecycle gates.'
        item={'id':key,'priority':priority,'category':category,'title':titles[key],
           'source':source,'line':line,'classification':raw.get('classification',raw.get('evidence_class','')),
           'trigger':raw.get('trigger','See detailed report'),
           'observation':raw.get('observation',raw.get('actual',raw.get('evidence','See detailed report and raw results'))),
           'proposal':proposal,'acceptance':acceptance,'report':report,
           'mechanismFamily':'R2-TIMER' if key in ['R2-DOM-06','R2-EBS-05','R2-CORE-01','R2-CORE-02','R2-CORE-03']else key,
           'status':'OPEN; audit/proposals only; no new fix applied',
           'nativeStatus':raw.get('native_status','NOT RUN: no native error/taint/FPS certification'),
           'originalRecord':raw,'evidenceFile':rel}
        if key=='R2-MOD-01':
            item['trigger']='Actual current combat modifier events scan all active hosts. Large out-of-combat setter counts are from a forced unsupported-paging fallback, not ordinary repaired Forever.'
            item['observation']='57 hosts/5120 combat events:291840 visits,875520 attribute reads,zero protected writes. Forced fallback7587840 setters is a countermodel; actual repaired Forever uses secure paging. See concurrent-review/REPORT.md.'
        records.append(item)
records.sort(key=lambda r:(int(re.search(r'\d+',r['priority']).group()),r['id']))
assert len(records)==25 and len({r['id'] for r in records})==25
(OUT/'FINDINGS.json').write_text(json.dumps({'scope':'25 qualified finding groups; not25 observed native bugs. Multiple timer sites share one mechanism.','findings':records},indent=2)+'\n',encoding='utf-8')
columns=[k for k in records[0] if k!='originalRecord']
with (OUT/'FINDINGS.csv').open('w',encoding='utf-8',newline='')as f:
    w=csv.DictWriter(f,fieldnames=columns);w.writeheader();w.writerows({k:r[k] for k in columns}for r in records)
counts=dict(Counter(r['category']for r in records))
(OUT/'finding-summary.json').write_text(json.dumps({'groups':len(records),'categories':counts,'nativeErrorsObserved':0,'newFixesApplied':0},indent=2)+'\n',encoding='utf-8')
print(json.dumps(counts,indent=2))
