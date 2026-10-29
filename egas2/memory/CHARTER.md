# EGAS SysML v2 Pilot Charter

## Purpose

Rebuild a scoped EGAS system architecture in SysML v2 using SPES viewpoints, then evaluate whether the model improves traceability, consistency, and architecture-level reasoning.

## Background

- The legacy inventory contains 31 files, 13,769 lines, and 1,963 commented lines.
- Eight legacy requirement-related packages participate in an import cycle.
- The legacy logical viewpoint files are almost entirely commented out.
- EGAS v6.0 identifies SZ-01 as unintended acceleration, ASIL B; SZ-02 through SZ-04 are considered controllable and excluded.
- EGAS calls for monitoring across L1 function, L2 functional monitoring, and L3 controller monitoring.
- The L3 concept uses Q&A between the functional controller and an independent monitoring module.
- EGAS gives a Q&A repetition interval of 80 ms or less and at least 10 questions.
- PVS dual-channel faults have specified limp-home responses that provide a grounded safety scenario.
- SPES calls for consistency across actors, goals, scenarios, requirements, and interface inputs and outputs.
- EGAS cites ISO 26262:2011; the pilot uses ISO 26262:2018 terminology while retaining EGAS references as sources.

## Scope

The pilot covers gasoline manifold injection with torque-comparison monitoring and L3 Q&A. Its Golden Paths are GP-A, the SZ-01 L2 monitoring path, and GP-B, PVS dual-channel fault response to limp home (EGAS 11.1.1). Brake override remains a thin scenario.

The pilot uses one architecture level. Gasoline direct injection, diesel torque comparison, diesel acceleration comparison, gasoline acceleration comparison, and A-SaCo are out of scope; the decision rationale is recorded in REGISTRY.md.

The viewpoint order is Objective, Needs, Context, Safety, SHR, Validation, Scenario, System Behavior, System Requirements, Functional BB/WB, Logical BB/WB, and Verification/Views. SHR remains a separate layer and a subtype of hard goal.

## Non-goals

- Reproducing the entire legacy model.
- Producing a certification-ready safety case.
- Modeling detailed hardware/software design, including WCET and per-step millisecond allocation.
- Deeply modeling every use case.
- Developing new modeling tools.

## Modeling and evidence rules

- Top-level model packages use `EgasArch_<Layer>_<Name>` and import only lower layers.
- Define reusable quantities and numeric catalogs in Common; cite source and status for values.
- Use MonitoringLevel for EGAS L1-L3. Use SafeStateStage for safe-state progression.
- UF means black-box user function; FN means white-box function; LC means logical component.
- Do not present assumed safety values as standard or approved values.
- Use the seven-item 1/3/5 scoring rubric and AQ1-AQ8 in EVAL_PLAN.md.

## Budget and completion

Keep the current 2,500-line total budget, layer-specific line/definition budgets, migration curve, and five non-goals in KPI.md and kpi_config.json. The approximate monthly budget is 2,000 AI Credits; 64 Credits per Task is a planning reference, not a quality-reducing hard cap. Carry work into the next month when needed.

Completion requires the selected scope and both Golden Paths to be represented, all hard KPI checks to pass, all eight acceptance questions to be answerable at T21, and no edits to legacy model files. Gate reviews sample model content against the legacy inventory and cited standards; this pilot is not a safety certification.
