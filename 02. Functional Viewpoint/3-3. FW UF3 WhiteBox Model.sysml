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
    action def <UF3_1_WB> HardwareDelayAndFrictionCompensation_WhiteBox :> CF3::UF3_1 {
        in sensor : EngineSensorData :>> CF3::UF3_1::sensor;
        in combustionStatus : CombustionSystemStatus :>> CF3::UF3_1::combustionStatus;
        out airIntake : IntakeAirFlow :>> CF3::UF3_1::airIntake;
        out fuelCmd : FuelIgnitionCommand :>> CF3::UF3_1::fuelCmd;

        // [Step 1: Sensing] 센서 및 연소 상태 오차 모니터링
        action monitorSensorError {
            in currentSensor : EngineSensorData;
            in currentCombustion : CombustionSystemStatus;
            out errorEst : InternalErrorData;
            attribute executionTime : Real [milli * s];

            // 오류 감지 레이턴시 할당
            constraint SensingLatency { executionTime <= 3.0 [milli * s] }
        }

        // [Step 2: Core Logic] 마찰/지연 보상값 연산
        action calcCorrectionValue {
            in rawError : InternalErrorData;
            in tempCheck : EngineSensorData;
            out correctionDemand : InternalCorrectionCmd;
            attribute executionTime : Real [milli * s];

            // 120도 이하 정상 상태에서만 보정 연산 수행
            constraint CalcConditionAndLatency {
                tempCheck.coolantTemp <= 120.0 ['°'] implies executionTime <= 4.0 [milli * s]
            }
        }

        // [Step 3: Actuation] 보정된 액추에이터 제어 명령 적용
        action applyCorrection {
            in correctionReq : InternalCorrectionCmd;
            out adjAir : IntakeAirFlow;
            out adjFuel : FuelIgnitionCommand;
            attribute executionTime : Real [milli * s];

            // 액추에이터 출력 변환 지연시간
            constraint ActuationLatency { executionTime <= 3.0 [milli * s] }
        }

        // ★ [예산 할당 제약] 부모의 전체 지연 제약(10ms) 만족 검증
        constraint CorrectionLatencyBudgetAllocation {
            monitorSensorError.executionTime +
            calcCorrectionValue.executionTime +
            applyCorrection.executionTime <=
            10.0 [milli * s]
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind sensor = monitorSensorError.currentSensor;
        bind sensor = calcCorrectionValue.tempCheck;
        bind combustionStatus = monitorSensorError.currentCombustion;

        flow monitorSensorError.errorEst to calcCorrectionValue.rawError;
        flow calcCorrectionValue.correctionDemand to applyCorrection.correctionReq;

        bind applyCorrection.adjAir = airIntake;
        bind applyCorrection.adjFuel = fuelCmd;
    }

    // ==========================================
    // 2. UF3_2 치명적 센서 결함 페일세이프 화이트박스 분해
    // ==========================================
    action def <UF3_2_WB> CriticalSensorFaultFailSafe_WhiteBox :> CF3::UF3_2 {
        in sensor : EngineSensorData :>> CF3::UF3_2::sensor;
        out airIntake : IntakeAirFlow :>> CF3::UF3_2::airIntake;
        out fuelCmd : FuelIgnitionCommand :>> CF3::UF3_2::fuelCmd;
        out dashboard : DashboardWarning :>> CF3::UF3_2::dashboard;

        // [Step 1: Sensing] 센서 데이터 한계치(Limit) 지속 검사
        action checkCriticalLimits {
            in sensorData : EngineSensorData;
            out fatalFaultTrigger : InternalFatalTrigger;

            // ★ [내부 로직 제약] 냉각수 120도 초과 시 비가역적 치명적 에러 플래그 활성화
            constraint TriggerFatalCondition {
                sensorData.coolantTemp > 120.0 ['°'] implies fatalFaultTrigger.isFatalActive == true
            }
        }

        // [Step 2 & 3: Logic & Actuation] 페일세이프 실행 및 시스템 셧다운
        action shutdownSystem {
            in trigger : InternalFatalTrigger;
            out cutAir : IntakeAirFlow;
            out cutFuel : FuelIgnitionCommand;
            out warnSign : DashboardWarning;

            // ★ [내부 로직 제약] 상위 FatalFaultCutoff 제약을 내부 플래그 수신 동작으로 치환
            constraint ExecuteShutdown {
                trigger.isFatalActive == true implies
                (cutAir.massFlow <= 0.0 [kg / s] and
                    cutFuel.injectionPulseWidth <= 0.0 [s] and
                    warnSign.status == DashboardWarningStatusEnum::Critical)
            }
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind sensor = checkCriticalLimits.sensorData;
        flow checkCriticalLimits.fatalFaultTrigger to shutdownSystem.trigger;

        bind shutdownSystem.cutAir = airIntake;
        bind shutdownSystem.cutFuel = fuelCmd;
        bind shutdownSystem.warnSign = dashboard;
    }
} // package FW_CF3_WhiteBoxModel
