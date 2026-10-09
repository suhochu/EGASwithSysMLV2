package ThrottleStuckLogic {
    doc
    /* 스로틀 고착(Stuck) 판정을 위한 공용 속성 및 계산 로직을 정의하는 네임스페이스 */

    private import SI::*;
    private import ScalarValues::*;

    // ==========================================
    // 스로틀 고착(Stuck) 판정 - 단일 정의
    // ==========================================
    attribute stuckDeviationLimit : Real = 2.0; // [%] 목표-실제 개도 허용 편차 (SYSR-04 maxDeviation과 같은 값)
    attribute stuckConfirmTime : TimeValue; // [TBD] 편차 초과가 이 시간 이상 지속되면 고착 확정

    calc def IsThrottleDeviated {
        doc
        /* 목표 개도와 실제 개도의 편차가 한계를 초과하는 순간 상태 (지속 조건 없음) */
        in commandedPct : Real;
        in actualPct : Real;
        in limit : Real;
        return : Boolean = commandedPct - actualPct > limit or actualPct - commandedPct > limit;
    }

    calc def IsThrottleStuck {
        doc
        /* 스로틀 고착 = 긴급 개입 중에 목표/실제 개도 편차 초과 상태가 확정 시간 이상 지속되는 상태.
         * 공기 질량 유량이 아니라 스로틀 위치로 판정하므로 흡기 매니폴드 지연과 무관하다.
         */
        in interventionActive : Boolean;
        in commandedPct : Real;
        in actualPct : Real;
        in limit : Real;
        in deviationDuration : TimeValue;
        in confirmTime : TimeValue;
        return : Boolean =
            interventionActive and
            IsThrottleDeviated(commandedPct, actualPct, limit) and
            deviationDuration >= confirmTime;
    }
} // package ThrottleStuckLogic

package SafeStateLogic {
    private import SI::*; // [mm], [Pa], [kg / s], [km / h], [s]
    private import ScalarValues::*;

    // ==========================================
    // 안전 상태 단계와 브레이크 오버라이드 트리거 - 단일 정의
    // ==========================================
    attribute idleAirMassFlow :> ISQ::massFlowRate = 0.05 [kg / s]; // 공회전 공기량 (FE standby와 같은 값)
    attribute idleFuelPulseWidth :> ISQ::duration = 0.002 [s]; // 공회전 연료 분사 시간 (FE standby와 같은 값)

    calc def IsDrivingRequestActive {
        doc
        /* 구동 요구 활성 = 가속 페달이 밟혔거나 크루즈가 활성(Active)인 상태. 레버의 setSpeed가 아니라 EGAS 내부 ccState를 쓴다. */
        in pedalDisplacement : ISQ::LengthValue;
        in ccState : ReqCommon::CruiseControlStateEnum;
        return : Boolean =
            pedalDisplacement > 0.0 [mm] or ccState == ReqCommon::CruiseControlStateEnum::Active;
    }

    calc def IsBrakeOverrideTriggered {
        doc
        /* 브레이크 오버라이드 트리거 = 구동 요구 활성 AND 제동 입력 */
        in pedalDisplacement : ISQ::LengthValue;
        in ccState : ReqCommon::CruiseControlStateEnum;
        in brakePressure : ISQ::PressureValue;
        return : Boolean =
            IsDrivingRequestActive(pedalDisplacement, ccState) and brakePressure > 0.0 [Pa];
    }

    calc def IsTorqueLimited {
        in airMassFlow : ISQ::MassFlowRateValue;
        in fuelPulseWidth : ISQ::DurationValue;
        return : Boolean = airMassFlow <= idleAirMassFlow and fuelPulseWidth <= idleFuelPulseWidth;
    }

    calc def IsFuelCutOff {
        in fuelPulseWidth : ISQ::DurationValue;
        return : Boolean = fuelPulseWidth <= 0.0 [s];
    }

    calc def IsFullCutOff {
        in airMassFlow : ISQ::MassFlowRateValue;
        in fuelPulseWidth : ISQ::DurationValue;
        return : Boolean = airMassFlow <= 0.0 [kg / s] and fuelPulseWidth <= 0.0 [s];
    }

    // ==========================================
    // 고장 판정 - 단일 정의
    // ==========================================
    attribute redundancyDeviationLimit : Real = 5.0; // [%] SYSR-02/06 maxDeviation과 같은 값
    attribute coolantOverheatLimit :> ISQ::thermodynamicTemperature = 393.15 [K]; // 120 °C
    attribute sensorFaultConfirmTime :> ISQ::duration; // [TBD] 센서 편차 확정 시간
    attribute overheatConfirmTime :> ISQ::duration; // [TBD] 과열 확정 시간

    calc def IsChannelDeviated {
        doc
        /* 이중화 두 채널의 절대 편차가 한계를 초과하는 순간 상태 (지속 조건 없음). SYSR-02/06의 faultFlag 조건과 같다. */
        in channel1 : Real;
        in channel2 : Real;
        in limit : Real;
        return : Boolean = channel1 - channel2 > limit or channel2 - channel1 > limit;
    }

    calc def IsOverheated {
        in coolantTemp : ISQ::ThermodynamicTemperatureValue;
        in limit : ISQ::ThermodynamicTemperatureValue;
        return : Boolean = coolantTemp > limit;
    }

    // ==========================================
    // 보정 후처리 (UF3_1)
    // ==========================================
    attribute maxAirCorrection :> ISQ::massFlowRate; // [TBD] 보정 허용 한계 (공기량)
    attribute maxFuelCorrection :> ISQ::duration; // [TBD] 보정 허용 한계 (연료 분사 시간)
    attribute compensationBudget :> ISQ::duration = 10.0 [milli * s]; // UF3_1 처리 예산 (기존 WB 3+4+3)
    attribute cf1PathBudget :> ISQ::duration = 50.0 [milli * s]; // UF1_1 현재 상한 (UF1_1 BB, SHR-08)
    attribute arbiterBudget :> ISQ::duration; // [TBD] Arbiter 처리 예산 (M4)
} // package SafeStateLogic

