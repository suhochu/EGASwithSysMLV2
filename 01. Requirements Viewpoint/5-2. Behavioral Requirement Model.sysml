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

            state Standby; // /* 엔진 시동 전 또는 제어 대기 상태

            state Active {
                // 주행 제어 활성화 상태 (UC1, UC2 주 작동 구간)

                first start then ManualDriving;

                state ManualDriving {
                    // 운전자 페달 조작에 의한 토크 산출 (UC1_Normal)
                    do action manageArbitration
                        : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
                }

                state CruiseDriving {
                    // 크루즈 컨트롤에 의한 정속 주행 (UC1_Alternative)
                    do action manageArbitration
                        : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
                }

                state EmergencyIntervention {
                    // ESP/TCU 개입에 의한 긴급 토크 저감 모드 (UC2)
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
                // 치명적 결함 및 하드웨어 고착 시 시스템 보호 상태 (UC3)
                do action executeFailSafe : EgasOperationalRequirements_UC3::ManageHardwareFailSafe;
            }

            // 최상위 상태 전이 (Global Transitions)
            transition standbyToActive first Standby accept AccelerationIntent then Active;

            transition activeToFailSafe first Active accept EngineSensorData then FailSafe;

            // 결함 해소 후 복귀 경로: 신규 센서 데이터 수신 시 대기 상태로 복귀하여 재기동을 시도함
            transition failSafeToStandby first FailSafe accept EngineSensorData then Standby;
        }

        // 주행 상태와 무관하게 상시 병렬로 동작하는 진단 및 캘리브레이션 영역.
        // UC4/UC5 단위로 상태를 분리하여 05-1 운용 모델의 분기 수준과 일치시킴.
        state monitoringAndServiceRegion {
            first start then MonitoringActive;

            state MonitoringActive {
                state calibrationHandling {
                    // UC4: 초기 주소 검증뿐만 아니라, 메모리 접근 인가 및 데이터 무결성 검증의
                    // 결과 상태를 연속적으로 확인하여 실패 시 즉각 거절 및 롤백(RejectAccess)을
                    // 수행하도록 예외 처리 흐름을 강화함.
                    do action processCalibration {
                        in calReq : RV_InterfaceModel::CalibrationRequest;

                        // 1차 검증: 대상 메모리 주소의 유효성 확인
                        if calReq.targetMemoryAddress > 0 {
                            first start;
                            then action authorize
                                : EgasOperationalRequirements_UC4::AuthorizeMemoryAccess;

                            // 2차 검증: 인가 결과 통신 코드(200) 확인
                            then if authorize.calStatus.responseCode == 200 {
                                action verifyIntegrity
                                    : EgasOperationalRequirements_UC4::VerifyDataIntegrity;

                                // 3차 검증: 무결성 검증 체크섬(>0) 실패 시 롤백 수행
                                then if verifyIntegrity.calStatus.verifiedChecksum <= 0 {
                                    action rejectOnVerifyFail
                                        : EgasOperationalRequirements_UC4::RejectInvalidAccess;
                                }
                            } else {
                                // 인가 실패 시 거절 수행
                                action rejectOnAuthFail
                                    : EgasOperationalRequirements_UC4::RejectInvalidAccess;
                            }
                        } else {
                            // 잘못된 메모리 주소 접근 시 즉각 거절 수행
                            action rejectOnInvalidAddress
                                : EgasOperationalRequirements_UC4::RejectInvalidAccess;
                        }
                    }
                }

                state diagnosticsHandling {
                    // UC5: 진단 요청의 serviceId에 따른 상호 배타적인 조건 분기 적용
                    do action processDiagnostics {
                        in diagReq : RV_InterfaceModel::DiagnosticRequest;

                        if diagReq.serviceId == 1 {
                            action readDtc
                                : EgasOperationalRequirements_UC5::ReadDiagnosticTroubleCode;
                        } else if diagReq.serviceId == 2 {
                            action zeroPointCal
                                : EgasOperationalRequirements_UC5::ExecuteZeroPointCalibration;
                        } else {
                            action rejectDiagnostic
                                : EgasOperationalRequirements_UC5::RejectInvalidDiagnosticRequest;
                        }
                    }
                }
            }
        }
    }
} // package RV_BehavioralModel
