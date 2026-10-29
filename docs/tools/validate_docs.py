"""Validate FluxUI documentation without writing files or launching WoW.

Checks source inventory freshness, load closure, coverage mappings, generated
setting/default/command/SV/interface inventories, curated evidence, and links.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

sys.dont_write_bytecode = True
from source_inventory import ROOT, collect

DOCS = ROOT / "docs"


def slug(text):
    text = re.sub(r"\[([^]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"<[^>]+>", "", text).lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    return re.sub(r"\s", "-", text)


def markdown_anchors(text):
    anchors, counts = set(), {}
    in_fence = False
    for line in text.splitlines():
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        match = re.match(r"^ {0,3}#{1,6}\s+(.+?)(?:\s+#+)?$", line)
        if match:
            base = slug(match[1])
            number = counts.get(base, 0)
            counts[base] = number + 1
            anchors.add(base + ("-" + str(number) if number else ""))
        anchors.update(re.findall(r'<a\s+(?:id|name)=["\']([^"\']+)', line))
    return anchors


def main():
    errors = []
    inventory_path = DOCS / "reference/inventory.json"
    if not inventory_path.is_file():
        raise SystemExit("Missing generated inventory; run python docs/tools/build_reference.py")
    stored = json.loads(inventory_path.read_text(encoding="utf-8"))
    current = collect()
    current["clients"] = list(current["clients"])
    if stored != current:
        old_files = {f["path"]: f for f in stored["files"]}
        new_files = {f["path"]: f for f in current["files"]}
        for rel in sorted(old_files.keys() | new_files.keys()):
            if old_files.get(rel) != new_files.get(rel):
                errors.append("Stale source inventory: " + rel)
        if stored["graph"] != current["graph"]:
            errors.append("TOC/XML load graph or SavedVariables declarations changed")
        if stored["defaults"] != current["defaults"]:
            errors.append("AceDB literal default inventory changed")
        if stored.get("assets") != current.get("assets"):
            errors.append("Resource asset inventory changed")
        if not errors:
            errors.append("Generated inventory format/data changed")
    errors += ["Invalid load reference: " + repr(m) for m in current["graph"]["missing"]]
    # Render in memory: the validator must never call the generator's writer.
    import build_reference
    rendered = {}
    def remember(name, lines):
        rendered[name] = "\n".join(lines).rstrip() + "\n"
    build_reference.write = remember
    for renderer in (build_reference.source_coverage, build_reference.settings,
                     build_reference.declarations, build_reference.interfaces,
                     build_reference.performance):
        renderer(current)
    for name, expected in rendered.items():
        path = DOCS / name
        if not path.is_file() or path.read_text(encoding="utf-8") != expected:
            errors.append("Stale generated view: " + name)
    for file in stored["files"]:
        if not (DOCS / file["chapter"]).is_file():
            errors.append("Missing owner chapter for " + file["path"] + ": " + file["chapter"])
        if not file["classification"]:
            errors.append("Unclassified source: " + file["path"])
    coverage = (DOCS / "30-source-coverage.md").read_text(encoding="utf-8")
    details = (DOCS / "reference/settings-details.md").read_text(encoding="utf-8")
    declarations = (DOCS / "reference/declarations.md").read_text(encoding="utf-8")
    interfaces = (DOCS / "reference/interfaces.md").read_text(encoding="utf-8")
    for file in stored["files"]:
        if not file["path"].startswith("libs/") and "../" + file["path"] not in unquote(coverage):
            errors.append("Source absent from coverage view: " + file["path"])
        for setting in file["settings"]:
            if "L" + str(setting["line"]) not in details or file["path"].split("/")[-1] not in details:
                errors.append("Setting absent from generated view: " + file["path"] + ":" + str(setting["line"]))
        if file["clients"]:
            for registration in file["slash"]:
                if registration["name"] not in declarations:
                    errors.append("Command registration absent from view: " + registration["name"])
            for function in file["functions"]:
                if function["name"].replace("|", "\\|").replace("<", "&lt;").replace(">", "&gt;") not in interfaces:
                    errors.append("Interface candidate absent from view: " + function["name"])
    sv_reference = (DOCS / "32-saved-variables.md").read_text(encoding="utf-8")
    for sv in stored["graph"]["saved_variables"]:
        if sv["name"] not in declarations or sv["name"] not in sv_reference:
            errors.append("Undocumented declared SavedVariable: " + sv["name"])
    command_reference = (DOCS / "31-commands-and-bindings.md").read_text(encoding="utf-8")
    widget_reference = (DOCS / "35-custom-widget-controls.md").read_text(encoding="utf-8")
    from source_inventory import literal
    for file in stored["files"]:
        if not file["clients"]:
            continue
        for registration in file["slash"]:
            if registration["kind"] == "alias" and registration["value"] not in command_reference:
                errors.append("Alias absent from behavioral reference: " + registration["value"])
        for setting in file["settings"]:
            widget = literal(setting["fields"].get("dialogControl", ""))
            if widget and widget not in widget_reference:
                errors.append("Custom control absent from behavioral reference: " + widget)
    import xml.etree.ElementTree as ET
    for binding in ET.parse(ROOT / "Bindings.xml").getroot().findall("Binding"):
        if binding.get("name") not in command_reference:
            errors.append("Undocumented binding entry: " + str(binding.get("name")))
    evidence_path = DOCS / "reference/contracts.json"
    if evidence_path.is_file():
        for entry in json.loads(evidence_path.read_text(encoding="utf-8")):
            path = ROOT / entry["source"]
            if not path.is_file() or entry["contains"] not in path.read_text(encoding="utf-8-sig"):
                errors.append("Missing documented source contract: " + entry["source"] + " :: " + entry["contains"])
    else:
        errors.append("Missing curated source-contract evidence")
    verification_path = DOCS / "reference/verification.json"
    if verification_path.is_file():
        evidence = json.loads(verification_path.read_text(encoding="utf-8"))
        corpus = evidence.get("lua_corpus", [])
        fingerprint = hashlib.sha256(json.dumps(corpus, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        if fingerprint != evidence.get("lua_corpus_sha256"):
            errors.append("Verification corpus fingerprint does not match its manifest")
        if len(corpus) != evidence.get("publishable_lua_files"):
            errors.append("Verification Lua file count does not match its manifest")
        corpus_paths = set()
        for entry in corpus:
            rel = entry["path"]
            path = (ROOT / rel).resolve()
            if not path.is_relative_to(ROOT.resolve()) or not path.is_file():
                errors.append("Invalid verification source: " + rel)
                continue
            if rel in corpus_paths:
                errors.append("Duplicate verification source: " + rel)
            corpus_paths.add(rel)
            actual = hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()
            if actual != entry["sha256"]:
                errors.append("Recorded verification predates current source: " + rel)
        for rel in current["graph"]["reachable"]:
            if rel.endswith(".lua") and rel not in corpus_paths:
                errors.append("Reachable Lua absent from verification corpus: " + rel)
        results = evidence.get("results", [])
        passed = sum(result["exitCode"] == 0 for result in results)
        failed = len(results) - passed
        if (len(results), passed, failed) != (evidence.get("smoke_scripts"), evidence.get("smoke_passed"), evidence.get("smoke_failed")):
            errors.append("Recorded smoke totals do not match per-script results")
        result_paths = {result["path"] for result in results}
        for file in current["files"]:
            if file["classification"] == "development harness" and "smoke" in file["path"] and file["path"] not in result_paths:
                errors.append("Smoke harness absent from verification record: " + file["path"])
        syntax = evidence.get("syntax_check", {})
        if syntax.get("passed", 0) + syntax.get("failed", 0) != len(corpus):
            errors.append("Recorded syntax totals do not match the Lua corpus")
    else:
        errors.append("Missing current verification record")
    links = 0
    anchors_cache = {}
    source_line_counts = {}
    link_pattern = re.compile(r'!?\[[^\]\n]*\]\((?:<([^>]+)>|([^\s)]+))(?:\s+"[^"]*")?\)')
    for md in sorted(DOCS.rglob("*.md")):
        text = md.read_text(encoding="utf-8-sig")
        in_fence = False
        for number, raw in enumerate(text.splitlines(), 1):
            if raw.lstrip().startswith(("```", "~~~")):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            line = re.sub(r"`+[^`]*`+", "", raw)
            for match in link_pattern.finditer(line):
                target = match[1] or match[2]
                if target.startswith(("http://", "https://", "mailto:", "data:")):
                    continue
                links += 1
                parsed = urlsplit(target)
                if parsed.scheme or target.startswith(("/", "\\")):
                    errors.append(f"Nonportable local link {md.relative_to(DOCS)}:{number}: {target}")
                    continue
                path = (md.parent / unquote(parsed.path)).resolve() if parsed.path else md
                if not path.exists():
                    errors.append(f"Broken link {md.relative_to(DOCS)}:{number}: {target}")
                    continue
                fragment = unquote(parsed.fragment)
                if not fragment or path.is_dir():
                    continue
                if path.suffix.lower() == ".md":
                    if path not in anchors_cache:
                        anchors_cache[path] = markdown_anchors(path.read_text(encoding="utf-8-sig"))
                    if fragment not in anchors_cache[path]:
                        errors.append(f"Missing heading {md.relative_to(DOCS)}:{number}: {target}")
                elif re.fullmatch(r"L\d+(?:-L\d+)?", fragment):
                    line_number = int(fragment.split("-")[0][1:])
                    if path not in source_line_counts:
                        source_line_counts[path] = len(path.read_text(encoding="utf-8-sig", errors="replace").splitlines())
                    if not 1 <= line_number <= source_line_counts[path]:
                        errors.append(f"Invalid source line {md.relative_to(DOCS)}:{number}: {target}")
    if errors:
        print("Documentation validation FAILED:")
        for error in errors:
            print("- " + error)
        print(f"{len(errors)} issue(s); checker made no edits.")
        return 1
    print(f"PASS: {len(stored['files'])} classified sources; {len(stored['graph']['reachable'])} TOC/XML reachable; "
          f"{sum(len(f['settings']) for f in stored['files'])} setting definitions; {len(stored['graph']['saved_variables'])} SavedVariables; "
          f"{links} local links. Source inventory/evidence current. No files written.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
