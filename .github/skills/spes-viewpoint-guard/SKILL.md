---
name: spes-viewpoint-guard
description: "Use when writing or reviewing EGAS2 requirement, functional, or logical viewpoint models to check allowed and forbidden elements per layer and the SPES hints. Pair with egas2/tools/lint.py."
---

# spes-viewpoint-guard

Rules and lint codes: `egas2/memory/MODELING_RULES.md`. Run `python egas2/tools/lint.py` before closing a Task.

| Layer      | Allowed                                                                       | Forbidden                                                                      |
| ---------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Obj, Needs | goals, concerns, stakeholders with `@GoalData`                                | `satisfy`, design parts, numeric values outside Common                         |
| Ctx        | `EgasSystem` black box with ports and `doc`, external actors, interface items | `part`, `perform`, `action`, `state`, `exhibit`, `assert` inside the black box |
| Safety     | hazards, safety goals with `@SourceRef` and `@ValueStatus`                    | ASIL, S/E/C, FTTI marked `standard` without an EGAS source                     |
| Shr, Val   | SHR as hard goals, validation criteria                                        | stage-by-stage ms allocation, WCET                                             |
| Scn        | scenarios with `@ScenarioData`, `#refinement` to goals                        | `satisfy`, scenarios without pre/postcondition                                 |
| Beh        | state, operation, and information structure, `#refinement`                    | `satisfy`                                                                      |
| Sysr       | SYSR, `#derivation` between SYSR                                              | design elements                                                                |
| Fbb, Fwb   | UF and FN, mode channels, `satisfy`                                           | components that belong in Lbb or Lwb                                           |
| Lbb, Lwb   | LC with ports and channels, FN-to-LC `allocate`, `satisfy`                    | anything besides port and `doc` inside `LogicalEgasSystem`                     |

## SPES hint checklist

1. Every context actor appears in a scenario and every scenario actor in the context (Hint 4-1; checked manually until T06).
2. Every hard goal is fulfilled by a scenario and every scenario fulfills a goal (Hint 4-2; lint L7).
3. Every scenario has `preCondition` and `postCondition` (Hint 4-3; lint L7).
4. Interfaces of a UF are a subset of the context interfaces (SPES 5.2).
5. The root logical component reuses the functional black-box boundary (SPES 6.3).

When lint reports a code, follow the fix column in MODELING_RULES.md and then re-run lint; repeated failure of one rule goes to OPEN_ISSUES.md.
