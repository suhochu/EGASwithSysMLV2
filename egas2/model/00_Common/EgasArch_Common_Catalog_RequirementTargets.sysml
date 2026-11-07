package EgasArch_Common_Catalog_RequirementTargets {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;

    attribute steadyStateTrackingLimit : PercentQuantity {
        @SourceRef { document = "Legacy SHR-02-1 (Tier 1 supplier interview)"; }
        @ValueStatus { status = ValueStatusKind::tbd; rationale = "Limits for the steady-state error and the overshoot are not given by EGAS; legacy values are not carried."; }
    }

    attribute interventionResponseBudget : DurationQuantity {
        @SourceRef { document = "Legacy SHR-04 (chassis control meeting minutes)"; }
        @ValueStatus { status = ValueStatusKind::tbd; rationale = "The intervention response budget is not given by EGAS."; }
    }

    attribute pedalResponseBudget : DurationQuantity {
        @SourceRef { document = "Legacy SHR-08 (vehicle dynamics and ergonomics guidelines)"; }
        @ValueStatus { status = ValueStatusKind::tbd; rationale = "The pedal response budget is not given by EGAS."; }
    }

    attribute limpHomeTorqueLimit : TorqueQuantity {
        @SourceRef { document = "EGAS v6.0"; itemId = "EGAS_e445~e465"; }
        @ValueStatus { status = ValueStatusKind::tbd; rationale = "EGAS 11.1.1 requires a limited torque in limp home but gives no value."; }
    }
} // package EgasArch_Common_Catalog_RequirementTargets
