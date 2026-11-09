package EgasArch_Common_Metadata {
    private import EgasArch_Common_Enums::*;
    private import ScalarValues::*;
    private import ISQ::*;

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

    metadata def SafetyGoalData {
        doc
        /* The HARA row named by hazardousEvent holds the S/E/C values; the three optional fields stay unset until they are approved. */
        attribute asil : AsilLevel;
        attribute severity : SeverityClass [0..1];
        attribute exposure : ExposureClass [0..1];
        attribute controllability : ControllabilityClass [0..1];
        attribute hazardousEvent : String;
        attribute ftti : DurationValue [0..1];
        attribute safeState : SafeStateStage;
    }

    metadata def SafetyRequirementData {
        attribute level : SafetyRequirementLevel;
        attribute asil : AsilLevel;
        attribute asilOrigin : AsilOrigin;
        attribute derivedFrom : String;
    }

    metadata def SafetyMechanism {
        doc
        /* DC and FIT are not modeled: EGAS gives no values and the hardware metric targets need an edition check. */
        attribute kind : MechanismKind;
        attribute monitoringLevel : MonitoringLevel;
        attribute detects : String;
        attribute derivedFrom : String;
    }

    metadata def AbstractionLayer {
        attribute layer : Integer;
    }
} // package EgasArch_Common_Metadata
