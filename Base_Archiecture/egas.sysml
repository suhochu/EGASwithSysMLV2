package EgasBaseArchitecture {
    // ==========================================
    // 1. 내부 컴포넌트 정의 (Internal Components)
    // ==========================================

    part def Engine_Control_Unit {
        doc
        /* 시스템의 중앙 마이크로컨트롤러(µC)로서 가속 페달, 크루즈 컨트롤, 외부 제어기의 토크 요구(Torque Request)를 수집 및 중재(Arbitration)함.
         * 목표 토크를 달성하기 위해 스로틀 밸브 및 연료/점화 시스템에 제어 명령을 내리며, 오작동을 감지하는 안전 모니터링을 수행함.
         */
    }

    part def Acceleration_Pedal {
        doc
        /* 운전자의 물리적인 가속 의지(페달을 밟는 정도)를 전기적 신호로 변환하여 ECU에 1차적인 운전자 토크 요구량으로 전달함. */
    }

    part def Throttle_Valve {
        doc
        /* ECU의 제어 명령에 따라 개방 각도를 조절하여 엔진으로 유입되는 공기량을 물리적으로 제어함. 
         * 동시에 현재 밸브의 위치 값을 ECU로 피드백하여 정밀한 폐루프 제어(Closed-loop control)를 가능하게 함.
         */
    }

    // ==========================================
    // 2. 외부 액터 정의 (External Actors)
    // ==========================================

    part def CruiseControlLever {
        doc
        /* 크루즈 컨트롤(Cruise Control) 활성화를 위한 운전자의 조작 상태를 전달하며, 지정된 속도를 유지하기 위한 지속적인 토크 요구 명령을 시스템에 입력함. */
    }

    part def Brake {
        doc
        /* 운전자의 제동 의지를 ECU에 전달함. 
         * 가속 페달 신호와 브레이크 신호가 동시에 입력될 경우, 제동을 우선시하여 토크를 강제로 차단하거나 줄이는 안전 기능(Brake Override)을 트리거함.
         */
    }

    part def Add_ECU {
        doc
        /* 변속기 제어기(TCU), 차체 자세 제어기(ESP) 등 다른 시스템의 마이크로컨트롤러가 전송하는 토크 개입(Torque Intervention) 신호를 전달함. 
         * 기어 변속 시점의 토크 저감이나 미끄럼 방지를 위한 토크 제한 등을 요구함.
         */
    }

    part def Add_Sensor_Components {
        doc
        /* 엔진 회전수(RPM), 냉각수 온도, 흡기 온도 등 ECU가 목표 토크를 정확하게 계산하고 보정하는 데 필요한 주변 환경 및 물리적 상태 데이터를 제공함. */
    }

    part def Fuel_Injection_Ignition_System {
        doc
        /* 스로틀 밸브의 공기량 제어와 협조하여, ECU가 요구하는 최종 토크를 실제 엔진 동력으로 구현하기 위해 연료 분사량과 점화 시기를 제어하는 외부 구동계 역할을 수행함. */
    }

    // ==========================================
    // 5. 페이로드 (Item) 정의
    // ==========================================

    item def CruiseControlCommand {
        doc
        /* 설정 속도, 크루즈 컨트롤 On/Off/Cancel 상태 등 */
    }
    item def BrakePedalPosition {
        doc
        /* 브레이크 페달이 밟힌 물리적 깊이 또는 압력 센서 값 */
    }
    item def TorqueInterventionRequest {
        doc
        /* TCU나 ESP 등 외부 제어기가 요구하는 토크 증감 요구량 */
    }
    item def EngineSensorData {
        doc
        /* RPM, 냉각수 온도, 흡기 온도, 산소 센서 값 등 엔진 제어에 필요한 복합 데이터 */
    }

    item def AccelerationPedalPosition {
        doc
        /* 운전자의 가속 페달 조작량 (0~100%) */
    }
    item def ThrottlePositionCommand {
        doc
        /* ECU가 스로틀 밸브 모터에 내리는 목표 개도각(Angle) 제어 신호 */
    }
    item def ThrottlePositionFeedback {
        doc
        /* 스로틀 밸브의 현재 위치 센서(TPS) 피드백 값 */
    }

    item def FuelIgnitionCommand {
        doc
        /* 인젝터 분사 시간(Pulse Width) 및 점화 플러그 점화 시기(Timing) 신호 */
    }
    item def CombustionSystemStatus {
        doc
        /* 연료/점화 구동계의 작동 상태 및 고장 진단(OBD) 피드백 */
    }

    // ==========================================
    // 3. 관심 시스템 (System of Interest) 정의
    // ==========================================

    part def EGAS_System {
        part ecu : Engine_Control_Unit;
        part pedal : Acceleration_Pedal;
        part throttle : Throttle_Valve;

        // 시스템 '내부'의 흐름 연결
        flow of AccelerationPedalPosition from pedal to ecu;
        flow of ThrottlePositionCommand from ecu to throttle;
        flow of ThrottlePositionFeedback from throttle to ecu;
    }

    // ==========================================
    // 4. 시스템 컨텍스트 (System Context)
    // ==========================================

    part def EGAS_Context {
        // 외부 환경(액터) 인스턴스화
        part cc_Lever : CruiseControlLever [0..1];
        part brake : Brake;
        part add_ecu : Add_ECU;
        part sensors : Add_Sensor_Components;
        part fuel_sys : Fuel_Injection_Ignition_System;

        // 관심 시스템 전체를 하나의 파트로 인스턴스화
        part egas : EGAS_System;

        // 외부 액터와 시스템 내부 컴포넌트 간의 흐름
        flow of CruiseControlCommand from cc_Lever to egas.ecu;
        flow of BrakePedalPosition from brake to egas.ecu;
        flow of TorqueInterventionRequest from add_ecu to egas.ecu;
        flow of EngineSensorData from sensors to egas.ecu;

        // 연료/점화 시스템과의 양방향 제어 및 피드백 흐름
        flow of FuelIgnitionCommand from fuel_sys to egas.ecu;
        flow of CombustionSystemStatus from egas.ecu to fuel_sys;
    }
} // package EgasBaseArchitecture
