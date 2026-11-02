package EgasArch_Ver_Verification {
    private import VerificationCases::*;
    private import EgasArch_Sysr_Requirement::*;

    requirement verifiedTorqueComparison : TorqueComparisonRequirement;

    verification def TorqueComparisonVerification {
        doc
        /* Verification case: inject a torque excess and check that the L2 monitor reports it. */
        objective {
            verify verifiedTorqueComparison;
        }
    }
} // package EgasArch_Ver_Verification
