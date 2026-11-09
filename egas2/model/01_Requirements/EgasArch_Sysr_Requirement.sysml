package EgasArch_Sysr_Requirement {
    private import RequirementDerivation::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Catalog_SafetyTargets::*;
    private import EgasArch_Common_Catalog_RequirementTargets::*;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Beh_Behavior::*;

    requirement def TorqueComparisonRequirement {
        doc
        /* The L2 monitor shall compare the actual torque with the permissible torque and report an excess. Parent: MonitorTorqueRequirement. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::FSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "SG-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e105~e111, EGAS_e117~e128";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from SG-01 (EGAS e83). The requirement is derived in the pilot and the safety values it relies on are pending user approval (OI-07).";
        }
    }

    requirement def ExcessConfirmationRequirement {
        doc
        /* A detected torque excess shall be confirmed before the safe state is entered. The confirmation time is tbd; the latch design is left to the functional layer. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::FSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "SG-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e105~e111";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from SG-01 (EGAS e83). EGAS requires the excess to be detected and confirmed (SReq-06) but gives no confirmation time. Pending user approval (OI-07).";
        }
    }

    requirement def SafeStateEnforcementRequirement {
        doc
        /* When a torque excess is confirmed, the system shall reach the safe state within the FTTI, independent of the demanded torque and of the L1 function. */
        attribute stage : SafeStateStage = SafeStateStage::TorqueLimited;
        attribute ftti : DurationQuantity = sg01Ftti;
        @SafetyRequirementData {
            level = SafetyRequirementLevel::FSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "SG-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e87, EGAS_e127";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from SG-01 (EGAS e83). The stage and the FTTI follow the safety goal: both the stage and the FTTI (catalog sg01Ftti) are pilotAssumed (OI-07).";
        }
    }

    requirement def PedalSensorFaultDetectionRequirement {
        doc
        /* The system shall detect a fault of a pedal value sensor channel by plausibility between the channels and report it to the limp home reaction. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::FSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "SG-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e105~e111";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from SG-01 (EGAS e83). EGAS requires the plausibility check (SReq-01, SReq-03); the assignment to this requirement is a pilot derivation (OI-07).";
        }
    }

    requirement def LimpHomeTorqueLimitRequirement {
        doc
        /* After a confirmed pedal sensor fault the system shall keep the torque below the limp home torque limit (EGAS 11.1.1). */
        attribute torqueLimit : TorqueQuantity = limpHomeTorqueLimit;
        @SafetyRequirementData {
            level = SafetyRequirementLevel::FSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "SG-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e445~e465";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from SG-01 (EGAS e83). EGAS gives no limp home torque value, so the limit is the pilotAssumed catalog entry limpHomeTorqueLimit (OI-10).";
        }
    }

    requirement def BrakeOverrideTorqueRequirement {
        doc
        /* While the driver requests propulsion, a brake application shall limit the propulsion torque to the controllable maximum, independent of the order of the inputs. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::FSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "SG-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e197~e199";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from SG-01 (EGAS e83). The legacy L1 limit and timing are not carried over and no limit value is set. Pending user approval (OI-07).";
        }
    }

    requirement def TorqueArbitrationPriorityRequirement {
        doc
        /* The torque arbitration shall give the safety reactions (brake override, limp home, safe state) priority over the driver torque demand. */
        @SourceRef {
            document = "Legacy SYSR-18";
        }
        @ValueStatus {
            status = ValueStatusKind::project;
            rationale =
                "Derived requirement without a numeric value; the legacy priority levels are not carried over.";
        }
    }

    requirement def TorqueInterventionReductionRequirement {
        doc
        /* On a torque reduction request of another ECU the system shall reduce the torque demand within the intervention response budget. */
        attribute responseBudget : DurationQuantity = interventionResponseBudget;
        @SourceRef {
            document = "Legacy SYSR-03";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The response budget is the pilotAssumed catalog entry interventionResponseBudget (OI-09).";
        }
    }

    requirement def InterventionReleaseRequirement {
        doc
        /* When the intervention request is released, the system shall return to driver-request torque control. */
        @SourceRef {
            document = "Legacy SYSR-19";
        }
        @ValueStatus {
            status = ValueStatusKind::project;
            rationale =
                "Derived requirement without a numeric value; the legacy reset timing is not carried over.";
        }
    }

    requirement def PedalOutputResponseRequirement {
        doc
        /* After a pedal input the system shall output the air and the fuel commands within the pedal response budget; the safety reactions take priority. */
        attribute responseBudget : DurationQuantity = pedalResponseBudget;
        @SourceRef {
            document = "Legacy SYSR-13";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The response budget is the pilotAssumed catalog entry pedalResponseBudget (OI-09); the ride comfort jerk is demoted.";
        }
    }

    requirement def SteadyStateTorqueTrackingRequirement {
        doc
        /* In steady state the delivered torque shall track the requested torque within the tracking limit. */
        attribute trackingLimit : PercentQuantity = steadyStateTrackingLimit;
        @SourceRef {
            document = "Legacy SHR-02-1";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The tracking limit is the pilotAssumed catalog entry steadyStateTrackingLimit (OI-09).";
        }
    }

    requirement parentShr : MonitorTorqueRequirement;
    requirement brakeShr : BrakeOverrideRequirement;
    requirement precisionShr : SteadyStatePrecisionRequirement;
    requirement interventionShr : TorqueInterventionRequirement;
    requirement responseShr : PedalResponseRequirement;

    requirement sysrTorqueComparison : TorqueComparisonRequirement;
    requirement sysrExcessConfirmation : ExcessConfirmationRequirement;
    requirement sysrSafeStateEnforcement : SafeStateEnforcementRequirement;
    requirement sysrPedalSensorFaultDetection : PedalSensorFaultDetectionRequirement;
    requirement sysrLimpHomeTorqueLimit : LimpHomeTorqueLimitRequirement;
    requirement sysrBrakeOverrideTorque : BrakeOverrideTorqueRequirement;
    requirement sysrArbitrationPriority : TorqueArbitrationPriorityRequirement;
    requirement sysrInterventionReduction : TorqueInterventionReductionRequirement;
    requirement sysrInterventionRelease : InterventionReleaseRequirement;
    requirement sysrPedalOutputResponse : PedalOutputResponseRequirement;
    requirement sysrSteadyStateTracking : SteadyStateTorqueTrackingRequirement;

    #derivation connection sysrDerivesFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrTorqueComparison;
    }
    #derivation connection sysrDerivesFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrTorqueComparison;
    }
    #derivation connection excessConfirmationFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrExcessConfirmation;
    }
    #derivation connection excessConfirmationFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrExcessConfirmation;
    }
    #derivation connection safeStateEnforcementFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrSafeStateEnforcement;
    }
    #derivation connection safeStateEnforcementFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrSafeStateEnforcement;
    }
    #derivation connection pedalSensorFaultFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrPedalSensorFaultDetection;
    }
    #derivation connection pedalSensorFaultFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrPedalSensorFaultDetection;
    }
    #derivation connection limpHomeLimitFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrLimpHomeTorqueLimit;
    }
    #derivation connection limpHomeLimitFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrLimpHomeTorqueLimit;
    }
    #derivation connection brakeOverrideFromShr {
        end #original ::> brakeShr;
        end #derive ::> sysrBrakeOverrideTorque;
    }
    #derivation connection brakeOverrideFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrBrakeOverrideTorque;
    }
    #derivation connection arbitrationPriorityFromShr {
        end #original ::> responseShr;
        end #derive ::> sysrArbitrationPriority;
    }
    #derivation connection arbitrationPriorityFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrArbitrationPriority;
    }
    #derivation connection interventionReductionFromShr {
        end #original ::> interventionShr;
        end #derive ::> sysrInterventionReduction;
    }
    #derivation connection interventionReductionFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrInterventionReduction;
    }
    #derivation connection interventionReleaseFromShr {
        end #original ::> interventionShr;
        end #derive ::> sysrInterventionRelease;
    }
    #derivation connection interventionReleaseFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrInterventionRelease;
    }
    #derivation connection pedalOutputResponseFromShr {
        end #original ::> responseShr;
        end #derive ::> sysrPedalOutputResponse;
    }
    #derivation connection steadyStateTrackingFromShr {
        end #original ::> precisionShr;
        end #derive ::> sysrSteadyStateTracking;
    }
} // package EgasArch_Sysr_Requirement
