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
    private import ReqCommon::*; // CruiseControlStateEnum

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

    calc def IsNormalDriving {
        doc
        /* 정상 주행 = 제동 오버라이드 트리거 아님 AND 치명 고장 없음 AND 외부 개입 요청 없음.
         * 승차감(Jerk) 기준(SYSR-26)의 적용 조건이며 SHR-08의 예외 조항을 형식화한다.
         */
        in pedalDisplacement : ISQ::LengthValue;
        in ccState : CruiseControlStateEnum;
        in brakePressure : ISQ::PressureValue;
        in faultCause : FaultCause;
        in interventionDelta : ISQ::TorqueValue;
        return : Boolean =
            not IsBrakeOverrideTriggered(pedalDisplacement, ccState, brakePressure) and
            faultCause == FaultCause::NoFault and
            interventionDelta >= 0.0 [N * m];
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
    private import ScalarValues::*;
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
    attribute cf1PathBudget :> ISQ::duration = 20.0 [milli * s]; // UF1_1 현재 상한 (S8)
    attribute compensationBudget :> ISQ::duration = 6.0 [milli * s]; // UF3_1 단계 (S8, SHR-02-2)
    attribute arbiterBudget :> ISQ::duration = 3.0 [milli * s]; // [TBD] Arbiter 단계 (S8)
    attribute dtcStorageBudget :> ISQ::duration = 50.0 [milli * s]; // UF5_4 NVM 기록 단계 (M1, SYSR-09)

    //  SHR-02-1 / SHR-08 정량 항목 (플랜트 관측 기준, S1)
    attribute torqueSteadyStateErrorLimitPct : Real = 2.0; // [%] 토크 정상 상태 오차 한계
    attribute torqueOvershootLimitPct : Real = 5.0; // [%] 토크 오버슛 한계
    attribute longitudinalJerkLimit : Real = 10.0; // 종방향 Jerk 한계 (단위는 SYSR-13과 동일, 확인 필요)

    // (B) 추가: 요구 수준
    attribute compensationResponseBudget :> ISQ::duration = 10.0 [milli * s]; // SHR-02-2, UC3 vc1 (구 compensationBudget의 요구 수준 용도)

    // (C) 실행 모델 [M4]
    attribute systemClockCycle :> ISQ::duration = 10.0 [milli * s]; // 제어 주기 (FE 로컬 속성을 이곳으로 이동)
    attribute minTimingMargin :> ISQ::duration = 1.0 [milli * s]; // [합의 필요] 모든 경로에 요구하는 최소 여유

    // 샘플링 지연: 주기 구동 경로는 systemClockCycle, 이벤트 구동 경로는 0 (결정 사항)
    attribute pedalSamplingDelay :> ISQ::duration = systemClockCycle;
    attribute overrideSamplingDelay :> ISQ::duration = 0.0 [milli * s];
    attribute interventionSamplingDelay :> ISQ::duration = 0.0 [milli * s];
    attribute stuckCutSamplingDelay :> ISQ::duration = 0.0 [milli * s];
    attribute failSafeSamplingDelay :> ISQ::duration = 0.0 [milli * s];
    attribute compensationSamplingDelay :> ISQ::duration = 0.0 [milli * s];

    // (D) 단계 할당 [값은 초안: 대상 하드웨어의 WCET 측정 후 확정]
    attribute overrideStageBudget :> ISQ::duration = 6.0 [milli * s]; // UF1_3 (WB 3+3), 구 10
    attribute integrityGuardBudget :> ISQ::duration = 2.0 [milli * s]; // UF2_4
    attribute interventionStageBudget :> ISQ::duration = 8.0 [milli * s]; // UF2_1 (WB 2+3+3), 구 15
    attribute stuckCutStageBudget :> ISQ::duration = 5.0 [milli * s]; // UF2_3 (WB 2+3)
    attribute failSafeStageBudget :> ISQ::duration = 5.0 [milli * s]; // UF3_2 (WB 2+3)
    // dtcStorageBudget(M1)는 중재기를 지나지 않는 경로라 변경 없음

    // (E) FTTI [TBD: 안전 목표별 FTTI 확정 필요]
    attribute sensorFaultFtti :> ISQ::duration;
    attribute overheatFtti :> ISQ::duration;
    attribute stuckFtti :> ISQ::duration;

    calc def IsPathBudgetMet {
        doc
        /* 경로 응답 = 샘플링 지연 + 직렬 단계 할당 합 + 중재기 + 최소 여유 가 요구 예산 이하인지 검사 */
        in requirementBudget : ISQ::DurationValue;
        in samplingDelay : ISQ::DurationValue;
        in stageSum : ISQ::DurationValue;
        in arbiterTime : ISQ::DurationValue;
        in margin : ISQ::DurationValue;
        return : Boolean = samplingDelay + stageSum + arbiterTime + margin <= requirementBudget;
    }

    attribute coreLogicReuseTargetPct : Real = 80.0;
} // package TimingConceptsAndLimits
