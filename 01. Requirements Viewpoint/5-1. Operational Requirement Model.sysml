package RV_OperationalModel {
    private import ReqCommon::*;
    private import RV_UseCases::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*; // Use Case 및 SHR 참조용
    private import SI::*;
    private import TimingConceptsAndLimits::*;
    private import SafeStateLogic::*;

    @MetaInformation {
        version = "v0.2";
    }

    item def TorqueDemand {
        doc
        /* EGAS 내부 토크 요구 (절대값). 외부 인터페이스의 TorqueInterventionRequest(상대 증감량)와 구분한다. */
        attribute requestedTorque :> ISQ::torque; // 요구 절대 토크
        attribute source : TorqueDemandSourceEnum; // 요구 출처
    }
    enum def TorqueDemandSourceEnum {
        enum Driver; // 가속 페달
        enum Cruise; // 크루즈 컨트롤
    }

    package EgasOperationalRequirements_UC1 {
        @MetaInformation {
            version = "v0.2";
        }
        dependency from EgasOperationalRequirements_UC1 to UC1;
        action def ArbitrateTorqueDemand {
            doc
            /* [UC1_Normal, Alternative] 가속 페달과 크루즈 요구를 중재하여 기준 토크 요구를 산출한다.
             * 우선순위는 가속 페달 > 크루즈 (SYSR-23). 목표 토크는 연소 피드백과 차속(속도 루프)을 입력으로 폐루프로 산출한다 (SHR-02).
             */
            in accel : AccelerationIntent;
            in ccCmd : CruiseControlCommand;
            in ccState : CruiseControlStateEnum;
            in combustionFeedback : CombustionSystemStatus; // [R6] 토크 루프 피드백
            in dynamics : VehicleDynamicsFeedback; // [R6] 속도 루프 피드백 (vehicleSpeed)
            out baseTorque : TorqueDemand; // Before: TorqueInterventionRequest

            constraint demandSource {
                // [R6] 출처 규칙 (SYSR-23 우선순위)
                (accel.pedalDisplacement > 0.0 [mm] implies
                    baseTorque.source == TorqueDemandSourceEnum::Driver) and
                ((accel.pedalDisplacement == 0.0 [mm] and
                        ccState == CruiseControlStateEnum::Active) implies
                    baseTorque.source == TorqueDemandSourceEnum::Cruise)
            }
        }

        action def OverrideBrakeIntervention {
            in baseTorque : TorqueDemand; // Before: TorqueInterventionRequest
            in accel : AccelerationIntent;
            in ccState : CruiseControlStateEnum;
            in brake : BrakePedalPosition;
            out finalTorque : TorqueDemand; // Before: TorqueInterventionRequest
            out isOverrideActive : Boolean;

            // SHR-01, SYSR-01a, uc1_vc05: 구동 요구 AND 제동 → 오버라이드 활성 (S5)
            constraint brakeOverridePriority {
                IsBrakeOverrideTriggered(accel.pedalDisplacement, ccState, brake.pressure) implies
                isOverrideActive == true
            }
        }

        action def ActuateEngineAndFuel {
            in finalTorque : TorqueDemand; // Before: TorqueInterventionRequest
            in isOverrideActive : Boolean;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // uc1_vc06, uc1_vc07: 오버라이드 시 L1 출력 제약 (S5)
            constraint overrideTorqueLimit {
                isOverrideActive == true implies
                IsTorqueLimited(airCmd.massFlow, fuelCmd.injectionPulseWidth)
            }
        }

        action def JudgeNormalDriving {
            // [묶음 2] Jerk 면제 조건 판정
            in accel : AccelerationIntent;
            in ccState : CruiseControlStateEnum;
            in brake : BrakePedalPosition;
            in faultCause : FaultCause;
            in interventionDelta : ISQ::TorqueValue;
            out normalDriving : Boolean;

            constraint definition {
                normalDriving ==
                IsNormalDriving(
                    accel.pedalDisplacement,
                    ccState,
                    brake.pressure,
                    faultCause,
                    interventionDelta
                )
            }
        }

        action def MonitorDynamicsAndFeedback {
            doc
            /* [관측] 정밀도와 승차감은 플랜트 결과이며 EGAS 보장이 아니다 (SHR-02-1, SHR-08). 제어 입력은 ArbitrateTorqueDemand로도 연결된다. */
            in combustionFeedback : CombustionSystemStatus;
            in dynamicsFeedback : VehicleDynamicsFeedback;
            in normalDriving : Boolean; // [묶음 2] JudgeNormalDriving 결과

            // SHR-02-1 및 uc1_vc02, uc1_vc03, uc1_vc04
            constraint steadyStatePrecision {
                @PlantObservation;
                combustionFeedback.steadyStateError <= torqueSteadyStateErrorLimitPct and
                combustionFeedback.torqueOvershoot <= torqueOvershootLimitPct
            }
            constraint rideComfort {
                @PlantObservation;
                normalDriving implies dynamicsFeedback.longitudinalJerk <= longitudinalJerkLimit // Before: 무조건
            }
        }

        action def ManageDrivingTorqueArbitration {
            in accelIn : AccelerationIntent;
            in ccCmdIn : CruiseControlCommand;
            in ccStateIn : CruiseControlStateEnum;
            in brakeIn : BrakePedalPosition;
            in combustionStatusIn : CombustionSystemStatus;
            in dynamicsStatusIn : VehicleDynamicsFeedback;
            in faultCauseIn : FaultCause; // [R5] 정상 주행 판정용
            in interventionDeltaIn : ISQ::TorqueValue; // [R5]
            out airFlowOut : IntakeAirFlow;
            out fuelCmdOut : FuelIgnitionCommand;
            out isOverrideActiveOut : Boolean; // S8

            action arbitrate : ArbitrateTorqueDemand;
            action overrideCheck : OverrideBrakeIntervention;
            action actuate : ActuateEngineAndFuel;
            action judgeNormal : JudgeNormalDriving; // [묶음 2]
            action monitor : MonitorDynamicsAndFeedback;

            // 입력 → 중재 → 오버라이드 → 구동 (S5, S9)
            flow accelIn to arbitrate.accel;
            flow ccCmdIn to arbitrate.ccCmd;
            flow ccStateIn to arbitrate.ccState;
            flow combustionStatusIn to arbitrate.combustionFeedback; // [R6] 폐루프: 피드백이 제어로 돌아감
            flow dynamicsStatusIn to arbitrate.dynamics; // [R6]
            flow arbitrate.baseTorque to overrideCheck.baseTorque;
            flow accelIn to overrideCheck.accel;
            flow ccStateIn to overrideCheck.ccState;
            flow brakeIn to overrideCheck.brake;
            flow overrideCheck.finalTorque to actuate.finalTorque;
            flow overrideCheck.isOverrideActive to actuate.isOverrideActive;
            flow overrideCheck.isOverrideActive to isOverrideActiveOut;
            flow actuate.airCmd to airFlowOut;
            flow actuate.fuelCmd to fuelCmdOut;

            // 관측 (정상 주행 판정 → 모니터)
            flow accelIn to judgeNormal.accel;
            flow ccStateIn to judgeNormal.ccState;
            flow brakeIn to judgeNormal.brake;
            flow faultCauseIn to judgeNormal.faultCause;
            flow interventionDeltaIn to judgeNormal.interventionDelta;
            flow judgeNormal.normalDriving to monitor.normalDriving;
            flow combustionStatusIn to monitor.combustionFeedback;
            flow dynamicsStatusIn to monitor.dynamicsFeedback;

            // SHR-08, SYSR-13, uc1_vc01: 가속 입력 수신 → 공기/연료 명령 출력 (S1, M2)
            constraint responseTime {
                accelIn.pedalDisplacement > 0.0 [mm] implies
                (airFlowOut.responseTime <= pedalResponseBudget and
                    fuelCmdOut.responseTime <= pedalResponseBudget)
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
                    torqueReq.messageAge <= commDelayThreshold) implies
                (airCmd.responseTime <= interventionResponseBudget and
                    fuelCmd.responseTime <= interventionResponseBudget and
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
                (fuelCmd.responseTime <= stuckCutResponseBudget and
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
            out interventionActive : Boolean;

            // 시나리오 분기 (Control Flow)
            if torqueReqIn.messageAge <= commDelayThreshold {
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

            constraint interventionActiveWhenRequested {
                torqueReqIn.requestedTorqueDelta < 0.0 [N * m] implies interventionActive == true
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
                fuelCmd.responseTime <= compensationResponseBudget
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
                airCutCmd.responseTime <= failSafeResponseBudget and
                fuelCutCmd.responseTime <= failSafeResponseBudget
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
            out failSafeActive : Boolean;

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

            constraint failSafeActiveDefinition {
                failSafeActive == (faultCauseIn != FaultCause::NoFault)
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
            in expectedCredential : Integer;
            in ignition : IgnitionState;
            in vehicleSpeed : ISQ::SpeedValue;
            out isAuthorized : Boolean;
            out authStatus : CalibrationStatus;

            // SHR-05-1, uc4_vc1, uc4_vc2
            constraint authDefinition {
                isAuthorized ==
                DtcStroage::IsCalibrationAuthorized(
                    calReq.targetMemoryAddress,
                    calReq.accessCredential,
                    expectedCredential,
                    calReq.operation,
                    ignition.status,
                    vehicleSpeed
                )
            }
            constraint authResponse {
                (isAuthorized and calReq.operation == CalibrationOperationEnum::Read) implies
                (authStatus.responseCode == 200 and authStatus.responseTime <= accessAuthBudget)
            }
        }

        action def VerifyDataIntegrity {
            doc
            /* [UC4_Normal 2] 튜닝 데이터 기록 시 메모리 무결성(Checksum) 자체 검증 */
            in calReq : CalibrationRequest;
            out isIntegrityOk : Boolean;
            out verifyStatus : CalibrationStatus;

            // SHR-05-2, uc4_vc3, uc4_vc4
            constraint integrityDefinition {
                isIntegrityOk == (verifyStatus.verifiedChecksum == calReq.payloadChecksum)
            }
            constraint verifyResponse {
                isIntegrityOk implies
                (verifyStatus.responseCode == 200 and
                    verifyStatus.rolledBack == false and
                    verifyStatus.responseTime <= mapUpdateBudget)
            }
        }

        action def RejectInvalidAccess {
            doc
            /* [UC4_Exception] 비유효 메모리 주소 접근 시 에러 반환 및 롤백 */
            in calReq : CalibrationRequest;
            in isAuthorized : Boolean;
            in integrityFailed : Boolean;
            out errorStatus : CalibrationStatus;

            // uc4_vc5, uc4_vc6, uc4_vc7, uc4_vc8
            constraint unauthorizedRejection {
                not isAuthorized implies
                (errorStatus.responseCode != 200 and
                    errorStatus.rolledBack == false and
                    errorStatus.responseTime <= addressRejectBudget)
            }
            constraint integrityRollback {
                integrityFailed implies
                (errorStatus.responseCode != 200 and
                    errorStatus.rolledBack == true and
                    errorStatus.responseTime <= mapUpdateBudget)
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
                in calReqIn : CalibrationRequest;
                in expectedCredentialIn : Integer;
                in ignitionIn : IgnitionState;
                in vehicleSpeedIn : ISQ::SpeedValue;
                out calStatusOut : CalibrationStatus; // 최종 응답은 요청마다 하나

                action authorize : AuthorizeMemoryAccess;
                flow calReqIn to authorize.calReq;
                flow expectedCredentialIn to authorize.expectedCredential;
                flow ignitionIn to authorize.ignition;
                flow vehicleSpeedIn to authorize.vehicleSpeed;

                if authorize.isAuthorized == false {
                    // 비인가
                    action reject : RejectInvalidAccess;
                    flow calReqIn to reject.calReq;
                    flow authorize.isAuthorized to reject.isAuthorized;
                    // integrityFailed: 비인가에서는 거짓
                    flow reject.errorStatus to calStatusOut;
                } else {
                    if calReqIn.operation == CalibrationOperationEnum::Read {
                        // 인가된 읽기
                        flow authorize.authStatus to calStatusOut;
                    } else {
                        // 인가된 쓰기
                        action verifyIntegrity : VerifyDataIntegrity;
                        flow calReqIn to verifyIntegrity.calReq;
                        if verifyIntegrity.isIntegrityOk == true {
                            flow verifyIntegrity.verifyStatus to calStatusOut;
                        } else {
                            action rollback : RejectInvalidAccess; // 롤백 응답
                            flow calReqIn to rollback.calReq;
                            flow authorize.isAuthorized to rollback.isAuthorized;
                            // integrityFailed: 참 (쓰기 검증 실패)
                            flow rollback.errorStatus to calStatusOut;
                        }
                    }
                }
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
            in faultMemory : FaultMemoryRecord;
            out diagStatus : DiagnosticStatus;

            // VC#1, VC#2 제약 할당
            constraint dtcReadSuccess {
                diagStatus.responseCode == 200 and diagStatus.dtcCode > 0
            }
            constraint dtcResponseTime {
                diagStatus.responseTime <= dtcResponseBudget
            }
            constraint dtcResponse {
                diagReq.serviceId == DtcStroage::diagServiceReadDtc implies
                (diagStatus.responseCode == 200 and
                    diagStatus.dtcCode == faultMemory.dtcCode and
                    diagStatus.responseTime <= dtcResponseBudget)
            }
        }

        action def ExecuteZeroPointCalibration {
            doc
            /* [UC5_Normal 2] 부품 교체 후 영점 조정 처리 및 완료 응답 반환 */
            in diagReq : DiagnosticRequest;
            in ignition : IgnitionState;
            in vehicleSpeed : ISQ::SpeedValue;
            out diagStatus : DiagnosticStatus;

            // VC#3, VC#4 제약 할당
            constraint zeroPointCalibrationSuccess {
                diagStatus.responseCode == 200
            }
            constraint zeroPointResponseTime {
                diagStatus.responseTime <= zeroPointBudget
            }

            constraint zeroPointCal {
                (diagReq.serviceId == DtcStroage::diagServiceRoutineControl and
                    DtcStroage::IsServiceModeAllowed(ignition.status, vehicleSpeed)) implies
                (diagStatus.responseCode == 200 and diagStatus.responseTime <= zeroPointBudget)
            }
        }

        action def RejectInvalidDiagnosticRequest {
            doc
            /* [UC5_Exception] 미지원 서비스 ID 요청 시 에러 응답 및 통신 거절 */
            in diagReq : DiagnosticRequest;
            out diagStatus : DiagnosticStatus;
            in ignition : IgnitionState;
            in vehicleSpeed : ISQ::SpeedValue;

            // VC#5, VC#6 제약 할당
            constraint invalidDiagnosticRequestRejection {
                diagStatus.responseCode != 200
            }
            constraint errorResponseTime {
                diagStatus.responseTime <= errorResponseTime
            }
            constraint rejectUds {
                ((diagReq.serviceId != DtcStroage::diagServiceReadDtc and
                        diagReq.serviceId != DtcStroage::diagServiceRoutineControl) or
                    (diagReq.serviceId == DtcStroage::diagServiceRoutineControl and
                        not DtcStroage::IsServiceModeAllowed(
                            ignition.status,
                            vehicleSpeed
                        ))) implies
                (diagStatus.responseCode != 200 and diagStatus.responseTime <= serviceRejectBudget)
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

    package EgasOperationalRequirements_Arbitration {
        private import RV_InterfaceModel::*;
        private import ReqCommon::*;

        action def ArbitrateFinalCommand {
            doc
            /* [SYSR-18] 최종 공기/연료 명령 중재: 페일세이프 > 긴급 개입(채널별 더 제한적인 값) > 정상 주행.
             * 기능 쪽 SystemModeControllerAndArbiter(S2)의 규칙과 같다.
             */
            in baseAir : IntakeAirFlow; // UC3 출력: 정상 시 보정된 주행 명령, 고장 시 차단 명령
            in baseFuel : FuelIgnitionCommand;
            in failSafeActive : Boolean; // UC3
            in interventionActive : Boolean; // UC2
            in interventionAir : IntakeAirFlow; // UC2 출력
            in interventionFuel : FuelIgnitionCommand;
            out finalAir : IntakeAirFlow;
            out finalFuel : FuelIgnitionCommand;

            constraint arbitrationPriority {
                (failSafeActive == true implies (finalAir == baseAir and finalFuel == baseFuel)) and
                ((failSafeActive == false and interventionActive == true) implies
                    (((finalAir == baseAir and baseAir.massFlow <= interventionAir.massFlow) or
                            (finalAir == interventionAir and
                                interventionAir.massFlow < baseAir.massFlow)) and
                        ((finalFuel == baseFuel and
                                baseFuel.injectionPulseWidth <=
                                interventionFuel.injectionPulseWidth) or
                            (finalFuel == interventionFuel and
                                interventionFuel.injectionPulseWidth <
                                baseFuel.injectionPulseWidth)))) and
                ((failSafeActive == false and interventionActive == false) implies
                    (finalAir == baseAir and finalFuel == baseFuel))
            }
        }
    } // package EgasOperationalRequirements_Arbitration
} // package RV_OperationalModel
