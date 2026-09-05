package EgasBaseArchitecture {
    doc
    /* [시스템 컨텍스트 뷰포인트]
     * EGAS(관심 시스템)의 경계를 정의하는 어휘를 제공한다: 외부 액터, 주고받는 아이템(payload), 경계 포트,
     * 그리고 관심 시스템 자체(EgasSystem)를 블랙박스로, 시스템+외부 액터 전체를 컨텍스트(EgasContext)로 정의한다.
     * 내부 컴포넌트(EngineControlUnit/AccelerationPedal/ThrottleValve)는 05/06번 파일에서 그레이박스 유스케이스의
     * subject나 요구사항의 allocationBudget 대상으로 참조되지만, 이 파일의 EgasSystem 정의 자체는 포트만 노출하는
     * 순수 블랙박스이며 내부 배선(어떻게 연결되는지)은 "02. Functional Viewpoint"가 책임진다.
     */

    private import ReqCommon::*;

    @ElementVersion {
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
    }

    part def AccelerationPedal {
        doc
        /* 운전자의 물리적인 가속 의지(페달을 밟는 정도)를 전기적 신호로 변환하여 ECU에 1차적인 운전자 토크 요구량으로 전달함. */
    }

    part def ThrottleValve {
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

    part def AddEcu {
        doc
        /* 변속기 제어기(TCU), 차체 자세 제어기(ESP) 등 다른 시스템의 마이크로컨트롤러가 전송하는 토크 개입(Torque Intervention) 신호를 전달함. 
         * 기어 변속 시점의 토크 저감이나 미끄럼 방지를 위한 토크 제한 등을 요구함.
         */
    }

    part def AddSensorComponents {
        doc
        /* 엔진 회전수(RPM), 냉각수 온도, 흡기 온도 등 ECU가 목표 토크를 정확하게 계산하고 보정하는 데 필요한 주변 환경 및 물리적 상태 데이터를 제공함. */
    }

    part def FuelInjectionIgnitionSystem {
        doc
        /* 스로틀 밸브의 공기량 제어와 협조하여, ECU가 요구하는 최종 토크를 실제 엔진 동력으로 구현하기 위해 연료 분사량과 점화 시기를 제어하는 외부 구동계 역할을 수행함. */
    }

    // ==========================================
    // 3. 페이로드 (Item) 정의
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
    // 4. 포트 정의 (Port Definitions)
    // - EgasSystem 경계에서 주고받는 아이템의 방향(in/out)을 명시함
    // ==========================================

    port def CruiseControlPort {
        in ccCmd : CruiseControlCommand;
    }
    port def BrakeInputPort {
        in brakeInput : BrakePedalPosition;
    }
    port def TorqueInterventionPort {
        in torqueReq : TorqueInterventionRequest;
    }
    port def SensorInputPort {
        in sensorData : EngineSensorData;
    }
    port def FuelCommandPort {
        out fuelCmd : FuelIgnitionCommand;
    }
    port def CombustionStatusPort {
        in combustionStatus : CombustionSystemStatus;
    }

    // ==========================================
    // 5. 관심 시스템 (System of Interest) 정의
    // - 요구사항 뷰포인트에서는 블랙박스로만 취급: 포트(인터페이스)만 노출하고
    //   내부 구성(컴포넌트 분해 및 내부 흐름)은 기능/논리 뷰포인트에서 정의함
    // ==========================================

    part def EgasSystem {
        port ccPort : CruiseControlPort;
        port brakePort : BrakeInputPort;
        port torqueInterventionPort : TorqueInterventionPort;
        port sensorPort : SensorInputPort;
        port fuelCmdPort : FuelCommandPort;
        port combustionStatusPort : CombustionStatusPort;

        @ElementVersion {
            version = "v0.1";
        }
    }

    // ==========================================
    // 6. 시스템 컨텍스트 (System Context)
    // ==========================================

    part def EgasContext {
        // 외부 환경(액터) 인스턴스화
        part ccLever : CruiseControlLever [0..1];
        part brake : Brake;
        part addEcu : AddEcu;
        part sensors : AddSensorComponents;
        part fuelSys : FuelInjectionIgnitionSystem;

        // 관심 시스템 전체를 하나의 파트로 인스턴스화
        part egas : EgasSystem;

        // 외부 액터와 시스템 경계 포트 간의 흐름 (내부 파트에는 직접 접근하지 않음)
        flow of CruiseControlCommand from ccLever to egas.ccPort.ccCmd;
        flow of BrakePedalPosition from brake to egas.brakePort.brakeInput;
        flow of TorqueInterventionRequest from addEcu to egas.torqueInterventionPort.torqueReq;
        flow of EngineSensorData from sensors to egas.sensorPort.sensorData;

        // 연료/점화 시스템과의 양방향 제어 및 피드백 흐름
        flow of FuelIgnitionCommand from egas.fuelCmdPort.fuelCmd to fuelSys;
        flow of CombustionSystemStatus from fuelSys to egas.combustionStatusPort.combustionStatus;

        @ElementVersion {
            version = "v0.1";
        }
    }
} // package EgasBaseArchitecture
