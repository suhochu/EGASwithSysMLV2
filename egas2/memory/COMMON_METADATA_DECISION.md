# Common Metadata Decision

## Decision

- Use metadata definitions for provenance and classifications that are attached to model elements: `SourceRef`, `ValueStatus`, `GoalData`, `ScenarioData`, and `AbstractionLayer`.
- Keep `ValueStatusKind` as the enum for `Standard`, `project`, `pilotAssumed`, `tbd`, and `reviewed`. The distinct names avoid a global namespace collision between an enum and a metadata definition. KPI counting normalizes `Standard` to `standard`.
- Keep quantitative constraints as typed attributes in Common catalogs, with `SourceRef` and `ValueStatus` applied to each value.
- Represent failure rates with the standard frequency quantity and define the project FIT conversion factor in Common: one FIT equals 1e-9 failures per hour. This is a unit conversion, not an allocated safety target.
- Keep cross-element references as identifier strings in this seed. Replace them with typed SysML relationships when the project relationship patterns are validated in T03.

## Rationale

Metadata expresses classification and provenance; attributes hold queryable values and constraints. The legacy `MetaInformation` only covers version, updater, and change note, so it remains a separate configuration-management concern rather than being overloaded for safety provenance. Existing metadata application syntax is known from the legacy model, but every new enum-typed application must pass current SysIDE diagnostics before it is treated as a verified pattern.
