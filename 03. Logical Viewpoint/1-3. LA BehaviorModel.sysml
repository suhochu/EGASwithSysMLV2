package LA_BehaviorModel {
    doc
    /* [논리 관점 (Logical Viewpoint) - 4단계: 완전 행위 명세]
     * 3단계의 정적 분해 모델(LA_DecompositionModel)을 확장하여,
     * 각 원자적 논리 컴포넌트 내부에 상태 머신(State Machine)과 
     * 우선순위 기반 입출력 변환 로직(Decision Logic)을 정의합니다.
     */

    private import RV_InterfaceModel::*;
    private import LA_RootComponentModel::*;
    private import LA_DecompositionModel::*;
    private import FW_UF1_WhiteBoxModel::*;
    private import FW_CF2_WhiteBoxModel::*;
    private import FW_CF3_WhiteBoxModel::*;
    private import FB_ModeArbitrationModel::*;
    private import ReqCommon::*;

    private import SI::*;

    @MetaInformation {
        version = "v1.0";
    }

    // ==========================================
    // 1. BehavioralInputProcessor 행위 명세
    // ==========================================

    part def BehavioralInputProcessor :> InputProcessingComponent {
        doc
        /* 기능 관점의 6개 소기능을 재정의하여 실행합니다.
         * 'action'과 'then' 키워드를 사용하여 [입력 ➔ 로직 처리 ➔ 출력 할당]의 
         * 절차적 실행 순서(Sequential Execution)를 강제합니다.
         */

        exhibit state inputBehavior {
            first start then continuousProcessing;

            state continuousProcessing {
                do action processStreamsAndEvents {
                    // ----------------------------------------------------
                    // [기능 1] 가속 페달 노이즈 필터링
                    // ----------------------------------------------------
                    perform action execFilterPedal :> uF1_1_WB.filterPedalInput {
                        in rawAccel = p_inAccel.accelIntent;
                        attribute redefines executionTime : TimeValue;
                        constraint Logical_Budget_Filter { executionTime <= 10.0 [milli * s] }

                        action processLogic {
                            if rawAccel.pedalDisplacement >= 0.0 [mm] {
                                out validAccel = rawAccel;
                            } else {
                                assign validAccel.pedalDisplacement := 0.0 [mm];
                            }
                        }

                        then action assignOut {
                            assign p_outValidAccel.validAccel := validAccel;
                        }
                    }

                    // ----------------------------------------------------
                    // [기능 2] 크루즈 컨트롤 명령 유효성 검증
                    // ----------------------------------------------------
                    perform action execProcessCruise :> uF1_2_WB.processCruiseCommand {
                        in rawCcCmd = p_inCcCmd.ccCmd;

                        action processLogic {
                            if rawCcCmd.setSpeed > 0.0 [km / h] {
                                out validCcCmd = rawCcCmd;
                            } else {
                                assign validCcCmd.setSpeed := 0.0 [km / h];
                            }
                        }

                        then action assignOut {
                            assign p_outValidCcCmd.validCcCmd := validCcCmd;
                        }
                    }

                    // ----------------------------------------------------
                    // [기능 3] 브레이크 밟힘 감지 및 오버라이드 트리거
                    // ----------------------------------------------------
                    perform action execDetectBrake :> uF1_3_WB.detectBrake {
                        in rawBrake = p_inBrake.brakeInput;
                        attribute redefines executionTime : TimeValue;
                        constraint Logical_Budget_DetectBrake { executionTime <= 4.0 [milli * s] }

                        action processLogic {
                            if rawBrake.pressure > 0.0 [Pa] {
                                assign cutoffTrigger.isCutoffActive := true;
                            } else {
                                assign cutoffTrigger.isCutoffActive := false;
                            }
                        }

                        then action assignOut {
                            assign p_outCutoffTrigger.cutoffTrigger := cutoffTrigger;
                        }
                    }

                    // ----------------------------------------------------
                    // [기능 4] 외부 제어기 긴급 개입 요구 수신
                    // ----------------------------------------------------
                    perform action execReceiveIntervention :> uF2_1_WB.receiveInterventionReq {
                        in rawReq = p_inTorqueReq.torqueReq;
                        attribute redefines executionTime : TimeValue;
                        constraint Logical_Budget_ReceiveReq { executionTime <= 5.0 [milli * s] }

                        action processLogic {
                            if rawReq.requestedTorqueDelta < 0.0 [N * m] {
                                out validReq = rawReq;
                            } else {
                                assign validReq.requestedTorqueDelta := 0.0 [N * m];
                            }
                        }

                        then action assignOut {
                            assign p_outValidTorqueReq.validTorqueReq := validReq;
                        }
                    }

                    // ----------------------------------------------------
                    // [기능 5] 통신 지연 모니터링 (Timeout 감지)
                    // ----------------------------------------------------
                    perform action execMonitorComm :> uF2_2_WB.monitorCommLatency {
                        in req = p_inTorqueReq.torqueReq;

                        action processLogic {
                            if req.latency > 15.0 [milli * s] {
                                assign delaySignal.isDelayed := true;
                            } else {
                                assign delaySignal.isDelayed := false;
                            }
                        }

                        then action assignOut {
                            assign p_outDelaySignal.delaySignal := delaySignal;
                        }
                    }

                    // ----------------------------------------------------
                    // [기능 6] 액추에이터 고착(Stuck) 감지
                    // ----------------------------------------------------
                    perform action execDetectStuck :> uF2_3_WB.detectActuatorStuck {
                        in feedback = p_inAirFeedback.airFlow;

                        action processLogic {
                            if feedback.massFlow >= feedback.previousMassFlow {
                                assign stuckTrigger.isCutoffActive := true;
                            } else {
                                assign stuckTrigger.isCutoffActive := false;
                            }
                        }

                        then action assignOut {
                            // Race Condition 방지를 위해 참일 때만 트리거 덮어쓰기
                            if stuckTrigger.isCutoffActive == true {
                                assign p_outCutoffTrigger.cutoffTrigger := stuckTrigger;
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. BehavioralTorqueArbiter 행위 명세 (명시적 제어 흐름 적용)
    // ==========================================
    part def BehavioralTorqueArbiter :> TorqueArbitrationComponent {
        doc
        /* 각 주행 상태 내부의 토크 연산 동작(do action)에 대해 
         * [입력 바인딩 ➔ 내부 로직 선언(=) ➔ 출력 할당(:=)] 패턴을 적용하여,
         * 상태 전이(Transition)와 데이터 연산(Data Computation)의 생명주기를 
         * 시스템적으로 안전하게 통제합니다.
         */

        exhibit state arbitrationBehavior {
            first start then off;

            // ----------------------------------------------------
            // [상태 1] Off: 시동 꺼짐 (초기 상태)
            // ----------------------------------------------------
            state off {
                entry action {
                    assign p_outModeStatus
                        .modeStatus := FB_ModeArbitrationModel::SystemOperatingMode::Normal_Mode;
                    assign p_outTargetTorque.targetTorque.targetTorque := 0.0 [N * m];
                }
            }

            // ----------------------------------------------------
            // [상태 2] Standby: 시동 켜짐, 조작 없음 (아이들링 대기)
            // ----------------------------------------------------
            state standby {
                entry action {
                    assign p_outModeStatus
                        .modeStatus := FB_ModeArbitrationModel::SystemOperatingMode::Normal_Mode;
                }
                do action maintainIdleTorque {
                    // 입력이 필요 없는 고정 출력은 직접 할당
                    assign p_outTargetTorque.targetTorque.targetTorque := 15.0 [N * m];
                }
            }

            // ----------------------------------------------------
            // [상태 3] ManualDriving: 운전자 수동 조작
            // ----------------------------------------------------
            state manualDriving {
                entry action {
                    assign p_outModeStatus
                        .modeStatus := FB_ModeArbitrationModel::SystemOperatingMode::Normal_Mode;
                }

                do action execCalcManual :> uF1_1_WB.calcManualTorque {
                    // [입력 바인딩]
                    in ignStatus = p_inIgnition.ignitionStatus;
                    in filteredAccel = p_inValidAccel.validAccel;

                    attribute redefines executionTime : TimeValue;
                    constraint Logical_Budget_CalcManual { executionTime <= 20.0 [milli * s] }

                    // [로직 처리] 선언적 바인딩(=)
                    action processLogic {
                        // 페달 밟힘량(0~100%) 비례 최대 토크(예: 300Nm) 연산
                        assign torqueDemand
                            .targetTorque := (filteredAccel.pedalPositionPercentage * 3.0) [N * m];
                    }

                    // [출력 할당] 순차 실행 강제(:=)
                    then action assignOut {
                        assign p_outTargetTorque.targetTorque := torqueDemand;
                    }
                }
            }

            // ----------------------------------------------------
            // [상태 4] CruiseDriving: 정속 주행 컨트롤
            // ----------------------------------------------------
            state cruiseDriving {
                entry action {
                    assign p_outModeStatus
                        .modeStatus := FB_ModeArbitrationModel::SystemOperatingMode::Normal_Mode;
                }

                do action execCalcCruise :> uF1_2_WB.calcCruiseTorque {
                    // [입력 바인딩]
                    in validCmd = p_inValidCcCmd.validCcCmd;
                    in engineStatus = p_inCombustionStatus.combustionStatus;

                    // [로직 처리] 선언적 바인딩(=)
                    action processLogic {
                        // 목표 속도와 정상 상태 오차를 반영한 P제어 보상 수식
                        assign torqueDemand
                            .targetTorque :=
                            validCmd.setSpeed * 2.5 [(N * m * h) / km] -
                            engineStatus.steadyStateError * 10.0 [N * m];
                    }

                    // [출력 할당] 순차 실행 강제(:=)
                    then action assignOut {
                        assign p_outTargetTorque.targetTorque := torqueDemand;
                    }
                }
            }

            // ----------------------------------------------------
            // [상태 5] EmergencyIntervention: 긴급 개입 (TCU/ESP) 최우선권
            // ----------------------------------------------------
            state emergencyIntervention {
                entry action {
                    assign p_outModeStatus
                        .modeStatus := FB_ModeArbitrationModel::SystemOperatingMode::Emergency_Mode;
                }

                do action execCalcReduction :> uF2_1_WB.calcReductionTorque {
                    // [입력 바인딩]
                    in validReq = p_inValidTorqueReq.validTorqueReq;

                    attribute redefines executionTime : TimeValue;
                    constraint Logical_Budget_CalcReduction { executionTime <= 5.0 [milli * s] }

                    // [로직 처리] 선언적 바인딩(=)
                    action processLogic {
                        // 외부 제어기가 요구한 토크 저감량(음수)을 산출
                        assign reducedTorque.targetTorque := validReq.requestedTorqueDelta;
                    }

                    // [출력 할당] 순차 실행 강제(:=)
                    then action assignOut {
                        assign p_outTargetTorque.targetTorque := reducedTorque;
                    }
                }
            }

            // ==========================================
            // [우선순위 기반 상태 전이 (Transitions)]
            // ==========================================

            // 1. 시동 On (Off -> Standby)
            transition t_TurnOn
                first off
                accept ign : IgnitionState
                if ign.status == ReqCommon::IgnitionStatusEnum::On then standby;

            // 2. 시동 Off 글로벌 전이 (Any Active State -> Off)
            transition t_TurnOff_Standby
                first standby
                accept ign : IgnitionState
                if ign.status == ReqCommon::IgnitionStatusEnum::Off then off;
            transition t_TurnOff_Manual
                first manualDriving
                accept ign : IgnitionState
                if ign.status == ReqCommon::IgnitionStatusEnum::Off then off;
            transition t_TurnOff_Cruise
                first cruiseDriving
                accept ign : IgnitionState
                if ign.status == ReqCommon::IgnitionStatusEnum::Off then off;
            transition t_TurnOff_Emergency
                first emergencyIntervention
                accept ign : IgnitionState
                if ign.status == ReqCommon::IgnitionStatusEnum::Off then off;

            // 3. [최우선 중재] 긴급 개입 요구 발생 시
            transition t_Emergency_Standby
                first standby
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0.0 [N * m] then emergencyIntervention;
            transition t_Emergency_Manual
                first manualDriving
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0.0 [N * m] then emergencyIntervention;
            transition t_Emergency_Cruise
                first cruiseDriving
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0.0 [N * m] then emergencyIntervention;

            // 4. [우선 중재] 수동 조작 우선권 (긴급 개입 중에는 무시됨)
            transition t_Manual_Standby
                first standby
                accept accel : AccelerationIntent
                if (
                    accel.pedalDisplacement > 0.0 [mm] and
                    p_inValidTorqueReq.validTorqueReq.requestedTorqueDelta >= 0.0 [N * m]
                )
                    then manualDriving;
            transition t_Manual_Cruise
                first cruiseDriving
                accept accel : AccelerationIntent
                if (
                    accel.pedalDisplacement > 0.0 [mm] and
                    p_inValidTorqueReq.validTorqueReq.requestedTorqueDelta >= 0.0 [N * m]
                )
                    then manualDriving;

            // 5. [일반 진입] 크루즈 컨트롤 진입
            transition t_Cruise_Standby
                first standby
                accept cc : CruiseControlCommand
                if (
                    cc.setSpeed > 0.0 [km / h] and
                    p_inValidAccel.validAccel.pedalDisplacement == 0.0 [mm] and
                    p_inValidTorqueReq.validTorqueReq.requestedTorqueDelta >= 0.0 [N * m]
                )
                    then cruiseDriving;
            transition t_Cruise_Manual
                first manualDriving
                accept cc : CruiseControlCommand
                if (
                    cc.setSpeed > 0.0 [km / h] and
                    p_inValidAccel.validAccel.pedalDisplacement == 0.0 [mm] and
                    p_inValidTorqueReq.validTorqueReq.requestedTorqueDelta >= 0.0 [N * m]
                )
                    then cruiseDriving;

            // 6. [해제 시 안전 복귀 전이] (즉시 다른 모드로 가지 않고 항상 Standby를 거쳐 안전 확보)
            transition t_ReleaseEmergency
                first emergencyIntervention
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m] then standby;
            transition t_ReleaseManual
                first manualDriving
                accept accel : AccelerationIntent
                if accel.pedalDisplacement == 0.0 [mm] then standby;
            transition t_ReleaseCruise
                first cruiseDriving
                accept cc : CruiseControlCommand
                if cc.setSpeed == 0.0 [km / h] then standby;
        }
    }

    // ==========================================
    // 3. BehavioralActuatorController 행위 명세 (명시적 제어 흐름 및 바인딩 적용)
    // ==========================================
    part def BehavioralActuatorController :> ActuatorControlComponent {
        doc
        /* 우선순위 멀티플렉서(Priority Multiplexer) 역할을 하는 최종 하드웨어 제어기입니다.
         * 상위 컴포넌트들에서 적용한 [입력 바인딩 ➔ 로직 선언(=) ➔ 출력 할당(:=)] 패턴을 
         * 우선순위 판별(if-else if-else) 블록 내부의 각 동작(Action)에 완벽하게 적용하여,
         * 다중 입력에 의한 충돌(Race Condition)을 방지하고 물리적 실행 순서를 강제합니다.
         */

        // ----------------------------------------------------
        // [컴포넌트 레벨 Action 선언부]
        // ----------------------------------------------------

        // 1순위: 치명적 결함 셧다운 (Fatal)
        action execShutdown :> uF3_2_WB.shutdownSystem {
            // 1. 입력 바인딩
            in trigger = p_inFatalTrigger.fatalTrigger;

            // 2. 내부 로직 처리 (선언적 바인딩)
            action processLogic {
                assign cutAir.massFlow := 0.0 [kg / s];
                assign cutFuel.injectionPulseWidth := 0.0 [s];
                assign warnSign.status := ReqCommon::DashboardWarningStatusEnum::Critical;
            }

            // 3. 순차적 출력 할당
            then action assignOut {
                assign p_outAir.airFlow := cutAir;
                assign p_outFuel.fuelCmd := cutFuel;
                assign p_outDashboard.dashboardWarning := warnSign;
            }
        }

        // 2순위: 제동/고착 오버라이드 차단 (Cut-off)
        action execOverride :> uF1_3_WB.arbitrateOverride {
            // 1. 입력 바인딩
            in trigger = p_inCutoffTrigger.cutoffTrigger;
            attribute redefines executionTime : TimeValue;
            constraint Logical_Budget_Override { executionTime <= 6.0 [milli * s] }

            // 2. 내부 로직 처리 (선언적 바인딩)
            action processLogic {
                assign zeroAirOut.massFlow := 0.0 [kg / s];
                assign zeroFuelOut.injectionPulseWidth := 0.0 [s];
            }

            // 3. 순차적 출력 할당
            then action assignOut {
                assign p_outAir.airFlow := zeroAirOut;
                assign p_outFuel.fuelCmd := zeroFuelOut;
                assign p_outDashboard
                    .dashboardWarning.status := ReqCommon::DashboardWarningStatusEnum::Normal;
            }
        }

        // 3순위: 통신 지연 시 이전 상태 동결 (Hold)
        action execHold :> uF2_2_WB.holdPreviousState {
            // 원본 시그니처에 맞게 trigger만 바인딩
            in trigger = p_inDelaySignal.delaySignal;

            action processLogic {
                // 현재 컴포넌트의 출력 포트(이전 사이클 상태)를 직접 참조하여 Hold 값 선언
                assign holdAirOut.massFlow := p_outAir.airFlow.previousMassFlow;
                assign holdFuelOut.injectionPulseWidth := p_outFuel.fuelCmd.previousPulseWidth;
            }

            then action assignOut {
                assign p_outAir.airFlow := holdAirOut;
                assign p_outFuel.fuelCmd := holdFuelOut;
                assign p_outDashboard
                    .dashboardWarning.status := ReqCommon::DashboardWarningStatusEnum::Normal;
            }
        }

        // 4순위: 정상 목표 토크 출력 + 물리 오차 보정 적용
        action execGenAndCorrect :> uF1_1_WB.genEngineCommand {
            // 원본 시그니처에 맞게 torqueReq만 바인딩
            in torqueReq = p_inTargetTorque.targetTorque;

            attribute redefines executionTime : TimeValue;
            constraint Logical_Budget_GenCommand {
                executionTime <= 20.0 [milli * s]
            }

            action processLogic {
                // 보정값(correctionCmd)은 액션 외부 포트에서 직접 참조하여 선언적 산출 수식에 포함
                assign outAir
                    .massFlow :=
                    torqueReq.targetTorque * 0.01 [kg / s / N / m] +
                    p_inCorrectionCmd.correctionCmd.targetAirAdjust;
                assign outFuel
                    .injectionPulseWidth :=
                    torqueReq.targetTorque * 0.0001 [s / N / m] +
                    p_inCorrectionCmd.correctionCmd.targetFuelAdjust;
            }

            then action assignOut {
                assign p_outAir.airFlow := outAir;
                assign p_outFuel.fuelCmd := outFuel;
                assign p_outDashboard
                    .dashboardWarning.status := ReqCommon::DashboardWarningStatusEnum::Normal;
            }
        }

        exhibit state actuatorBehavior {
            first start then outputExecution;

            state outputExecution {
                // 매 제어 주기마다 실시간으로 제어 신호의 우선순위를 평가하고 출력을 결정함
                do action evaluateOutputs {
                    // ----------------------------------------------------
                    // 1순위: 치명적 결함 셧다운 (Fatal) - CF3 안전 감시기 개입
                    // ----------------------------------------------------
                    if p_inFatalTrigger.fatalTrigger.isFatalActive == true {
                        perform execShutdown;
                    } else if p_inCutoffTrigger.cutoffTrigger.isCutoffActive == true {
                        // ---------------------------------------------------- // 2순위: 제동/고착 오버라이드 차단 (Cut-off) - CF1/CF2 하드 블로킹 // ----------------------------------------------------
                        perform execOverride;
                    } else if p_inDelaySignal.delaySignal.isDelayed == true {
                        // ---------------------------------------------------- // 3순위: 통신 지연 시 이전 상태 동결 (Hold) - CF2 예외 처리 // ----------------------------------------------------
                        perform execHold;
                    } else {
                        // ---------------------------------------------------- // 4순위: 정상 목표 토크 출력 + 물리 오차 보정 적용 (Normal Execution) // ----------------------------------------------------
                        perform execGenAndCorrect;
                    }
                }
            }
        }
    }

    // ==========================================
    // 4. BehavioralSafetyMonitor 행위 명세 (내부 파이프라인 및 시그니처 매핑 완결)
    // ==========================================
    part def BehavioralSafetyMonitor :> SafetyMonitorComponent {
        doc
        /* 차량의 물리적 한계를 감시하고 보호하는 독립적인 워치독(Watchdog) 상태 머신입니다.
         * NormalMonitoring 상태 내에서 할당된 2개의 소기능(monitorSensorError -> calcCorrectionValue)을 
         * 'then' 키워드로 직렬 연결하여 데이터 파이프라인(Internal Pipeline)을 완벽하게 구현합니다.
         */

        exhibit state safetyBehavior {
            first start then NormalMonitoring;

            // ----------------------------------------------------
            // [상태 1] NormalMonitoring: 정상 상태 감시 및 오차 보정
            // ----------------------------------------------------
            state NormalMonitoring {
                entry action {
                    assign p_outFatalTrigger.fatalTrigger.isFatalActive := false;
                }

                do action executeCorrectionRoutine {
                    // [기능 할당 1] 센서 오차 모니터링 (Sensing)
                    perform action execMonitor :> uF3_1_WB.monitorSensorError {
                        // 1. Component Port ➔ Action Input 바인딩
                        in currentSensor = p_inSensor.sensorData;
                        in currentCombustion = p_inCombustionStatus.combustionStatus;

                        attribute redefines executionTime : TimeValue;
                        constraint Logical_Budget_Monitor { executionTime <= 3.0 [milli * s] }

                        // 2. 내부 로직 처리 (에러 추정)
                        action processLogic {
                            // 연소 상태의 정상 오차(steadyStateError)를 마찰 오차로 매핑
                            assign errorEst.frictionError := currentCombustion.steadyStateError;
                            assign errorEst.latencyError := 0.0 [s]; // 단순화
                        }
                    }

                    // [기능 할당 2] 오차 보정치 산출 (Core Logic)
                    // execMonitor가 완료된 후(then) 실행되며, 그 결과값을 입력으로 받음
                    then perform action execCalc :> uF3_1_WB.calcCorrectionValue {
                        // 1. 이전 액션의 결과물 및 Component Port ➔ Action Input 바인딩
                        in rawError = execMonitor.errorEst;
                        in tempCheck = p_inSensor.sensorData;

                        attribute redefines executionTime : TimeValue;
                        constraint Logical_Budget_CalcCorrection {
                            executionTime <= 4.0 [milli * s]
                        }

                        // 2. 내부 로직 처리
                        action processLogic {
                            // 전달받은 rawError를 바탕으로 최종 보정 명령 산출
                            assign correctionDemand
                                .targetAirAdjust := (rawError.frictionError * 0.001) [kg / s];
                            assign correctionDemand
                                .targetFuelAdjust := (rawError.frictionError * 0.0001) [s];
                        }

                        // 3. 최종 산출물을 외부 포트에 할당
                        then action assignOut {
                            assign p_outCorrectionCmd.correctionCmd := correctionDemand;
                        }
                    }
                }
            }

            // ----------------------------------------------------
            // [상태 2] CriticalFault: 치명적 결함 페일세이프 (Latching State)
            // ----------------------------------------------------
            state CriticalFault {
                entry action {
                    assign p_outFatalTrigger.fatalTrigger.isFatalActive := true;
                    // 보정 명령(Correction Cmd) 전송 완전 중단 (0으로 안전 클램핑)
                    assign p_outCorrectionCmd.correctionCmd.targetAirAdjust := 0.0 [kg / s];
                    assign p_outCorrectionCmd.correctionCmd.targetFuelAdjust := 0.0 [s];
                }

                // [기능 할당 3] 치명적 한계치 감시 유지
                do action execCheckCritical :> uF3_2_WB.checkCriticalLimits {
                    in sensorData = p_inSensor.sensorData;

                    action processLogic {
                        // 이미 Critical 상태이므로 방어적으로 지속적인 True 출력 유지
                        assign fatalFaultTrigger.isFatalActive := true;
                    }

                    then action assignOut {
                        assign p_outFatalTrigger.fatalTrigger := fatalFaultTrigger;
                    }
                }
            }

            // ==========================================
            // [상태 전이 (Transitions)]
            // ==========================================
            transition t_DetectFault
                first NormalMonitoring
                accept sens : EngineSensorData
                if sens.coolantTemp > 120.0 ['°'] then CriticalFault;
        }
    }

    // ==========================================
    // 5. 행위가 주입된 최종 논리 아키텍처 조립
    // ==========================================
    part def FinalBehavioralEgasSystem :> DecomposedLogicalEgasSystem {
        doc
        /* 3단계의 정적 구조 시스템 모델(DecomposedLogicalEgasSystem)에서 
         * 정의된 각 논리 서브 컴포넌트를, 완전 행위(FSM 및 Decision Logic)가 
         * 완벽하게 명세된 Behavioral 파트로 재정의(Redefine)하여 최종 조립합니다.
         *
         * 이 조립을 통해 포트 바인딩 및 데이터/제어 채널 배선(정적 아키텍처)은 
         * 그대로 유지된 채, 하위 SW 개발자가 즉시 코드로 변환할 수 있는 
         * 완벽한 '실행 가능한 명세(Executable Specification)'가 완성됩니다.
         */

        // 정적 파트를 행위가 내장된 파트로 일대일 재정의(Redefinition)
        part redefines inputProcessor : BehavioralInputProcessor;
        part redefines torqueArbiter : BehavioralTorqueArbiter;
        part redefines safetyMonitor : BehavioralSafetyMonitor;
        part redefines actuatorController : BehavioralActuatorController;
    }
} // package LA_BehaviorModel
