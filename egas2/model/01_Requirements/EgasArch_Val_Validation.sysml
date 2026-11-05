package EgasArch_Val_Validation {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Shr_Requirement::*;
    private import VerificationCases::*;

    requirement validatedShr : MonitorTorqueRequirement;
    requirement validatedBrakeOverride : BrakeOverrideRequirement;
    requirement validatedSteadyState : SteadyStatePrecisionRequirement;
    requirement validatedIntervention : TorqueInterventionRequirement;
    requirement validatedPedalResponse : PedalResponseRequirement;
    requirement validatedCompliance : FunctionalSafetyComplianceRequirement;

    verification def MonitorTorqueValidation {
        doc
        /* Method: test (HILS fault injection). Stakeholder validation: demonstrate that an injected torque excess, or a pedal or throttle sensor fault confirmed beyond the confirmation time, is detected and ends in the safe state. Acceptance criterion: no sustained unintended acceleration. */
        objective {
            verify validatedShr;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e105~e111";
        }
    }

    verification def BrakeOverrideValidation {
        doc
        /* Method: test (vehicle). Apply pedal or cruise request and brake together, in both input orders. Acceptance criterion: the propulsion torque is reduced after the brake application, independent of the order. */
        objective {
            verify validatedBrakeOverride;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e197~e199";
        }
    }

    verification def SteadyStatePrecisionValidation {
        doc
        /* Method: demonstration (dynamometer). Track a torque request in steady state. Acceptance criterion: error and overshoot stay within the limits, which are not set yet. */
        objective {
            verify validatedSteadyState;
        }
        @SourceRef { document = "Legacy DemonstrateSteadyStatePrecision"; }
        @ValueStatus {
            status = ValueStatusKind::tbd;
            rationale = "The error and overshoot limits follow SteadyStatePrecisionRequirement and have no Common catalog entry yet.";
        }
    }

    verification def TorqueInterventionValidation {
        doc
        /* Method: test (track). Send a torque reduction request from another ECU and release it. Acceptance criterion: air and fuel and ignition commands are reduced within the intervention response budget, and driver-request control returns after the release. */
        objective {
            verify validatedIntervention;
        }
        @SourceRef { document = "Legacy TestInterventionViaAirflow, TestInterventionViaFuelIgnition"; }
        @ValueStatus {
            status = ValueStatusKind::tbd;
            rationale = "The intervention response budget follows TorqueInterventionRequirement and has no Common catalog entry yet.";
        }
    }

    verification def PedalResponseValidation {
        doc
        /* Method: test (vehicle). Apply a pedal input in normal driving. Acceptance criterion: air and fuel commands are output within the pedal response budget; safety reactions keep priority. */
        objective {
            verify validatedPedalResponse;
        }
        @SourceRef { document = "Legacy TestDriverPedalResponsiveness"; }
        @ValueStatus {
            status = ValueStatusKind::tbd;
            rationale = "The pedal response budget follows PedalResponseRequirement and has no Common catalog entry yet.";
        }
    }

    verification def FunctionalSafetyComplianceValidation {
        doc
        /* Method: inspection (audit). Review the development work products against ISO 26262 for the ASIL of the safety goal. Acceptance criterion: every required work product exists and is reviewed. */
        objective {
            verify validatedCompliance;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e90";
        }
    }
} // package EgasArch_Val_Validation
