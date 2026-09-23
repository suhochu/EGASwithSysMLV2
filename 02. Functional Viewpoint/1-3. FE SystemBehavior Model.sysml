package FE_SystemBehaviorModel {
    private import RV_BehavioralModel::*;
    private import FE_BehaviorModel::*;
    private import RV_InterfaceModel::*;
    private import FB_FunctionalBlackBoxModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    // ==========================================
    // FE 통합 시스템 동작 모델 (FE System Behavioral Model)
    // ==========================================
    state def FeEgasBehavior :> EgasBehavior {
        doc
        /* RV 관점의 EgasBehavior(뼈대 및 이벤트 트랜지션)를 상속받으며, 
         * FE_BehaviorModel의 구체적인 상태 머신들을 Usage로 선언 후 
         * 각 상태(State)를 부분집합(:>)으로 연결합니다.
         *
         * (SysML v2 문법에 따라, 트랜지션은 부모의 구조를 그대로 상속받으므로
         * 별도의 transition redefines 구문을 작성하지 않습니다.)
         */

        // [Usage 선언] FE 모델의 상태 머신들을 시스템 모델의 컴포넌트로 선언
        state drivingTorqueBehavior : FE_BehaviorModel::DrivingTorqueBehavior;
        state emergencyInterventionBehavior : FE_BehaviorModel::EmergencyInterventionBehavior;
        state safetyMonitoringBehavior : FE_BehaviorModel::SafetyMonitoringBehavior;
        state calibrationSupportBehavior : FE_BehaviorModel::CalibrationSupportBehavior;
        state diagnosticsBehavior : FE_BehaviorModel::DiagnosticsAndMaintenanceSupportBehavior;

        // ==========================================
        // 1. 주행 토크 제어 영역 병합
        // ==========================================
        state redefines drivingControlRegion {
            // 상태 1:1 매핑 (트랜지션은 RV 모델의 연결을 그대로 사용)
            state redefines Standby :> drivingTorqueBehavior.Idle;

            state redefines Active {
                state redefines ManualDriving :> drivingTorqueBehavior.Accelerating.ManualDriving;
                state redefines CruiseDriving :> drivingTorqueBehavior.Accelerating.CruiseActive;
            }

            state redefines BrakeOverridden :> drivingTorqueBehavior.BrakeOverridden;
            state redefines WaitForPedalRelease :> drivingTorqueBehavior.WaitForPedalRelease;
        }

        // ==========================================
        // 2. 긴급 개입 제어 영역 병합
        // ==========================================
        state redefines emergencyInterventionRegion {
            state redefines EmergencyStandby :> emergencyInterventionBehavior.Standby;

            state redefines InterventionActive {
                state
                    redefines InitialCheck
                    :> emergencyInterventionBehavior.InterventionActive.InitialCheck;
                state
                    redefines ParallelReduction
                    :> emergencyInterventionBehavior.InterventionActive.ParallelReduction;
                state
                    redefines DelayCompensating
                    :> emergencyInterventionBehavior.InterventionActive.DelayCompensating;
                state
                    redefines ActuatorStuckFallback
                    :> emergencyInterventionBehavior.InterventionActive.ActuatorStuckFallback;
            }
        }

        // ==========================================
        // 3. 상시 안전 감시 영역 병합
        // ==========================================
        state redefines safetyMonitoringRegion {
            state redefines NormalMonitoring :> safetyMonitoringBehavior.NormalMonitoring;
            state redefines CriticalFault :> safetyMonitoringBehavior.CriticalFault;
        }

        // ==========================================
        // 4 & 5. 진단 및 캘리브레이션 영역 병합
        // ==========================================
        state redefines monitoringAndServiceRegion {
            state redefines MonitoringActive {
                state redefines calibrationHandling {
                    state redefines Cal_Idle :> calibrationSupportBehavior.Idle;
                    state redefines Authorizing :> calibrationSupportBehavior.Authorizing;
                    state redefines Verifying :> calibrationSupportBehavior.Verifying;
                    state
                        redefines RejectingAndRollback
                        :> calibrationSupportBehavior.RejectingAndRollback;
                }

                state redefines diagnosticsHandling {
                    state redefines Diag_Idle :> diagnosticsBehavior.Idle;
                    state redefines ReadingDTC :> diagnosticsBehavior.ReadingDTC;
                    state
                        redefines CalibratingZeroPoint :> diagnosticsBehavior.CalibratingZeroPoint;
                    state redefines RejectingRequest :> diagnosticsBehavior.RejectingRequest;
                }
            }
        }
    }
} // package FE_SystemBehaviorModel
