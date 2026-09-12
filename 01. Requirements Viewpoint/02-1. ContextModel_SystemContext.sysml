package EgasSystemContext {
    doc
    /* [시스템 컨텍스트 뷰포인트]
     * EGAS(관심 시스템)의 경계를 정의하는 어휘를 제공한다: 외부 액터, 주고받는 아이템(payload), 경계 포트,
     * 그리고 관심 시스템 자체(EgasSystem)를 블랙박스로, 시스템+외부 액터 전체를 컨텍스트(EgasContext)로 정의한다.
     * 내부 컴포넌트(EngineControlUnit/AccelerationPedal/ThrottleValve)는 05/06번 파일에서 그레이박스 유스케이스의
     * subject나 요구사항의 allocationBudget 대상으로 참조되지만, 이 파일의 EgasSystem 정의 자체는 포트만 노출하는
     * 순수 블랙박스이며 내부 배선(어떻게 연결되는지)은 "02. Functional Viewpoint"가 책임진다.
     */

    private import ReqCommon::*;
    private import ScalarValues::*;
    public import Actors::*;
    public import EgasSystemContextInterfaces::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 관심 시스템 (System of Interest) 정의
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
        port accelPort : AccelerationInputPort;
        port airIntakePort : AirIntakePort;
        port calibrationPort : CalibrationPort;
        port diagPort : DiagnosticPort;
        port dynamicsFeedbackPort : DynamicsFeedbackPort;

        event occurrence commandsManualTorque; // 수동 목표 토크 산출 및 제어 명령
        event occurrence commandsCruiseTorque; // 크루즈 목표 토크 자동 산출 및 제어 명령
        event occurrence overridesAndCutsTorque; // 브레이크 입력에 따른 기존 요구 무효화 및 동력 차단

        event occurrence commandsEmergencyReduction; // 정상 긴급 감속 명령
        event occurrence compensatesCommDelay; // 지연 보상 제어 명령
        event occurrence commandsEmergencyFuelCut; // 예외 상황 연료 차단 명령

        event occurrence compensatesDelayAndFriction; // 정상 지연/마찰 보정 명령
        event occurrence triggersEmergencyFailSafe; // 결함 감지 및 페일세이프 차단 명령

        event occurrence authorizesAccess; // 유효 메모리 접근 인가
        event occurrence verifiesAndCommitsData; // 데이터 무결성 검증 및 기록
        event occurrence rejectsAndRollsBack; // 비유효 접근 거절 및 롤백

        event occurrence registersSensorFault; // 센서 결함 상태 기록
        event occurrence processesDtcRequest; // DTC 조회 요청 처리 및 응답
        event occurrence processesZeroPointCal; // 영점 조정 처리 및 응답
        event occurrence rejectsInvalidRequest; // 비유효 진단 요청 거절

        @MetaInformation {
            version = "v0.3";
        }
    }

    // ==========================================
    // 2. 시스템 컨텍스트 (System Context)
    // ==========================================

    part def EgasContext {
        // 외부 환경(액터) 인스턴스화
        part driver : Driver;
        part ccLever : CruiseControlLever [0..1];
        part brake : Brake;
        part addEcu : AddEcu;
        part sensors : AddSensorComponents;
        part fuelSys : FuelInjectionIgnitionSystem;
        part engine : Engine;
        part calTool : CalibrationTool;
        part diagTool : DiagnosticTool;

        // 관심 시스템 전체를 하나의 파트로 인스턴스화
        part egas : EgasSystem;

        // 외부 액터와 시스템 경계 포트 간의 흐름 (내부 파트에는 직접 접근하지 않음)
        flow of AccelerationIntent from driver to egas.accelPort.accelIntent;
        flow of CruiseControlCommand from ccLever to egas.ccPort.ccCmd;
        flow of BrakePedalPosition from brake to egas.brakePort.brakeInput;
        flow of TorqueInterventionRequest from addEcu to egas.torqueInterventionPort.torqueReq;
        flow of EngineSensorData from sensors to egas.sensorPort.sensorData;

        // 연료/점화 시스템과의 양방향 제어 및 피드백 흐름
        flow of FuelIgnitionCommand from egas.fuelCmdPort.fuelCmd to fuelSys;
        flow of CombustionSystemStatus from fuelSys to egas.combustionStatusPort.combustionStatus;

        // 스로틀 밸브(내부)가 만들어낸 공기 흐름이 엔진으로 전달됨
        flow of IntakeAirFlow from egas.airIntakePort.airFlow to engine;

        // Calibariont Tool 과의 양방향 데이터 전달 및 입력
        flow of CalibrationRequest from calTool to egas.calibrationPort.calReq;
        flow of CalibrationStatus from egas.calibrationPort.calStatus to calTool;

        // 진단기와 EgasSystem 간의 양방향 데이터 흐름(Flow) 연결
        flow of DiagnosticRequest from diagTool to egas.diagPort.diagReq;
        flow of DiagnosticStatus from egas.diagPort.diagStatus to diagTool;

        @MetaInformation {
            version = "v0.2";
        }
    } // package EgasSystemContext
} // package EgasSystemContext
