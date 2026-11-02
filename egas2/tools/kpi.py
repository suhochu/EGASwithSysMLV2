#!/usr/bin/env python3
"""Drift KPIs for the egas2 pilot. Cheap: no AI, compact output (about 25 lines).
  python egas2/tools/kpi.py --task T05 --ide-errors 0 [--gate] [--no-write]
  --ide-errors N : number of Syside diagnostics (errors) in egas2/model, read from the agent's diagnostics tool or the
                   Problems panel. Omitted = WARN (FAIL with --gate). N>0 = HARD.
Writes egas2/memory/KPI_SNAPSHOT.md (overwritten) and appends a row to egas2/memory/KPI_LOG.csv.
Exit code 1 when a HARD KPI fails (with --gate every WARN also fails)."""
import re, sys, json, csv, hashlib, subprocess, datetime, collections, pathlib
from sysml_scan import repo_root, sysml_files, clean, top_level, read, EGAS2

args = sys.argv[1:]
if "--task" not in args:
    print("usage: python egas2/tools/kpi.py --task T00 --ide-errors 0   (--task is required; nothing was written)")
    sys.exit(2)
task = args[args.index("--task") + 1]
gate, write = "--gate" in args, "--no-write" not in args
ide = int(args[args.index("--ide-errors") + 1]) if "--ide-errors" in args else None
root = repo_root(); egas2 = EGAS2; mem = egas2 / "memory"
cfg = json.loads((egas2 / "tools" / "kpi_config.json").read_text(encoding="utf-8"))
P, L = cfg["prefix"], cfg["layers"]
files = sysml_files(egas2 / "model")
hard, warn, kv = [], [], {}
rel = lambda p: p.relative_to(root).as_posix()

# ---- scan new model
lines_by, defs_by, file_layer, pkg_layer, imports = collections.Counter(), collections.Counter(), {}, {}, collections.defaultdict(set)
names = collections.defaultdict(set); unknown = []
for f in files:
    raw = read(f); c = clean(raw)
    pk = [n for k, n, _ in top_level(c) if k == "package"]
    lay = None
    for n in pk:
        m = re.match(re.escape(P) + r"(\w+?)_", n)
        if m and m.group(1) in L: lay = m.group(1); pkg_layer[n] = lay
        else: unknown.append(f"{rel(f)}:{n}")
    file_layer[f] = lay
    live = [l for l in c.split("\n") if l.strip()]
    if lay:
        lines_by[lay] += len(live)
        defs_by[lay] += sum(1 for l in live if re.search(r"\bdef\s+(?:<[^>]*>\s*)?['\w]", l))
    for n in pk:
        imports[n] |= set(re.findall(r"(?<![\w'])(" + re.escape(P) + r"\w+)\s*::", c))
    for m in re.finditer(r"\b(?:\w+ )?def\s+(?:<[^>]*>\s*)?('[^']+'|\w+)", c):
        names[m.group(1).strip("'")].add(rel(f))
# ---- K1/K2 size
tot_lines, tot_budget = sum(lines_by.values()), sum(cfg["budget_lines"].values())
for lay, b in cfg["budget_lines"].items():
    n = lines_by[lay]
    if n > b * cfg["hard_over_ratio"]: hard.append(f"K1 {lay} lines {n} > {int(b * cfg['hard_over_ratio'])}")
    elif n > b: warn.append(f"K1 {lay} lines {n} > budget {b}")
    d, db = defs_by[lay], cfg["budget_defs"][lay]
    if d > db * cfg["hard_over_ratio"]: hard.append(f"K2 {lay} defs {d} > {int(db * cfg['hard_over_ratio'])}")
    elif d > db: warn.append(f"K2 {lay} defs {d} > budget {db}")
kv["lines"], kv["defs"] = tot_lines, sum(defs_by.values())
# ---- K3 namespace + layer direction + cycles
r = subprocess.run([sys.executable, str(egas2 / "tools" / "check_namespace.py")], capture_output=True, text=True)
m = re.search(r"errors: (\d+)", r.stdout); ns_err = int(m.group(1)) if m else 99
if ns_err: hard.append(f"K3 namespace errors {ns_err} (run check_namespace.py)")
if unknown: hard.append(f"K3 packages without layer token: {', '.join(unknown[:3])}")
up = [f"{a}->{b}" for a, ts in imports.items() for b in ts
      if a in pkg_layer and b in pkg_layer and L[pkg_layer[b]] > L[pkg_layer[a]]]
