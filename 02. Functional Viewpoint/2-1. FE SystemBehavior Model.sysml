package FE_SystemBehaviorModel {
    private import FE_BehaviorModel::*;
    private import FB_ModeArbitrationModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    
    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // FE 통합 시스템 동작 모델 (FE System Behavioral Model)
    // ==========================================
    state rvEgasState : RV_BehavioralModel::EgasBehavior;

    state FeEgasBehavior :> rvEgasState {
        // Mode Channel 포트 선언 (Arbiter가 생성하여 각 Sub-state로 전송)
        out modeChannelBroadcast : ModeChannelData;

        // 최종 시스템 출력 포트
        out finalAirCmd : IntakeAirFlow;
        out finalFuelCmd : FuelIgnitionCommand;

        // 시스템 기동 시 모든 영역이 병렬로 실행됨 (Parallel Regions)

        // 1. 주행 토크 제어 상태 머신 (Extended 버전으로 교체)
        state redefines drivingControlRegion : ExtendedDrivingTorqueBehavior {
            // Arbiter가 출력한 modeChannel 신호를 입력으로 받음
            bind In_ModeCtrl = modeChannelBroadcast;
        }
        state
            redefines emergencyInterventionRegion : FE_BehaviorModel::EmergencyInterventionBehavior;
        state redefines safetyMonitoringRegion : FE_BehaviorModel::SafetyMonitoringBehavior;
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.calibrationHandling
            : FE_BehaviorModel::CalibrationSupportBehavior;
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
            : FE_BehaviorModel::DiagnosticsAndMaintenanceSupportBehavior;

        // 다른 상태 영역들(drivingControlRegion 등)과 병렬로 상시 동작하며
        // 하위 시스템들의 출력을 모아 우선순위를 평가하고 최종 출력을 내보냅니다.
        state ModeArbitrationRegion {
            // 이 영역 내에서 Arbiter action을 상시 실행 (Do-behavior)
            do action systemArbiter : Arbiter {
                // 각 상태 영역에서 산출된 값을 Arbiter의 입력으로 바인딩
                bind cf1_airCmd = drivingControlRegion.Out_AirCmd;
                bind cf1_fuelCmd = drivingControlRegion.Out_FuelCmd;

                bind cf2_airCmd = emergencyInterventionRegion.Out_AirCmd;
                bind cf2_fuelCmd = emergencyInterventionRegion.Out_FuelCmd;

                bind cf3_airCmd = safetyMonitoringRegion.Out_AirCmd;
                bind cf3_fuelCmd = safetyMonitoringRegion.Out_FuelCmd;

                // Arbiter의 최종 결정값을 시스템 출력 및 내부 브로드캐스트로 바인딩
                bind final_airCmd = finalAirCmd;
                bind final_fuelCmd = finalFuelCmd;
                bind modeChannelBroadcaster = modeChannelBroadcast;
            }
        }
    }
} // package FE_SystemBehaviorModel
