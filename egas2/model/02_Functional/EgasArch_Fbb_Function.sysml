package EgasArch_Fbb_Function {
    private import ScalarValues::Boolean;
    private import EgasArch_Common_Enums::OperatingMode;
    private import EgasArch_Common_Enums::ValueStatusKind;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Beh_Behavior::TorqueDemand;
    private import EgasArch_Sysr_Requirement::*;
    private import EgasArch_Shr_Fsr::*;

    // activeModes is a pilot allocation; the entry conditions of limpHome and safeState are tbd.
    action def TorqueComparisonFunction {
        doc
        /* UF-01: compare the actual with the permissible torque and flag an excess. Observable at the system boundary through the pedal and the engine signals. */
        in pedalPosition : AccelerationPedalPosition;
        in engineSensor : EngineSensorData;
        out excessFlag : TorqueExcessFlag;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
        );
    }

    action def ExcessConfirmationFunction {
        doc
        /* UF-02: confirm a flagged torque excess before the safe state is requested. The confirmation time is tbd. */
        in excessFlag : TorqueExcessFlag;
        out safeStateRequest : SafeStateRequest;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
        );
    }

    action def SafeStateEnforcementFunction {
        doc
        /* UF-03: on a confirmed excess force the torque demand to the safe state, independent of the driver request, and warn the driver. Otherwise it passes the demand on, so it is the only path of the torque demand to the output function. */
        in safeStateRequest : SafeStateRequest;
        in demand : TorqueDemand;
        out safeDemand : TorqueDemand;
        out warning : DashboardWarning;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
        );
    }

    action def PedalSensorFaultDetectionFunction {
        doc
        /* UF-04: detect a fault of the pedal value sensor channels by plausibility. The fault condition for limp home is tbd. */
        in pedalPosition : AccelerationPedalPosition;
        out pedalFault : PedalFaultStatus;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention,
        );
    }

    action def LimpHomeTorqueLimitFunction {
        doc
        /* UF-05: keep the torque demand limited in limp home after a confirmed pedal sensor fault. The limit value is the pilotAssumed catalog entry limpHomeTorqueLimit. */
        in pedalFault : PedalFaultStatus;
        in modeChannel : ModeChannel;
        in demand : TorqueDemand;
        out limitedDemand : TorqueDemand;
        attribute activeModes : OperatingMode [1..*] = OperatingMode::limpHome;
    }

    action def TorqueArbitrationFunction {
        doc
        /* UF-06: turn the pedal, brake and intervention inputs into the torque demand, give the safety reactions priority and broadcast the mode channel. Cruise control is out of the pilot scope. */
        in pedalPosition : AccelerationPedalPosition;
        in brakePosition : BrakePedalPosition;
        in torqueRequest : TorqueInterventionRequest;
        in pedalFault : PedalFaultStatus;
        in safeStateRequest : SafeStateRequest;
        out demand : TorqueDemand;
        out modeChannel : ModeChannel;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
        );
    }

    action def PedalOutputResponseFunction {
        doc
        /* UF-07: output the air and the fuel commands for the torque demand, and shut them off on a shut off request of the independent monitoring module. The shut off takes priority over the demand and the safe state demand, does not change the operating mode, and is latched until the next driving cycle (pilot assumption, OI-24). */
        in demand : TorqueDemand;
        in engineSensor : EngineSensorData;
        in shutOffRequest : ShutOffRequest;
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
        attribute shutOffLatched : Boolean = true {
            @SourceRef { document = "EGAS v6.0"; itemId = ("EGAS-e403", "EGAS-e404"); }
            @ValueStatus {
                status = ValueStatusKind::pilotAssumed;
                rationale =
                    "EGAS tests the shut off path once per driving cycle (e403) and allows engine drive only after the test succeeds (e404) but gives no latch rule; the latch, its release by a new driving cycle and the Boolean default are pilot derivations, not a catalog value, and not approved (OI-24).";
            }
        }
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
        );
    }

    action def ControllerMonitoringFunction {
        doc
        /* UF-08: ask the function controller questions, check its answers and request the shut off on a wrong answer, independent of the L1 and L2 functions except the Q&A partner UF-09. */
        in qnaAnswer : QnaAnswer;
        out qnaQuestion : QnaQuestion;
        out shutOffRequest : ShutOffRequest;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
        );
    }

    action def QnaAnsweringFunction {
        doc
        /* UF-09: the L3_SW role in the function controller; answer the questions of UF-08. Its internal behavior is not modeled. */
        in qnaQuestion : QnaQuestion;
        out qnaAnswer : QnaAnswer;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
        );
    }

    action def ThrottleSensorFaultDetectionFunction {
        doc
        /* UF-10: detect a fault of the throttle position sensor by plausibility of the engine sensor data and request the safe state once the fault is confirmed. The plausibility rule and the confirmation time are tbd. */
        in engineSensor : EngineSensorData;
        out safeStateRequest : SafeStateRequest;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
        );
    }

    action def EgasUserFunctions {
        doc
        /* Hierarchy of the user functions of the pilot scope. */
        action torqueComparison : TorqueComparisonFunction;
        action excessConfirmation : ExcessConfirmationFunction;
        action safeStateEnforcement : SafeStateEnforcementFunction;
        action pedalSensorFaultDetection : PedalSensorFaultDetectionFunction;
        action limpHomeTorqueLimit : LimpHomeTorqueLimitFunction;
        action torqueArbitration : TorqueArbitrationFunction;
        action pedalOutputResponse : PedalOutputResponseFunction;
        action controllerMonitoring : ControllerMonitoringFunction;
        action qnaAnswering : QnaAnsweringFunction;
        action throttleSensorFaultDetection : ThrottleSensorFaultDetectionFunction;

        flow torqueComparison.excessFlag to excessConfirmation.excessFlag;
        flow excessConfirmation.safeStateRequest to safeStateEnforcement.safeStateRequest;
        flow excessConfirmation.safeStateRequest to torqueArbitration.safeStateRequest;
        flow throttleSensorFaultDetection.safeStateRequest to safeStateEnforcement.safeStateRequest;
        flow throttleSensorFaultDetection.safeStateRequest to torqueArbitration.safeStateRequest;
        flow pedalSensorFaultDetection.pedalFault to limpHomeTorqueLimit.pedalFault;
        flow pedalSensorFaultDetection.pedalFault to torqueArbitration.pedalFault;
        flow torqueArbitration.modeChannel to limpHomeTorqueLimit.modeChannel;
        flow torqueArbitration.demand to safeStateEnforcement.demand;
        flow torqueArbitration.demand to limpHomeTorqueLimit.demand;
        // The demand reaches pedalOutputResponse only through safeStateEnforcement; its source is selected by the active mode and the selection rule is not modeled here.
        flow limpHomeTorqueLimit.limitedDemand to safeStateEnforcement.demand;
        flow safeStateEnforcement.safeDemand to pedalOutputResponse.demand;
        // The shut off request reaches pedalOutputResponse without passing the torque arbitration or the safe state enforcement.
        flow controllerMonitoring.shutOffRequest to pedalOutputResponse.shutOffRequest;
        // The Q&A flows pass only through qnaAnswering, not through the torque arbitration or the output response.
        flow controllerMonitoring.qnaQuestion to qnaAnswering.qnaQuestion;
        flow qnaAnswering.qnaAnswer to controllerMonitoring.qnaAnswer;
    }

    action egasUf : EgasUserFunctions;

    satisfy fsrTorqueExcessSafeState by egasUf.torqueComparison;
    satisfy fsrTorqueExcessSafeState by egasUf.excessConfirmation;
    satisfy fsrTorqueExcessSafeState by egasUf.safeStateEnforcement;
    satisfy fsrTorqueExcessSafeState by egasUf.pedalOutputResponse;
    satisfy fsrControllerFaultShutOff by egasUf.controllerMonitoring;
    satisfy fsrControllerFaultShutOff by egasUf.pedalOutputResponse;
    satisfy fsrControllerFaultShutOff by egasUf.qnaAnswering;
    satisfy fsrPedalSensorFaultLimpHome by egasUf.pedalSensorFaultDetection;
    satisfy fsrPedalSensorFaultLimpHome by egasUf.limpHomeTorqueLimit;
    satisfy fsrBrakeOverride by egasUf.torqueArbitration;
    satisfy fsrThrottleSensorFaultSafeState by egasUf.throttleSensorFaultDetection;
    satisfy fsrThrottleSensorFaultSafeState by egasUf.safeStateEnforcement;
    satisfy sysrArbitrationPriority by egasUf.torqueArbitration;
    satisfy sysrInterventionReduction by egasUf.torqueArbitration;
    satisfy sysrInterventionRelease by egasUf.torqueArbitration;
    satisfy sysrSteadyStateTracking by egasUf.torqueArbitration;
    satisfy sysrPedalOutputResponse by egasUf.pedalOutputResponse;
} // package EgasArch_Fbb_Function
