package EgasArch_Ver_Verification {
    private import VerificationCases::*;
    private import EgasArch_Sysr_Requirement::*;

    requirement verifiedTorqueComparison : TorqueComparisonRequirement;
    requirement verifiedExcessConfirmation : ExcessConfirmationRequirement;
    requirement verifiedSafeStateEnforcement : SafeStateEnforcementRequirement;
    requirement verifiedPedalSensorFaultDetection : PedalSensorFaultDetectionRequirement;
    requirement verifiedLimpHomeTorqueLimit : LimpHomeTorqueLimitRequirement;
    requirement verifiedBrakeOverrideTorque : BrakeOverrideTorqueRequirement;
    requirement verifiedControllerMonitoring : ControllerMonitoringRequirement;

    verification def TorqueComparisonVerification {
        doc
        /* Verification case: inject a torque excess and check that the L2 monitor reports it. */
        objective {
            verify verifiedTorqueComparison;
        }
    }

    verification def ExcessConfirmationVerification {
        doc
        /* Verification case: inject a short and a persistent torque excess and check that only the persistent one is confirmed. The confirmation time is tbd (see the requirement). */
        objective {
            verify verifiedExcessConfirmation;
        }
    }

    verification def SafeStateEnforcementVerification {
        doc
        /* Verification case: confirm a torque excess and check that the output stage reaches TorqueLimited within the FTTI of the safety goal (catalog sg01Ftti, pilotAssumed) for any torque demand. The reaction path is l2Reaction and l2Output. */
        objective {
            verify verifiedSafeStateEnforcement;
        }
    }

    verification def PedalSensorFaultDetectionVerification {
        doc
        /* Verification case: deviate one pedal value sensor channel and check that the plausibility check detects it and reports it to the limp home reaction. */
        objective {
            verify verifiedPedalSensorFaultDetection;
        }
    }

    verification def LimpHomeTorqueLimitVerification {
        doc
        /* Verification case: confirm a pedal sensor fault and check that the torque stays below limpHomeTorqueLimit for every pedal position. */
        objective {
            verify verifiedLimpHomeTorqueLimit;
        }
    }

    verification def BrakeOverrideTorqueVerification {
        doc
        /* Verification case: press the brake and the pedal together and check that the brake request overrides the pedal torque demand. */
        objective {
            verify verifiedBrakeOverrideTorque;
        }
    }

    verification def ControllerMonitoringVerification {
        doc
        /* Verification case: let UF-09 in l1Control answer wrongly and check that UF-08 in l3Monitor requests the shut off and that UF-07 in l2Output latches it; the pilot expectation is that the request passes neither L1 nor L2. The Q&A cycle, the question count, l3Fdti and l3Frti (tbd) are quoted from the requirement. A fault of the Q&A channel itself is not covered (OI-27). */
        objective {
            verify verifiedControllerMonitoring;
        }
    }
} // package EgasArch_Ver_Verification
