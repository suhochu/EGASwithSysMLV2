package RV_OperationalModel {
    private import ReqCommon::*;
    private import RV_UseCases::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*; // Use Case 및 SHR 참조용
    private import SI::*;

    @MetaInformation {
        version = "v0.2";
    }

    package EgasOperationalRequirements_UC1 {
        @MetaInformation {
            version = "v0.2";
        }
        dependency from EgasOperationalRequirements_UC1 to UC1;

        action def ArbitrateTorqueDemand {
            doc
            /* Arbitrate torque demand from accelerator and cruise control */

            dependency from self to UC1::UC1_Normal_Manual_Acceleration;
            dependency from self to UC1::UC1_Alternative_Cruise_Control_Driving;

            // 크루즈 요구의 반영 여부는 ccState(SYSR-23)가 결정한다 (제동 > 가속 페달 > 크루즈)
            in accel : AccelerationIntent;
            in ccCmd : CruiseControlCommand;
            in ccState : CruiseControlStateEnum;
            out baseTorque : TorqueInterventionRequest;
        }

        action def OverrideBrakeIntervention {
            doc
            /* [UC1_Exception] 구동 요구 중 브레이크 입력 시 기존 토크 요구 무효화 및 토크 제한(L1) */

            dependency from self to UC1::UC1_Exception_Brake_Override_Intervention;
            in baseTorque : TorqueInterventionRequest;
            in accel : AccelerationIntent;
            in ccState : CruiseControlStateEnum;
            in brake : BrakePedalPosition;
            out finalTorque : TorqueInterventionRequest;
            out isOverrideActive : Boolean;

            // SHR-01, SYSR-01a, 및 VC#05: 제동 최우선 개입 제약 (제동만이 아니라 구동 요구 AND 제동)
            constraint brakeOverridePriority {
                SafeStateLogic::IsBrakeOverrideTriggered(
                    accel.pedalDisplacement,
                    ccState,
                    brake.pressure
                ) implies
                isOverrideActive == true
            }
        }

        action def ActuateEngineAndFuel {
            doc
            /* Air and fuel control commands based on final torque */

            dependency from self to UC1::UC1_Normal_Manual_Acceleration;
            dependency from self to UC1::UC1_Alternative_Cruise_Control_Driving;
            dependency from self to UC1::UC1_Exception_Brake_Override_Intervention;

            in finalTorque : TorqueInterventionRequest;
            in isOverrideActive : Boolean;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // VC#06, VC#07: 오버라이드 시 L1 출력 제약 (기존: 공기/연료 0 원천 차단)
            constraint overrideTorqueLimit {
                isOverrideActive == true implies
                SafeStateLogic::IsTorqueLimited(airCmd.massFlow, fuelCmd.injectionPulseWidth)
            }
        }

        action def MonitorDynamicsAndFeedback {
            doc
            /* Monitor combustion status and vehicle dynamics feedback */

            dependency from self to UC1::UC1_Normal_Manual_Acceleration;
            dependency from self to UC1::UC1_Alternative_Cruise_Control_Driving;

            in combustionFeedback : CombustionSystemStatus;
            in dynamicsFeedback : VehicleDynamicsFeedback;

            // Precision and ride comfort constraints (SHR-02-1, VC#02-04)
            constraint steadyStatePrecision {
                @PlantObservation;
                combustionFeedback.steadyStateError <= 2.0 and
                combustionFeedback.torqueOvershoot <= 5.0
            }
            constraint rideComfort {
                @PlantObservation;
                dynamicsFeedback.longitudinalJerk <= 10.0
            }
        }

        action def ManageDrivingTorqueArbitration {
            doc
            /* UC1 integrated operational flow */

            // 외부 컨텍스트 모델과 매핑되는 I/O 파라미터
            in accelIn : AccelerationIntent;
            in ccCmdIn : CruiseControlCommand;
            in brakeIn : BrakePedalPosition;
            in combustionStatusIn : CombustionSystemStatus;
            in dynamicsStatusIn : VehicleDynamicsFeedback;
            in ccStateIn : CruiseControlStateEnum;

            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;
            out isOverrideActiveOut : Boolean;

            // 내부 서브 오퍼레이션(Action) 인스턴스화
            action arbitrate : ArbitrateTorqueDemand;
            action overrideCheck : OverrideBrakeIntervention;
            action actuate : ActuateEngineAndFuel;
            action monitor : MonitorDynamicsAndFeedback;

            // 데이터 흐름(Object Flow) 구성: 입력 -> 중재 -> 제동 판단 -> 액추에이터 제어 -> 출력
            flow accelIn to arbitrate.accel;
            flow ccCmdIn to arbitrate.ccCmd;

            flow arbitrate.baseTorque to overrideCheck.baseTorque;

            flow accelIn to overrideCheck.accel;
            flow ccStateIn to arbitrate.ccState;
            flow ccStateIn to overrideCheck.ccState;
            flow brakeIn to overrideCheck.brake;

            flow overrideCheck.finalTorque to actuate.finalTorque;
            flow overrideCheck.isOverrideActive to actuate.isOverrideActive;
            flow overrideCheck.isOverrideActive to isOverrideActiveOut;

            flow actuate.airCmd to airFlowOut;
            flow actuate.fuelCmd to fuelCmdOut;

            flow combustionStatusIn to monitor.combustionFeedback;
            flow dynamicsStatusIn to monitor.dynamicsFeedback;

            // SHR-08 및 VC#01: 가속 입력 수신 → 공기/연료 명령 출력까지 50ms (EGAS 소유 보장)
            constraint responseTime {
                accelIn.pedalDisplacement > 0.0 [mm] implies
                (airFlowOut.responseTime <= 50.0 [milli * s] and
                    fuelCmdOut.responseTime <= 50.0 [milli * s])
            }
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
                (torqueReq.requestedTorqueDelta < 0.0 [N * m] and
                    torqueReq.latency <= 15.0 [milli * s]) implies
                (airCmd.responseTime <= 15.0 [milli * s] and
                    fuelCmd.responseTime <= 15.0 [milli * s] and
                    airCmd.massFlow < airCmd.previousMassFlow and
                    fuelCmd.injectionPulseWidth < fuelCmd.previousPulseWidth)
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
            private import ThrottleStuckLogic::*;
            doc
            /* [UC2_Exception] 스로틀 고착 감지 시 연료 전면 차단 (10ms 이내), 미확정이면 정상 연료 명령을 통과 */
            in torqueReq : TorqueInterventionRequest;
            in throttleCmd : ThrottlePositionCommand;
            in throttleFb : ThrottlePositionFeedback;
            in deviationDuration : TimeValue;
            in normalFuelCmd : FuelIgnitionCommand;
            out fuelCmd : FuelIgnitionCommand;

            // VC#06, VC#07 제약 할당
            constraint failsafeFuelCut {
                IsThrottleStuck(
                    torqueReq.requestedTorqueDelta < 0.0 [N * m],
                    throttleCmd.openingPercentage,
                    throttleFb.openingPercentage,
                    stuckDeviationLimit,
                    deviationDuration,
                    stuckConfirmTime
                ) implies
                (fuelCmd.responseTime <= 10.0 [milli * s] and
                    fuelCmd.injectionPulseWidth <= 0.0 [s])
            }
            constraint passThroughWhenNotStuck {
                // 정상 연료 저감이 출력에 연결되도록 함
                not IsThrottleStuck(
                    torqueReq.requestedTorqueDelta < 0.0 [N * m],
                    throttleCmd.openingPercentage,
                    throttleFb.openingPercentage,
                    stuckDeviationLimit,
                    deviationDuration,
                    stuckConfirmTime
                ) implies
                fuelCmd == normalFuelCmd
            }
        }

        // ==========================================
        // 2. 최상위 운용 시나리오 (Control & Object Flow)
        // ==========================================

        action def ManageEmergencyIntervention {
            doc
            /* UC2 전체의 판단 로직 및 데이터 흐름을 오케스트레이션 */

            in torqueReqIn : TorqueInterventionRequest;
            in throttleCmdIn : ThrottlePositionCommand;
            in throttleFbIn : ThrottlePositionFeedback;
            in deviationDurationIn : TimeValue;
            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;

            // 시나리오 분기 (Control Flow)
            if torqueReqIn.latency <= 15.0 [milli * s] {
                action normalReduction : ExecuteParallelTorqueReduction;
                flow torqueReqIn to normalReduction.torqueReq;

                action stuckMonitor : MitigateActuatorStuck;
                flow torqueReqIn to stuckMonitor.torqueReq; // 자기 출력 대신 실제 입력
                flow throttleCmdIn to stuckMonitor.throttleCmd;
                flow throttleFbIn to stuckMonitor.throttleFb;
                flow deviationDurationIn to stuckMonitor.deviationDuration;
                flow normalReduction.fuelCmd to stuckMonitor.normalFuelCmd; // [신규]

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
            /* [UC3_Normal] 정상 주행 중 CF1 기준 명령에 하드웨어 마찰 및 지연 보정을 직렬로 적용 (후처리) */

            private import SafeStateLogic::*;

            in baseAirCmd : IntakeAirFlow; // CF1 기준 명령
            in baseFuelCmd : FuelIgnitionCommand; //
            in isOverrideActive : Boolean; // 오버라이드 중에는 보정하지 않음
            in sensorData : EngineSensorData;
            in combustionFeedback : CombustionSystemStatus;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // SHR-02-2 및 VC#15 제약 할당 (S1: 이 단계의 처리시간)
            constraint compensationResponseTime {
                fuelCmd.responseTime <= compensationBudget
            }

            constraint boundedCorrection {
                // 기준 대비 허용 보정량 이내 (SYSR-22)
                airCmd.massFlow >= baseAirCmd.massFlow - maxAirCorrection and
                airCmd.massFlow <= baseAirCmd.massFlow + maxAirCorrection and
                fuelCmd.injectionPulseWidth >=
                baseFuelCmd.injectionPulseWidth - maxFuelCorrection and
                fuelCmd.injectionPulseWidth <= baseFuelCmd.injectionPulseWidth + maxFuelCorrection
            }

            constraint bypassWhenOverride {
                //  오버라이드 중 무변경 (SYSR-22)
                isOverrideActive == true implies
                (airCmd.massFlow == baseAirCmd.massFlow and
                    fuelCmd.injectionPulseWidth == baseFuelCmd.injectionPulseWidth)
            }

            constraint misfirePreventionConstraint {
                @PlantObservation;
                combustionFeedback.misfireRate <= 0.0 [Hz]
            }
        }

        action def ExecuteEmergencyFailSafe {
            doc
            /* [UC3_Exception] 치명 고장(센서 편차 또는 과열) 확정 시 공기/연료 전면 차단(L3) */
            in faultCause : FaultCause;
            out airCutCmd : IntakeAirFlow;
            out fuelCutCmd : FuelIgnitionCommand;

            // SHR-03 및 VC#17, VC#18, VC#19 제약 할당
            constraint failSafeResponseTime {
                airCutCmd.responseTime <= 10.0 [milli * s] and
                fuelCutCmd.responseTime <= 10.0 [milli * s]
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
            in faultCauseIn : FaultCause; // 확정된 치명 고장 원인 (SYSR-21)
            in combustionStatusIn : CombustionSystemStatus;
            in baseAirCmdIn : IntakeAirFlow;
            in baseFuelCmdIn : FuelIgnitionCommand;
            in isOverrideActiveIn : Boolean;

            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;

            // 센서 데이터(냉각수 온도 등)를 기반으로 한 시나리오 분기 (Control Flow)
            if faultCauseIn == FaultCause::NoFault {
                action compensate : ExecuteDelayCompensation;
                flow baseAirCmdIn to compensate.baseAirCmd;
                flow baseFuelCmdIn to compensate.baseFuelCmd;
                flow isOverrideActiveIn to compensate.isOverrideActive;
                flow sensorIn to compensate.sensorData;
                flow combustionStatusIn to compensate.combustionFeedback;
                flow compensate.airCmd to airFlowOut;
                flow compensate.fuelCmd to fuelCmdOut;
            } else {
                action failSafe : ExecuteEmergencyFailSafe;
                flow faultCauseIn to failSafe.faultCause; // Before: flow sensorIn to failSafe.faultySensorData
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
                calStatus.responseTime <= 50.0 [milli * s]
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
                calStatus.responseTime <= 100.0 [milli * s]
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
                errorStatus.responseTime <= 10.0 [milli * s]
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
                diagStatus.responseTime <= 50.0 [milli * s]
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
                diagStatus.responseTime <= 100.0 [milli * s]
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
                diagStatus.responseTime <= 10.0 [milli * s]
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
