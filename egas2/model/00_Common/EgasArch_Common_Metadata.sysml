package EgasArch_Common_Metadata {
    private import EgasArch_Common_Enums::*;
    private import ScalarValues::*;

    metadata def SourceRef {
        attribute document : String;
        attribute itemId : String [0..*];
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
    metadata def SafetyMechanism {
        doc
        /* DC and FIT are not modeled: EGAS gives no values and the hardware metric targets need an edition check. */
        attribute kind : MechanismKind;
        attribute monitoringLevel : MonitoringLevel;
        attribute detects : String;
        attribute derivedFrom : String;
    }

    metadata def FailureMode {
        doc
        /* Common cause failure of a shared input or resource. Naming it does not show independence; DC and FIT are not modeled. */
        attribute mode : String;
        attribute effect : String;
        attribute propagatesTo : String [1..*];
        attribute detectedBy : String [0..*];
    }

    metadata def IndependenceConstraint {
        doc
        /* Intended independence of a monitoring path and its freedom-from-interference (FFI) targets. demonstrated is true only when an approved analysis shows the independence; naming the constraint does not. */
        attribute path : String [1..*];
        attribute isolatedFrom : String [1..*];
        attribute sharedResources : String [0..*];
        attribute ffiTargets : String [0..*];
        attribute demonstrated : Boolean;
    }

    metadata def AbstractionLayer {
        attribute layer : Integer;
    }
} // package EgasArch_Common_Metadata
