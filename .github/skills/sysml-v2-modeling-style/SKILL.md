---
name: sysml-v2-modeling-style
description: "Use when creating or reviewing EGAS SysML v2 models, Common catalogs, metadata, package imports, or value provenance."
---

# EGAS SysML v2 Modeling Style

- Keep one top-level `EgasArch_<Layer>_<Name>` package per model file; put no definitions outside it.
- Import only lower layers. Same-layer Common packages may depend on one another, but avoid cycles.
- Place reusable quantities and numeric catalogs in `EgasArch_Common_*`; do not redefine standard-library quantity types.
- Register each new part, item, action, enum, or requirement in `egas2/memory/REGISTRY.md` before defining it.
- Give numeric values a `SourceRef` and a `ValueStatus`; keep unsupported safety values `pilotAssumed` or `tbd`, never `standard`.
- `ValueStatusKind::Standard` is the Common enum literal; KPI status counting normalizes it to the lowercase report key `standard`.
- Model FIT as a frequency quantity and use the Common conversion factor `1 FIT = 1e-9 failures/hour`; do not treat it as a numeric safety target.
- Keep enum and metadata names distinct because the SysML namespace is shared. In Common, `ValueStatusKind` is the enum and `ValueStatus` is metadata.
- Existing legacy syntax uses `enum def Name { enum Member; }`, qualified enum literals, and `@Metadata { feature = value; }`. Treat new type combinations as provisional until SysIDE reports no diagnostics.
- Run `python egas2/tools/check_namespace.py` after adding model files. Do not copy legacy package names or create upward imports.
