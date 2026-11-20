#!/usr/bin/env python3
"""Read-only acceptance queries (AQ1-AQ8) and diagnostics for egas2/model, answered from the Syside model graph.
  python egas2/tools/trace_query.py [--aq 1,3] [--model DIR] [--out FILE]
  python egas2/tools/trace_query.py --diag      # Syside diagnostics as text, exit 1 on errors
Needs the syside Python package. Rules are not duplicated from lint.py; this script reports, lint.py enforces."""
import re, sys, json, pathlib, collections
from sysml_scan import EGAS2, sysml_files

try:
    import syside
except ImportError:
    sys.exit("trace_query: the 'syside' Python package is required (pip install syside)")

PREFIX = json.loads((EGAS2 / "tools" / "kpi_config.json").read_text(encoding="utf-8"))["prefix"]
SG_META, SR_META, ASIL_BASE = "SafetyGoalData", "SafetyRequirementData", "AsilAllocatedComponent"
DERIVATION_META = {"Derivation", "DerivationMetadata"}
kind = lambda e: type(e).__name__
fmt = lambda xs: ", ".join(sorted(xs)) or "-"
qn = lambda e: str(e.qualified_name)
owned_meta = lambda d: {x.name for mu in d.owned_elements if kind(mu) == "MetadataUsage" for x in mu.definitions}


def layer(e):
    while e is not None and not (kind(e) == "Package" and (e.name or "").startswith(PREFIX)):
        e = e.owner
    m = re.match(re.escape(PREFIX) + r"(\w+?)_", e.name) if e else None
    return m.group(1) if m else None


def tail(f):
    """Element that a feature expression such as a.b.c points at."""
    if f is None: return None
    chain = list(f.chaining_features)
    return chain[-1] if chain else (f.referenced_feature_target or f)


def meta_names(e):
    return {d.name for mu in e.metadata for d in mu.definitions}


class Graph:
    def __init__(self, model):
        n = lambda t: [x for x in model.nodes(t) if layer(x)]
        top = lambda x: kind(x.owner) == "Package"
        self.reqs = [r for r in n(syside.RequirementUsage) if r.name and top(r)]
        self.defs = {qn(d): d for d in n(syside.RequirementDefinition)}
        self.deriv = [(tail(c.source_feature), tail(c.target_features[0])) for c in n(syside.ConnectionUsage) if meta_names(c) & DERIVATION_META]
        self.refine = [(d.sources[0], d.targets[0]) for d in n(syside.Dependency) if "Refinement" in meta_names(d)]
        self.decomp = [(s, d.targets[0]) for d in n(syside.Dependency) if not meta_names(d) and layer(d) == "Fwb" for s in d.sources]
        self.alloc = [(tail(a.source_feature), tail(a.target_features[0])) for a in n(syside.AllocationUsage)]
        self.sat = [(s.satisfied_requirement, tail(s.satisfying_feature)) for s in n(syside.SatisfyRequirementUsage) if s.satisfying_feature]
        self.verify = [(vd, list(vd.verified_requirements)) for vd in n(syside.VerificationCaseDefinition)]
        self.ucs = [u for u in n(syside.UseCaseDefinition) if layer(u) == "Scn"]
        self.parts = n(syside.PartUsage)
        self.metas = [m for m in model.nodes(syside.MetadataUsage) if layer(m)]
        acts = n(syside.ActionUsage)
        self.uf = {qn(a): a for a in acts if layer(a) == "Fbb" and kind(a.owner) == "ActionDefinition"}
        self.fn = {qn(a): a for a in acts if layer(a) == "Fwb" and kind(a.owner) == "ActionUsage"}
        self.lc = {qn(p): p for p in self.parts if layer(p) == "Lwb" and not top(p)}
        self.sg_defs = {q: d for q, d in self.defs.items() if SG_META in owned_meta(d)}
        self.fsr = [r for r in self.reqs if layer(r) == "Shr" and (d := self.defn(r)) is not None and layer(d) == "Shr" and SR_META in owned_meta(d)]
        self.sysr = [r for r in self.reqs if layer(r) == "Sysr" and layer(self.defn(r)) == "Sysr"]

    def defn(self, u):
        return next((d for d in u.definitions if layer(d)), None)

    def sg_of(self, u):
        """Safety goal definitions that the type of usage u is or specializes."""
        d = self.defn(u)
        return {q for q, s in self.sg_defs.items() if d is not None and (qn(d) == q or d.specializes(s))}

    def parents(self, u):
        return [a for a, b in self.deriv if a and b and qn(b) == qn(u)]

    def root_sgs(self, u, seen=None):
        """Safety goals reached from u by walking derivations upward; types specializing a goal count as that goal."""
        seen = seen if seen is not None else set()
        if qn(u) in seen: return set()
        seen.add(qn(u))
        out = {self.sg_defs[q].name for q in self.sg_of(u)}
        for p in self.parents(u): out |= self.root_sgs(p, seen)
        return out