if up: hard.append(f"K3 upward imports {len(up)}: {', '.join(up[:3])}")
idx, low, st, on, cyc, n_ = {}, {}, [], set(), 0, [0]
def sc(v):
    global cyc
    idx[v] = low[v] = n_[0]; n_[0] += 1; st.append(v); on.add(v)
    for w in imports.get(v, ()):
        if w not in pkg_layer: continue
        if w not in idx: sc(w); low[v] = min(low[v], low[w])
        elif w in on: low[v] = min(low[v], idx[w])
    if low[v] == idx[v]:
        comp = []
        while True:
            w = st.pop(); on.discard(w); comp.append(w)
            if w == v: break
        if len(comp) > 1: cyc += 1
for v in list(pkg_layer):
    if v not in idx: sc(v)
if cyc: hard.append(f"K3 import cycles {cyc}")
# ---- K4 duplicates / registry
dups = [n for n, fs in names.items() if len(fs) > 1]
if dups: hard.append(f"K4 duplicate definitions {len(dups)}: {', '.join(dups[:4])}")
reg = (mem / "REGISTRY.md").read_text(encoding="utf-8") if (mem / "REGISTRY.md").exists() else ""
unreg = [n for n in names if n not in reg]
(hard if cfg["registry_enforced"] else warn).append(f"K4 defs not in REGISTRY {len(unreg)}") if unreg else None
# ---- K5 literals outside Common, K6 purity
lit = sat = tags = bb = 0
for f in files:
    raw = read(f); c = clean(raw); lay = file_layer[f]
    if lay != "Common": lit += len(re.findall(r"\d+(?:\.\d+)?\s*\[[^\]]+\]", c))
    if lay is not None and L[lay] < cfg["satisfy_min_layer"]: sat += len(re.findall(r"\bsatisfy\b", c))
    tags += sum(len(re.findall(p, raw)) for p in cfg["history_tag_patterns"])
    for mm in re.finditer(r"part def\s+(EgasSystem|LogicalEgasSystem)\b[^{]*\{", c):
        depth, i = 1, mm.end()
        while i < len(c) and depth:
            depth += (c[i] == "{") - (c[i] == "}"); i += 1
        bb += len(re.findall(r"^\s*(?:part|perform|action|state|exhibit|assert)\b", c[mm.end():i], re.M))
for k, v, t in (("K5 numeric literals outside Common", lit, hard), ("K6 satisfy below layer 10", sat, hard),
                ("K6 history tags in comments", tags, hard), ("K6 black-box impurity", bb, hard)):
    if v: t.append(f"{k}: {v}")
# ---- K7 migration + legacy untouched
rows = []
mp = mem / "MIGRATION_MAP.csv"
if mp.exists(): rows = list(csv.reader(mp.open(encoding="utf-8", newline="")))[1:]
frows = [x for x in rows if len(x) > 3 and x[1] == "*"]
mapped = sum(1 for x in frows if x[3] != "unmapped"); ratio = mapped / len(frows) if frows else 0.0
need = max([v for k, v in cfg["migration_curve"].items() if k <= task] or [0.0])
if ratio + 1e-9 < need: warn.append(f"K7 migration {ratio:.0%} < curve {need:.0%}")
hp = mem / "LEGACY_HASHES.json"; changed = []
if hp.exists():
    for p, h in json.loads(hp.read_text(encoding="utf-8")).items():
        if pathlib.Path(p).name in cfg.get("legacy_ignore", []): continue
        fp = root / p
        if not fp.exists() or hashlib.sha1(fp.read_bytes()).hexdigest() != h: changed.append(p)
    if changed and task != "T23":
        hard.append(f"K7 legacy files modified/missing {len(changed)}: {changed[0]} (legitimate edit? run legacy_inventory.py --rebaseline and log it in DECISIONS.md)")
kv["migrated"] = f"{ratio:.0%}"
# ---- K8 safety values
stat = collections.Counter(); srcref = 0
for f in files:
    c = clean(read(f))
    stat.update(x.lower() for x in re.findall(cfg["status_pattern"], c) if x.lower() in ("standard", "project", "pilotassumed", "tbd", "reviewed")); srcref += len(re.findall(cfg["sourceref_pattern"], c))
