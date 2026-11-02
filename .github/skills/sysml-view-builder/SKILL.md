---
name: sysml-view-builder
description: "Use when writing viewpoint and view definitions or choosing a diagram type for EGAS2 models, including the fallback for view kinds that Syside does not render specially."
---

# sysml-view-builder

Pattern verified in T04 (`egas2/model/04_Views/EgasArch_Ver_Views.sysml`):

```
private import StandardViewDefinitions::*;
viewpoint def ChainTraceViewpoint { doc /* concern */ }
view goalView : GeneralView {
    viewpoint chainTrace : ChainTraceViewpoint;
    satisfy chainTrace;
    expose EgasArch_Obj_Objective::*;
}
```

Use `expose` only. `render` and `filter` are not needed for the chain; the legacy keeps `render` commented out.

## Standard view support in Syside (checked in T04)

| View definition     | Diagnostics | Rendering              | Use for                                    |
| ------------------- | ----------- | ---------------------- | ------------------------------------------ |
| GeneralView         | none        | dedicated              | goal and requirement structure             |
| InterconnectionView | none        | dedicated              | context boundary and logical decomposition |
| ActionFlowView      | none        | dedicated              | functions and their flows                  |
| StateTransitionView | none        | dedicated              | behavior states                            |
| SequenceView        | none        | shown as a GeneralView | not usable for sequences                   |
| GridView            | none        | shown as a GeneralView | not usable for matrices                    |
| BrowserView         | none        | shown as a GeneralView | not usable as a tree                       |

## Fallback for the three unsupported kinds

- Sequence: describe the scenario steps as text in the scenario `doc` and keep `preCondition`/`postCondition` in `@ScenarioData`.
- Matrix: write the traceability result as a Markdown table from the acceptance query (AQ) result.
- Tree: use the model explorer; do not claim a tree view in a report.

Record every fallback in EVALLOG.md. Do not create a view whose kind is unsupported only to satisfy the one-view-per-layer rule.
