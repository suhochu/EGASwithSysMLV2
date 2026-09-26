package LA_DecompositionModel {
    doc
    /* [논리 관점 (Logical Viewpoint) - 2단계: 아키텍처 분해 및 기능 할당]
     * 기능 관점 화이트박스에서 도출된 총 23개의 세부 소기능(Action)을 
     * 4개의 논리 서브 컴포넌트에 100% 누락 없이 완전하게 할당(Allocation)합니다.
     */

    private import RV_ContextModel::*;
    private import RV_InterfaceModel::*;
    private import LA_RootComponentModel::*;
    private import ReqCommon::*;

    private import FW_UF1_WhiteBoxModel::*;
    private import FW_CF2_WhiteBoxModel::*;
    private import FW_CF3_WhiteBoxModel::*;

    @MetaInformation {
        version = "v0.5";
    }

    // ==========================================
    // 1. 내부 통신용 논리 포트 정의 (데이터 vs 제어 분리)
    // ==========================================

    port def ControlChannels;
    port def DataChannels;

    // [Data Ports] 연속적인 물리량 및 명령 데이터
    port def ValidAccelPort :> DataChannels { out validAccel : AccelerationIntent; }
    port def ValidCcCmdPort :> DataChannels { out validCcCmd : CruiseControlCommand; }
    port def ValidTorqueReqPort :> DataChannels {
        out validTorqueReq : TorqueInterventionRequest;
    }
    port def TargetTorquePort :> DataChannels {
        out targetTorque : FW_UF1_WhiteBoxModel::InternalTorqueDemand;
    }
    port def CorrectionCmdPort :> DataChannels {
        out correctionCmd : FW_CF3_WhiteBoxModel::InternalCorrectionCmd;
    }

    // [Control Ports] 상태 전이 및 강제 제어(트리거) 신호
    port def CutoffTriggerPort :> ControlChannels {
        out cutoffTrigger : FW_UF1_WhiteBoxModel::InternalCutoffSignal;
    }
    port def DelaySignalPort :> ControlChannels {
        out delaySignal : FW_CF2_WhiteBoxModel::InternalDelaySignal;
    }
    port def ModeStatusPort :> ControlChannels {
        out modeStatus : FB_ModeArbitrationModel::SystemOperatingMode;
    }
    port def FatalTriggerPort :> ControlChannels {
        out fatalTrigger : FW_CF3_WhiteBoxModel::InternalFatalTrigger;
    }

    // ==========================================
    // 2. 논리 서브 컴포넌트 정의 및 기능 전체 할당
    // ==========================================

    part def InputProcessingComponent {
        // [외부 ↔ 내부 수신 포트]
        port p_inAccel : AccelerationInputPort;
        port p_inBrake : BrakeInputPort;
        port p_inCcCmd : CruiseControlPort;
        port p_inSensor : SensorInputPort;
        port p_inTorqueReq : TorqueInterventionPort;

        // [내부 ↔ 내부 송신 포트]
        port p_outValidAccel : ValidAccelPort;
        port p_outValidCcCmd : ValidCcCmdPort;
        port p_outValidTorqueReq : ValidTorqueReqPort;
        port p_outCutoffTrigger : CutoffTriggerPort;
        port p_outDelaySignal : DelaySignalPort;

        action uF1_1_WB : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox;
        action uF1_2_WB : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox;
        action uF1_3_WB : FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox;
        action uF2_1_WB : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox;
        action uF2_2_WB : FW_CF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox;
        action uF2_3_WB : FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox;

        // [할당: Sensing 6개 기능 전체]
        perform uF1_1_WB.filterPedalInput;
        perform uF1_2_WB.processCruiseCommand;
        perform uF1_3_WB.detectBrake;
        perform uF2_1_WB.receiveInterventionReq;
        perform uF2_2_WB.monitorCommLatency;
        perform uF2_3_WB.detectActuatorStuck;
    }

    part def TorqueArbitrationComponent {
        // [외부/내부 ↔ 내부 수신 포트]
        port p_inIgnition : IgnitionPort;
        port p_inCombustionStatus : CombustionStatusPort;
        port p_inValidAccel : ~ValidAccelPort;
        port p_inValidCcCmd : ~ValidCcCmdPort;
        port p_inValidTorqueReq : ~ValidTorqueReqPort;

        // [내부 ↔ 내부 송신 포트]
        port p_outTargetTorque : TargetTorquePort;
        port p_outModeStatus : ModeStatusPort;

        action uF1_1_WB : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox;
        action uF1_2_WB : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox;
        action uF2_1_WB : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox;
        action arbiter_WB : FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox;

        // [할당: Core Logic & Arbitration 6개 기능 전체]
        perform uF1_1_WB.calcManualTorque;
        perform uF1_2_WB.calcCruiseTorque;
        perform uF2_1_WB.calcReductionTorque;
        perform arbiter_WB.collectInputs;
        perform arbiter_WB.evaluatePriority;
        perform arbiter_WB.broadcastOutput;
    }

    part def SafetyMonitorComponent {
        // [외부 ↔ 내부 수신 포트]
        port p_inSensor : SensorInputPort;
        port p_inCombustionStatus : CombustionStatusPort;

        // [내부 ↔ 내부 송신 포트]
        port p_outFatalTrigger : FatalTriggerPort;
        port p_outCorrectionCmd : CorrectionCmdPort;

        action uF3_1_WB : FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox;
        action uF3_2_WB : FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox;

        // [할당: Safety & Correction 3개 기능 전체]
        perform uF3_1_WB.monitorSensorError;
        perform uF3_1_WB.calcCorrectionValue;
        perform uF3_2_WB.checkCriticalLimits;
    }

    part def ActuatorControlComponent {
        // [내부 ↔ 내부 수신 포트 (Conjugated)]
        port p_inTargetTorque : ~TargetTorquePort;
        port p_inCutoffTrigger : ~CutoffTriggerPort;
        port p_inFatalTrigger : ~FatalTriggerPort;
        port p_inDelaySignal : ~DelaySignalPort;
        port p_inModeStatus : ~ModeStatusPort;
        port p_inCorrectionCmd : ~CorrectionCmdPort;

        // [내부 ↔ 외부(물리적 액추에이터) 송신 포트]
        port p_outAir : AirIntakePort;
        port p_outFuel : FuelCommandPort;
        port p_outDashboard : DashboardPort;

        action uF1_1_WB : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox;
        action uF1_2_WB : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox;
        action uF1_3_WB : FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox;
        action uF2_1_WB : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox;
        action uF2_2_WB : FW_CF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox;
        action uF2_3_WB : FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox;
        action uF3_1_WB : FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox;
        action uF3_2_WB : FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox;

        // [할당: Actuation & Cut-off 8개 기능 전체]
        perform uF1_1_WB.genEngineCommand;
        perform uF1_2_WB.genEngineCommandOut;
        perform uF1_3_WB.arbitrateOverride;
        perform uF2_1_WB.limitActuatorOutput;
        perform uF2_2_WB.holdPreviousState;
        perform uF2_3_WB.executeEmergencyFuelCut;
        perform uF3_1_WB.applyCorrection;
        perform uF3_2_WB.shutdownSystem;
    }

    // ==========================================
    // 3. 루트 컴포넌트 재정의 및 내부 논리 채널 배선
    // ==========================================

    part def DecomposedLogicalEgasSystem :> LogicalEgasSystem {
        part inputProcessor : InputProcessingComponent;
        part torqueArbiter : TorqueArbitrationComponent;
        part safetyMonitor : SafetyMonitorComponent;
        part actuatorController : ActuatorControlComponent;

        // 3.1 External Boundary ↔ Internal Component Connections
        bind accelPort = inputProcessor.p_inAccel;
        bind brakePort = inputProcessor.p_inBrake;
        bind ccPort = inputProcessor.p_inCcCmd;
        bind torqueInterventionPort = inputProcessor.p_inTorqueReq;

        bind sensorPort = inputProcessor.p_inSensor;
        bind sensorPort = safetyMonitor.p_inSensor;

        bind combustionStatusPort = torqueArbiter.p_inCombustionStatus;
        bind combustionStatusPort = safetyMonitor.p_inCombustionStatus;
        bind ignitionPort = torqueArbiter.p_inIgnition;

        bind actuatorController.p_outAir = airIntakePort;
        bind actuatorController.p_outFuel = fuelCmdPort;
        bind actuatorController.p_outDashboard = dashboardPort; // RV_ContextModel의 dashboardPort로 연결됨

        // 3.2 Internal ↔ Internal Connections & Flows

        // [채널 1] 입력 처리부 -> 중재부 (Data)
        connect inputProcessor.p_outValidAccel to torqueArbiter.p_inValidAccel {
            flow of AccelerationIntent
                from inputProcessor.p_outValidAccel to torqueArbiter.p_inValidAccel;
        }

        connect inputProcessor.p_outValidCcCmd to torqueArbiter.p_inValidCcCmd {
            flow of CruiseControlCommand
                from inputProcessor.p_outValidCcCmd to torqueArbiter.p_inValidCcCmd;
        }

        connect inputProcessor.p_outValidTorqueReq to torqueArbiter.p_inValidTorqueReq {
            flow of TorqueInterventionRequest
                from inputProcessor.p_outValidTorqueReq to torqueArbiter.p_inValidTorqueReq;
        }

        // [채널 2] 중재부 -> 액추에이터 제어부 (Data & Control)
        connect torqueArbiter.p_outTargetTorque to actuatorController.p_inTargetTorque {
            flow of FW_UF1_WhiteBoxModel::InternalTorqueDemand
                from torqueArbiter.p_outTargetTorque to actuatorController.p_inTargetTorque;
        }

        connect torqueArbiter.p_outModeStatus to actuatorController.p_inModeStatus {
            flow of FB_ModeArbitrationModel::SystemOperatingMode
                from torqueArbiter.p_outModeStatus to actuatorController.p_inModeStatus;
        }

        // [채널 3] 고속/비가역 차단 트리거 배선 (Control - Direct Routing)
        connect inputProcessor.p_outCutoffTrigger to actuatorController.p_inCutoffTrigger {
            flow of FW_UF1_WhiteBoxModel::InternalCutoffSignal
                from inputProcessor.p_outCutoffTrigger to actuatorController.p_inCutoffTrigger;
        }

        connect inputProcessor.p_outDelaySignal to actuatorController.p_inDelaySignal {
            flow of FW_CF2_WhiteBoxModel::InternalDelaySignal
                from inputProcessor.p_outDelaySignal to actuatorController.p_inDelaySignal;
        }

        // [채널 4] 안전 감시기 -> 액추에이터 제어부 (Control & Data)
        connect safetyMonitor.p_outFatalTrigger to actuatorController.p_inFatalTrigger {
            flow of FW_CF3_WhiteBoxModel::InternalFatalTrigger
                from safetyMonitor.p_outFatalTrigger to actuatorController.p_inFatalTrigger;
        }

        connect safetyMonitor.p_outCorrectionCmd to actuatorController.p_inCorrectionCmd {
            flow of FW_CF3_WhiteBoxModel::InternalCorrectionCmd
                from safetyMonitor.p_outCorrectionCmd to actuatorController.p_inCorrectionCmd;
        }
    }
} // package LA_DecompositionModel
