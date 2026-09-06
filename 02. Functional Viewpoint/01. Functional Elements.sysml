package EgasFunctionalArchitecture {
    private import EgasSystemContext::*;
    private import EgasUseCaseActivities::*;

    // ==========================================
    // 1. 포트 정의 (Port Definitions)
    // - 방향성(out, in)은 포트 자체가 아닌 내부 피처(item)에 지정합니다.
    // - 재사용성을 높이기 위해 기본적으로 송신(out) 기준으로 정의합니다.
    // ==========================================

    port def EngineStatePort { out item stateData; }
    port def DriverDemandPort { out item demandData; }
    port def BrakeStatePort { out item brakeData; }
    port def ExtRequestPort { out item requestData; }
    port def FlagPort { out item triggerFlag; }
    port def TorquePort { out item torqueValue; }
    port def ActuatorCmdPort { out item cmdSignal; }

    // ==========================================
    // 2. 기능 블록 (Functional Blocks) 정의
    // - 수신 포트는 공액 포트(~)를 사용하여 out 방향을 in으로 역전시킵니다.
    // ==========================================

    part def InputDataAcquisition {
        // 외부로부터 수신하므로 공액 포트(~) 사용
        port rawSensorData : ~EngineStatePort;
        port rawPedalInput : ~DriverDemandPort;
        port rawBrakeInput : ~BrakeStatePort;
        port rawExternalIntervention : ~ExtRequestPort;

        // 내부 다른 블록으로 송신하므로 기본 포트 사용
        port processedEngineState : EngineStatePort;
        port validatedDriverDemand : DriverDemandPort;
        port validatedBrakeState : BrakeStatePort;
        port validatedExtRequest : ExtRequestPort;
    }

    part def SafetyMonitoringAndOverride {
        port validatedDriverDemand : ~DriverDemandPort;
        port validatedBrakeState : ~BrakeStatePort;
        port actuatorFeedback : ~ActuatorCmdPort;

        port brakeOverrideFlag : FlagPort;
        port safeStateTrigger : FlagPort;
    }

    part def TorqueCoordinator {
        port validatedDriverDemand : ~DriverDemandPort;
        port validatedExtRequest : ~ExtRequestPort;
        port cruiseControlDemand : ~TorquePort;
        port brakeOverrideFlag : ~FlagPort;
        port safeStateTrigger : ~FlagPort;

        port finalTargetTorque : TorquePort;
    }

    part def EngineCombustionControl {
        port finalTargetTorque : ~TorquePort;
        port processedEngineState : ~EngineStatePort;

        port targetThrottleAngle : ActuatorCmdPort;
        port injectionDuration : ActuatorCmdPort;
        port sparkTiming : ActuatorCmdPort;
    }

    part def ActuatorCommandAndOutput {
        port targetThrottleAngle : ~ActuatorCmdPort;
        port injectionDuration : ~ActuatorCmdPort;
        port sparkTiming : ~ActuatorCmdPort;

        port throttleMotorCommand : ActuatorCmdPort;
        port fuelIgnitionCommand : ActuatorCmdPort;
    }

    // ==========================================
    // 3. 기능 아키텍처 통합 및 흐름 (Flow) 정의
    // ==========================================
    part def EgasFunctionalSystem {
        part inputAcquisition : InputDataAcquisition;
        part safetyMonitor : SafetyMonitoringAndOverride;
        part torqueCoord : TorqueCoordinator;
        part combustionCtrl : EngineCombustionControl;
        part actuatorCmd : ActuatorCommandAndOutput;

        // [흐름 연결] 공액 포트와 기본 포트 간의 연결 (방향성이 일치하여 연결 가능)
        flow inputAcquisition.validatedDriverDemand to safetyMonitor.validatedDriverDemand;
        flow inputAcquisition.validatedBrakeState to safetyMonitor.validatedBrakeState;

        flow inputAcquisition.validatedDriverDemand to torqueCoord.validatedDriverDemand;
        flow inputAcquisition.validatedExtRequest to torqueCoord.validatedExtRequest;
        flow safetyMonitor.brakeOverrideFlag to torqueCoord.brakeOverrideFlag;
        flow safetyMonitor.safeStateTrigger to torqueCoord.safeStateTrigger;

        flow torqueCoord.finalTargetTorque to combustionCtrl.finalTargetTorque;
        flow inputAcquisition.processedEngineState to combustionCtrl.processedEngineState;

        flow combustionCtrl.targetThrottleAngle to actuatorCmd.targetThrottleAngle;
        flow combustionCtrl.injectionDuration to actuatorCmd.injectionDuration;
        flow combustionCtrl.sparkTiming to actuatorCmd.sparkTiming;
    }
} // package EgasFunctionalArchitecture
