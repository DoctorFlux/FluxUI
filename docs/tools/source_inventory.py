"""Read-only, standard-library source inspection for FluxUI documentation.

This is a source inventory, not a Lua interpreter or a proof of runtime behavior.
Comments and strings are tokenized so commented registrations are not counted.
"""
from __future__ import annotations

import hashlib
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLIENTS = ("mainline", "camelot", "vanilla", "tbc", "wrath", "cata", "mists", "classic")
EXCLUDED = {".git", ".cursor", ".cache", ".perf-backup-20260919", ".gamepad-taint-backup-20261009", "__pycache__"}
LONG_BRACKET = re.compile(r"\[(=*)\[")
CODE_TOKEN = re.compile(r"[A-Za-z_][A-Za-z_0-9]*|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|\.\.\.|\.\.|==|~=|<=|>=|::")


@dataclass
class Token:
    value: str
    start: int
    end: int
    kind: str


def tokens(source):
    """Lex strings/comments (including long brackets) without executing Lua."""
    out = []
    i, n = 0, len(source)
    while i < n:
        c = source[i]
        if c.isspace():
            i += 1
            continue
        comment = source.startswith("--", i)
        bracket_at = i + 2 if comment else i
        long = LONG_BRACKET.match(source, bracket_at) if bracket_at < n and source[bracket_at] == "[" else None
        if long:
            end_marker = "]" + long[1] + "]"
            end = source.find(end_marker, bracket_at + len(long[0]))
            end = n if end < 0 else end + len(end_marker)
            if not comment:
                out.append(Token(source[i:end], i, end, "string"))
            i = end
        elif comment:
            end = source.find("\n", i)
            i = n if end < 0 else end + 1
        elif c in "\"'":
            start, quote = i, c
            i += 1
            while i < n:
                if source[i] == "\\":
                    i += 2
                elif source[i] == quote:
                    i += 1
                    break
                else:
                    i += 1
            out.append(Token(source[start:i], start, i, "string"))
        else:
            match = CODE_TOKEN.match(source, i)
            value = match[0] if match else c
            kind = "id" if re.match(r"^[A-Za-z_]", value) else "code"
            out.append(Token(value, i, i + len(value), kind))
            i += len(value)
    return out


def literal(value):
    if len(value) >= 2 and value[0] in "\"'" and value[-1] == value[0]:
        return value[1:-1].replace("\\\"", "\"").replace("\\'", "'").replace("\\n", "\n").replace("\\t", "\t").replace("\\\\", "\\")
    return None


def line_at(source, pos):
    return source.count("\n", 0, pos) + 1


def expression_end(ts, start, stop):
    brackets, blocks = [], []
    i = start
    while i < stop:
        t = ts[i]
        v = t.value
        if t.kind != "string":
            if v in ("(", "[", "{"):
                brackets.append(v)
            elif v in (")", "]", "}"):
                if not brackets:
                    return i
                brackets.pop()
            elif v == "function" or v == "if" or v == "repeat":
                blocks.append(v)
            elif v in ("for", "while"):
                blocks.append("loop_wait")
            elif v == "do":
                if blocks and blocks[-1] == "loop_wait":
                    blocks[-1] = "loop"
                else:
                    blocks.append("do")
            elif v in ("end", "until") and blocks:
                blocks.pop()
            elif v in (",", ";") and not brackets and not blocks:
                return i
        i += 1
    return stop


