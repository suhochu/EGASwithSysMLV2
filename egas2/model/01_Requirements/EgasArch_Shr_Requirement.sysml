package EgasArch_Shr_Requirement {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Needs_Concern::*;
    private import EgasArch_Safety_Goal::*;

    requirement def MonitorTorqueRequirement :> UnintendedAccelerationGoal {
        doc
        /* The system shall detect an actual torque above the permissible torque, and a confirmed pedal or throttle sensor fault, and move to a safe state (EGAS SReq-06, SReq-03; legacy SHR-03). */
        frame concern unintendedAcceleration : UnintendedAccelerationConcern;
        frame concern hardwareFailure : HardwareFailureConcern;
        @GoalData {
            kind = GoalKind::hard;
            refinement = GoalRefinementKind::AND;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e105~e111";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale =
                "The detection and safe-state reaction are given by EGAS; the safe-state stage and the time limit are set by the safety goal.";
        }
    }

    requirement def BrakeOverrideRequirement :> UnintendedAccelerationGoal {
        doc
        /* While the driver requests propulsion by pedal or cruise, a brake application shall reduce the propulsion torque, independent of the order in which the inputs arrive (legacy SHR-01). */
        frame concern torqueArbitration : TorqueArbitrationConcern;
        @GoalData {
            kind = GoalKind::hard;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e197~e199";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale =
                "EGAS requires the reduction to the controllable maximum; the legacy torque-limit level L1 is not carried and no limit value is set here.";
        }
    }

    requirement def SteadyStatePrecisionRequirement {
        doc
        /* The delivered torque shall track the requested torque in steady state with a small error and a small overshoot (legacy SHR-02, SHR-02-1). */
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

    requirement def TorqueInterventionRequirement {
        doc
        /* When another ECU requests a torque reduction, the system shall reduce the air and the fuel and ignition commands within the intervention response budget, and return to driver-request control once the request is released (legacy SHR-04, SHR-04-1, SHR-04-2, SHR-04-4). */
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

    requirement def PedalResponseRequirement {
        doc
        /* After a pedal input the system shall output the air and the fuel commands within the pedal response budget; the safety reactions of the other requirements take priority (legacy SHR-08). */
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

    requirement def FunctionalSafetyComplianceRequirement :> UnintendedAccelerationGoal {
        doc
        /* The development of the system shall follow ISO 26262 for the ASIL of the safety goal (legacy SHR-P01). */
        frame concern functionalSafety : FunctionalSafetyConcern;
        @GoalData {
            kind = GoalKind::hard;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e90";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale =
                "EGAS requires implementation to the safety goal ASIL; the legacy ASIL-D text is not carried.";
        }
    }
} // package EgasArch_Shr_Requirement
