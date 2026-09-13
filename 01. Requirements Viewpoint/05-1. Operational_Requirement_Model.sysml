package RV_OperationalModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*; // Use Case 및 SHR 참조용
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 개별 운용 기능(Action) 정의
    // - 시나리오의 각 메시지 처리 단계를 구체적인 오퍼레이션으로 분해
    // ==========================================
    package EgasOperationalRequirements_UC1 {
        @MetaInformation {
            version = "v0.1";
        }

        action def ArbitrateTorqueDemand {
            doc
            /* [UC1_Normal & Alternative] 가속 페달과 크루즈 컨트롤의 토크 요구량 중재 */
            in accel : AccelerationIntent;
            in ccCmd : CruiseControlCommand;
            out baseTorque : TorqueInterventionRequest;

            // SHR-08 및 VC#01: 가속 처리 응답성 제약 적용
            constraint responseTime {
                accel.pedalDisplacement > 0.0 [mm] implies accel.latency <= 50.0 [milli * s]
            }
        }

        action def OverrideBrakeIntervention {
            doc
            /* [UC1_Exception] 브레이크 개입 시 기존 토크 요구 무효화 및 강제 차단 */
            in baseTorque : TorqueInterventionRequest;
            in brake : BrakePedalPosition;
            out finalTorque : TorqueInterventionRequest;
            out isEmergencyCut : Boolean; // 페일세이프 트리거 플래그

            // SHR-01 및 VC#05: 제동 최우선 개입 제약 적용
            constraint brakeOverridePriority {
                brake.pressure > 0.0 [Pa] implies isEmergencyCut == true
            }
        }

        action def ActuateEngineAndFuel {
            doc
            /* 산출된 최종 토크를 기반으로 엔진 공기량 및 연료량 제어명령 하달 */
            in finalTorque : TorqueInterventionRequest;
            in isEmergencyCut : Boolean;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // VC#06, VC#07: 페일세이프 시 원천 차단 제약
            constraint emergencyCutoff {
                isEmergencyCut == true implies
                (airCmd.massFlow <= 0.0 [kg / s] and fuelCmd.injectionPulseWidth <= 0.0 [s])
            }
        }

        action def MonitorDynamicsAndFeedback {
            doc
            /* [UC1_Normal & Alternative] 연소 상태 및 차량 거동 피드백 모니터링 */
            in combustionFeedback : CombustionSystemStatus;
            in dynamicsFeedback : VehicleDynamicsFeedback;

            // SHR-02-1 및 VC#02, VC#03, VC#04: 정밀도 및 승차감 제약 적용
            constraint steadyStatePrecision {
                combustionFeedback.steadyStateError <= 2.0 and
                combustionFeedback.torqueOvershoot <= 5.0
            }
            constraint rideComfort {
                dynamicsFeedback.longitudinalJerk <= 10.0
            }
        }

        // ==========================================
        // 2. 최상위 운용 시나리오 (Control & Object Flow)
        // - 분해된 Action들을 인스턴스화하고 데이터 흐름(flow)을 연결하여 전체 기능 체인 완성
        // ==========================================

        action def ManageDrivingTorqueArbitration {
            doc
            /* UC1의 세 가지 시나리오를 모두 포괄하는 최상위 운용 요구사항 흐름 */

            // 외부 컨텍스트 모델과 매핑되는 I/O 파라미터
            in accelIn : AccelerationIntent;
            in ccCmdIn : CruiseControlCommand;
            in brakeIn : BrakePedalPosition;
            in combustionStatusIn : CombustionSystemStatus;
            in dynamicsStatusIn : VehicleDynamicsFeedback;

            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;

            // 내부 서브 오퍼레이션(Action) 인스턴스화
            action arbitrate : ArbitrateTorqueDemand;
            action overrideCheck : OverrideBrakeIntervention;
            action actuate : ActuateEngineAndFuel;
            action monitor : MonitorDynamicsAndFeedback;

            // 데이터 흐름(Object Flow) 구성: 입력 -> 중재 -> 제동 판단 -> 액추에이터 제어 -> 출력
            flow accelIn to arbitrate.accel;
            flow ccCmdIn to arbitrate.ccCmd;

            flow arbitrate.baseTorque to overrideCheck.baseTorque;
            flow brakeIn to overrideCheck.brake;

            flow overrideCheck.finalTorque to actuate.finalTorque;
            flow overrideCheck.isEmergencyCut to actuate.isEmergencyCut;

            flow actuate.airCmd to airFlowOut;
            flow actuate.fuelCmd to fuelCmdOut;

            flow combustionStatusIn to monitor.combustionFeedback;
            flow dynamicsStatusIn to monitor.dynamicsFeedback;
        }
    } // package EgasOperationalRequirements_UC1

    package EgasOperationalRequirements_UC2 {
        @MetaInformation {
            version = "v0.1";
        }

        // ==========================================
        // 1. 개별 운용 기능(Action) 정의
        // ==========================================
        action def ExecuteParallelTorqueReduction {
            doc
            /* [UC2_Normal] 15ms 이내 공기량 및 연료량 병렬 축소 */
            in torqueReq : TorqueInterventionRequest;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // SHR-04-1, SHR-04-2 및 VC#01, VC#02, VC#03 제약 할당
            constraint rapidReduction {
                airCmd.start - torqueReq.done <= 15.0 [milli * s] and
                fuelCmd.start - torqueReq.done <= 15.0 [milli * s] and
                airCmd.massFlow < airCmd.previousMassFlow and
                fuelCmd.injectionPulseWidth < fuelCmd.previousPulseWidth
            }
        }

        action def CompensateCommunicationDelay {
            doc
            /* [UC2_Alternative] 통신 지연(15ms 초과) 시 직전 제어값 유지 */
            in torqueReq : TorqueInterventionRequest;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // VC#04, VC#05 제약 할당
            constraint maintainPreviousState {
                airCmd.massFlow == airCmd.previousMassFlow and
                fuelCmd.injectionPulseWidth == fuelCmd.previousPulseWidth
            }
        }

        action def MitigateActuatorStuck {
            doc
            /* [UC2_Exception] 스로틀 고착 감지 시 연료 전면 차단 (10ms 이내) */
            in airCmdFeedback : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // VC#06, VC#07 제약 할당
            constraint failsafeFuelCut {
                airCmdFeedback.massFlow >= airCmdFeedback.previousMassFlow implies
                (fuelCmd.start - airCmdFeedback.done <= 10.0 [milli * s] and
                    fuelCmd.injectionPulseWidth <= 0.0 [s])
            }
        }

        // ==========================================
        // 2. 최상위 운용 시나리오 (Control & Object Flow)
        // ==========================================

        action def ManageEmergencyIntervention {
            doc
            /* UC2 전체의 판단 로직 및 데이터 흐름을 오케스트레이션 */

            in torqueReqIn : TorqueInterventionRequest;
            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;

            // 시나리오 분기 (Control Flow)
            if torqueReqIn.latency <= 15.0 [milli * s] {
                action normalReduction : ExecuteParallelTorqueReduction;
                flow torqueReqIn to normalReduction.torqueReq;

                // 하드웨어 고착 감지 판단을 위한 예외 처리 파이프라인
                action stuckMonitor : MitigateActuatorStuck;
                flow normalReduction.airCmd to stuckMonitor.airCmdFeedback;

                flow normalReduction.airCmd to airFlowOut;
                flow stuckMonitor.fuelCmd to fuelCmdOut;
            } else {
                action delayCompensator : CompensateCommunicationDelay;
                flow torqueReqIn to delayCompensator.torqueReq;

                flow delayCompensator.airCmd to airFlowOut;
                flow delayCompensator.fuelCmd to fuelCmdOut;
            }
        }
    } // package EgasOperationalRequirements_UC2

    package EgasOperationalRequirements_UC3 {
        @MetaInformation {
            version = "v0.1";
        }

        // ==========================================
        // 1. 개별 운용 기능(Action) 정의
        // ==========================================

        action def ExecuteDelayCompensation {
            doc
            /* [UC3_Normal] 정상 상태에서 하드웨어 마찰 및 지연을 보정하여 제어 명령 산출 */
            in sensorData : EngineSensorData;
            in combustionFeedback : CombustionSystemStatus;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // SHR-02-2 및 VC#15, VC#16 제약 할당
            constraint actuatorLatencyConstraint {
                fuelCmd.actuatorLatency <= 10.0 [milli * s]
            }

            constraint misfirePreventionConstraint {
                combustionFeedback.misfireRate <= 0.0 [Hz]
            }
        }

        action def ExecuteEmergencyFailSafe {
            doc
            /* [UC3_Exception] 치명적 센서 결함 감지 시 즉각적인 공기/연료 전면 차단 수행 */
            in faultySensorData : EngineSensorData;
            out airCutCmd : IntakeAirFlow;
            out fuelCutCmd : FuelIgnitionCommand;

            // SHR-03 및 VC#17, VC#18, VC#19 제약 할당
            constraint failSafeResponseTime {
                airCutCmd.start - faultySensorData.done <= 10.0 [milli * s] and
                fuelCutCmd.start - faultySensorData.done <= 10.0 [milli * s]
            }

            constraint sensorFaultAirCutConstraint {
                airCutCmd.massFlow <= 0.0 [kg / s]
            }

            constraint sensorFaultFuelCutConstraint {
                fuelCutCmd.injectionPulseWidth <= 0.0 [s]
            }
        }

        // ==========================================
        // 2. 최상위 운용 시나리오 (Control & Object Flow)
        // ==========================================

        action def ManageHardwareFailSafe {
            doc
            /* UC3 전체의 하드웨어 모니터링 판단 로직 및 데이터 흐름 오케스트레이션 */

            in sensorIn : EngineSensorData;
            in combustionStatusIn : CombustionSystemStatus;
            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;

            // 센서 데이터(냉각수 온도 등)를 기반으로 한 시나리오 분기 (Control Flow)
            if sensorIn.coolantTemp <= 120.0 ['°'] {
                // [정상 흐름] 마찰 및 지연 보정 제어 수행
                action compensate : ExecuteDelayCompensation;

                flow sensorIn to compensate.sensorData;
                flow combustionStatusIn to compensate.combustionFeedback;

                flow compensate.airCmd to airFlowOut;
                flow compensate.fuelCmd to fuelCmdOut;
            } else {
                // [예외 흐름] 치명적 결함으로 판단하여 즉각 페일세이프 차단 수행
                action failSafe : ExecuteEmergencyFailSafe;

                flow sensorIn to failSafe.faultySensorData;

                flow failSafe.airCutCmd to airFlowOut;
                flow failSafe.fuelCutCmd to fuelCmdOut;
            }
        }
    } // package EgasOperationalRequirements_UC3

    package EgasOperationalRequirements_UC4 {
        @MetaInformation {
            version = "v0.1";
        }

        // ==========================================
        // 1. 개별 운용 기능(Action) 정의
        // ==========================================

        action def AuthorizeMemoryAccess {
            doc
            /* [UC4_Normal 1] 유효한 메모리 접근 요청 시 통신 세션 인가 */
            in calReq : CalibrationRequest;
            out calStatus : CalibrationStatus;

            // SHR-05-1 및 VC#1, VC#2 제약 할당
            constraint accessAuthorizationSuccess {
                calStatus.responseCode == 200
            }

            constraint authResponseTime {
                calStatus.start - calReq.done <= 50.0 [milli * s]
            }
        }

        action def VerifyDataIntegrity {
            doc
            /* [UC4_Normal 2] 튜닝 데이터 기록 시 메모리 무결성(Checksum) 자체 검증 */
            in writeReq : CalibrationRequest;
            out calStatus : CalibrationStatus;

            // SHR-05-2 및 VC#3, VC#4 제약 할당
            constraint dataIntegrityVerification {
                calStatus.verifiedChecksum > 0
            }

            constraint verificationResponseTime {
                calStatus.start - writeReq.done <= 100.0 [milli * s]
            }
        }

        action def RejectInvalidAccess {
            doc
            /* [UC4_Exception] 비유효 메모리 주소 접근 시 에러 반환 및 롤백 */
            in invalidReq : CalibrationRequest;
            out errorStatus : CalibrationStatus;

            // VC#5, VC#6 제약 할당
            constraint invalidAccessRejection {
                errorStatus.responseCode != 200
            }

            constraint rejectionResponseTime {
                errorStatus.start - invalidReq.done <= 10.0 [milli * s]
            }
        }

        // ==========================================
        // 2. 최상위 운용 시나리오 (Control & Object Flow)
        // ==========================================

        action def ManagePowertrainCalibration {
            doc
            /* UC4 전체의 메모리 보안 검증 및 튜닝 데이터 업데이트 흐름 오케스트레이션 */

            in calReqIn : CalibrationRequest;
            out calStatusOut : CalibrationStatus;

            // 요청된 메모리 주소의 유효성에 따른 시나리오 분기 (Control Flow)
            if calReqIn.targetMemoryAddress > 0 {
                // [정상 흐름] 접근 인가 후 무결성 검증 수행
                action authorize : AuthorizeMemoryAccess;
                action verifyIntegrity : VerifyDataIntegrity;

                // 1) 접근 요청 처리 및 인가 응답
                flow calReqIn to authorize.calReq;
                flow authorize.calStatus to calStatusOut;

                // 2) 인가 완료 후 데이터 기록 및 무결성 검증으로 시퀀스 전이
                first authorize;
                then verifyIntegrity;

                // (실제 데이터 기록 요청이 들어왔다고 가정하고 검증 로직으로 데이터 흐름 연결)
                flow calReqIn to verifyIntegrity.writeReq;
                flow verifyIntegrity.calStatus to calStatusOut;
            } else {
                // [예외 흐름] 비유효 접근 즉각 거절 및 에러 반환
                action reject : RejectInvalidAccess;

                flow calReqIn to reject.invalidReq;
                flow reject.errorStatus to calStatusOut;
            }
        }
    } // package EgasOperationalRequirements_UC4

    package EgasOperationalRequirements_UC5 {
        @MetaInformation {
            version = "v0.1";
        }

        // ==========================================
        // 1. 개별 운용 기능(Action) 정의
        // ==========================================

        action def ReadDiagnosticTroubleCode {
            doc
            /* [UC5_Normal 1] 센서 결함 데이터를 기반으로 유효한 고장 코드(DTC) 처리 및 반환 */
            in sensorData : EngineSensorData;
            in diagReq : DiagnosticRequest;
            out diagStatus : DiagnosticStatus;

            // VC#1, VC#2 제약 할당
            constraint dtcReadSuccess {
                diagStatus.responseCode == 200 and diagStatus.dtcCode > 0
            }
            constraint dtcResponseTime {
                diagStatus.start - diagReq.done <= 50.0 [milli * s]
            }
        }

        action def ExecuteZeroPointCalibration {
            doc
            /* [UC5_Normal 2] 부품 교체 후 영점 조정 처리 및 완료 응답 반환 */
            in diagReq : DiagnosticRequest;
            out diagStatus : DiagnosticStatus;

            // VC#3, VC#4 제약 할당
            constraint zeroPointCalibrationSuccess {
                diagStatus.responseCode == 200
            }
            constraint zeroPointResponseTime {
                diagStatus.start - diagReq.done <= 100.0 [milli * s]
            }
        }

        action def RejectInvalidDiagnosticRequest {
            doc
            /* [UC5_Exception] 미지원 서비스 ID 요청 시 에러 응답 및 통신 거절 */
            in diagReq : DiagnosticRequest;
            out diagStatus : DiagnosticStatus;

            // VC#5, VC#6 제약 할당
            constraint invalidDiagnosticRequestRejection {
                diagStatus.responseCode != 200
            }
            constraint errorResponseTime {
                diagStatus.start - diagReq.done <= 10.0 [milli * s]
            }
        }

        // ==========================================
        // 2. 최상위 운용 시나리오 (Control & Object Flow)
        // ==========================================

        action def ManageDiagnosticsAndMaintenance {
            doc
            /* UC5 전체의 진단 서비스 판별 로직 및 데이터 흐름 오케스트레이션 */

            in diagReqIn : DiagnosticRequest;
            in sensorIn : EngineSensorData;
            out diagStatusOut : DiagnosticStatus;

            // 요청된 진단 서비스 ID(serviceId)에 따른 제어 흐름(Control Flow) 다중 분기
            if diagReqIn.serviceId == 1 {
                // [정상 흐름 1] 고장 코드(DTC) 조회 처리
                action readDtc : ReadDiagnosticTroubleCode;

                flow sensorIn to readDtc.sensorData;
                flow diagReqIn to readDtc.diagReq;
                flow readDtc.diagStatus to diagStatusOut;
            } else if diagReqIn.serviceId == 2 {
                // [정상 흐름 2] 영점 조정 루틴 수행
                action zeroPointCal : ExecuteZeroPointCalibration;

                flow diagReqIn to zeroPointCal.diagReq;
                flow zeroPointCal.diagStatus to diagStatusOut;
            } else {
                // [예외 흐름] 비유효 서비스 ID 거절
                action rejectReq : RejectInvalidDiagnosticRequest;

                flow diagReqIn to rejectReq.diagReq;
                flow rejectReq.diagStatus to diagStatusOut;
            }
        }
    } // package EgasOperationalRequirements_UC5
} // package RV_OperationalModel
