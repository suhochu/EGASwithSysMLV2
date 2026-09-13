package RV_BehavioralModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*;
    private import RV_OperationalModel::*;

    @MetaInformation {
        version = "v0.2";
    }

    // ==========================================
    // 동작 요구사항 모델 (Behavioral Requirements Model)
    // ==========================================
    state def EgasBehavior {
        doc
        /* 시스템의 거시적인 상태 공간(State Space)과 Item(Payload) 수신 기반의 상태 전이를 정의하며,
         * 각 상태에서 활성화될 운용 요구사항(Action)을 매핑함.
         */

        // 병렬 상태(Orthogonal Regions) 선언: 주행 제어와 시스템 모니터링은 동시에 수행됨
        state drivingControlRegion {
            first start then Standby;

            state Standby {
                doc
                /* 엔진 시동 전 또는 제어 대기 상태 */
            }

            state Active {
                doc
                /* 주행 제어 활성화 상태 (UC1, UC2 주 작동 구간) */

                first start then ManualDriving;

                state ManualDriving {
                    doc
                    /* 운전자 페달 조작에 의한 토크 산출 (UC1_Normal) */
                    do action manageArbitration
                        : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
                }

                state CruiseDriving {
                    doc
                    /* 크루즈 컨트롤에 의한 정속 주행 (UC1_Alternative) */
                    do action manageArbitration
                        : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
                }

                state EmergencyIntervention {
                    doc
                    /* ESP/TCU 개입에 의한 긴급 토크 저감 모드 (UC2) */
                    do action manageEmergency
                        : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
                }

                // 페이로드 수신을 트리거로 사용하는 명시적 상태 전이
                transition manualToCruise
                    first ManualDriving accept CruiseControlCommand then CruiseDriving;

                transition cruiseToManual
                    first CruiseDriving accept AccelerationIntent then ManualDriving;

                transition manualToEmergency
                    first ManualDriving accept TorqueInterventionRequest then EmergencyIntervention;

                transition cruiseToEmergency
                    first CruiseDriving accept TorqueInterventionRequest then EmergencyIntervention;

                transition emergencyToManual
                    first EmergencyIntervention accept AccelerationIntent then ManualDriving;
            }

            state FailSafe {
                doc
                /* 치명적 결함 및 하드웨어 고착 시 시스템 보호 상태 (UC3) */
                do action executeFailSafe : EgasOperationalRequirements_UC3::ManageHardwareFailSafe;
            }

            // 최상위 상태 전이 (Global Transitions)
            transition standbyToActive first Standby accept AccelerationIntent then Active;

            transition activeToFailSafe first Active accept EngineSensorData then FailSafe;
        }

        state monitoringAndServiceRegion {
            doc
            /* 주행 상태와 무관하게 상시 병렬로 동작하는 진단 및 캘리브레이션 영역 */

            first start then MonitoringActive;

            state MonitoringActive {
                do action manageMonitoring : ManageMonitoringAndService;
            }
        }
    }

    action def ManageMonitoringAndService {
        doc
        /* 진단 및 캘리브레이션 오퍼레이션을 병렬 오케스트레이션 */
        fork monitorFork;
            then action manageCalibration
                : EgasOperationalRequirements_UC4::ManagePowertrainCalibration;
            then action manageDiagnostics
                : EgasOperationalRequirements_UC5::ManageDiagnosticsAndMaintenance;
    }
} // package RV_BehavioralModel
