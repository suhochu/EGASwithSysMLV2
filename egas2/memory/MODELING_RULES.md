# EGAS2 Modeling Rules (lint L1-L8)

Run `python egas2/tools/lint.py`. ERROR blocks closing a Task; WARNING does not. `registry_enforced` in `kpi_config.json` turns L1 from WARNING to ERROR.

| Code | Checks                                                                                                                 | Fix                                                                                       |
| ---- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| L1   | Definition is not in REGISTRY.md                                                                                       | Register the concept first (concept-registry-guard)                                       |
| L2   | Duplicate definition or Registry row; Registry home package differs from the defining package; invalid status          | Merge, or correct the home package. Status is one of planned, active, retired, outOfScope |
| L3   | Defined but `retired` or `outOfScope` (ERROR); defined but still `planned` (WARNING)                                   | Set the Registry status to `active` when the definition lands                             |
| L4   | A package references a higher layer, or packages import each other in a cycle                                          | Move the shared concept down to the lower layer or Common                                 |
| L5   | Relationship used outside its allowed layers                                                                           | See the table below                                                                       |
| L6   | `EgasSystem` or `LogicalEgasSystem` contains `part`, `perform`, `action`, `state`, `exhibit`, or `assert`              | Keep only `port` and `doc` in a black box                                                 |
| L7   | SPES hints: `@GoalData`/`@ScenarioData` placement, scenario pre/postcondition, scenario to goal, hard goal to scenario | See Hint rules below                                                                      |
| L8   | Literal attribute value without both `@SourceRef` and `@ValueStatus`                                                   | Add both annotations directly before the attribute                                        |

## Relationship placement (L5)

| Relationship                     | Allowed layers                      | Direction and meaning                                                                                                                                                    |
| -------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `#refinement` dependency         | Scn, Beh                            | A scenario or behavior refines a goal or SHR. Scenarios and behaviors never `satisfy` requirements; a legacy `satisfy` in a scenario becomes `#refinement` when migrated |
| `#derivation` connection         | Sysr                                | A SYSR derives from another SYSR. The SYSR to SHR trace is not covered by L5 (`#refinement` is only allowed in Scn and Beh); its pattern is open and decided in T12      |
| `satisfy requirement ... by ...` | Fbb and above (`satisfy_min_layer`) | A functional or logical design element satisfies a requirement                                                                                                           |
| `allocate ... to ...`            | Lbb, Lwb                            | A function (FN) is allocated to a logical component (LC)                                                                                                                 |

## SPES hint rules (L7)

- Write `@GoalData { ... }` and `@ScenarioData { ... }` directly before the element they describe, like `@SourceRef`. The lint reads the next element name as the owner.
- A scenario gives `fulfills = ("G1", ...)`, `preCondition`, and `postCondition` (Hints 4-2, 4-3). Every fulfilled id must be a described goal.
- Every goal with `kind = GoalKind::hard` must be fulfilled by at least one scenario.
- Not yet checked mechanically: context-actor to scenario-actor match (Hint 4-1) and input/output consistency (Hints 4-4 to 4-7). They need Ctx and Scn models and are added in T06 and T10.

## Limits

The scanner is regex based. It handles declarations written on one line or many, but not macros or generated text. Fixtures in `egas2/tools/test_lint.py` document the accepted forms.
