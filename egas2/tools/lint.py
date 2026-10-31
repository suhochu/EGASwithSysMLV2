#!/usr/bin/env python3
"""EGAS2 model lint: Registry, layer direction, relationship placement, black-box purity, SPES hints, value provenance.
  python egas2/tools/lint.py [--model DIR] [--registry FILE]
Exit code 1 on any ERROR. Rule codes L1-L8 are described in egas2/memory/MODELING_RULES.md."""
import re, sys, json, pathlib, collections
from sysml_scan import EGAS2, clean, top_level, read, sysml_files

STATUSES = {"planned", "active", "retired", "outOfScope"}
REL_LAYERS = {"refinement": ("Scn", "Beh"), "derivation": ("Sysr", "Sysr"), "allocate": ("Lbb", "Lwb")}
REL_PATTERNS = {"satisfy": r"\bsatisfy\b", "allocate": r"\ballocate\b",
                "refinement": r"#\s*refinement\b", "derivation": r"#\s*derivation\b"}
DEF_RE = re.compile(r"\b(?:\w+\s+)?def\s+(?:<[^>]*>\s*)?('[^']+'|\w+)")
BB_RE = re.compile(r"(?:^|[;{}])\s*((?:part|perform|action|state|exhibit|assert)\b)")
FOLLOWER_RE = re.compile(r"\s*(?:(?:abstract|variation)\s+)?(?:requirement|use case|concern|part|item|action|state|goal|scenario)\s+(?:def\s+)?(?:<('[^']+'|\w+)>\s*)?('[^']+'|\w+)")
LITERAL_ATTR_RE = re.compile(r"\battribute\s+(\w+)[^;{=]*=\s*(?:-?\d[\w.]*|true|false)\s*(?:\[[^\]]*\])?\s*;")

line_of = lambda c, pos: c.count("\n", 0, pos) + 1


def block_end(c, i):
    depth = 1
    while i < len(c) and depth:
        depth += (c[i] == "{") - (c[i] == "}"); i += 1
    return i


def owner_names(c, end):
    """Short name and name of the element declared right after a prefix annotation that ends at end."""
    while True:
        m = re.match(r"\s*@\s*\w+\s*\{", c[end:])
        if not m: break
        end = block_end(c, end + m.end())
    m = FOLLOWER_RE.match(c, end)
    return {g.strip("'") for g in m.groups() if g} if m else set()


def prefix_meta(c, pos):
    """Metadata names applied as prefix annotations (@Name { ... }) directly before pos."""
    names = set()
    while True:
        s = c[:pos].rstrip()
        if not s.endswith("}"): return names
        depth, i = 0, len(s) - 1
        while i >= 0:
            depth += (s[i] == "}") - (s[i] == "{")
            if depth == 0: break
            i -= 1
        m = re.search(r"@\s*(\w+)\s*$", s[:max(i, 0)])
        if i < 0 or not m: return names
        names.add(m.group(1)); pos = m.start()


def load_registry(path):
    rows, dups = {}, []
    for ln, line in enumerate(pathlib.Path(path).read_text(encoding="utf-8").splitlines(), 1):
        cells = [x.strip() for x in line.strip().strip("|").split("|")]
        if not line.startswith("|") or len(cells) < 6 or cells[0] == "concept" or set(cells[0]) <= set("-: "): continue
        if cells[0] in rows: dups.append((ln, cells[0]))
        rows[cells[0]] = (cells[2], cells[4], ln)
    return rows, dups


