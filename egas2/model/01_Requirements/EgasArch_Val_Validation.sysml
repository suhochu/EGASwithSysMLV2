package EgasArch_Val_Validation {
    private import EgasArch_Shr_Requirement::*;

    private import VerificationCases::*;

    requirement validatedShr : MonitorTorqueRequirement;

    verification def MonitorTorqueValidation {
        doc
        /* Stakeholder validation: demonstrate that an injected torque excess is detected and ends in the safe state. Acceptance criterion: no sustained unintended acceleration. */
        objective {
            verify validatedShr;
        }
    }
} // package EgasArch_Val_Validation