def tables(source, ts):
    stack, ends = [], {}
    for i, t in enumerate(ts):
        if t.kind == "string":
            continue
        if t.value == "{":
            stack.append(i)
        elif t.value == "}" and stack:
            ends[stack.pop()] = i
    out = []
    for begin, end in sorted(ends.items()):
        fields, field_lines = {}, {}
        i = begin + 1
        array_index = 0
        while i < end:
            if ts[i].value in (",", ";"):
                i += 1
                continue
            key = None
            value_start = i
            if i + 1 < end and ts[i + 1].value == "=" and ts[i].kind == "id":
                key, value_start = ts[i].value, i + 2
            elif i + 3 < end and ts[i].value == "[" and ts[i + 2].value == "]" and ts[i + 3].value == "=":
                key = literal(ts[i + 1].value) or "[" + ts[i + 1].value + "]"
                value_start = i + 4
            j = expression_end(ts, value_start, end)
            if key is None:
                array_index += 1
                key = str(array_index)
            if j > value_start:
                fields[key] = source[ts[value_start].start:ts[j - 1].end]
                field_lines[key] = line_at(source, ts[value_start].start)
            i = j + 1
        name = "<anonymous>"
        if begin > 1 and ts[begin - 1].value == "=":
            before = ts[begin - 2]
            name = before.value
            if name == "]":
                j = begin - 3
                while j >= 0 and ts[j].value != "[":
                    j -= 1
                name = source[ts[j].start:before.end] if j >= 0 else "[dynamic]"
        parent = next((p for p in reversed(out) if p["start"] < ts[begin].start < p["end"]), None)
        if name == "<anonymous>" and parent:
            own_text = source[ts[begin].start:ts[end].end]
            for field_key, field_value in parent["fields"].items():
                if field_key.isdigit() and field_value == own_text and parent["field_lines"][field_key] == line_at(source, ts[begin].start):
                    name = "[" + field_key + "]"
                    break
        item = {"key": name, "line": line_at(source, ts[begin].start), "start": ts[begin].start,
                "end": ts[end].end, "fields": fields, "field_lines": field_lines,
                "parent_line": parent["line"] if parent else None}
        out.append(item)
    return out


def source_files():
    return sorted((p for p in ROOT.rglob("*") if p.is_file() and p.suffix.lower() in (".lua", ".xml")
                   and not any(part in EXCLUDED for part in p.relative_to(ROOT).parts)
                   and "docs" not in p.relative_to(ROOT).parts), key=lambda p: p.relative_to(ROOT).as_posix().lower())


def load_graph():
    reachable, missing, order, visiting = {}, [], [], set()

    def visit(path, clients, parent):
        path = path.resolve()
        try:
            rel = path.relative_to(ROOT).as_posix()
        except ValueError:
            missing.append({"path": str(path), "parent": parent, "reason": "outside addon"})
            return
        if not path.is_file():
            missing.append({"path": rel, "parent": parent, "reason": "missing"})
            return
        if not clients:
            return
        rec = reachable.setdefault(rel, {"clients": set(), "parents": set()})
        new_clients = set(clients) - rec["clients"]
        rec["clients"].update(clients)
        rec["parents"].add(parent)
        if rel not in order:
            order.append(rel)
        if path.suffix.lower() != ".xml" or not new_clients or rel in visiting:
            return
        visiting.add(rel)
        try:
            tree = ET.fromstring(path.read_text(encoding="utf-8-sig"))
            for node in tree.iter():
                tag = node.tag.rsplit("}", 1)[-1]
                if tag in ("Include", "Script") and node.get("file"):
                    child = node.get("file").replace("\\", "/")
                    visit(path.parent / child, new_clients, rel)
        except ET.ParseError as exc:
            missing.append({"path": rel, "parent": parent, "reason": str(exc)})
        visiting.remove(rel)

    toc = (ROOT / "_FluxUI.toc").read_text(encoding="utf-8-sig")
    saved = []
    for no, raw in enumerate(toc.splitlines(), 1):
        text = raw.strip()
        if text.startswith("## SavedVariables"):
            field, values = text[3:].split(":", 1)
            saved.extend({"name": name.strip(), "scope": "character" if field.endswith("PerCharacter") else "account", "line": no}
                         for name in values.split(",") if name.strip())
        if not text or text.startswith("#"):
            continue
        clients = set(CLIENTS)
        for gate, values in re.findall(r"\[(AllowLoadGameType|DenyLoadGameType)\s+([^]]+)\]", text):
            allowed = {v.strip() for v in values.split(",")}
            clients = clients & allowed if gate.startswith("Allow") else clients - allowed
        filename = re.sub(r"\s*\[[^]]+\]", "", text).strip().replace("\\", "/")
        visit(ROOT / filename, clients, "_FluxUI.toc:" + str(no))
    for rec in reachable.values():
        rec["clients"] = sorted(rec["clients"])
        rec["parents"] = sorted(rec["parents"])
    return {"reachable": reachable, "missing": missing, "order": order, "saved_variables": saved}


