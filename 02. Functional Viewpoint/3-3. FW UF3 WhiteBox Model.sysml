package FW_CF3_WhiteBoxModel {
    doc
    /* [CF3 하드웨어 안전 모니터링 - 화이트박스 모델 파트 ]
     * 엔진 마찰/지연 실시간 보정(UF3_1)과 치명적 결함 페일세이프(UF3_2)의 
     * 상세 내부 구조, 내부 트리거 논리, 그리고 처리 시간 할당을 명세합니다.
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;
    private import SafeStateLogic::*;

    @MetaInformation {
        version = "v0.1";
    }
    // ==========================================
    // 0. CF3 전용 내부 공용 데이터 타입
    // ==========================================
    item def InternalErrorData {
        attribute frictionError : Real;
        attribute latencyError : TimeValue;
    }

    item def InternalCorrectionCmd {
        attribute targetAirAdjust : MassFlowValue; // 공기량 조절 (kg/s)
        attribute targetFuelAdjust : TimeValue; // 연료 펄스 조절 (s)
    }

    item def InternalFatalTrigger {
        attribute isFatalActive : Boolean;
    }

    // ==========================================
    // 1. UF3_1 하드웨어 마찰 및 지연 보정 화이트박스 분해
    // ==========================================
    action def <UF3_1_WB> HardwareDelayAndFrictionCompensation_WhiteBox :> CF3::CF3_1 {
        in baseAirCmd : IntakeAirFlow :>> CF3::CF3_1::baseAirCmd; // [신규]
        in baseFuelCmd : FuelIgnitionCommand :>> CF3::CF3_1::baseFuelCmd; // [신규]
        in sensor : EngineSensorData :>> CF3::CF3_1::sensor;
        in combustionStatus : CombustionSystemStatus :>> CF3::CF3_1::combustionStatus;
        out airIntake : IntakeAirFlow :>> CF3::CF3_1::airIntake;
        out fuelCmd : FuelIgnitionCommand :>> CF3::CF3_1::fuelCmd;

        // [Step 1: Sensing] 변경 없음
        action monitorSensorError {
            in currentSensor : EngineSensorData;
            in currentCombustion : CombustionSystemStatus;
            out errorEst : InternalErrorData;
            attribute executionTime : TimeValue;
            constraint Local_SensingLatency { executionTime <= 3.0 [milli * s] }
        }

        // [Step 2: Core Logic] 보상값 연산 (과열 게이팅 삭제, 보정량 한계 추가)
        action calcCorrectionValue {
            in rawError : InternalErrorData;
            in sensorCtx : EngineSensorData; // Before: tempCheck
            out correctionDemand : InternalCorrectionCmd;
            attribute executionTime : TimeValue;

            constraint Local_CalcLatency { executionTime <= 4.0 [milli * s] }
            constraint Local_CorrectionBound {
                // [신규] 보정량은 한계 이내
                correctionDemand.targetAirAdjust >= -maxAirCorrection and
                correctionDemand.targetAirAdjust <= maxAirCorrection and
                correctionDemand.targetFuelAdjust >= -maxFuelCorrection and
                correctionDemand.targetFuelAdjust <= maxFuelCorrection
            }
        }

        // [Step 3: Actuation] 기준 명령에 보정량을 가감 (직렬 후처리)
        action applyCorrection {
            in baseAir : IntakeAirFlow; // [신규]
            in baseFuel : FuelIgnitionCommand; // [신규]
            in correctionReq : InternalCorrectionCmd;
            out adjAir : IntakeAirFlow;
            out adjFuel : FuelIgnitionCommand;
            attribute executionTime : TimeValue;

            constraint Local_ActuationLatency { executionTime <= 3.0 [milli * s] }
            constraint Local_SeriesApply {
                // [신규] 기준 + 보정량
                adjAir.massFlow == baseAir.massFlow + correctionReq.targetAirAdjust and
                adjFuel.injectionPulseWidth ==
                baseFuel.injectionPulseWidth + correctionReq.targetFuelAdjust
            }
        }

        assert constraint redefines ResponseTimeConstraint {
            out redefines result =
                monitorSensorError.executionTime +
                calcCorrectionValue.executionTime +
                applyCorrection.executionTime <=
                compensationBudget;
        }

        assert constraint redefines BoundedCorrection { // BB 제약과 같은 본문 (S2와 같은 방식)
            out redefines result =
                airIntake.massFlow >= baseAirCmd.massFlow - maxAirCorrection and
                airIntake.massFlow <= baseAirCmd.massFlow + maxAirCorrection and
                fuelCmd.injectionPulseWidth >=
                baseFuelCmd.injectionPulseWidth - maxFuelCorrection and
                fuelCmd.injectionPulseWidth <= baseFuelCmd.injectionPulseWidth + maxFuelCorrection;
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind sensor = monitorSensorError.currentSensor;
        bind sensor = calcCorrectionValue.sensorCtx; // Before: tempCheck
        bind combustionStatus = monitorSensorError.currentCombustion;
        bind baseAirCmd = applyCorrection.baseAir; // [신규]
        bind baseFuelCmd = applyCorrection.baseFuel; // [신규]

        flow monitorSensorError.errorEst to calcCorrectionValue.rawError;
        flow calcCorrectionValue.correctionDemand to applyCorrection.correctionReq;

        bind applyCorrection.adjAir = airIntake;
        bind applyCorrection.adjFuel = fuelCmd;
    }

    // ==========================================
    // 2. UF3_2 치명적 센서 결함 페일세이프 화이트박스 분해
    // ==========================================
    action def <UF3_2_WB> CriticalSensorFaultFailSafe_WhiteBox :> CF3::CF3_2 {
        in faultCause : FaultCause :>> CF3::CF3_2::faultCause;
        out airIntake : IntakeAirFlow :>> CF3::CF3_2::airIntake;
        out fuelCmd : FuelIgnitionCommand :>> CF3::CF3_2::fuelCmd;
        out dashboard : DashboardWarning :>> CF3::CF3_2::dashboard;

        // [Step 1: Sensing] 확정된 고장 원인을 내부 차단 플래그로 변환 (확정 판정 자체는 FE가 담당)
        action classifyFault {
            // Before: checkCriticalLimits
            in cause : FaultCause;
            out fatalFaultTrigger : InternalFatalTrigger;
            constraint Local_DetectFatal {
                cause != FaultCause::NoFault implies fatalFaultTrigger.isFatalActive == true
            }
        }

        // [Step 2 & 3: Logic & Actuation] 페일세이프 실행 및 시스템 셧다운
        action shutdownSystem {
            in trigger : InternalFatalTrigger;
            out cutAir : IntakeAirFlow;
            out cutFuel : FuelIgnitionCommand;
            out warnSign : DashboardWarning;

            // [논리 분해 2단계: Actuation] 차단 플래그 수신 시 즉시 공기/연료 제로 클램핑 및 클러스터에 치명적 결함(Critical) 경고 점등
            constraint Local_ExecuteShutdown {
                trigger.isFatalActive == true implies
                (SafeStateLogic::IsFuelCutOff(fuelCmd.injectionPulseWidth) and
                    warnSign.status == DashboardWarningStatusEnum::Critical)
            }
        }

        assert constraint redefines FatalFaultCutoff {
            out redefines result =
                classifyFault.fatalFaultTrigger.isFatalActive == true implies
                (shutdownSystem.cutAir.massFlow <= 0.0 [kg / s] and
                    shutdownSystem.cutFuel.injectionPulseWidth <= 0.0 [s] and
                    shutdownSystem.warnSign.status == DashboardWarningStatusEnum::Critical);
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind faultCause = classifyFault.cause;
        flow classifyFault.fatalFaultTrigger to shutdownSystem.trigger;

        bind shutdownSystem.cutAir = airIntake;
        bind shutdownSystem.cutFuel = fuelCmd;
        bind shutdownSystem.warnSign = dashboard;
    }
} // package FW_CF3_WhiteBoxModel
