package EgasArch_Sysr_Requirement {
    private import RequirementDerivation::*;
    private import ModelingMetadata::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Catalog_SafetyTargets::*;
    private import EgasArch_Common_Catalog_RequirementTargets::*;
    private import EgasArch_Common_Catalog_EgasStandard::*;
    private import ScalarValues::Integer;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Beh_Behavior::*;
    private import EgasArch_Shr_Fsr::*;
    private import EgasArch_Scn_Scenario::*;

    requirement def TorqueComparisonRequirement {
        doc
        /* The L2 monitor shall compare the actual torque with the permissible torque and report an excess. Parent: MonitorTorqueRequirement. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e105", "EGAS-e106", "EGAS-e107", "EGAS-e108", "EGAS-e109",
                "EGAS-e110", "EGAS-e111", "EGAS-e117", "EGAS-e118", "EGAS-e119",
                "EGAS-e120", "EGAS-e121", "EGAS-e122", "EGAS-e123", "EGAS-e124",
                "EGAS-e125", "EGAS-e126", "EGAS-e127", "EGAS-e128"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-01 (SG-01, EGAS e83). The requirement is derived in the pilot and the safety values it relies on are pending user approval (OI-07).";
        }
    }

    requirement def ExcessConfirmationRequirement {
        doc
        /* A detected torque excess shall be confirmed before the safe state is entered. The confirmation time is tbd; the latch design is left to the functional layer. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e105", "EGAS-e106", "EGAS-e107", "EGAS-e108", "EGAS-e109",
                "EGAS-e110", "EGAS-e111"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-01 (SG-01, EGAS e83). EGAS requires the excess to be detected and confirmed (SReq-06) but gives no confirmation time. Pending user approval (OI-07).";
        }
    }

    requirement def SafeStateEnforcementRequirement {
        doc
        /* On a safe state request the L2 reaction shall replace the torque demand with the safe state demand, warn the driver and pass the demand to the L2 output within the FTTI, independent of the demanded torque and without passing the L1 control. */
        attribute stage : SafeStateStage = SafeStateStage::TorqueLimited;
        attribute ftti : DurationQuantity = sg01Ftti;
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-01";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e87", "EGAS-e127");
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-01 (SG-01, EGAS e83). The stage and the FTTI follow the safety goal: both the stage and the FTTI (catalog sg01Ftti) are pilotAssumed (OI-07).";
        }
    }

    requirement def ControllerMonitoringRequirement {
        doc
        /* An independent monitoring module shall monitor the function controller by question and answer and, on a wrong answer, shut the engine off within the FTTI, independent of the L1 and L2 functions. The shut off takes priority over the demand and the safe state demand and does not change the operating mode; it follows the L2 reaction (TorqueLimited) as the last stage (FuelCutOff). These priority and stage order statements are pilot assumptions (OI-24). The number of wrong answers that confirm the fault (3) and the relation between the Q&A cycle and the detection time are pilot assumptions; l3Fdti and l3Frti are pilot candidates, so FDTI plus FRTI within the FTTI is not proven until they are approved (OI-23, A-19). */
        attribute stage : SafeStateStage = SafeStateStage::FuelCutOff;
        attribute ftti : DurationQuantity = sg01Ftti;
        attribute detectionTime : DurationQuantity = l3Fdti;
        attribute reactionTime : DurationQuantity = l3Frti;
        attribute qnaCycle : DurationQuantity = qnaCycleMax;
        attribute qnaQuestionCount : Integer = qnaQuestionCountMin;
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-04";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e111", "EGAS-e117", "EGAS-e118", "EGAS-e119", "EGAS-e120",
                "EGAS-e121", "EGAS-e122", "EGAS-e123", "EGAS-e124", "EGAS-e125",
                "EGAS-e126", "EGAS-e127", "EGAS-e128", "EGAS-e340", "EGAS-e369",
                "EGAS-e383"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-04 (SG-01, EGAS e83). EGAS requires the function controller monitoring (SReq-07) and an independent reaction (e127); the shut off stage and the FTTI are pilotAssumed, the Q&A values are standard catalog entries. The shut off priority, the unchanged mode and the stage order have no EGAS source and are pilotAssumed (OI-24); l3Fdti and l3Frti are pilotAssumed candidates (OI-23, OI-07, A-19).";
        }
    }

    requirement def PedalSensorFaultDetectionRequirement {
        doc
        /* The system shall detect a fault of a pedal value sensor channel by plausibility between the channels and report it to the limp home reaction. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-02";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e105", "EGAS-e106", "EGAS-e107", "EGAS-e108", "EGAS-e109",
                "EGAS-e110", "EGAS-e111"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-02 (SG-01, EGAS e83). EGAS requires the plausibility check (SReq-01, SReq-03); the assignment to this requirement is a pilot derivation (OI-07).";
        }
    }

    requirement def LimpHomeTorqueLimitRequirement {
        doc
        /* While the pedal fault status is set and the mode channel signals limp home, the L1 control shall limit the torque demand to the limp home torque limit before the demand reaches the L2 reaction (EGAS 11.1.1). */
        attribute torqueLimit : TorqueQuantity = limpHomeTorqueLimit;
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-02";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e445", "EGAS-e446", "EGAS-e447", "EGAS-e448", "EGAS-e449",
                "EGAS-e450", "EGAS-e451", "EGAS-e452", "EGAS-e453", "EGAS-e454",
                "EGAS-e455", "EGAS-e456", "EGAS-e457", "EGAS-e458", "EGAS-e459",
                "EGAS-e460", "EGAS-e461", "EGAS-e462", "EGAS-e463", "EGAS-e464",
                "EGAS-e465"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-02 (SG-01, EGAS e83). EGAS gives no limp home torque value, so the limit is the pilotAssumed catalog entry limpHomeTorqueLimit (OI-10).";
        }
    }

    requirement def BrakeOverrideTorqueRequirement {
        doc
        /* The torque arbitration shall give a brake application priority over the pedal torque demand and limit the propulsion torque to the controllable maximum, independent of the order of the inputs. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-03";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e197", "EGAS-e198", "EGAS-e199");
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-03 (SG-01, EGAS e83). The legacy L1 limit and timing are not carried over and no limit value is set. Pending user approval (OI-07).";
        }
    }

    requirement def ThrottleSensorFaultDetectionRequirement {
        doc
        /* The L2 monitor shall detect a fault of the throttle position sensor by plausibility of the engine sensor data and, once the fault is confirmed, send a safe state request to the L2 reaction. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "FSR-05";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e105", "EGAS-e106", "EGAS-e107", "EGAS-e108", "EGAS-e109",
                "EGAS-e110", "EGAS-e111"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from FSR-05 (SG-01, EGAS e83). EGAS requires the plausibility check of the throttle sensor (SReq-02, SReq-03) but names no reaction and no confirmation time; the safe state request follows the wording of the SHR and is a pilot derivation (OI-07). Pending user approval.";
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
    requirement sysrControllerMonitoring : ControllerMonitoringRequirement;
    requirement sysrThrottleSensorFaultDetection : ThrottleSensorFaultDetectionRequirement;

    #derivation connection sysrDerivesFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrTorqueComparison;
    }
    #derivation connection excessConfirmationFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrExcessConfirmation;
    }
    #derivation connection safeStateEnforcementFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrSafeStateEnforcement;
    }
    #derivation connection pedalSensorFaultFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrPedalSensorFaultDetection;
    }
    #derivation connection limpHomeLimitFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrLimpHomeTorqueLimit;
    }
    #derivation connection brakeOverrideFromShr {
        end #original ::> brakeShr;
        end #derive ::> sysrBrakeOverrideTorque;
    }
    #derivation connection arbitrationPriorityFromShr {
        end #original ::> responseShr;
        end #derive ::> sysrArbitrationPriority;
    }
    #derivation connection interventionReductionFromShr {
        end #original ::> interventionShr;
        end #derive ::> sysrInterventionReduction;
    }
    #derivation connection interventionReleaseFromShr {
        end #original ::> interventionShr;
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
    #derivation connection controllerMonitoringFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrControllerMonitoring;
    }
    #derivation connection throttleFaultFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrThrottleSensorFaultDetection;
    }

    // The behavior is not a source of a requirement; it refines the requirements it realizes.
    #refinement dependency behaviorRefinesSysr
        from l2Behavior
        to
            sysrTorqueComparison,
            sysrExcessConfirmation,
            sysrSafeStateEnforcement,
            sysrPedalSensorFaultDetection,
            sysrLimpHomeTorqueLimit,
            sysrBrakeOverrideTorque,
            sysrArbitrationPriority,
            sysrInterventionReduction,
            sysrInterventionRelease;

    // Each TSR derives from the FSR it refines; the FSRs derive from SG-01 in EgasArch_Shr_Fsr.
    #derivation connection torqueComparisonFromFsr {
        end #original ::> fsrTorqueExcessSafeState;
        end #derive ::> sysrTorqueComparison;
    }
    #derivation connection excessConfirmationFromFsr {
        end #original ::> fsrTorqueExcessSafeState;
        end #derive ::> sysrExcessConfirmation;
    }
    #derivation connection safeStateEnforcementFromFsr {
        end #original ::> fsrTorqueExcessSafeState;
        end #derive ::> sysrSafeStateEnforcement;
    }
    #derivation connection pedalSensorFaultFromFsr {
        end #original ::> fsrPedalSensorFaultLimpHome;
        end #derive ::> sysrPedalSensorFaultDetection;
    }
    #derivation connection limpHomeLimitFromFsr {
        end #original ::> fsrPedalSensorFaultLimpHome;
        end #derive ::> sysrLimpHomeTorqueLimit;
    }
    #derivation connection brakeOverrideFromFsr {
        end #original ::> fsrBrakeOverride;
        end #derive ::> sysrBrakeOverrideTorque;
    }
    #derivation connection controllerMonitoringFromFsr {
        end #original ::> fsrControllerFaultShutOff;
        end #derive ::> sysrControllerMonitoring;
    }
    #derivation connection throttleFaultFromFsr {
        end #original ::> fsrThrottleSensorFaultSafeState;
        end #derive ::> sysrThrottleSensorFaultDetection;
    }

    // Scenario to SYSR refinement; Scn cannot import Sysr, so the relation is declared here. It narrows the logical components a scenario passes.
    #refinement dependency monitorScenarioRefinesTorqueComparison
        from L2TorqueMonitorScenario
        to sysrTorqueComparison;
    #refinement dependency monitorScenarioRefinesExcessConfirmation
        from L2TorqueMonitorScenario
        to sysrExcessConfirmation;
    #refinement dependency monitorScenarioRefinesSafeStateEnforcement
        from L2TorqueMonitorScenario
        to sysrSafeStateEnforcement;
    #refinement dependency monitorScenarioRefinesControllerMonitoring
        from L2TorqueMonitorScenario
        to sysrControllerMonitoring;
    #refinement dependency monitorScenarioRefinesThrottleFault
        from L2TorqueMonitorScenario
        to sysrThrottleSensorFaultDetection;
    #refinement dependency limpHomeScenarioRefinesPedalSensorFault
        from PvsFaultLimpHomeScenario
        to sysrPedalSensorFaultDetection;
    #refinement dependency limpHomeScenarioRefinesLimpHomeLimit
        from PvsFaultLimpHomeScenario
        to sysrLimpHomeTorqueLimit;
    #refinement dependency brakeScenarioRefinesBrakeOverride
        from BrakeOverrideScenario
        to sysrBrakeOverrideTorque;
    #refinement dependency interventionScenarioRefinesReduction
        from TorqueInterventionScenario
        to sysrInterventionReduction;
    #refinement dependency interventionScenarioRefinesRelease
        from TorqueInterventionScenario
        to sysrInterventionRelease;
    #refinement dependency interventionScenarioRefinesArbitration
        from TorqueInterventionScenario
        to sysrArbitrationPriority;
    #refinement dependency demandScenarioRefinesOutputResponse
        from DriverTorqueDemandScenario
        to sysrPedalOutputResponse;
    #refinement dependency demandScenarioRefinesSteadyState
        from DriverTorqueDemandScenario
        to sysrSteadyStateTracking;
} // package EgasArch_Sysr_Requirement
