package EgasArch_Shr_Requirement {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Needs_Concern::*;
    private import EgasArch_Ctx_Context::*;

    // Nominal & Process Stakeholder Requirements (Functional Safety Requirements are separated in EgasArch_Shr_Fsr)

    requirement def StakeholderRequirement;

    requirement SteadyStatePrecisionRequirement : StakeholderRequirement {
        doc
        /* The delivered torque shall track the requested torque in steady state with a small error 
         * and a small overshoot (legacy SHR-02, SHR-02-1).
         */
        subject egas : EgasSystem;
        frame concern preciseControl : PreciseControlConcern;

        @GoalData {
            kind = GoalKind::soft;
        }
        @SourceRef {
            document = "Legacy SHR-02-1 (Tier 1 supplier interview)";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The limit is the pilotAssumed catalog entry steadyStateTrackingLimit; EGAS gives none. The overshoot limit is not set.";
        }
    }

    requirement TorqueInterventionRequirement : StakeholderRequirement {
        doc
        /* When another ECU requests a nominal torque reduction (e.g., chassis stability control),
         * the system shall reduce air, fuel, and ignition commands within the intervention response budget 
         * and return to driver-request control once released (legacy SHR-04, SHR-04-1, SHR-04-2, SHR-04-4). 
         * Safety protection of external torque-increasing requests is covered by FSR-04.
         */

        subject egas : EgasSystem;
        frame concern torqueArbitration : TorqueArbitrationConcern;

        @GoalData {
            kind = GoalKind::hard;
            refinement = GoalRefinementKind::AND;
        }
        @SourceRef {
            document = "Legacy SHR-04 (chassis control meeting minutes)";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The budget is the pilotAssumed catalog entry interventionResponseBudget; EGAS gives none. The throttle-stuck fallback (legacy SHR-04-3) is demoted.";
        }
    }

    requirement PedalResponseRequirement : StakeholderRequirement {
        doc
        /* After a pedal input the system shall output the air and the fuel commands within the pedal response budget; 
         * safety reactions defined in EgasArch_Shr_Fsr take priority (legacy SHR-08).
         */

        subject egas : EgasSystem;
        frame concern drivability : DrivabilityAndResponseConcern;

        @GoalData {
            kind = GoalKind::soft;
        }
        @SourceRef {
            document = "Legacy SHR-08 (vehicle dynamics and ergonomics guidelines)";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The budget is the pilotAssumed catalog entry pedalResponseBudget; EGAS gives none.";
        }
    }

    requirement def FunctionalSafetyComplianceRequirement {
        doc
        /* The development of the system shall follow ISO 26262 for the ASIL of the safety goal (legacy SHR-P01). */
        subject egas : EgasSystem;

        frame concern functionalSafety : FunctionalSafetyConcern;

        @GoalData {
            kind = GoalKind::hard;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e90";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale =
                "EGAS requires implementation to the safety goal ASIL (ASIL B); the legacy ASIL-D text is not carried.";
        }
    }
} // package EgasArch_Shr_Requirement
