---
name: legacy-distiller
description: "Use when deciding whether a legacy SysML element is kept, merged, demoted, deleted, or rebuilt in egas2, and when logging the decision in MIGRATION_MAP.csv."
---

# legacy-distiller

Look up legacy elements only with `python egas2/tools/legacy_query.py list|show|grep --max N`. Never read a legacy file whole.

| Verdict | Use when                                                                                                                     | Action                                                                                |
| ------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| keep    | The element is in scope (D-05), uses the new vocabulary (D-06), and fits one layer                                           | Copy into the new package, rename to the layer package, register in REGISTRY.md       |
| merge   | Several legacy elements say the same thing (duplicate enums, repeated SHR)                                                   | One new element; list every old name in the Registry `legacy names` column            |
| rebuild | The idea is in scope but the legacy structure breaks a rule (L4 import cycle, `satisfy` in a scenario, parts in a black box) | Write a new element from the intent; cite the legacy name only as `legacy names`      |
| demote  | Detailed behavior outside the Golden Paths (D-03)                                                                            | Move the text to `egas2/archive/*.sysml.archived`; one group row in MIGRATION_MAP.csv |
| delete  | Out of scope (D-05) or obsolete                                                                                              | One group row with the reason                                                         |

## Checks before a verdict

1. Search the Registry and the legacy for the concept first (concept-registry-guard).
2. Does the legacy element exist at all? In T04 the GP-A chain had almost no legacy counterpart, so most of it was new. Say "new" instead of forcing a legacy mapping.
3. Do not import or reference a legacy package. Keep the name only in the Registry.
4. Set a file-level `*` row in MIGRATION_MAP.csv to a verdict only when the whole file is handled.
