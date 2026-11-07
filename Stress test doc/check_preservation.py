"""Check original files/settings identities without writing outside this folder."""
from pathlib import Path
import datetime
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent
baseline = json.loads((OUT / 'evidence/baseline.json').read_text(encoding='utf-8'))
original = {r['path']: r for r in baseline['files']}
changed, missing = [], []
for rel, row in original.items():
    path = ROOT / rel
    if not path.is_file():
        missing.append(rel)
    elif hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
        changed.append(rel)
extra = []
for path in ROOT.rglob('*'):
    rel = path.relative_to(ROOT)
    if not path.is_file() or any(p in ('.git', 'Stress test doc', '__pycache__') for p in rel.parts):
        continue
    if rel.as_posix() not in original:
        extra.append(rel.as_posix())
external = Path(baseline['externalCheckpoint'])
settings = json.loads((external / 'private-settings-metadata.json').read_text(encoding='utf-8'))
settings_changed = 0
for row in settings:
    p = Path(row['path'])
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest() != row['sha256']:
        settings_changed += 1
def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()
report = {'checkedUTC': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'originalFiles': len(original), 'existingFilesChanged': changed, 'existingFilesMissing': missing,
          'runtimeOrTestSourceChanged': [p for p in changed + missing if Path(p).suffix.lower() in ('.lua', '.xml', '.toc', '.py', '.ps1')],
          'runtimeOrTestSourceAddedOutsideStressFolder': [p for p in extra if Path(p).suffix.lower() in ('.lua', '.xml', '.toc', '.py', '.ps1')],
          'newFilesOutsideStressFolder': sorted(extra), 'headBefore': baseline['head'], 'headAfter': git('rev-parse', 'HEAD'),
          'branchBefore': baseline['branch'], 'branchAfter': git('branch', '--show-current'),
          'settingsFilesCompared': len(settings), 'settingsContentsChangedSinceBaseline': settings_changed,
          'privateSettingsNote': 'Only private external metadata was read; no settings content copied to AddOns. A running client/user may independently save settings.',
          'pass': not changed and not missing and not extra and git('rev-parse', 'HEAD') == baseline['head']}
report['runtimeAndTestSourceUnchanged'] = not report['runtimeOrTestSourceChanged'] and not report['runtimeOrTestSourceAddedOutsideStressFolder']
report['interpretation'] = 'No audit tool wrote outside Stress test doc or the external checkpoint. Existing documentation/settings drift is reported separately, not reverted or attributed to this audit.'
(OUT / 'evidence/preservation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
raise SystemExit(0 if report['pass'] else 1)
