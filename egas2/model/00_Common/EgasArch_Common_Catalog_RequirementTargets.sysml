package EgasArch_Common_Catalog_RequirementTargets {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import SI::*;

    attribute steadyStateTrackingLimit : PercentQuantity = 5.0 as PercentQuantity {
        @SourceRef { document = "Legacy SHR-02-1 (Tier 1 supplier interview)"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "EGAS gives no limit; 5 percent is a pilot value chosen by the AI at the T16 Gate-F on user request and not approved.";
        }
    }

    attribute interventionResponseBudget : DurationQuantity = 50 [milli * s] {
        @SourceRef { document = "Legacy SHR-04 (chassis control meeting minutes)"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "EGAS gives no budget; 50 ms is a pilot value chosen by the AI at the T16 Gate-F on user request and not approved.";
        }
    }

    attribute pedalResponseBudget : DurationQuantity = 100 [milli * s] {
        @SourceRef { document = "Legacy SHR-08 (vehicle dynamics and ergonomics guidelines)"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "EGAS gives no budget; 100 ms is a pilot value chosen by the AI at the T16 Gate-F on user request and not approved.";
        }
    }

    attribute limpHomeTorqueLimit : TorqueQuantity = 50 [N * m] {
        @SourceRef { document = "EGAS v6.0"; itemId = "EGAS_e445~e465"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "EGAS 11.1.1 requires a limited torque but gives no value; 50 N*m is a pilot value chosen by the AI at the T16 Gate-F on user request and not approved.";
        }
    }
} // package EgasArch_Common_Catalog_RequirementTargets
