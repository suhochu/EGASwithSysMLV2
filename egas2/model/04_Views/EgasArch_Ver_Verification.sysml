package EgasArch_Ver_Verification {
    private import VerificationCases::*;
    private import EgasArch_Sysr_Requirement::*;
    private import EgasArch_Sysr_L2Monitor::*;

    requirement verifiedTorqueComparison : TorqueComparisonRequirement;
    requirement verifiedExcessConfirmation : ExcessConfirmationRequirement;
    requirement verifiedSafeStateEnforcement : SafeStateEnforcementRequirement;
    requirement verifiedPedalSensorFaultDetection : PedalSensorFaultDetectionRequirement;
    requirement verifiedLimpHomeTorqueLimit : LimpHomeTorqueLimitRequirement;
    requirement verifiedBrakeOverrideTorque : BrakeOverrideTorqueRequirement;
    requirement verifiedControllerMonitoring : ControllerMonitoringRequirement;
    requirement verifiedArbitrationPriority : TorqueArbitrationPriorityRequirement;
    requirement verifiedInterventionReduction : TorqueInterventionReductionRequirement;
    requirement verifiedInterventionRelease : InterventionReleaseRequirement;
    requirement verifiedPedalOutputResponse : PedalOutputResponseRequirement;
    requirement verifiedSteadyStateTracking : SteadyStateTorqueTrackingRequirement;
    requirement verifiedSudTorqueComparison : SudTorqueComparisonRequirement;
    requirement verifiedSudExcessConfirmation : SudExcessConfirmationRequirement;

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
        /* Verification case: let UF-09 in l1Control answer wrongly and check that UF-08 in l3Monitor requests the shut off and that UF-07 in l2Output latches it; the pilot expectation is that the request passes neither L1 nor L2. The Q&A cycle, the question count, l3Fdti and l3Frti (pilotAssumed) are quoted from the requirement. A fault of the Q&A channel itself is not covered (OI-27). */
        objective {
            verify verifiedControllerMonitoring;
        }
    }

    verification def ArbitrationPriorityVerification {
        doc
        /* Verification case: raise the brake override, the limp home reaction and the safe state together with a driver torque demand and check that each safety reaction takes priority over the demand. */
        objective {
            verify verifiedArbitrationPriority;
        }
    }

    verification def InterventionReductionVerification {
        doc
        /* Verification case: send a torque reduction request of another ECU and check that the torque demand is reduced within the intervention response budget (catalog interventionResponseBudget, pilotAssumed). */
        objective {
            verify verifiedInterventionReduction;
        }
    }

    verification def InterventionReleaseVerification {
        doc
        /* Verification case: release an active intervention request and check that the system returns to driver-request torque control. */
        objective {
            verify verifiedInterventionRelease;
        }
    }

    verification def PedalOutputResponseVerification {
        doc
        /* Verification case: change the pedal position and check that the air and the fuel commands are output within the pedal response budget (catalog pedalResponseBudget, pilotAssumed) while a safety reaction keeps priority. */
        objective {
            verify verifiedPedalOutputResponse;
        }
    }

    verification def SteadyStateTrackingVerification {
        doc
        /* Verification case: hold a constant torque request and check that the delivered torque stays within the tracking limit (catalog steadyStateTrackingLimit, pilotAssumed). */
        objective {
            verify verifiedSteadyStateTracking;
        }
    }

    verification def SudTorqueComparisonVerification {
        doc
        /* Verification case (SUD l2Monitor): feed the permissible torque unit, the actual torque unit and the excess judge unit a torque above the permissible value and check that the excess judge reports it. */
        objective {
            verify verifiedSudTorqueComparison;
        }
    }

    verification def SudExcessConfirmationVerification {
        doc
        /* Verification case (SUD l2Monitor): present a short and a persistent judged excess to the excess judge unit and check that only the persistent one is confirmed; the confirmation time is the pilotAssumed catalog value sudConfirmationTime. */
        objective {
            verify verifiedSudExcessConfirmation;
        }
    }
} // package EgasArch_Ver_Verification
