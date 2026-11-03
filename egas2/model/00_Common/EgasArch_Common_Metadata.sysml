package EgasArch_Common_Metadata {
    private import EgasArch_Common_Enums::*;
    private import ScalarValues::*;

    metadata def SourceRef {
        attribute document : String;
        attribute itemId : String [0..1];
        attribute page : Integer [0..1];
    }

    metadata def ValueStatus {
        attribute status : ValueStatusKind;
        attribute reviewer : String [0..1];
        attribute rationale : String [0..1];
    }

    metadata def GoalData {
        attribute kind : GoalKind;
        attribute refinement : GoalRefinementKind [0..1];
    }

    metadata def GoalConflict;

    metadata def GoalContribution;

    metadata def ScenarioData {
        attribute kind : ScenarioKind;
        attribute preCondition : String [0..1];
        attribute postCondition : String [0..1];
    }

    metadata def AbstractionLayer {
        attribute layer : Integer;
    }
} // package EgasArch_Common_Metadata
