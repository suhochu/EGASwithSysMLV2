package FW_CF2_WhiteBoxModel {
    doc
    /* [CF2 긴급 토크 개입 - 화이트박스 모델 파트 2]
     * 외부 능동안전 제어기(ESP/TCU)의 개입 요구, 통신 지연, 액추에이터 고착 등
     * 긴급 상황에 대응하는 UF2_1, UF2_2, UF2_3의 상세 내부 구조와 제약 할당을 명세합니다.
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

        @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 0. CF2 전용 내부 공용 데이터 타입
    // ==========================================
    item def InternalTorqueDemand {
        attribute targetTorque : TorqueValue;
        attribute calculationTimestamp : TimeValue;
    }

    item def InternalCutoffSignal {
        attribute isCutoffActive : Boolean;
    }

    item def InternalDelaySignal {
        attribute isDelayed : Boolean;
    }

    // ==========================================
    // 1. UF2_1 병렬 토크 저감 제어 화이트박스 분해
    // ==========================================
    action def <UF2_1_WB> ParallelTorqueReduction_WhiteBox :> CF2::UF2_1 {
        in torqueIntervention : TorqueInterventionRequest :>> CF2::UF2_1::torqueIntervention;
        out airIntake : IntakeAirFlow :>> CF2::UF2_1::airIntake;
        out fuelCmd : FuelIgnitionCommand :>> CF2::UF2_1::fuelCmd;

        // [Step 1: Sensing] 개입 요청 수신 및 검증
        action receiveInterventionReq {
            in rawReq : TorqueInterventionRequest;
            out validReq : TorqueInterventionRequest;
            attribute executionTime : TimeValue;

            // [로컬 제약] 외부 제어기의 긴급 개입 요구 수신 및 유효성 검증 레이턴시 (예산 5ms)
            constraint Local_ValidationLatency { executionTime <= 5.0 [milli * s] }
            // [로컬 제약] 토크 델타가 음수(-, 저감)일 때만 유효한 개입 요청으로 취급하는 선행 조건
            constraint Local_ValidIntervention { rawReq.requestedTorqueDelta < 0.0 [N * m] }
        }

        // [Step 2: Core Logic] 공기/연료 저감량 동기화 연산
        action calcReductionTorque {
            in validReq : TorqueInterventionRequest;
            out reducedTorque : InternalTorqueDemand;
            attribute executionTime : TimeValue;

            // [로컬 제약] 공기량 및 연료 분사량 동기화 축소 알고리즘 연산 레이턴시 (예산 5ms)
            constraint Local_CalculationLatency { executionTime <= 5.0 [milli * s] }
        }

        // [Step 3: Actuation] 실제 액추에이터 출력 제한 명령 생성
        action limitActuatorOutput {
            in targetTorque : InternalTorqueDemand;
            out outAir : IntakeAirFlow;
            out outFuel : FuelIgnitionCommand;
            attribute executionTime : TimeValue;

            // [로컬 제약] 출력 클램핑(Clamping) 및 액추에이터 명령 생성 레이턴시 (예산 5ms)
            constraint Local_CmdGenLatency { executionTime <= 5.0 [milli * s] }
            // [로컬 제약] 이전 사이클 대비 현재 사이클의 공기량 및 연료량이 반드시 감소해야 한다는 물리적 저감 강제 로직
            constraint Local_EnforceReduction {
                outAir.massFlow < outAir.previousMassFlow and
                outFuel.injectionPulseWidth < outFuel.previousPulseWidth
            }
        }

        // [예산 할당 검증] 부모의 InterventionLatency (총 15ms) 요구를 내부 3단계 지연시간 합산으로 증명
        assert constraint redefines InterventionLatency {
            out redefines result =
                receiveInterventionReq.executionTime +
                calcReductionTorque.executionTime +
                limitActuatorOutput.executionTime <=
                15.0 [milli * s];
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind torqueIntervention = receiveInterventionReq.rawReq;

        flow receiveInterventionReq.validReq to calcReductionTorque.validReq;
        flow calcReductionTorque.reducedTorque to limitActuatorOutput.targetTorque;

        bind limitActuatorOutput.outAir = airIntake;
        bind limitActuatorOutput.outFuel = fuelCmd;
    }

    // ==========================================
    // 2. UF2_2 통신 지연 보상 제어 화이트박스 분해
    // ==========================================
    action def <UF2_2_WB> CommunicationDelayCompensation_WhiteBox :> CF2::UF2_2 {
        in torqueIntervention : TorqueInterventionRequest :>> CF2::UF2_2::torqueIntervention;
        out airIntake : IntakeAirFlow :>> CF2::UF2_2::airIntake;
        out fuelCmd : FuelIgnitionCommand :>> CF2::UF2_2::fuelCmd;

        // [Step 1: Sensing] 통신 레이턴시 모니터링
        action monitorCommLatency {
            in req : TorqueInterventionRequest;
            out delaySignal : InternalDelaySignal;

            // [논리 분해 1단계: Sensing] CAN/LIN 통신 지연시간이 15ms를 초과하면 통신 지연 감지 플래그 활성화
            constraint Local_DetectDelay {
                req.latency > 15.0 [milli * s] implies delaySignal.isDelayed == true
            }
        }

        // [Step 2 & 3: Logic & Actuation] 이전 출력 상태 유지 (Hold) 로직
        action holdPreviousState {
            in trigger : InternalDelaySignal;
            out holdAirOut : IntakeAirFlow;
            out holdFuelOut : FuelIgnitionCommand;

            // [논리 분해 2단계: Logic/Actuation] 지연 플래그 수신 시, 새로운 제어값 연산을 멈추고 이전 사이클의 유효 출력값(Hold)을 유지
            constraint Local_FreezeOutput {
                trigger.isDelayed == true implies
                (holdAirOut.massFlow == holdAirOut.previousMassFlow and
                    holdFuelOut.injectionPulseWidth == holdFuelOut.previousPulseWidth)
            }
        }

        assert constraint redefines DelayCompensation {
        out redefines result = monitorCommLatency.delaySignal.isDelayed == true implies 
            (holdPreviousState.holdAirOut.massFlow == holdPreviousState.holdAirOut.previousMassFlow and 
             holdPreviousState.holdFuelOut.injectionPulseWidth == holdPreviousState.holdFuelOut.previousPulseWidth);
    }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind torqueIntervention = monitorCommLatency.req;
        flow monitorCommLatency.delaySignal to holdPreviousState.trigger;
        bind holdPreviousState.holdAirOut = airIntake;
        bind holdPreviousState.holdFuelOut = fuelCmd;
    }

    // ==========================================
    // 3. UF2_3 고착 대응 연료 차단 제어 화이트박스 분해
    // ==========================================
    action def <UF2_3_WB> ActuatorStuckFuelCut_WhiteBox :> CF2::UF2_3 {
        in airIntakeFeedback : IntakeAirFlow :>> CF2::UF2_3::airIntakeFeedback;
        out fuelCmd : FuelIgnitionCommand :>> CF2::UF2_3::fuelCmd;

        // [Step 1: Sensing] 스로틀 밸브 고착(Stuck) 감지
        action detectActuatorStuck {
            in feedback : IntakeAirFlow;
            out stuckTrigger : InternalCutoffSignal;

            // [논리 분해 1단계: Sensing] 스로틀 저감 명령에도 불구하고 실제 피드백 공기량이 줄어들지 않으면(고착 상태) 차단 플래그 활성화
            constraint Local_DetectStuck {
                feedback.massFlow >= feedback.previousMassFlow implies
                stuckTrigger.isCutoffActive == true
            }
        }

        // [Step 2 & 3: Logic & Actuation] 연료 차단 컷오프 실행
        action executeEmergencyFuelCut {
            in trigger : InternalCutoffSignal;
            out zeroFuelOut : FuelIgnitionCommand;

            // [논리 분해 2단계: Actuation] 공기 유입 통제 불가 상황이므로, 최종 안전 상태(Safe State)인 연료 차단 강제 실행
            constraint Local_FuelCut {
                trigger.isCutoffActive == true implies zeroFuelOut.injectionPulseWidth == 0.0 [s]
            }
        }

        assert constraint redefines StuckFailSafe {
        out redefines result = detectActuatorStuck.stuckTrigger.isCutoffActive == true implies 
            executeEmergencyFuelCut.zeroFuelOut.injectionPulseWidth == 0.0 [s];
    }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind airIntakeFeedback = detectActuatorStuck.feedback;
        flow detectActuatorStuck.stuckTrigger to executeEmergencyFuelCut.trigger;
        bind executeEmergencyFuelCut.zeroFuelOut = fuelCmd;
    }
} // package FW_CF2_WhiteBoxModel
