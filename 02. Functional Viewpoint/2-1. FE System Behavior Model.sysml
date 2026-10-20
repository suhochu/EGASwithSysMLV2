package FE_SystemBehaviorModel {
    private import FE_BehaviorModel::*;
    private import FB_ModeArbitrationModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    private import RV_ContextModel::*;

    private import SI::*;
    private import ScalarValues::*;

    @MetaInformation {
        version = "v0.3";
    }

    // ==========================================
    // FE 통합 시스템 동작 모델 (FE System Behavioral Model)
    // ==========================================
    state rvEgasState : RV_BehavioralModel::EgasBehavior;

    state FeEgasBehavior :> rvEgasState {
        // 외부 컨텍스트 시스템(EgasSystem)을 대변하는 파라미터 명시적 선언
        in sys_ignition : IgnitionState;
        in sys_accelInput : AccelerationIntent;
        in sys_brakeInput : BrakePedalPosition;
        in sys_ccCmd : CruiseControlCommand;
        in sys_sensorData : EngineSensorData;
        in sys_dynamicsStatus : VehicleDynamicsFeedback;
        in sys_combustionStatus : CombustionSystemStatus;
        in sys_torqueReq : TorqueInterventionRequest;
        in sys_calReq : CalibrationRequest;
        in sys_diagReq : DiagnosticRequest;

        in sys_pedalPosition : AccelerationPedalPosition; // ECU 내부 센서 입력 (페달 → ECU)
        in sys_throttleFeedback : ThrottlePositionFeedback; // (스로틀 → ECU)
        in sys_throttleCmd : ThrottlePositionCommand; // 스로틀 루프 목표 개도 (출력단 산출값을 감시 입력으로 사용)

        egas : EgasSystem;

        // 최종 시스템 출력 포트
        out sys_airCmd : IntakeAirFlow;
        out sys_fuelCmd : FuelIgnitionCommand;
        out sys_dashboard : DashboardWarning; // 운전자 경고 (SYSR-25)
        out sys_calStatus : CalibrationStatus; // 캘리브레이션 응답
        out sys_diagStatus : DiagnosticStatus; // 진단 응답

        // Mode Channel 포트 선언
        out modeChannelBroadcast : ModeChannelData;

        bind egas.ignitionPort.ignitionStatus = sys_ignition;
        bind egas.accelPort.accelIntent = sys_accelInput;
        bind egas.brakePort.brakeInput = sys_brakeInput;
        bind egas.ccPort.ccCmd = sys_ccCmd;
        bind egas.sensorPort.sensorData = sys_sensorData;
        bind egas.sensorPort.dynamicsStatus = sys_dynamicsStatus;
        bind egas.combustionStatusPort.combustionStatus = sys_combustionStatus;
        bind egas.torqueInterventionPort.torqueReq = sys_torqueReq;
        bind egas.calibrationPort.calReq = sys_calReq;
        bind egas.diagPort.diagReq = sys_diagReq;
        bind egas.pedal.pedalPosition = sys_pedalPosition;
        bind egas.throttle.positionFeedback = sys_throttleFeedback;
        bind egas.throttle.positionCommand = sys_throttleCmd;

        bind egas.airIntakePort.airFlow = sys_airCmd;
        bind egas.fuelCmdPort.fuelCmd = sys_fuelCmd;
        bind egas.dashboardPort.dashboardWarning = sys_dashboard;
        bind egas.calibrationPort.calStatus = sys_calStatus;
        bind egas.diagPort.diagStatus = sys_diagStatus;

        bind egas.ecu.ccState = drivingControlRegion.Out_CcState; // S9
        bind egas.ecu.ccSetSpeed = drivingControlRegion.Out_CcSetSpeed; // S9
        bind egas.ecu.confirmedFaultCause = safetyMonitoringRegion.Out_ConfirmedFaultCause; // S7

        attribute normalDriving : Boolean = SafeStateLogic::IsNormalDriving(
            sys_accelInput.pedalDisplacement,
            drivingControlRegion.Out_CcState,
            sys_brakeInput.pressure,
            safetyMonitoringRegion.Out_ConfirmedFaultCause,
            sys_torqueReq.requestedTorqueDelta
        );
        // 모드 채널 되먹임: 첫 주기 초기값. CF1은 직전 주기에 방송된 모드를 본다 (1주기 지연).
        // 모드는 플래그(cf2_active, cf3_faultActive)로만 정해져 CF1 출력에 의존하지 않으므로 대수 루프는 없다 (S2).
        entry action {
            assign modeChannelBroadcast.currentMode := SystemOperatingMode::Normal_Mode;
            assign modeChannelBroadcast.inhibitDrivingControl := false;
        }

        bind egas.ecu.activeInterventionSource = emergencyInterventionRegion.Out_ActiveSource; // M5 관측 속성

        // 상태 전이 시 충돌 방지를 위한 이벤트 우선순위 중재 제약
        constraint RaceConditionResolutionAndPriority {
            doc
            /* [중재 논리]
             * 동일한 제어 주기(systemClockCycle) 내에 외부 액터의 제동 입력(sys_brakeInput)과 
             * 내부 Arbiter의 안전(FailSafe) 차단 브로드캐스트(inhibitDrivingControl == true)가 
             * 동시에 발생(Simultaneous Events)할 수 있습니다.
             * 시스템의 물리적 안전 보장이 최우선이므로, 상태 머신은 브레이크 오버라이드(Brake Override)로 전이하는 것보다 
             * Mode Channel의 강제 대기(Forced Inhibited Standby) 차단 신호를 절대적으로 우선(Strictly Higher Priority)하여 평가하고 처리해야 합니다.
             * 제어 경로(페달, 크루즈)는 systemClockCycle 주기로 갱신되고 반응 경로(오버라이드, 개입, 고착 차단, 페일세이프, 보정)는 입력 이벤트로 즉시 처리된다(RV_InterfaceModel (C) 샘플링 지연 상수 참조).
             */
            modeChannelBroadcast.inhibitDrivingControl == true implies
            SafeStateLogic::IsFullCutOff(sys_airCmd.massFlow, sys_fuelCmd.injectionPulseWidth)
        }

        constraint BrakeOverrideSystemLevel {
            // SHR-01의 시스템 통합 수준 보장 (모드와 무관)
            doc
            /* 구동 요구 중 제동 입력이 있으면 Normal/Emergency/FailSafe 어느 모드에서도 최종 출력은 L1 이내여야 한다. */
            SafeStateLogic::IsBrakeOverrideTriggered(
                sys_accelInput.pedalDisplacement,
                drivingControlRegion.Out_CcState,
                sys_brakeInput.pressure
            ) implies
            SafeStateLogic::IsTorqueLimited(sys_airCmd.massFlow, sys_fuelCmd.injectionPulseWidth)
        }

        // 시스템 기동 시 모든 영역이 병렬로 실행됨 (Parallel Regions)
        // 1. 주행 토크 제어 상태 머신 (Extended 버전으로 교체)
        state redefines drivingControlRegion : ExtendedDrivingTorqueBehavior {
            bind In_Ignition = sys_ignition;
            bind In_CombustionSystemStatus = sys_combustionStatus;
            bind In_Accel = sys_accelInput;
            bind In_Brake = sys_brakeInput;
            bind In_CcCmd = sys_ccCmd;
            bind In_VehicleDynamics = sys_dynamicsStatus;
            bind In_NormalDriving = normalDriving;

            // Arbiter가 출력한 modeChannel 신호를 입력으로 받음
            bind In_ModeCtrl = modeChannelBroadcast;
            bind In_Sensor = sys_sensorData;
        }

        // 2. 긴급 토크 개입 상태 머신
        state
            redefines emergencyInterventionRegion
            : FE_BehaviorModel::EmergencyInterventionBehavior {
            // 시스템 경계의 피드백 데이터를 내부로 바인딩
            bind In_ThrottleCmd = sys_throttleCmd;
            bind In_TorqueReq = sys_torqueReq;
        }

        // 3. 안전 감시 상태 머신
        state redefines safetyMonitoringRegion : FE_BehaviorModel::SafetyMonitoringBehavior {
            // 이중화 센서 데이터 및 연소 상태 피드백 바인딩
            bind In_Sensor = sys_sensorData;
            bind In_PedalPosition = sys_pedalPosition;
            bind In_ThrottleFeedback = sys_throttleFeedback;
            bind In_Ignition = sys_ignition; // 래치 해제에 필요
            bind Out_Dashboard = sys_dashboard;
        }
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.calibrationHandling
            : FE_BehaviorModel::CalibrationSupportBehavior {
            bind In_Ignition = sys_ignition;
            bind In_VehicleSpeed = sys_dynamicsStatus.vehicleSpeed; // S9
            bind In_ExpectedCredential = egas.ecu.expectedAccessCredential;
            bind In_CalReq = sys_calReq;

            bind Out_CalRes = sys_calStatus;
        }
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
            : FE_BehaviorModel::DiagnosticsAndMaintenanceSupportBehavior {
            // 진단/유지보수 영역에도 센서 데이터 바인딩 적용
            bind In_FaultMemory = safetyMonitoringRegion.Out_FaultMemory; // Before: In_FaultCause = ...Out_ConfirmedFaultCause
            bind In_Ignition = sys_ignition;
            bind In_VehicleSpeed = sys_dynamicsStatus.vehicleSpeed;
            bind In_DiagReq = sys_diagReq;
            bind Out_DiagRes = sys_diagStatus;
        }

        // 다른 상태 영역들(drivingControlRegion 등)과 병렬로 상시 동작하며
        // 하위 시스템들의 출력을 모아 우선순위를 평가하고 최종 출력을 내보냅니다.
        state ModeArbitrationRegion {
            // 이 영역 내에서 Arbiter action을 상시 실행 (Do-behavior)
            do action systemArbiter : Arbiter {
                // 각 상태 영역에서 산출된 값을 Arbiter의 입력으로 바인딩 (기존과 동일)
                bind cf1_airCmd = drivingControlRegion.Out_AirCmd;
                bind cf1_fuelCmd = drivingControlRegion.Out_FuelCmd;

                bind cf2_airCmd = emergencyInterventionRegion.Out_AirCmd;
                bind cf2_fuelCmd = emergencyInterventionRegion.Out_FuelCmd;
                bind cf2_active = emergencyInterventionRegion.Out_Active;

                bind cf3_airCmd = safetyMonitoringRegion.Out_AirCmd;
                bind cf3_fuelCmd = safetyMonitoringRegion.Out_FuelCmd;
                bind cf3_faultActive = safetyMonitoringRegion.Out_FaultActive;

                // Arbiter의 최종 결정값을 기존의 내부 변수(finalAirCmd)가 아닌 외부 시스템 경계 출력(sys_airCmd)으로 다이렉트 바인딩
                bind final_airCmd = sys_airCmd;
                bind final_fuelCmd = sys_fuelCmd;
                bind modeChannelBroadcaster = modeChannelBroadcast;
            }
        }

        state redefines historyLatchRegion {
            transition historyTick
                first latching
                accept after TimingConceptsAndLimits::systemClockCycle
                do action {
                    assign egas.ecu.lastAirMassFlow := sys_airCmd.massFlow; // 직전 최종 출력 기록
                    assign egas.ecu.lastFuelPulseWidth := sys_fuelCmd.injectionPulseWidth;
                }
                then latching {
                dependency self to t_historyTick;
            }
        }
    }
} // package FE_SystemBehaviorModel