dec = (mem / "DECISIONS.md").read_text(encoding="utf-8") if (mem / "DECISIONS.md").exists() else ""
approvals = len(re.findall(r"^\|\s*A-\d+", dec, re.M))
if stat["reviewed"] and not approvals: hard.append(f"K8 status=reviewed used {stat['reviewed']}x but DECISIONS.md has no A-xx approval rows")
if stat["standard"] > srcref: warn.append(f"K8 status=standard {stat['standard']} > SourceRef {srcref}")
kv["status"] = "/".join(f"{k}:{stat[k]}" for k in ("standard", "project", "pilotassumed", "tbd", "reviewed"))
# ---- K9 context footprint
res = [root / p for p in cfg["resident_files"]]
ho = sorted((mem / "handoffs").glob("T*.md")); card = egas2 / "tasks" / f"{task}.md"
res += ho[-1:] + ([card] if card.exists() else [])
byt = sum(p.stat().st_size for p in res if p.exists()); kv["resident_bytes"] = byt
if byt > cfg["limits"]["resident_bytes"]: hard.append(f"K9 resident context {byt}B > {cfg['limits']['resident_bytes']}B")
nl = lambda p: len(p.read_text(encoding="utf-8").split("\n")) if p.exists() else 0
for p, key in ((mem / "STATE.md", "state_lines"), (ho[-1] if ho else None, "handoff_lines"), (card, "card_lines")):
    if p and nl(p) > cfg["limits"][key]: hard.append(f"K9 {p.name} {nl(p)} lines > {cfg['limits'][key]}")
# ---- K15 orphan definitions: defined in a chain layer but named in no relationship statement
blob = "\n".join(clean(read(f)) for f in files)
rel = "\n".join(m.group(0) for m in re.finditer(r"\b(?:dependency|satisfy|allocation|allocate|verify|frame)\b[^;{]*[;{]", blob))
rel += "\n" + "\n".join(re.findall(r"\bdef\s+\w+\s*:>\s*[\w:]+", blob))
usages = collections.defaultdict(set)
for m in re.finditer(r"\b(\w+)\s*:\s*(\w+)\s*[;{=]", blob): usages[m.group(2)].add(m.group(1))
orph = []
for f in files:
    if file_layer[f] not in cfg["orphan_check_layers"]: continue
    c = clean(read(f))
    for m in re.finditer(r"\b(?:requirement|use case|state|action|concern|part) def\s+(\w+)", c):
        nm = m.group(1)
        if nm in ("EgasSystem", "LogicalEgasSystem"): continue
        if not any(re.search(r"\b" + re.escape(x) + r"\b", rel) for x in {nm} | usages[nm]): orph.append(nm)
if orph: warn.append(f"K15 orphan definitions {len(orph)}: {', '.join(orph[:5])}")
kv["orphans"] = len(orph)
# ---- K14 IDE diagnostics
if ide is None: warn.append("K14 IDE diagnostics not reported (pass --ide-errors N)")
elif ide > 0: hard.append(f"K14 IDE diagnostics errors: {ide}")
kv["ide"] = "n/a" if ide is None else ide
# ---- trend
logp = mem / "KPI_LOG.csv"; prev = None
if logp.exists():
    old = list(csv.reader(logp.open(encoding="utf-8", newline="")))[1:]
    prev = int(old[-1][2]) if old and old[-1][2].isdigit() else None
if prev and tot_lines > prev * cfg["growth_warn_ratio"] and tot_lines - prev > 100:
    warn.append(f"TREND lines {prev} -> {tot_lines} (+{tot_lines / prev - 1:.0%})")
# ---- output
status = "FAIL" if hard or (gate and warn) else ("WARN" if warn else "PASS")
out = [f"# KPI_SNAPSHOT ({task}, {datetime.date.today()}) {status}",
       f"- lines {tot_lines}/{tot_budget}, defs {kv['defs']}, migrated {kv['migrated']}, status {kv['status']}, resident {byt}B, ide errors {kv['ide']}",
       "- by layer (lines/budget): " + ", ".join(f"{k}:{lines_by[k]}/{v}" for k, v in cfg["budget_lines"].items() if lines_by[k] or v and False)]
out += [f"- HARD {h}" for h in hard] + [f"- WARN {w}" for w in warn]
if not hard and not warn: out.append("- no alerts")
out.append("- manual at gates: K10 Golden Path chain, K11 AQ answerable, K12 charter alignment, K13 cost vs baseline (see KPI.md)")
text = "\n".join(out); print(text)
if write:
    (mem / "KPI_SNAPSHOT.md").write_text(text + "\n", encoding="utf-8")
    new = not logp.exists()
    with logp.open("a", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh, lineterminator="\n")
        if new: w.writerow(["task", "date", "lines", "defs", "migrated", "hard", "warn", "resident_bytes", "ide_errors"])
        w.writerow([task, datetime.date.today(), tot_lines, kv["defs"], kv["migrated"], len(hard), len(warn), byt, kv["ide"]])
sys.exit(1 if status == "FAIL" else 0)