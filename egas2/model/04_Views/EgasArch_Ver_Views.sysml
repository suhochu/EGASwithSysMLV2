package EgasArch_Ver_Views {
    private import StandardViewDefinitions::*;
    private import EgasArch_Ctx_Context::EgasSystem;
    private import EgasArch_Needs_Concern::UnintendedAccelerationConcern;

    viewpoint def ChainTraceViewpoint {
        doc
        /* Concern: every element of the thin GP-A chain is traceable from the objective down to the logical component. */
    }

    view goalView : GeneralView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Obj_Objective::*;
    }

    viewpoint def GoalViewpoint {
        doc
        /* Concern: every concern refines a goal and has a stakeholder, and every hard goal is refined by a scenario (SPES Hint 4-2). */
    }

    view goalTreeView : GeneralView {
        viewpoint goalCompleteness : GoalViewpoint;
        satisfy goalCompleteness;
        expose EgasArch_Obj_Objective::*;
        expose EgasArch_Needs_Concern::*;
    }

    // GridView is shown as a GeneralView by Syside
    view stakeholderConcernMatrix : GridView {
        viewpoint goalCompleteness : GoalViewpoint;
        satisfy goalCompleteness;
        expose EgasArch_Needs_Stakeholder::*;
        expose EgasArch_Needs_Concern::*;
    }

    viewpoint def ContextViewpoint {
        doc
        /* Concern: every signal crossing the system boundary has a port and an external actor, and every actor has a signal (SPES Hint 4-1). */
        subject egasSystem : EgasSystem;
        frame concern boundaryConcern : UnintendedAccelerationConcern;
    }

    view contextView : InterconnectionView {
        viewpoint contextCompleteness : ContextViewpoint;
        satisfy contextCompleteness;
        expose EgasArch_Ctx_Context::EgasContext::*;
    }

    // GridView is shown as a GeneralView by Syside
    view actorInterfaceTable : GridView {
        viewpoint contextCompleteness : ContextViewpoint;
        satisfy contextCompleteness;
        expose EgasArch_Ctx_Context::*;
        expose EgasArch_Common_Signals::*;
    }

    viewpoint def SafetyConceptViewpoint {
        doc
        /* Concern: every hazardous event has an ASIL or an exclusion reason, and every safety goal traces to a hazardous event and an ASIL. */
    }

    // GridView is shown as a GeneralView by Syside
    view haraTable : GridView {
        viewpoint safetyConcept : SafetyConceptViewpoint;
        satisfy safetyConcept;
        expose EgasArch_Safety_Goal::*;
    }

    view safetyGoalView : GeneralView {
        viewpoint safetyConcept : SafetyConceptViewpoint;
        satisfy safetyConcept;
        expose EgasArch_Safety_Goal::*;
        expose EgasArch_Common_Catalog_SafetyTargets::*;
    }

    viewpoint def RequirementViewpoint {
        doc
        /* Concern: every stakeholder requirement is a hard or soft goal and traces to a safety goal or a concern. */
    }

    // GridView is shown as a GeneralView by Syside
    view shrTable : GridView {
        viewpoint requirementTrace : RequirementViewpoint;
        satisfy requirementTrace;
        expose EgasArch_Shr_Requirement::*;
    }

    // GridView is shown as a GeneralView by Syside
    view validationCoverageMatrix : GridView {
        viewpoint requirementTrace : RequirementViewpoint;
        satisfy requirementTrace;
        expose EgasArch_Shr_Requirement::*;
        expose EgasArch_Val_Validation::*;
    }

    viewpoint def ScenarioViewpoint {
        doc
        /* Concern: every scenario has pre- and postconditions and refines a goal and a stakeholder requirement. */
    }

    // GridView is shown as a GeneralView by Syside
    view goalScenarioMatrix : GridView {
        viewpoint scenarioTrace : ScenarioViewpoint;
        satisfy scenarioTrace;
        expose EgasArch_Obj_Objective::*;
        expose EgasArch_Shr_Requirement::*;
        expose EgasArch_Scn_Scenario::*;
    }

    viewpoint def BehaviorViewpoint {
        doc
        /* Concern: every operating mode is reachable from the start state and every behavior element refines a stakeholder requirement or a scenario (SPES Hints 4-4 to 4-6). */
    }

    view modeStateView : StateTransitionView {
        viewpoint behaviorCompleteness : BehaviorViewpoint;
        satisfy behaviorCompleteness;
        expose EgasArch_Beh_Behavior::EgasBehavior::*;
    }

    view operationalFlowView : ActionFlowView {
        viewpoint behaviorCompleteness : BehaviorViewpoint;
        satisfy behaviorCompleteness;
        expose EgasArch_Beh_Behavior::*;
    }

    view infoStructureView : GeneralView {
        viewpoint behaviorCompleteness : BehaviorViewpoint;
        satisfy behaviorCompleteness;
        expose EgasArch_Beh_Behavior::TorqueDemand;
        expose EgasArch_Common_Signals::*;
    }

    viewpoint def SystemRequirementViewpoint {
        doc
        /* Concern: every system requirement derives from a stakeholder requirement or a behavior element, and every FSR has an ASIL inherited from the safety goal. */
    }

    // GridView is shown as a GeneralView by Syside
    view sysrTable : GridView {
        viewpoint sysrTrace : SystemRequirementViewpoint;
        satisfy sysrTrace;
        expose EgasArch_Sysr_Requirement::*;
    }

    view fsrView : GeneralView {
        viewpoint sysrTrace : SystemRequirementViewpoint;
        satisfy sysrTrace;
        expose EgasArch_Sysr_Requirement::*;
        expose EgasArch_Common_Catalog_SafetyTargets::*;
        expose EgasArch_Common_Catalog_RequirementTargets::*;
    }

    // GridView is shown as a GeneralView by Syside
    view sysrTraceView : GridView {
        viewpoint sysrTrace : SystemRequirementViewpoint;
        satisfy sysrTrace;
        expose EgasArch_Sysr_Requirement::*;
        expose EgasArch_Shr_Requirement::*;
        expose EgasArch_Beh_Behavior::*;
    }

    viewpoint def FunctionalViewpoint {
        doc
        /* Concern: every user function has typed inputs and outputs from the boundary or the internal signals, every system requirement is satisfied by a user function, and every mode-dependent function names its modes (SPES 5.2). */
    }

    view ufHierarchyView : GeneralView {
        viewpoint functionalCompleteness : FunctionalViewpoint;
        satisfy functionalCompleteness;
        expose EgasArch_Fbb_Function::egasUf::*;
    }

    view modeDependencyView : GeneralView {
        viewpoint functionalCompleteness : FunctionalViewpoint;
        satisfy functionalCompleteness;
        expose EgasArch_Fbb_Function::*;
        expose EgasArch_Common_Enums::OperatingMode;
        expose EgasArch_Common_Signals::ModeChannel;
    }

    // GridView is shown as a GeneralView by Syside
    view ufInterfaceTable : GridView {
        viewpoint functionalCompleteness : FunctionalViewpoint;
        satisfy functionalCompleteness;
        expose EgasArch_Fbb_Function::*;
        expose EgasArch_Beh_Behavior::TorqueDemand;
        expose EgasArch_Common_Signals::*;
    }

    view functionView : ActionFlowView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Fbb_Function::*;
    }

    view fwbDecompositionView : ActionFlowView {
        viewpoint functionalCompleteness : FunctionalViewpoint;
        satisfy functionalCompleteness;
        expose EgasArch_Fwb_Function::*;
    }

    // GridView is shown as a GeneralView by Syside
    view bbWbMappingTable : GridView {
        viewpoint functionalCompleteness : FunctionalViewpoint;
        satisfy functionalCompleteness;
        expose EgasArch_Fwb_Function::*;
    }

    view behaviorView : StateTransitionView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Beh_Behavior::*;
    }

    view scenarioView : SequenceView {
        viewpoint scenarioTrace : ScenarioViewpoint;
        satisfy scenarioTrace;
        expose EgasArch_Scn_Scenario::*;
    }

    viewpoint def LogicalViewpoint {
        doc
        /* Concern: the logical root preserves the boundary of the functional black box and its port contract matches the user function boundary (SPES 6.2). */
    }

    view logicalBbView : InterconnectionView {
        viewpoint logicalCompleteness : LogicalViewpoint;
        satisfy logicalCompleteness;
        expose EgasArch_Lbb_Logical::LogicalEgasSystem::*;
    }

    view allocationView : GridView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Lwb_Logical::*;
    }

    view chainBrowser : BrowserView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Ver_Verification::*;
    }
} // package EgasArch_Ver_Views
