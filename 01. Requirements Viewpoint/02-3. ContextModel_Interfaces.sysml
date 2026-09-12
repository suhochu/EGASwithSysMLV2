package EgasSystemContextInterfaces {
    private import ReqCommon::*;
    private import ScalarValues::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 페이로드 (Item) 정의
    // ==========================================

    item def CruiseControlCommand {
        doc
        /* 설정 속도, 크루즈 컨트롤 On/Off/Cancel 상태 등 */
        attribute setSpeed :> ISQ::speed;
        @MetaInformation {
            version = "v0.2";
        }
    }
    item def BrakePedalPosition {
        doc
        /* 브레이크 페달이 밟힌 물리적 깊이 또는 압력 센서 값 */
        attribute pressure :> ISQ::pressure; // 브레이크 페달이 밟힌 물리적 깊이 또는 압력 센서의 측정값
        @MetaInformation {
            version = "v0.3";
        }
    }
    item def TorqueInterventionRequest {
        doc
        /* TCU나 ESP 등 외부 제어기가 요구하는 토크 증감 요구량 */
        attribute requestedTorqueDelta :> ISQ::torque; // 외부 제어기가 요구하는 토크의 증감 요구량
        attribute latency :> ISQ::duration; // 외부 제어기의 토크 개입 요청에 따른 신호 지연 시간
        @MetaInformation {
            version = "v0.3";
        }
    }
    item def EngineSensorData {
        doc
        /* RPM, 냉각수 온도, 흡기 온도, 산소 센서 값 등 엔진 제어에 필요한 복합 데이터 */
        attribute engineRpm :> ISQ::frequency; // 엔진의 분당 회전수(RPM)
        attribute coolantTemp :> ISQ::thermodynamicTemperature; // 엔진 냉각수의 현재 온도
        @MetaInformation {
            version = "v0.3";
        }
    }

    item def AccelerationPedalPosition {
        doc
        /* AccelerationPedal 센서가 생성하여 ECU로 전달하는 이중화 전기 신호(PVS1/PVS2). 
         * Driver의 AccelerationIntent를 내부적으로 변환한 결과이며, 시스템 경계를 넘나들지 않는다.
         */
        @MetaInformation {
            version = "v0.2";
        }
    }
    item def ThrottlePositionCommand {
        doc
        /* ECU가 스로틀 밸브 모터에 내리는 목표 개도각(Angle) 제어 신호 */
        @MetaInformation {
            version = "v0.2";
        }
    }
    item def ThrottlePositionFeedback {
        doc
        /* 스로틀 밸브의 현재 위치 센서(TPS) 피드백 값 */
        @MetaInformation {
            version = "v0.2";
        }
    }

    item def FuelIgnitionCommand {
        doc
        /* 인젝터 분사 시간(Pulse Width) 및 점화 플러그 점화 시기(Timing) 신호 */
        attribute injectionPulseWidth :> ISQ::duration; // 인젝터의 연료 분사 유지 시간(Pulse Width)
        attribute actuatorLatency :> ISQ::duration; // 액추에이터(인젝터 및 점화 플러그)의 작동 지연 시간
        attribute previousPulseWidth :> ISQ::duration; // 토크 저감 여부 판별을 위한 직전 제어 주기의 연료 분사량
        @MetaInformation {
            version = "v0.5";
        }
    }
    item def CombustionSystemStatus {
        doc
        /* 연료/점화 구동계의 작동 상태 및 고장 진단(OBD) 피드백 */
        attribute misfireRate :> ISQ::frequency; // 엔진 실화(Misfire) 발생 빈도 및 비율
        attribute steadyStateError : Real; // 목표 제어값과 실제 측정값 간의 정상 상태 오차(Steady State Error)
        attribute actualTorqueValue :> ISQ::torque; // 현재 연소 상태를 기반으로 추정/측정된 실제 토크 값
        attribute torqueOvershoot : Real; // 목표 토크를 초과하여 발생한 오버슛(Overshoot) 수치
        @MetaInformation {
            version = "v0.4";
        }
    }

    item def AccelerationIntent {
        doc
        /* 운전자가 가속 페달을 밟는 물리적 정도/변위 및 신호 지연 시간 측정용 속성 추가 */
        attribute pedalDisplacement :> ISQ::length; // 운전자가 가속 페달을 밟은 물리적 변위 거리 측정값
        attribute latency :> ISQ::duration; // 페달 조작부터 ECU 인지까지의 지연 시간
        @MetaInformation { version = "v0.4"; }
    }

    item def VehicleDynamicsFeedback {
        doc
        /* 운전자가 가속 페달을 밟는 물리적 정도/변위 및 신호 지연 시간 측정용 속성 추가 */
        attribute longitudinalJerk : Real; // 가속도의 변화율(Jerk)을 m/s³ 단위의 Real 값으로 처리
        @MetaInformation { version = "v0.1"; }
    }

    item def IntakeAirFlow {
        attribute massFlow :> ISQ::massFlowRate; // 스로틀 밸브의 개도각에 따라 엔진으로 유입되는 공기 질량 유량
        attribute previousMassFlow :> ISQ::massFlowRate; // 토크 저감 여부 판별을 위한 직전 제어 주기의 공기 유입량
        @MetaInformation {
            version = "v0.3";
        }
    }

    item def CalibrationRequest {
        doc
        /* 캘리브레이션 툴에서 전송하는 맵 데이터 메모리 주소 및 튜닝 데이터 페이로드 */

        attribute targetMemoryAddress : Integer; // 접근하려는 제어기 내부 메모리 번지수
        attribute mapDataPayload : Real; // 쓰기/업데이트할 엔진 맵 파라미터 값

        @MetaInformation {
            version = "v0.3";
        }
    }

    item def CalibrationStatus {
        doc
        /* ECU가 반환하는 통신 응답 코드 및 업데이트된 맵 데이터의 무결성 검증 값 */
        attribute responseCode : Integer; // 예: 200(OK/접근 허용), 401(Locked) 등 통신 상태 코드
        attribute verifiedChecksum : Integer; // 맵 데이터 업데이트 후 확인된 메모리 체크섬 값

        @MetaInformation {
            version = "v0.3";
        }
    }

    item def DiagnosticRequest {
        doc
        /* 진단기(OBD 스캐너 등)에서 UDS(Unified Diagnostic Services) 프로토콜 기반으로 전송하는 진단 서비스 요청 패킷 */
        attribute serviceId : Integer; // 예: 1(ReadDTC - DTC 읽기), 2(RoutineControl - 영점 조정)
        attribute dataRecord : Integer; // 진단 세부 명령 또는 루틴 식별자(ID) 페이로드

        @MetaInformation {
            version = "v0.3";
        }
    }

    item def DiagnosticStatus {
        doc
        /* ECU가 진단기로 반환하는 응답 상태 및 실제 DTC 데이터 페이로드 */

        attribute responseCode : Integer; // 예: 200(Positive Response / 정상 수행), 400(Negative Response)
        attribute dtcCode : Integer; // 출력된 실제 고장 코드 값 (고장이 없을 경우 0)

        @MetaInformation {
            version = "v0.3";
        }
    }

    // ==========================================
    // 2. 포트 정의 (Port Definitions)
    // - EgasSystem 경계에서 주고받는 아이템의 방향(in/out)을 명시함
    // ==========================================

    port def CruiseControlPort {
        in ccCmd : CruiseControlCommand;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def BrakeInputPort {
        in brakeInput : BrakePedalPosition;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def TorqueInterventionPort {
        in torqueReq : TorqueInterventionRequest;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def SensorInputPort {
        in sensorData : EngineSensorData;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def FuelCommandPort {
        out fuelCmd : FuelIgnitionCommand;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def CombustionStatusPort {
        in combustionStatus : CombustionSystemStatus;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def AccelerationInputPort {
        in accelIntent : AccelerationIntent;
        @MetaInformation {
            version = "v0.2";
        }
    }
    port def AirIntakePort {
        out airFlow : IntakeAirFlow;
        @MetaInformation {
            version = "v0.2";
        }
    }

    port def CalibrationPort {
        doc
        /* 캘리브레이션 툴과 연결되는 양방향 통신 포트 */
        in calReq : CalibrationRequest;
        out calStatus : CalibrationStatus;
        @MetaInformation {
            version = "v0.2";
        }
    }

    port def DiagnosticPort {
        doc
        /* 진단기(DiagnosticTool)와 연결되는 양방향 통신 포트 */
        in diagReq : DiagnosticRequest;
        out diagStatus : DiagnosticStatus;
        @MetaInformation {
            version = "v0.2";
        }
    }

    port def DynamicsFeedbackPort {
        in dynamicsStatus : VehicleDynamicsFeedback;
        @MetaInformation {
            version = "v0.1";
        }
    }
} // package EgasSystemContextInterfaces