def chapter_for(rel):
    first = rel.split("/")[0]
    mapping = {"Bars": "11-action-bars.md", "Binding": "13-binding-system.md", "ExtraButtonSystem": "12-extra-button-system.md",
               "UnitFrames": "14-unit-frames.md", "RaidFrame": "15-raid-frames.md", "StatusBars": "16-status-bars.md",
               "MicroMenu": "17-micromenu.md", "Minimap": "18-minimap-and-trackers.md", "NamePlates": "19-nameplates.md",
               "Battlezonemap": "10-flux-window.md", "CharacterInfo": "27-character-info.md", "WindowMover": "28-window-mover.md",
               "Salvage": "22-salvage.md", "Respec": "23-respec.md", "BaganatorCompat": "24-baganator-compat.md",
               "ConsoleportCompat": "29-integrations.md", "Other": "25-other-qol.md", "AddonOptions": "26-options-map.md",
               "Blizzard": "07-runtime-architecture.md", "BlizzardSettings": "05-defaults-and-bindings.md", "Layout": "06-layout.md"}
    if rel.startswith("Inventory/Restock/") or rel == "Inventory/FluxItemMover.lua":
        return "20-vendor-restock-junk.md"
    if first == "Inventory":
        return "21-inventory-foundation.md"
    if rel.startswith("Core/API/Secrets") or rel.startswith("Core/FluxAPI/Secrets") or rel.endswith("RetailSecrets.lua"):
        return "03-midnight-constraints.md"
    if rel.startswith("Core/Client") or rel == "Core/Capabilities.lua":
        return "02-multi-client-matrix.md"
    if rel in ("Core/Flux.lua", "Core/Module.lua", "Core/Optional.lua"):
        return "07-runtime-architecture.md"
    if rel == "Core/DB.lua":
        return "09-persistence.md"
    if first == "Core" or rel in ("Other/FluxPerfCapture.lua", "Other/FluxPerfDebug.lua"):
        return "08-shared-services.md"
    if first == "libs":
        return "90-reference-inspirations.md"
    if rel == "FluxDefaultSettings.lua" or rel == "Bindings.xml":
        return "05-defaults-and-bindings.md"
    if rel == "FluxBorder.lua":
        return "04-visual-system.md"
    return mapping.get(first, "34-assets.md")


def call_args(source, ts, index):
    if index + 1 >= len(ts) or ts[index + 1].value != "(":
        return []
    out, i = [], index + 2
    while i < len(ts) and ts[i].value != ")":
        j = expression_end(ts, i, len(ts))
        if j <= i:
            break
        out.append(source[ts[i].start:ts[j - 1].end])
        if j >= len(ts) or ts[j].value == ")":
            break
        i = j + 1
    return out


