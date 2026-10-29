"""Shared helpers for the egas2 tools: repo discovery and a light SysML v2 scanner.
The scanner is regex based (no full parser): good enough for namespace checks and lookups."""
import re, sys, pathlib

for _s in (sys.stdout, sys.stderr):   # Korean text on Windows consoles
    try: _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception: pass

EGAS2 = pathlib.Path(__file__).resolve().parents[1]   # the egas2/ folder, wherever it sits

PREFIX = "EgasArch_"          # every top-level package under egas2/model must start with this
SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", ".vscode", ".github"}
EXTS = (".sysml", ".kerml")

# Best-effort list of SysML v2 / KerML standard-library root packages.
STDLIB = set("""Base ScalarValues Collections Occurrences Objects Items Parts Ports Connections Interfaces
Allocations Actions Calculations Constraints Requirements Cases AnalysisCases VerificationCases UseCases States
Metadata ModelingMetadata RiskMetadata ParametersOfInterestMetadata ImageMetadata Views StandardViewDefinitions
SysML KerML Performances Transfers Observation Clocks Time ISQ ISQBase ISQSpaceTime ISQMechanics
ISQThermodynamics ISQElectromagnetism ISQLight ISQAcoustics ISQAtomicNuclear ISQCondensedMatter
ISQChemistryMolecular ISQInformation SI SIPrefixes USCustomaryUnits MeasurementReferences Quantities
QuantityCalculations VectorCalculations VectorFunctions NumericalFunctions RealFunctions IntegerFunctions
NaturalFunctions RationalFunctions ComplexFunctions ScalarFunctions BaseFunctions TrigFunctions
SequenceFunctions CollectionFunctions ControlFunctions DataFunctions OccurrenceFunctions Triggers
SampledFunctions Metaobjects KerMLSemantics SpatialItems ShapeItems UnitsAndScales Links Associations
BindingConnectors AnalysisTooling TradeStudies CauseAndEffect Geometry Systems""".split())


def repo_root(start=None):
    p = pathlib.Path(start).resolve() if start else EGAS2
    for q in [p] + list(p.parents):
        if (q / ".git").exists():
            return q
    return EGAS2.parent


def sysml_files(base, skip_under=None):
    out = []
    for p in sorted(pathlib.Path(base).rglob("*")):
        if not p.is_file() or not p.name.endswith(EXTS):
            continue
        rel = p.relative_to(base).parts
        if any(part in SKIP_DIRS for part in rel):
            continue
        if skip_under and skip_under in p.parents:
            continue
        out.append(p)
    return out


def clean(text):
    """Blank out comments and double-quoted strings, keep newlines so line numbers still match."""
    out, i, n = [], 0, len(text)
    while i < n:
        c, d = text[i], text[i:i + 2]
        if d == "//":
            j = text.find("\n", i); j = n if j < 0 else j
            out.append(" " * (j - i)); i = j
        elif d == "/*":
            j = text.find("*/", i + 2); j = n if j < 0 else j + 2
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j
        else:
            out.append(c); i += 1
    return "".join(out)


PKG_RE = re.compile(r"^\s*(?:(?:standard|library|private|public|protected)\s+)*package\s+(?:<[^>]*>\s*)?('[^']*'|[A-Za-z_]\w*)")


def top_level(cleaned):
    """Return [(kind, name, line)] for statements at brace depth 0. kind: 'package', 'import', 'other'."""
    depth, start, res = 0, 0, []
    for i, ch in enumerate(cleaned):
        if ch == "{":
            if depth == 0:
                res.append((start, cleaned[start:i]))
            depth += 1
        elif ch == "}":
            depth = max(depth - 1, 0)
            if depth == 0:
                start = i + 1
        elif ch == ";" and depth == 0:
            res.append((start, cleaned[start:i])); start = i + 1
    out = []
    for off, hdr in res:
        s = hdr.strip()
        if not s:
            continue
        line = cleaned[:off + len(hdr) - len(hdr.lstrip())].count("\n") + 1
        m = PKG_RE.match(hdr)
        if m:
            out.append(("package", m.group(1).strip("'"), line))
        elif re.match(r"^(?:(?:private|public|protected)\s+)?import\b", s):
            out.append(("import", s, line))
        else:
            out.append(("other", s.split("\n")[0][:60], line))
    return out


def read(p):
    return pathlib.Path(p).read_text(encoding="utf-8-sig", errors="replace")   # utf-8-sig: files with BOM
