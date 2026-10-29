#!/usr/bin/env python3
"""EGAS2 namespace guard. Run from anywhere inside the repository.

Why: SysML v2 shares one global namespace across all loaded files; duplicate top-level names make
name resolution ambiguous. The new model (egas2/model) must never collide with the legacy model.

Checks (exit code 1 if any ERROR):
  N1 top-level package names under egas2/model start with PREFIX
  N2 top-level names are unique inside egas2/model
  N3 no collision with legacy top-level package names
  N4 no collision with SysML standard-library root packages
  N5 new files never reference legacy packages (X::), legacy files never reference new packages
  N6 no loose top-level elements outside a package in new files
  N7 (warning) more than one top-level package in a file
  N8 (warning) .sysml/.kerml files under egas2/archive would be loaded by the language server
"""
import re, sys, collections, pathlib
from sysml_scan import PREFIX, STDLIB, repo_root, sysml_files, clean, top_level, read, EGAS2

root = repo_root()
egas2 = EGAS2
new_files = sysml_files(egas2 / "model")
legacy_files = sysml_files(root, skip_under=egas2)
errors, warns = [], []
rel = lambda p: p.relative_to(root).as_posix()

def scan(files):
    info = {}
    for f in files:
        c = clean(read(f))
        info[f] = (c, top_level(c))
    return info

new, old = scan(new_files), scan(legacy_files)
old_names = collections.defaultdict(list)
for f, (_, tl) in old.items():
    for kind, name, line in tl:
        if kind == "package":
            old_names[name].append(f"{rel(f)}:{line}")
new_names = collections.defaultdict(list)
for f, (c, tl) in new.items():
    pk = [t for t in tl if t[0] == "package"]
    for kind, name, line in tl:
        if kind == "package":
            new_names[name].append(f"{rel(f)}:{line}")
            if not name.startswith(PREFIX):
                errors.append(f"{rel(f)}:{line}: N1 package '{name}' must start with '{PREFIX}'")
            if name in STDLIB:
                errors.append(f"{rel(f)}:{line}: N4 package '{name}' collides with a standard-library package")
            if name in old_names:
                errors.append(f"{rel(f)}:{line}: N3 package '{name}' also defined in legacy at {old_names[name][0]}")
        elif kind == "other":
            errors.append(f"{rel(f)}:{line}: N6 top-level element outside a package: '{name}'")
    if len(pk) > 1:
        warns.append(f"{rel(f)}: N7 {len(pk)} top-level packages in one file (keep one)")
for name, locs in new_names.items():
    if len(locs) > 1:
        errors.append(f"N2 package '{name}' defined {len(locs)} times: " + ", ".join(locs))

def refs(cleaned, names):
    hits = []
    for nm in names:
        for m in re.finditer(r"(?<![\w'])'?" + re.escape(nm) + r"'?\s*::", cleaned):
            hits.append((nm, cleaned[:m.start()].count("\n") + 1))
    return hits

for f, (c, _) in new.items():
    for nm, line in refs(c, old_names):
        errors.append(f"{rel(f)}:{line}: N5 references legacy package '{nm}'")
legacy_visible = [n for n in new_names if n not in old_names and n not in STDLIB]
for f, (c, _) in old.items():
    for nm, line in refs(c, legacy_visible):
        errors.append(f"{rel(f)}:{line}: N5 legacy file references new package '{nm}'")
for f in sysml_files(egas2 / "archive"):
    warns.append(f"{rel(f)}: N8 rename to '.sysml.archived' so the language server does not load it")

LIMIT = None if "--all" in sys.argv else 25
for w in warns[:LIMIT]: print("WARN ", w)
for e in errors[:LIMIT]: print("ERROR", e)
if LIMIT and len(errors) > LIMIT: print(f"... {len(errors) - LIMIT} more errors (use --all)")
print(f"new files: {len(new_files)}, legacy files: {len(legacy_files)}, "
      f"new packages: {len(new_names)}, legacy packages: {len(old_names)}, "
      f"errors: {len(errors)}, warnings: {len(warns)}")
sys.exit(1 if errors else 0)
