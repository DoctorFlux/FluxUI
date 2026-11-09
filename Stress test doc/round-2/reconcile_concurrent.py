"""Record independent current-worktree changes without rewriting the baseline."""
from pathlib import Path
from datetime import datetime, timezone
import difflib
import hashlib
import json
import zipfile

OUT=Path(__file__).resolve().parent
ROOT=OUT.parent.parent
b=json.loads((OUT/'baseline.json').read_text())
old={r['path']:r for r in b['files']}
paths=['UnitFrames/FluxUnitFrames_Party.lua','UnitFrames/FluxUnitFrames_Shared.lua','tests/raid_party_frames.lua','tests/unit_indicator_layout.lua']
previous=OUT/'concurrent-source-drift.json'
if previous.exists():
    prior=json.loads(previous.read_text())
    archive_name='concurrent-source-drift-'+prior['capturedUTC'].replace(':','').replace('+','_')+'.json'
    (OUT/archive_name).write_bytes(previous.read_bytes())
rows=[]
with zipfile.ZipFile(Path(b['externalSnapshot'])/'source.zip')as z:
 for path in paths:
  current=(ROOT/path).read_bytes();before=z.read(path)
  diff=''.join(difflib.unified_diff(before.decode('utf-8-sig').splitlines(keepends=True),current.decode('utf-8-sig').splitlines(keepends=True),fromfile='baseline/'+path,tofile='current/'+path))
  patch=path.replace('/','_')+'-'+hashlib.sha256(current).hexdigest()[:12]+'.patch'
  (OUT/patch).write_text(diff,encoding='utf-8')
  rows.append({'path':path,'baselineSHA256':old[path]['sha256'],'currentSHA256':hashlib.sha256(current).hexdigest(),
               'patch':patch,'attribution':'Independent worktree change, not issued by this audit/team; preserved',
               'review':'Independent shared/party PvP badge presentation/routing and indicator fixtures changed. Current source review/probes are separate; native visual/secret permission remains untested.'})
(OUT/'concurrent-source-drift.json').write_text(json.dumps({'capturedUTC':datetime.now(timezone.utc).isoformat(),
 'baselinePreserved':True,'changes':rows,'validationPolicy':'Current suite, affected domain probe and fresh current source/load index required. Do not hide drift or replace earlier evidence.'},indent=2)+'\n',encoding='utf-8')
print('Recorded independent unit-frame/PvP source and fixture delta; baseline retained')
