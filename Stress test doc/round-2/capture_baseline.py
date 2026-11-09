"""Capture read-only source identities/history outside AddOns for round-2 review."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import zipfile

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
if (OUT / 'baseline.json').exists():
    raise SystemExit('Round-2 baseline already exists; preserve it and use a new dated audit folder for another capture.')
EXTERNAL = Path('C:/Users/mario/.codex/visualizations/2026/11/07/01a1b5b8-1789-7050-b49c-88d0a742e874')
stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
snapshot = EXTERNAL / ('round2-audit-' + stamp)
snapshot.mkdir(parents=True, exist_ok=False)
excluded = {'.git', '__pycache__', '.cache'}
files = []
for path in sorted(ROOT.rglob('*')):
    rel = path.relative_to(ROOT)
    if not path.is_file() or any(p in excluded for p in rel.parts) or rel.parts[:2] == ('Stress test doc', 'round-2'):
        continue
    data = path.read_bytes()
    files.append({'path': rel.as_posix(), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                  'sha256LF': hashlib.sha256(data.replace(b'\r\n', b'\n')).hexdigest()})
source_paths = [r for r in files if Path(r['path']).suffix.lower() in {'.lua', '.xml', '.toc'}
                or r['path'].startswith('tests/fixtures/') or Path(r['path']).name.lower().startswith('license')]
with zipfile.ZipFile(snapshot / 'source.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for row in source_paths:
        data = (ROOT / row['path']).read_bytes()
        assert hashlib.sha256(data).hexdigest() == row['sha256'], row['path']
        archive.writestr(row['path'], data)
def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True)
status = git('status', '--porcelain=v1')
(snapshot / 'working.diff').write_text(git('diff', '--binary'), encoding='utf-8')
(snapshot / 'git-history.txt').write_text(git('log', '-12', '--format=%H%n%aI%n%s'), encoding='utf-8')
record = {'capturedUTC': stamp, 'head': git('rev-parse', 'HEAD').strip(), 'branch': git('branch', '--show-current').strip(),
          'dirtyStatus': status, 'externalSnapshot': str(snapshot), 'files': files,
          'archivedSourceFiles': len(source_paths), 'settingsAndNativeOperations': 'None; source/history read only',
          'scope': 'All pre-existing files excluding Git/caches and this new audit folder; current code authoritative, earlier applied suite is historical.'}
(OUT / 'baseline.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
(snapshot / 'baseline.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v for k, v in record.items() if k not in ('files', 'dirtyStatus')}, indent=2))
