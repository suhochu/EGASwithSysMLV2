package EgasArch_Ver_Views {
    private import StandardViewDefinitions::*;

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

    view contextView : InterconnectionView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Ctx_Context::*;
    }

    view functionView : ActionFlowView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Fbb_Function::*;
    }

    view behaviorView : StateTransitionView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Beh_Behavior::*;
    }

    view scenarioView : SequenceView {
        viewpoint chainTrace : ChainTraceViewpoint;
        satisfy chainTrace;
        expose EgasArch_Scn_Scenario::*;
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