def satisfiers(g, req, lay):
    return {b.name for a, b in g.sat if a and qn(a) == qn(req) and b and layer(b) == lay}


def aq1(g):
    rows = []
    for sg in sorted(g.sg_defs.values(), key=lambda d: d.name):
        fs = {qn(r): r for r in g.fsr if sg.name in g.root_sgs(r)}
        sy = {qn(r): r for r in g.sysr if sg.name in g.root_sgs(r)}
        uf = {qn(b) for a, b in g.sat if a and qn(a) in fs.keys() | sy.keys() and b and layer(b) == "Fbb"}
        fn = {qn(f) for f, u in g.decomp if qn(u) in uf}
        lc = {qn(b) for a, b in g.sat if a and qn(a) in sy and b and qn(b) in g.lc}
        lc |= {qn(l) for f, l in g.alloc if f and l and qn(f) in fn | uf and qn(l) in g.lc}
        names = lambda keys: fmt(g.lc[k].name for k in keys)
        rows.append((f"AQ1 {sg.name}", f"FSR {len(fs)}, SYSR {len(sy)}, UF {len(uf)}/{len(g.uf)}, FN {len(fn)}/{len(g.fn)}, LC {len(lc)}/{len(g.lc)}",
                     f"LC: {names(lc)}", f"LC not reached: {names(set(g.lc) - lc)}"))
    return rows


def aq2(g):
    rows = []
    for lc in sorted(g.lc.values(), key=lambda p: p.name):
        sy = [r for r in g.sysr if lc.name in satisfiers(g, r, "Lwb")]
        sgs = set().union(*(g.root_sgs(r) for r in sy)) if sy else set()
        rows.append((f"AQ2 {lc.name}", f"SYSR {len(sy)}", fmt(r.name for r in sy), f"SG: {fmt(sgs)}"))
    rows.append(("AQ2 totals", f"satisfy by LC {sum(1 for a, b in g.sat if b and qn(b) in g.lc)}", f"derivation {len(g.deriv)}", ""))
    return rows


def aq3(g):
    uf_sat = {qn(b) for a, b in g.sat if b and layer(b) == "Fbb"}
    lc_sat = {qn(b) for a, b in g.sat if b and qn(b) in g.lc}
    fn_done = {qn(f) for f, u in g.decomp} & {qn(f) for f, l in g.alloc if f}
    names = lambda keys, pool: fmt(pool[k].name for k in keys)
    return [("AQ3", f"UF {len(g.uf)}, LC {len(g.lc)}, FN {len(g.fn)}",
             f"UF without satisfy: {names(set(g.uf) - uf_sat, g.uf)}; LC without satisfy: {names(set(g.lc) - lc_sat, g.lc)}",
             f"FN without UF or LC link: {names(set(g.fn) - fn_done, g.fn)}")]


def aq4(g):
    no_shr, no_beh, with_fsr = [], [], 0
    fsr_names = {qn(r) for r in g.fsr}
    for r in g.sysr:
        lays = {"FSR" if qn(a) in fsr_names else layer(g.defn(a) or (a.definitions[0] if a.definitions else a)) for a in g.parents(r)}
        if "Shr" not in lays: no_shr.append(r.name)
        if "Beh" not in lays: no_beh.append(r.name)
        with_fsr += "FSR" in lays
    return [("AQ4", f"SYSR {len(g.sysr)}, without SHR parent {len(no_shr)}, with FSR parent {with_fsr}", f"without SHR: {fmt(no_shr)}", f"without Beh parent: {fmt(no_beh)}")]


def aq5(g, model):
    base = next((d for d in model.nodes(syside.PartDefinition) if d.name == ASIL_BASE), None)
    attr = next((f for f in base.owned_features if f.name == "asil"), None) if base else None
    ref = getattr(attr.feature_value_expression, "referent", None) if attr else None
    ref = getattr(ref.feature_value_expression, "referent", None) or ref if ref is not None else None
    lcs = [p for p in g.lc.values() if base and any(d is base or d.specializes(base) for d in p.definitions)]
    mech = {p.name for p in g.lc.values() for d in p.definitions if "SafetyMechanism" in meta_names(d)}
    is_ = lambda m, name: name in {d.name for d in m.definitions}
    fm = [m.owner.name for m in g.metas if is_(m, "FailureMode")]
    ind = [f"{m.owner.name} demonstrated={next((f.feature_value_expression.value for f in m.owned_features if f.name == 'demonstrated'), None)}"
           for m in g.metas if is_(m, "IndependenceConstraint")]
    return [("AQ5", f"LC with ASIL {len(lcs)}/{len(g.lc)} (asil = {ref.name if ref else 'n/a'})",
             f"mechanisms: {fmt(mech)}; FailureMode: {fmt(fm)}", f"independence: {fmt(ind)}")]