package CruiseControlLogic {
    private import ScalarValues::*;
    private import ReqCommon::*;
    private import SI::*;
    private import SafeStateLogic::*;

    attribute cruiseSpeedErrorLimitPct : Real = 2.0; // [%] 설정 속도 대비 허용 정상 상태 속도 오차 (구 UC1 vc04/UF1_2의 2.0)

    calc def IsCruiseSpeedHeld {
        doc
        /* 속도 오차율 |설정 속도 - 차속| / 설정 속도 x 100 이 한계 이내인지 판정 (플랜트 관측용, EGAS 보장식 아님) */
        in setSpeed : ISQ::SpeedValue;
        in vehicleSpeed : ISQ::SpeedValue;
        in limitPercent : Real;
        return : Boolean =
            setSpeed > 0.0 [km / h] and
            (setSpeed - vehicleSpeed) * 100.0 <= limitPercent * setSpeed and
            (vehicleSpeed - setSpeed) * 100.0 <= limitPercent * setSpeed;
    }
} // package CruiseControlLogic

package DtcStroage {
    private import SI::*;
    attribute dtcStorageBudget :> ISQ::duration = 50.0 [milli * s]; // SYSR-09 maxResponseTime과 같은 값
} // package DtcStroage

package TimingConceptsAndLimits {
    private import SI::*;
    // ==========================================
    // [M2] 시간 개념과 한계값 카탈로그
    //  messageAge          : 입력 관측치 (외부 요인, 보장 대상 아님)
    //  responseTime / start-done : EGAS 보장 (수신 완료 ~ 출력 시작)
    //  ...Threshold        : 입력 판정 기준 (assume / 가드 / 분기에서만 사용)
    //  ...Budget           : 응답 한계 (responseTime 또는 start-done 에서만 사용)
    //  ...ConfirmTime      : 디바운스 확정 시간 (S4, S7)
    //  executionTime       : WB 단계 처리시간 (예산의 하위 할당, 합이 예산 이하)
    // ==========================================

    // (A) 입력 관측 한계
    attribute commDelayThreshold :> ISQ::duration = 15.0 [milli * s]; // 정상 통신 지연 한계 (SYSR-15 maxLatency)
    attribute commTimeout :> ISQ::duration; // [TBD] 이 시간을 넘으면 무결성 오류. commDelayThreshold보다 커야 함 (SYSR-05)

    // (B) EGAS 응답 예산 (요구 수준)
    attribute pedalResponseBudget :> ISQ::duration = 50.0 [milli * s]; // SHR-08, SYSR-13, UC1 vc01
    attribute overrideResponseBudget :> ISQ::duration = 10.0 [milli * s]; // SYSR-01b, UC1 vc05, UF1_3
    attribute interventionResponseBudget :> ISQ::duration = 15.0 [milli * s]; // SHR-04-1/2, SYSR-03, UC2 vc01, UF2_1
    attribute stuckCutResponseBudget :> ISQ::duration = 10.0 [milli * s]; // SHR-04-3, SYSR-14, UC2 vc06, UF2_3
    attribute failSafeResponseBudget :> ISQ::duration = 10.0 [milli * s]; // UC3 vc5/vc8, Operational failSafeResponseTime
    attribute combustionComputeBudget :> ISQ::duration = 5.0 [milli * s]; // SYSR-08 (WB 20ms와 충돌: M4)
    attribute accessAuthBudget :> ISQ::duration = 50.0 [milli * s]; // UC4 vc2, UF4_1
    attribute mapUpdateBudget :> ISQ::duration = 100.0 [milli * s]; // SYSR-11, UC4 vc4
    attribute addressRejectBudget :> ISQ::duration = 10.0 [milli * s]; // SYSR-16, UC4 vc6, UF4_3
    attribute dtcResponseBudget :> ISQ::duration = 50.0 [milli * s]; // UC5 vc2
    attribute zeroPointBudget :> ISQ::duration = 100.0 [milli * s]; // SYSR-17, UC5 vc4
    attribute serviceRejectBudget :> ISQ::duration = 10.0 [milli * s]; // UC5 vc6

    // (C) 단계 할당 (예산을 기능에 나눈 값, 합 검사는 FV, 조정은 M4)
    attribute cf1PathBudget :> ISQ::duration = 50.0 [milli * s]; // UF1_1 현재 상한 (S8)
    attribute compensationBudget :> ISQ::duration = 10.0 [milli * s]; // UF3_1 단계 (S8, SHR-02-2)
    attribute arbiterBudget :> ISQ::duration; // [TBD] Arbiter 단계 (S8)
    attribute dtcStorageBudget :> ISQ::duration = 50.0 [milli * s]; // UF5_4 NVM 기록 단계 (M1, SYSR-09)
} // package TimingConceptsAndLimits