def lint(model, registry, cfg):
    P, L = cfg["prefix"], cfg["layers"]
    name_of = {v: k for k, v in L.items()}
    rng = {k: (L[a], L[b]) for k, (a, b) in REL_LAYERS.items()}
    rng["satisfy"] = (cfg["satisfy_min_layer"], max(L.values()))
    out = []
    def add(code, sev, f, line, msg): out.append((code, sev, f"{f}:{line}", msg))

    reg, dup_rows = load_registry(registry)
    for ln, n in dup_rows: add("L2", "ERROR", "REGISTRY.md", ln, f"duplicate Registry concept '{n}'")
    for n, (_, st, ln) in reg.items():
        if st not in STATUSES: add("L2", "ERROR", "REGISTRY.md", ln, f"'{n}' has status '{st}'; allowed: {', '.join(sorted(STATUSES))}")

    info, layer_of, pkg_file, defs = [], {}, {}, collections.defaultdict(list)
    for f in sysml_files(model):
        raw = read(f); c = clean(raw); rel = f.relative_to(model).as_posix()
        pkg = next((n for k, n, _ in top_level(c) if k == "package"), "")
        m = re.match(re.escape(P) + r"(\w+?)_", pkg)
        lay = L.get(m.group(1)) if m else None
        info.append((rel, raw, c, pkg, lay)); layer_of[pkg] = lay; pkg_file[pkg] = rel
        for d in DEF_RE.finditer(c): defs[d.group(1).strip("'")].append((rel, line_of(c, d.start()), pkg))

    for n, places in defs.items():
        f, ln, pkg = places[0]
        if len(places) > 1: add("L2", "ERROR", places[1][0], places[1][1], f"duplicate definition '{n}' (first at {f}:{ln})")
        if n not in reg:
            add("L1", "ERROR" if cfg["registry_enforced"] else "WARNING", f, ln, f"'{n}' is not in REGISTRY.md")
            continue
        home, status, _ = reg[n]
        if home != pkg: add("L2", "ERROR", f, ln, f"'{n}' is registered in '{home}' but defined in '{pkg}'")
        if status in ("retired", "outOfScope"): add("L3", "ERROR", f, ln, f"'{n}' is {status} in REGISTRY.md but defined")
        elif status == "planned": add("L3", "WARNING", f, ln, f"'{n}' is defined; set its Registry status to active")

    graph, goals, scens = {}, [], []
    for rel, raw, c, pkg, lay in info:
        graph[pkg] = set()
        for m in re.finditer(r"(?<![\w'])(" + re.escape(P) + r"\w+)\s*::", c):
            tgt = m.group(1)
            if tgt == pkg: continue
            graph[pkg].add(tgt)
            if lay is not None and layer_of.get(tgt) is not None and layer_of[tgt] > lay:
                add("L4", "ERROR", rel, line_of(c, m.start()), f"{pkg} ({name_of[lay]}) references higher layer {tgt} ({name_of[layer_of[tgt]]})")
        if lay is not None:
            for kind, pat in REL_PATTERNS.items():
                lo, hi = rng[kind]
                if not lo <= lay <= hi:
                    for m in re.finditer(pat, c):
                        add("L5", "ERROR", rel, line_of(c, m.start()), f"{kind} is allowed only in {name_of[lo]}..{name_of[hi]}, not in {pkg} ({name_of[lay]})")
        for m in re.finditer(r"part def\s+(EgasSystem|LogicalEgasSystem)\b[^{]*\{", c):
            for b in BB_RE.finditer(c[m.end():block_end(c, m.end())]):
                add("L6", "ERROR", rel, line_of(c, m.end() + b.start(1)), f"black box {m.group(1)} may only contain port and doc, found '{b.group(1)}'")
        for kind in ("GoalData", "ScenarioData"):
            for m in re.finditer(r"@\s*" + kind + r"\s*\{", c):
                end = block_end(c, m.end()); body, body_raw = c[m.end():end - 1], raw[m.end():end - 1]
                names, ln = owner_names(c, end), line_of(c, m.start())
                if not names: add("L7", "ERROR", rel, ln, f"@{kind} must be written directly before the element it describes")
                if kind == "GoalData":
                    goals.append((names, bool(re.search(r"\bhard\b", body)), rel, ln))
                    continue
                if not all(re.search(k + r"\s*=", body) for k in ("preCondition", "postCondition")):
                    add("L7", "ERROR", rel, ln, "scenario needs preCondition and postCondition (SPES Hint 4-3)")
                fm = re.search(r"fulfills\s*=\s*(\([^)]*\)|\"[^\"]*\")", body_raw)
                scens.append((set(re.findall(r'"([^"]*)"', fm.group(1))) if fm else set(), rel, ln))
        for m in LITERAL_ATTR_RE.finditer(c):
            if not {"SourceRef", "ValueStatus"} <= prefix_meta(c, m.start()):
                add("L8", "ERROR", rel, line_of(c, m.start()), f"attribute '{m.group(1)}' has a literal value without @SourceRef and @ValueStatus")

    state, cyclic = {}, set()
    def visit(n, path):
        state[n] = 1
        for t in graph.get(n, ()):
            if state.get(t) == 1: cyclic.update(path[path.index(t):])
            elif t not in state: visit(t, path + [t])
        state[n] = 2
    for n in list(graph):
        if n not in state: visit(n, [n])
    for n in sorted(cyclic): add("L4", "ERROR", pkg_file.get(n, "model"), 1, f"{n} is part of an import cycle")

    all_goals = set().union(*(g[0] for g in goals)) if goals else set()
    fulfilled = set().union(*(s[0] for s in scens)) if scens else set()
    for ids, rel, ln in scens:
        if not ids: add("L7", "ERROR", rel, ln, "scenario fulfills no goal (SPES Hint 4-2)")
        for i in sorted(ids - all_goals): add("L7", "ERROR", rel, ln, f"scenario fulfills unknown goal '{i}'")
    for names, hard, rel, ln in goals:
        if hard and names and not names & fulfilled:
            add("L7", "ERROR", rel, ln, f"hard goal {sorted(names)} is fulfilled by no scenario (SPES Hint 4-2)")
    return out


def main(argv):
    arg = lambda k, d: pathlib.Path(argv[argv.index(k) + 1]) if k in argv else d
    cfg = json.loads((EGAS2 / "tools" / "kpi_config.json").read_text(encoding="utf-8"))
    out = lint(arg("--model", EGAS2 / "model"), arg("--registry", EGAS2 / "memory" / "REGISTRY.md"), cfg)
    for code, sev, loc, msg in sorted(out, key=lambda o: (o[2], o[0])):
        print(f"{sev:7} {code} {loc}: {msg}")
    errors = sum(o[1] == "ERROR" for o in out)
    print(f"lint: errors: {errors}, warnings: {len(out) - errors}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