def aq6(g):
    covered = {qn(d) for vd, rs in g.verify for r in rs for d in r.definitions if layer(d)}
    val_covered = {qn(d) for vd, rs in g.verify if layer(vd) == "Val" for r in rs for d in r.definitions if layer(d)}
    sysr_missing = [r.name for r in g.sysr if qn(g.defn(r)) not in covered]
    fsr_defs = {qn(g.defn(r)): g.defn(r) for r in g.fsr}
    fsr_missing = [d.name for q, d in fsr_defs.items() if q not in covered]
    shr_defs = [d for q, d in g.defs.items() if layer(d) == "Shr" and q not in g.sg_defs and q not in fsr_defs]
    shr_missing = [d.name for d in shr_defs if qn(d) not in val_covered]
    return [("AQ6", f"FSR verified {len(fsr_defs) - len(fsr_missing)}/{len(fsr_defs)}, SYSR verified {len(g.sysr) - len(sysr_missing)}/{len(g.sysr)}, SHR validated {len(shr_defs) - len(shr_missing)}/{len(shr_defs)}",
             f"FSR without verification: {fmt(fsr_missing)}; SYSR without verification: {fmt(sysr_missing)}", f"SHR without validation: {fmt(shr_missing)}; SG has no direct verify, it is covered through its FSRs")]


def aq7(g):
    sysr = {qn(r) for r in g.sysr}
    rows = []
    for uc in sorted(g.ucs, key=lambda u: u.name):
        targets = [t for s, t in g.refine if qn(s) == qn(uc)]
        sy = [t for t in targets if qn(t) in sysr]
        lc = {x for t in sy for x in satisfiers(g, t, "Lwb")}
        rows.append((f"AQ7 {uc.name}", f"refines {len(targets)}, SYSR {len(sy)}", f"SYSR: {fmt(t.name for t in sy)}", f"LC: {fmt(lc)}"))
    return rows


def aq8(model):
    ctx = next((d for d in model.nodes(syside.PartDefinition) if d.name == "EgasContext"), None)
    if ctx is None: return [("AQ8", "EgasContext not found", "", "")]
    egas = next(p for p in ctx.owned_features if kind(p) == "PartUsage" and any(d.name == "EgasSystem" for d in p.definitions))
    ports = {f.name for f in egas.definitions[0].owned_features if kind(f) == "PortUsage"}
    links, connected = collections.defaultdict(set), set()
    for c in ctx.owned_features:
        if kind(c) != "ConnectionUsage": continue
        ends = [list(f.chaining_features) for f in c.related_features]
        for mine, other in (ends, ends[::-1]):
            if len(mine) == 2 and mine[0].name == egas.name:
                connected.add(mine[1].name); links[other[0].name].add(f"{other[1].name}->{mine[1].name}")
    return [("AQ8", f"actors {len(links)}, EgasSystem ports {len(connected)}/{len(ports)} connected",
             "; ".join(f"{k}: {fmt(v)}" for k, v in sorted(links.items())), f"ports without actor: {fmt(ports - connected)}")]


def diagnostics(diags):
    for d in diags.all:
        msg = re.sub(r", expected one of \[.*$", ", ...", d.message)[:200]
        print(f"{str(d.severity).split('.')[-1]:7} {d.code} {d.filename}:{d.line}:{d.col}: {msg}")
    errors = sum(1 for _ in diags.errors)
    print(f"diagnostics: errors {errors}, warnings {sum(1 for _ in diags.warnings)}")
    return errors


def main(argv):
    arg = lambda k, d: argv[argv.index(k) + 1] if k in argv else d
    model, diags = syside.try_load_model(paths=[str(f) for f in sysml_files(pathlib.Path(arg("--model", EGAS2 / "model")))])
    if "--diag" in argv:
        return 1 if diagnostics(diags) else 0
    g = Graph(model)
    run = {1: aq1, 2: aq2, 3: aq3, 4: aq4, 5: lambda g: aq5(g, model), 6: aq6, 7: aq7, 8: lambda g: aq8(model)}
    rows = [r for n in arg("--aq", "1,2,3,4,5,6,7,8").split(",") for r in run[int(n)](g)]
    text = "\n".join(["| query | result | evidence | gaps |", "|---|---|---|---|"] + ["| " + " | ".join(r) + " |" for r in rows])
    if "--out" in argv: pathlib.Path(arg("--out", "")).write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
