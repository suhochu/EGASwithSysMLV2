# Evaluation Plan

## Scoring rubric

Score each criterion 1, 3, or 5 using the observable evidence below. Record the score and evidence at T24; do not infer safety validity from model completeness.

| Criterion                      | 1 point                                                                      | 3 points                                                                | 5 points                                                                                                   |
| ------------------------------ | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Expressiveness                 | Required architecture concepts cannot be represented without losing meaning. | The scoped concepts are represented, with some manual workarounds.      | The scoped concepts are represented directly with reusable SysML v2 structures and views.                  |
| Traceability                   | Important relationships are missing or only described in prose.              | Main relationships exist, but coverage or navigation is incomplete.     | The required chains are explicit, navigable, and queryable across viewpoints.                              |
| Consistency maintenance        | Contradictions and omissions are not detected.                               | Some checks are automated; remaining checks need manual review.         | Key SPES consistency rules are checked repeatably and violations are actionable.                           |
| Tool maturity                  | Core editing or validation is unreliable or blocked.                         | Text editing and diagnostics work, with known limitations documented.   | Modeling, diagnostics, queries, and supported views work repeatably for the pilot.                         |
| AI collaboration efficiency    | Cards and constraints do not prevent substantial rework.                     | The AI completes bounded work with user corrections and review.         | Card-scoped work is reproducible, traceable, and reviewable with recorded effort.                          |
| Effort vs. document-based work | Modeling adds effort without reusable or traceable results.                  | Effort is comparable, with some reusable structure or automated checks. | Reuse and automation reduce repeated effort while preserving reviewable evidence.                          |
| ISO 26262 suitability          | Safety concepts or values are misrepresented or lack provenance.             | Relevant concepts are mapped with limitations and assumptions stated.   | Applicable concepts use 2018 terminology, EGAS sources are traceable, and unsupported claims are excluded. |

## Acceptance questions

An answer is acceptable when the model produces the requested elements and their relationship evidence. A justified empty result is acceptable for a coverage query; an unexplained missing result is not.

| ID  | Question                                                                 | Evidence required                                                               |
| --- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| AQ1 | Which logical components and functions satisfy a Safety Goal?            | SG-to-requirement-to-function/component trace chain.                            |
| AQ2 | Which SGs and SYSRs are affected when a component changes?               | Impact path from component through allocations and requirements to SGs.         |
| AQ3 | Which functions or components satisfy no SYSR?                           | Complete satisfy/allocation coverage query, including a justified empty result. |
| AQ4 | Which SYSRs have no parent SHR?                                          | SYSR-to-SHR trace query, including any uncovered SYSR.                          |
| AQ5 | Which components have an ASIL, and what independence requirements apply? | ASIL allocation plus relevant independence/FFI constraints and rationale.       |
| AQ6 | Which SGs or SYSRs have no verification?                                 | Verification coverage query for both requirement classes.                       |
| AQ7 | Which components does scenario SC-x traverse?                            | Scenario-to-function-to-component path for the selected scenario.               |
| AQ8 | Which interface ports belong to each external actor?                     | Actor-to-port table with boundary direction and item/type.                      |

## Milestones

- T04: at least 2 acceptance questions answerable.
- T13: at least 4 acceptance questions answerable.
- T20: at least 7 acceptance questions answerable.
- T21: all 8 acceptance questions answered with model evidence.
