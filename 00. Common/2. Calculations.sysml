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
        /* 구동 요구 활성 = 가속 페달이 밟혔거나 크루즈 설정 속도가 있는 상태 (FE active 상태의 유지 조건과 동일) */
        in pedalDisplacement :> ISQ::length;
        in setSpeed :> ISQ::speed;
        return : Boolean = pedalDisplacement > 0.0 [mm] or setSpeed > 0.0 [km / h];
    }

    calc def IsBrakeOverrideTriggered {
        doc
        /* 브레이크 오버라이드 트리거 = 구동 요구 활성 AND 제동 입력. 제동만 있는 경우는 트리거가 아니다. */
        in pedalDisplacement :> ISQ::length;
        in setSpeed :> ISQ::speed;
        in brakePressure :> ISQ::pressure;
        return : Boolean =
            IsDrivingRequestActive(pedalDisplacement, setSpeed) and brakePressure > 0.0 [Pa];
    }

    calc def IsTorqueLimited {
        // L1
        in airMassFlow :> ISQ::massFlowRate;
        in fuelPulseWidth :> ISQ::duration;
        return : Boolean = airMassFlow <= idleAirMassFlow and fuelPulseWidth <= idleFuelPulseWidth;
    }

    calc def IsFuelCutOff {
        // L2
        in fuelPulseWidth :> ISQ::duration;
        return : Boolean = fuelPulseWidth <= 0.0 [s];
    }

    calc def IsFullCutOff {
        // L3
        in airMassFlow :> ISQ::massFlowRate;
        in fuelPulseWidth :> ISQ::duration;
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
        doc
        /* 냉각수 온도가 한계를 초과하는 순간 상태 (지속 조건 없음). 센서 고장이 아니라 열 보호 조건이다. */
        in coolantTemp :> ISQ::thermodynamicTemperature;
        in limit :> ISQ::thermodynamicTemperature;
        return : Boolean = coolantTemp > limit;
    }
} // package SafeStateLogic
