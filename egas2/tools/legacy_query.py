#!/usr/bin/env python3
"""Cheap lookups in the legacy model so the agent never has to read whole legacy files.
  python egas2/tools/legacy_query.py list [path-substring]    top-level packages and defs per file
  python egas2/tools/legacy_query.py show NAME [--max 80]     declaration(s) named NAME with their body
  python egas2/tools/legacy_query.py grep REGEX [--max 50]    matching live (non-comment) lines
"""
import re, sys
from sysml_scan import repo_root, sysml_files, clean, read, EGAS2

root = repo_root(); egas2 = EGAS2
files = sysml_files(root, skip_under=egas2)
args = sys.argv[1:]
if not args:
    print(__doc__); sys.exit(2)
cmd, rest = args[0], args[1:]
limit = 80 if cmd == "show" else 50
if "--max" in rest:
    i = rest.index("--max"); limit = int(rest[i + 1]); rest = rest[:i] + rest[i + 2:]
rel = lambda f: f.relative_to(root).as_posix()
DEF = re.compile(r"^\s*(?:(?:abstract|private|public|protected|variation|ref)\s+)*"
                 r"(package|[a-z]+(?: [a-z]+)? def|part|item|action|state|port|attribute|requirement|constraint|calc|"
                 r"verification|use case|concern|viewpoint|view|enum|metadata|occurrence|interface|connection|flow|"
                 r"allocation|analysis|case)\s+(?:<[^>]*>\s*)?('[^']*'|\w+)")

if cmd == "list":
    sub = rest[0] if rest else ""
    for f in files:
        if sub not in rel(f): continue
        c = clean(read(f)).split("\n")
        items = []
        for no, l in enumerate(c, 1):
            m = DEF.match(l)
            if m and (m.group(1) == "package" or m.group(1).endswith("def")):
                items.append(f"{no}:{m.group(1)} {m.group(2).strip(chr(39))}")
        print(f"## {rel(f)} ({len(c)} lines)"); print("  " + "\n  ".join(items) if items else "  (no definitions)")
elif cmd == "show":
    name = rest[0]; found = 0
    for f in files:
        raw = read(f).split("\n"); c = clean("\n".join(raw)).split("\n")
        for no, l in enumerate(c):
            m = DEF.match(l)
            if m and m.group(2).strip("'") == name:
                found += 1; depth, end = 0, no
                for j in range(no, len(c)):
                    depth += c[j].count("{") - c[j].count("}")
                    end = j
                    if depth <= 0 and ("{" in "".join(c[no:j + 1]) or ";" in c[j]): break
                print(f"--- {rel(f)}:{no + 1}-{end + 1}")
                print("\n".join(raw[no:min(end + 1, no + limit)]))
                if end + 1 - no > limit: print(f"... ({end + 1 - no - limit} more lines)")
    if not found: print(f"no declaration named {name}")
elif cmd == "grep":
    rx = re.compile(rest[0]); n = 0
    for f in files:
        c = clean(read(f)).split("\n"); raw = read(f).split("\n")
        for no, l in enumerate(c):
            if rx.search(l):
                print(f"{rel(f)}:{no + 1}: {raw[no].strip()[:160]}"); n += 1
                if n >= limit: print("... limit reached"); sys.exit(0)
else:
    print(__doc__); sys.exit(2)
