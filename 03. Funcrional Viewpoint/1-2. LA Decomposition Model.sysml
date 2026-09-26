package LA_DecompositionModel {
    doc
    /* [논리 관점 (Logical Viewpoint) - 2단계: 아키텍처 분해 및 기능 할당]
     * 루트 컴포넌트(LogicalEgasSystem) 내부를 4개의 서브 컴포넌트로 분해합니다.
     * 기능 관점의 화이트박스(action)를 인스턴스화하여 perform으로 기능 할당을 수행하며,
     * 내부 통신은 Item을 페이로드로 갖는 논리 포트(port def)를 통해 완벽히 규정합니다.
     */

    private import RV_ContextModel::*;
    private import RV_InterfaceModel::*;
    private import LA_RootComponentModel::*;
    private import ReqCommon::*;

    private import FW_UF1_WhiteBoxModel::*;
    private import FW_CF2_WhiteBoxModel::*;
    private import FW_CF3_WhiteBoxModel::*;

    @MetaInformation {
        version = "v0.3";
    }

    // ==========================================
    // 1. 내부 통신용 논리 포트 정의 (Internal Port Definitions)
    // - Item(페이로드)을 주고받기 위한 명시적 포트 정의
    // ==========================================

    port def ValidAccelPort {
        out validAccel : AccelerationIntent;
    }
    port def CutoffTriggerPort {
        out cutoffTrigger : FW_UF1_WhiteBoxModel::InternalCutoffSignal;
    }
    port def DelaySignalPort {
        out delaySignal : FW_CF2_WhiteBoxModel::InternalDelaySignal;
    }
    port def TargetTorquePort {
        out targetTorque : FW_UF1_WhiteBoxModel::InternalTorqueDemand;
    }
    port def ModeStatusPort {
        out modeStatus : FB_ModeArbitrationModel::SystemOperatingMode;
    }
    port def FatalTriggerPort {
        out fatalTrigger : FW_CF3_WhiteBoxModel::InternalFatalTrigger;
    }

    // ==========================================
    // 2. 논리 서브 컴포넌트 정의 및 기능 할당
    // ==========================================

    part def InputProcessingComponent {
        // [외부 경계 위임용 포트]
        port p_inAccel : AccelerationInputPort;
        port p_inBrake : BrakeInputPort;
        port p_inSensor : SensorInputPort;
        port p_inTorqueReq : TorqueInterventionPort;

        // [내부 통신용 출력 포트]
        port p_outValidAccel : ValidAccelPort;
        port p_outCutoffTrigger : CutoffTriggerPort;
        port p_outDelaySignal : DelaySignalPort;

        // [기능 화이트박스 액션 인스턴스화]
        action uF1_1_WB : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox;
        action uF1_2_WB : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox;
        action uF1_3_WB : FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox;
        action uF2_1_WB : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox;
        action uF2_2_WB : FW_CF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox;
        action uF2_3_WB : FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox;

        // [기능 할당 (Function Allocation)]
        perform uF1_1_WB.filterPedalInput;
        perform uF1_2_WB.processCruiseCommand;
        perform uF1_3_WB.detectBrake;
        perform uF2_1_WB.receiveInterventionReq;
        perform uF2_2_WB.monitorCommLatency;
        perform uF2_3_WB.detectActuatorStuck;
    }

    part def TorqueArbitrationComponent {
        // [내부 통신용 입력 포트 (Conjugated ~)]
        port p_inValidAccel : ~ValidAccelPort;
        port p_inTorqueReq : TorqueInterventionPort;

        // [내부 통신용 출력 포트]
        port p_outTargetTorque : TargetTorquePort;
        port p_outModeStatus : ModeStatusPort;

        action uF1_1_WB : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox;
        action uF1_2_WB : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox;
        action uF2_1_WB : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox;
        action arbiter_WB : FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox;

        perform uF1_1_WB.calcManualTorque;
        perform uF1_2_WB.calcCruiseTorque;
        perform uF2_1_WB.calcReductionTorque;
        perform arbiter_WB.evaluatePriority;
    }

    part def SafetyMonitorComponent {
        port p_inSensor : SensorInputPort;

        port p_outFatalTrigger : FatalTriggerPort;
        port p_outDashboard : DashboardPort;

        action uF3_1_WB : FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox;
        action uF3_2_WB : FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox;

        perform uF3_1_WB.monitorSensorError;
        perform uF3_2_WB.checkCriticalLimits;
    }

    part def ActuatorControlComponent {
        // [내부 통신용 입력 포트 (Conjugated ~)]
        port p_inTargetTorque : ~TargetTorquePort;
        port p_inCutoffTrigger : ~CutoffTriggerPort;
        port p_inFatalTrigger : ~FatalTriggerPort;

        port p_outAir : AirIntakePort;
        port p_outFuel : FuelCommandPort;

        action uF1_1_WB : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox;
        action uF1_3_WB : FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox;
        action uF2_3_WB : FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox;
        action uF3_2_WB : FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox;

        perform uF1_1_WB.genEngineCommand;
        perform uF1_3_WB.arbitrateOverride;
        perform uF2_3_WB.executeEmergencyFuelCut;
        perform uF3_2_WB.shutdownSystem;
    }

    // ==========================================
    // 3. 루트 컴포넌트 재정의 및 내부 배선 (Internal Routing)
    // ==========================================

    part def DecomposedLogicalEgasSystem :> LogicalEgasSystem {
        doc
        /* 분해된 서브 컴포넌트를 인스턴스화하고 내부 포트를 통해 배선(Connect)합니다. */

        // 3.1 서브 컴포넌트 인스턴스화
        part inputProcessor : InputProcessingComponent;
        part torqueArbiter : TorqueArbitrationComponent;
        part safetyMonitor : SafetyMonitorComponent;
        part actuatorController : ActuatorControlComponent;

        // 3.2 시스템 외부 경계(External Boundary) ↔ 내부 컴포넌트 간 연결
        connect accelPort to inputProcessor.p_inAccel;
        connect brakePort to inputProcessor.p_inBrake;
        connect sensorPort to inputProcessor.p_inSensor;
        connect torqueInterventionPort to inputProcessor.p_inTorqueReq;

        connect sensorPort to safetyMonitor.p_inSensor;

        connect safetyMonitor.p_outDashboard to dashboardPort;
        connect actuatorController.p_outAir to airIntakePort;
        connect actuatorController.p_outFuel to fuelCmdPort;

        // 3.3 내부 컴포넌트 ↔ 내부 컴포넌트 간 완벽한 포트 배선 (Conjugated Matching)
        connect inputProcessor.p_outValidAccel to torqueArbiter.p_inValidAccel;
        connect inputProcessor.p_outCutoffTrigger to actuatorController.p_inCutoffTrigger;

        connect torqueArbiter.p_outTargetTorque to actuatorController.p_inTargetTorque;

        connect safetyMonitor.p_outFatalTrigger to actuatorController.p_inFatalTrigger;
    }
} // package LA_DecompositionModel
