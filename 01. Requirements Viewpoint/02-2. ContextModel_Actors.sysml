package Actors {
    private import ReqCommon::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 내부 컴포넌트 정의 (Internal Components)
    // - 관심 시스템 내부의 요소로, 그레이박스 유스케이스(05번 파일)와 요구사항 할당(06번 파일)의 대상이 됨
    // ==========================================

    part def EngineControlUnit {
        doc
        /* 시스템의 중앙 마이크로컨트롤러(µC)로서 가속 페달, 크루즈 컨트롤, 외부 제어기의 토크 요구(Torque Request)를 수집 및 중재(Arbitration)함.
         * 목표 토크를 달성하기 위해 스로틀 밸브 및 연료/점화 시스템에 제어 명령을 내리며, 오작동을 감지하는 안전 모니터링을 수행함.
         */

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def AccelerationPedal {
        doc
        /* 운전자의 물리적인 가속 의지(페달을 밟는 정도)를 전기적 신호로 변환하여 ECU에 1차적인 운전자 토크 요구량으로 전달함. */

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def ThrottleValve {
        doc
        /* ECU의 제어 명령에 따라 개방 각도를 조절하여 엔진으로 유입되는 공기량을 물리적으로 제어함. 
         * 동시에 현재 밸브의 위치 값을 ECU로 피드백하여 정밀한 폐루프 제어(Closed-loop control)를 가능하게 함.
         */

        @MetaInformation {
            version = "v0.2";
        }
    }

    // ==========================================
    // 2. 외부 액터 정의 (External Actors)
    // ==========================================

    part def Driver {
        doc
        /* 가속 페달을 밟아 가속 의도를 표현하는 물리적 운전자. AccelerationPedal(센서)이 EgasSystem
         * 내부 컴포넌트로 포함되므로, 운전자의 물리적 가속 의도가 시스템 경계를 넘는 입력이 된다.
         * (03번 파일의 stakeholder Driver와는 별개 개념: 이해관계자 관점이 아닌 컨텍스트 경계 관점의 액터)
         */

        event occurrence pressesAccelPedal; // 가속 페달 입력 (가속 의지)

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def CruiseControlLever {
        doc
        /* 크루즈 컨트롤(Cruise Control) 활성화를 위한 운전자의 조작 상태를 전달하며, 
         * 지정된 속도를 유지하기 위한 지속적인 토크 요구 명령을 시스템에 입력함.
         */

        event occurrence setsCruiseSpeed; // 크루즈 컨트롤 목표 속도 설정

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def Brake {
        doc
        /* 운전자의 제동 의지를 ECU에 전달함. 
         * 가속 페달 신호와 브레이크 신호가 동시에 입력될 경우, 
         * 제동을 우선시하여 토크를 강제로 차단하거나 줄이는 안전 기능(Brake Override)을 트리거함.
         */

        event occurrence pressesBrakePedal; // 브레이크 페달 입력 (제동 의지)

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def AddEcu {
        doc
        /* 변속기 제어기(TCU), 차체 자세 제어기(ESP) 등 다른 시스템의 마이크로컨트롤러가 
         * 전송하는 토크 개입(Torque Intervention) 신호를 전달함. 
         * 기어 변속 시점의 토크 저감이나 미끄럼 방지를 위한 토크 제한 등을 요구함.
         */

        event occurrence requestsIntervention; // 정상 긴급 개입 요청
        event occurrence requestsIntervention_Delayed; // 지연 수신된 개입 요청
        event occurrence requestsIntervention_Stuck; // 고착 상황 하의 개입 요청

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def AddSensorComponents {
        doc
        /* 엔진 회전수(RPM), 냉각수 온도, 흡기 온도 등 ECU가 목표 토크를 
         * 정확하게 계산하고 보정하는 데 필요한 주변 환경 및 물리적 상태 데이터를 제공함.
         */

        event occurrence sendsNormalSensorData; // 정상 범위의 센서 데이터 송신
        event occurrence sendsFaultyData; // 물리적 결함(온도 초과 등) 데이터 송신

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def FuelInjectionIgnitionSystem {
        doc
        /* 스로틀 밸브의 공기량 제어와 협조하여, 
         * ECU가 요구하는 최종 토크를 실제 엔진 동력으로 구현하기 위해 연료 분사량과 점화 시기를 제어하는 외부 구동계 역할을 수행함.
         */

        event occurrence injectsFuel; // 수동 가속용 연료/점화 제어 실행
        event occurrence injectsFuel_CC; // 정속 주행용 연료/점화 제어 실행
        event occurrence cutsFuel; // 제동 최우선 개입에 따른 연료 차단
        event occurrence executesReducedFuel; // 축소된 연료/점화 지각 실행
        event occurrence executesMaintainedFuel; // 동결(유지)된 연료량 실행
        event occurrence executesFuelCut; // 연료 전면 차단 실행
        event occurrence executesCompensatedFuel; // 보정된 연료/점화 제어 실행
        event occurrence sendsCombustionFeedback; // 연소 상태(실화율) 피드백 송신

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def Engine {
        doc
        /* 스로틀 밸브(ThrottleValve)를 통해 유입된 공기를 받아들이는 물리적 엔진 블록(실린더/흡기 매니폴드).
         * FuelInjectionIgnitionSystem과는 별도의 외부 액터로, 공기 경로(air path)만을 담당함.
         */

        event occurrence receivesAirFlow; // 수동 가속용 공기 유입 수용
        event occurrence receivesAirFlow_CC; // 정속 주행용 공기 유입 수용
        event occurrence receivesAirCut; // 제동 최우선 개입에 따른 공기 차단 수용
        event occurrence receivesReducedAir; // 축소된 공기량 수신
        event occurrence receivesMaintainedAir; // 동결(유지)된 공기량 수신
        event occurrence receivesCompensatedAir; // 보정된 공기량 수신

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def CalibrationTool {
        doc
        /* 엔지니어가 사용하는 외부 XCP/CCP 튜닝 장비 */

        event occurrence requestsValidAccess; // 유효한 메모리 주소 접근 요청
        event occurrence receivesAuthOk; // 인가 응답(200) 수신
        event occurrence sendsTuningData; // 튜닝 파라미터 데이터 송신
        event occurrence receivesVerifiedChecksum; // 검증된 체크섬 수신
        event occurrence requestsInvalidAccess; // 비유효/잘못된 메모리 주소 접근 요청
        event occurrence receivesErrorResponse; // 거절/에러 응답 수신

        @MetaInformation {
            version = "v0.2";
        }
    }

    part def DiagnosticTool {
        doc
        /* 서비스 센터(A/S) 엔지니어가 사용하는 외부 진단 장비 */

        event occurrence requestsDtcRead; // DTC 읽기(serviceId=1) 요청
        event occurrence receivesDtcResponse; // DTC 코드 및 200 응답 수신
        event occurrence requestsZeroPointCal; // 영점 조정(serviceId=2) 요청
        event occurrence receivesZeroPointResponse; // 영점 조정 완료(200) 응답 수신
        event occurrence requestsInvalidService; // 비유효 진단 서비스 요청
        event occurrence receivesErrorResponse; // 에러 응답 수신

        @MetaInformation {
            version = "v0.2";
        }
    }
} // package Actors
