"""Record repeated applied-owner checks and independent frozen pre-edit controls."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
checkpoint = json.loads((OUT / 'checkpoint.json').read_text(encoding='utf-8-sig'))
external = Path(checkpoint['externalCheckpoint']).resolve()
before = (external / 'before').resolve()
assert before.is_relative_to(external)
owners = ['Core/Engine/' + x + '.lua' for x in
          ['Context', 'Modifier', 'Events', 'Scheduler', 'Range', 'Combat', 'Ticker']]
owners += ['Binding/Input/FluxMouseoverKeybind.lua', 'Inventory/Builtin/Auctions.lua',
           'UnitFrames/FluxCastBar.lua', 'UnitFrames/FluxSwingTimer.lua']
known = {r['path']: r['sha256'] for r in checkpoint['files']}
with zipfile.ZipFile(external / 'source.zip') as archive:
    for path in owners:
        data = archive.read(path)
        assert hashlib.sha256(data).hexdigest() == known[path], path
        target = (before / path).resolve()
        assert target.is_relative_to(before)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

checks = ['tests/shared_service_integrity.lua', 'tests/context_invalidation_stress.lua',
          'tests/hover_children_varargs.lua', 'Stress test doc/performance/stress_auction_sustained.lua.txt']
records = []
for repeat in range(1, 4):
    for script in checks:
        result = subprocess.run(['lua', script], cwd=ROOT, capture_output=True, text=True, timeout=90)
        name = Path(script).stem.replace('.lua', '') + f'-run-{repeat}.txt'
        (OUT / name).write_text(result.stdout + result.stderr, encoding='utf-8')
        records.append({'script': script, 'repeat': repeat, 'exit': result.returncode, 'raw': name})

overlay = 'Stress test doc/fix-proposals/overlay.lua.txt'
for script in checks[:3]:
    if script.endswith('shared_service_integrity.lua'):
        command = ['lua', script, str(before)]
    else:
        command = ['lua', overlay, str(before), 'baseline', script, str(ROOT)]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=90)
    name = Path(script).stem + '-baseline-rejection.txt'
    (OUT / name).write_text(result.stdout + result.stderr, encoding='utf-8')
    marker = {'tests/shared_service_integrity.lua': 'inventory per-frame callback budget',
              'tests/context_invalidation_stress.lua': 'SUMMARY checks=7605 failures=15',
              'tests/hover_children_varargs.lua': 'SUMMARY checks=55 failures=20'}[script]
    records.append({'script': script, 'expectedBaselineFailure': True,
                    'exit': result.returncode, 'raw': name, 'expectedMarkerFound': marker in result.stdout + result.stderr})
fade_script = 'Stress test doc/fix-proposals/fades/verify.lua.txt'
native = ROOT.parent / '__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua'
native_data = native.read_bytes().replace(b'\r\n', b'\n')
assert hashlib.sha1(b'blob ' + str(len(native_data)).encode() + b'\0' + native_data).hexdigest() == 'a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d'
fade_command = ['lua', fade_script, str(before), str(ROOT), str(native)]
for repeat in range(1, 4):
    result = subprocess.run(fade_command, cwd=ROOT, capture_output=True, text=True, timeout=90)
    name = f'fade-ownership-run-{repeat}.txt'
    (OUT / name).write_text(result.stdout + result.stderr, encoding='utf-8')
    records.append({'script': fade_script, 'repeat': repeat, 'exit': result.returncode, 'raw': name})
for mutation in ['swing-force-one', 'swing-drop-record', 'cast-restore-getter',
                 'busy-restore-getter', 'swing-stale-timer']:
    result = subprocess.run(fade_command + [mutation], cwd=ROOT, capture_output=True, text=True, timeout=90)
    name = f'fade-mutation-{mutation}.txt'
    (OUT / name).write_text(result.stdout + result.stderr, encoding='utf-8')
    marker = {'swing-force-one': 'restart has no alpha jump', 'swing-drop-record': 'restart has no alpha jump',
              'cast-restore-getter': 'candidate cast fade never reads native alpha',
              'busy-restore-getter': 'OPAQUE_ALPHA_GETTER', 'swing-stale-timer': 'stale historical timer hides replacement'}[mutation]
    records.append({'script': fade_script, 'mutation': mutation,
                    'expectedBaselineFailure': True, 'exit': result.returncode, 'raw': name,
                    'expectedMarkerFound': marker in result.stdout + result.stderr})
evidence = {'scope': 'Actual production owners under desktop API/event fixtures; native VM, taint, pixels and hardware CPU/FPS not tested.',
            'before': str(before), 'checkpoint': checkpoint['capturedUTC'], 'runs': records,
            'sources': [{'path': p, 'beforeSHA256': known[p],
                         'appliedSHA256': hashlib.sha256((ROOT / p).read_bytes()).hexdigest()} for p in owners]}
(OUT / 'shared-results.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
assert all((r['exit'] != 0) if r.get('expectedBaselineFailure') else (r['exit'] == 0) for r in records), records
assert all(r.get('expectedMarkerFound', True) for r in records), records
print(f'PASS {len(records)} repeated applied checks and baseline rejection controls')
