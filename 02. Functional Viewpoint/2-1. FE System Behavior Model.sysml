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
        in sys_combustionStatus : CombustionSystemStatus;
        in sys_sensorData : EngineSensorData;
        in sys_airFeedback : IntakeAirFlow;

        in sys_brakeInput : BrakePedalPosition;

        // Mode Channel 포트 선언
        out modeChannelBroadcast : ModeChannelData;

        // 최종 시스템 출력 포트
        out sys_airCmd : IntakeAirFlow;
        out sys_fuelCmd : FuelIgnitionCommand;

        attribute systemClockCycle : TimeValue = 10.0 [milli * s]; // 시스템 제어 주기 (Clock Domain) 명시

        // 상태 전이 시 충돌 방지를 위한 이벤트 우선순위 중재 제약
        constraint RaceConditionResolutionAndPriority {
            doc
            /* [중재 논리]
             * 동일한 제어 주기(systemClockCycle) 내에 외부 액터의 제동 입력(sys_brakeInput)과 
             * 내부 Arbiter의 긴급/안전 차단 브로드캐스트(inhibitDrivingControl == true)가 
             * 동시에 발생(Simultaneous Events)할 수 있습니다.
             * 시스템의 물리적 안전 보장이 최우선이므로, 상태 머신은 브레이크 오버라이드(Brake Override)로 전이하는 것보다 
             * Mode Channel의 강제 대기(Forced Inhibited Standby) 차단 신호를 절대적으로 우선(Strictly Higher Priority)하여 평가하고 처리해야 합니다.
             */
            (sys_brakeInput.pressure > 0.0 [Pa] and
                modeChannelBroadcast.inhibitDrivingControl == true) implies
            // 제동 페달 입력 유무와 관계없이, Arbiter 차단 신호가 활성화되면 최종 공기량은 0으로 강제 클램핑됨
            sys_airCmd.massFlow <= 0.0 [kg / s]
        }

        // 시스템 기동 시 모든 영역이 병렬로 실행됨 (Parallel Regions)
        // 1. 주행 토크 제어 상태 머신 (Extended 버전으로 교체)
        state redefines drivingControlRegion : ExtendedDrivingTorqueBehavior {
            // 컨텍스트에서 들어오는 시스템 레벨의 입력을 내부 상태 머신의 포트로 명시적 바인딩
            bind In_Ignition = sys_ignition;
            bind In_CombustionSystemStatus = sys_combustionStatus;

            // Arbiter가 출력한 modeChannel 신호를 입력으로 받음
            bind In_ModeCtrl = modeChannelBroadcast;
        }

        // 2. 긴급 토크 개입 상태 머신
        state
            redefines emergencyInterventionRegion
            : FE_BehaviorModel::EmergencyInterventionBehavior {
            // 시스템 경계의 피드백 데이터를 내부로 바인딩
            bind In_AirFeedback = sys_airFeedback;
        }

        // 3. 안전 감시 상태 머신
        state redefines safetyMonitoringRegion : FE_BehaviorModel::SafetyMonitoringBehavior {
            // 이중화 센서 데이터 및 연소 상태 피드백 바인딩
            bind In_Sensor = sys_sensorData;
            bind In_CombustionStatus = sys_combustionStatus;
        }
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.calibrationHandling
            : FE_BehaviorModel::CalibrationSupportBehavior;
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
            : FE_BehaviorModel::DiagnosticsAndMaintenanceSupportBehavior {
            // 진단/유지보수 영역에도 센서 데이터 바인딩 적용
            bind In_SensorPort = sys_sensorData;
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

                bind cf3_airCmd = safetyMonitoringRegion.Out_AirCmd;
                bind cf3_fuelCmd = safetyMonitoringRegion.Out_FuelCmd;

                // Arbiter의 최종 결정값을 기존의 내부 변수(finalAirCmd)가 아닌 외부 시스템 경계 출력(sys_airCmd)으로 다이렉트 바인딩
                bind final_airCmd = sys_airCmd;
                bind final_fuelCmd = sys_fuelCmd;
                bind modeChannelBroadcaster = modeChannelBroadcast;
            }
        }
    }
} // package FE_SystemBehaviorModel