def inspect_file(path, graph):
    rel = path.relative_to(ROOT).as_posix()
    source = path.read_text(encoding="utf-8-sig", errors="replace")
    loaded = graph["reachable"].get(rel)
    if rel == "Bindings.xml":
        loaded = {"clients": list(CLIENTS), "parents": ["_FluxUI.toc:Bindings metadata / WoW binding loader"]}
    tool = path.name.startswith("_tmp") or path.name.endswith("smoke.lua")
    classification = "development harness" if tool else "bundled library" if rel.startswith("libs/") else "active compatibility" if loaded and ("Compat" in rel or "FluxAPI/" in rel or "LegacyBridge" in rel) else "active" if loaded else "inactive source"
    rec = {"path": rel, "classification": classification, "chapter": chapter_for(rel), "lines": len(source.splitlines()),
           "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "clients": loaded["clients"] if loaded else [],
           "parents": loaded["parents"] if loaded else [], "settings": [], "functions": [], "events": [], "slash": [], "widgets": [], "loads": [], "sv_sites": []}
    if path.suffix.lower() != ".lua" or rel.startswith("libs/") or tool:
        return rec
    ts = tokens(source)
    table_nodes = tables(source, ts) if rel.startswith("AddonOptions/") else []
    for table in table_nodes:
        f = table["fields"]
        ty = literal(f.get("type", ""))
        if rel.startswith("AddonOptions/") and (ty in {"group", "header", "description", "toggle", "range", "select", "multiselect", "execute", "input", "color", "keybinding"} or ("key" in f and "get" in f and "set" in f and "name" in f)):
            rec["settings"].append({k: table[k] for k in ("key", "line", "fields", "field_lines", "parent_line")})
    for i, t in enumerate(ts):
        v = t.value
        if t.kind == "id" and v.startswith("SLASH_") and i + 2 < len(ts) and ts[i + 1].value == "=" and ts[i + 2].kind == "string":
            alias = literal(ts[i + 2].value)
            if alias and alias.startswith("/"):
                rec["slash"].append({"kind": "alias", "name": v, "value": alias, "line": line_at(source, t.start)})
        if v == "SlashCmdList" and i + 4 < len(ts) and ts[i + 1].value == "[" and ts[i + 3].value == "]" and ts[i + 4].value == "=":
            rec["slash"].append({"kind": "handler", "name": literal(ts[i + 2].value) or ts[i + 2].value, "line": line_at(source, t.start)})
        if v == "SlashCmdList" and i + 2 < len(ts) and ts[i + 1].value == "." and ((i + 3 < len(ts) and ts[i + 3].value == "=") or (i > 0 and ts[i - 1].value == "function")):
            rec["slash"].append({"kind": "handler", "name": ts[i + 2].value, "line": line_at(source, t.start)})
        if v in ("RegisterEvent", "RegisterUnitEvent", "Subscribe", "RegisterChatCommand", "RegisterWidgetType", "LoadAddOn", "LoadAddon", "FlagToggle", "HealthTextOpt", "AuraToggle", "ButtonToggle", "BlizzardThreatToggle", "AddTextAndBars", "AddIcons") and i + 1 < len(ts) and ts[i + 1].value == "(" and not (i and ts[i - 1].value == "function"):
            args = call_args(source, ts, i)
            if not args:
                continue
            obj_start = max(0, i - 5)
            obj = "".join(x.value for x in ts[obj_start:i])
            item = {"line": line_at(source, t.start), "method": v, "arguments": args, "context": obj}
            if v in ("RegisterEvent", "RegisterUnitEvent", "Subscribe"):
                rec["events"].append(item)
            elif v == "RegisterChatCommand":
                rec["slash"].append({"kind": "ace", "name": args[0], "line": item["line"], "arguments": args})
            elif v == "RegisterWidgetType":
                rec["widgets"].append(item)
            elif v in ("LoadAddOn", "LoadAddon"):
                rec["loads"].append(item)
            elif rel.startswith("AddonOptions/"):
                rec.setdefault("setting_factories", []).append(item)
        if v == "function":
            j = i + 1
            if j < len(ts) and ts[j].kind == "id":
                parts = []
                while j < len(ts) and (ts[j].kind == "id" or ts[j].value in (".", ":")):
                    parts.append(ts[j].value)
                    j += 1
                if j < len(ts) and ts[j].value == "(":
                    local = i > 0 and ts[i - 1].value == "local"
                    if not local:
                        rec["functions"].append({"name": "".join(parts), "line": line_at(source, t.start)})
            elif i >= 2 and ts[i - 1].value == "=":
                j = i - 2
                parts = []
                while j >= 0 and (ts[j].kind == "id" or ts[j].value in (".", ":")):
                    parts.insert(0, ts[j].value)
                    j -= 1
                name = "".join(parts)
                if "." in name or ":" in name:
                    rec["functions"].append({"name": name, "line": line_at(source, t.start)})
    for sv in graph["saved_variables"]:
        sites = [line_at(source, t.start) for t in ts if (t.kind == "id" and t.value == sv["name"]) or (t.kind == "string" and literal(t.value) == sv["name"])]
        if sites:
            rec["sv_sites"].append({"name": sv["name"], "lines": sorted(set(sites))})
    return rec


def defaults_inventory():
    source = (ROOT / "AddonOptions/FluxOptionsDefaults.lua").read_text(encoding="utf-8-sig")
    nodes = tables(source, tokens(source))
    out = []
    by_line = {t["line"]: t for t in nodes}
    for table in nodes:
        parents, cur = [], table
        while cur:
            if cur["key"] != "<anonymous>":
                parents.insert(0, cur["key"])
            cur = by_line.get(cur["parent_line"])
        for key, value in table["fields"].items():
            if not value.lstrip().startswith("{"):
                out.append({"path": ".".join(parents + [key]).replace(".[", "["), "value": value, "line": table["field_lines"][key]})
    return out


def collect():
    graph = load_graph()
    files = [inspect_file(p, graph) for p in source_files()]
    assets = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in EXCLUDED or part == "docs" for part in rel.parts):
            continue
        media_file = path.suffix.lower() in {".tga", ".blp", ".png", ".jpg", ".jpeg", ".dds", ".ttf", ".otf", ".ogg", ".wav", ".mp3"}
        resource_file = rel.parts[0] in {"Assets", "Media", "Texture"} and path.suffix.lower() not in {".md", ".lua", ".xml"}
        if not (media_file or resource_file):
            continue
        assets.append({"path": rel.as_posix(), "bytes": path.stat().st_size,
                       "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    return {"format_version": 1, "clients": CLIENTS, "graph": graph, "files": files, "defaults": defaults_inventory(), "assets": assets}
