package EgasArch_Fbb_Function {
    private import EgasArch_Common_Enums::OperatingMode;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Beh_Behavior::TorqueDemand;
    private import EgasArch_Sysr_Requirement::*;

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
        /* UF-07: output the air and the fuel commands for the torque demand, and shut them off on a shut off request of the independent monitoring module. */
        in demand : TorqueDemand;
        in engineSensor : EngineSensorData;
        in shutOffRequest : ShutOffRequest;
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
        );
    }

    action def ControllerMonitoringFunction {
        doc
        /* UF-08: ask the function controller questions, check its answers and request the shut off on a wrong answer, independent of the L1 and L2 functions. The partner of the Q&A is inside the function controller and is not modeled. */
        in qnaAnswer : QnaAnswer;
        out qnaQuestion : QnaQuestion;
        out shutOffRequest : ShutOffRequest;
        attribute activeModes : OperatingMode [1..*] = (
            OperatingMode::normal, OperatingMode::intervention, OperatingMode::limpHome,
            OperatingMode::safeState,
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

        flow torqueComparison.excessFlag to excessConfirmation.excessFlag;
        flow excessConfirmation.safeStateRequest to safeStateEnforcement.safeStateRequest;
        flow excessConfirmation.safeStateRequest to torqueArbitration.safeStateRequest;
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
    }

    action egasUf : EgasUserFunctions;

    satisfy sysrTorqueComparison by egasUf.torqueComparison;
    satisfy sysrExcessConfirmation by egasUf.excessConfirmation;
    satisfy sysrSafeStateEnforcement by egasUf.safeStateEnforcement;
    satisfy sysrSafeStateEnforcement by egasUf.pedalOutputResponse;
    satisfy sysrControllerMonitoring by egasUf.controllerMonitoring;
    satisfy sysrControllerMonitoring by egasUf.pedalOutputResponse;
    satisfy sysrPedalSensorFaultDetection by egasUf.pedalSensorFaultDetection;
    satisfy sysrLimpHomeTorqueLimit by egasUf.limpHomeTorqueLimit;
    satisfy sysrBrakeOverrideTorque by egasUf.torqueArbitration;
    satisfy sysrArbitrationPriority by egasUf.torqueArbitration;
    satisfy sysrInterventionReduction by egasUf.torqueArbitration;
    satisfy sysrInterventionRelease by egasUf.torqueArbitration;
    satisfy sysrSteadyStateTracking by egasUf.torqueArbitration;
    satisfy sysrPedalOutputResponse by egasUf.pedalOutputResponse;
} // package EgasArch_Fbb_Function
