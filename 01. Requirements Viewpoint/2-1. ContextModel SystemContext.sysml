package RV_ContextModel {
    doc
    /* [시스템 컨텍스트 뷰포인트]
     * EGAS(관심 시스템)의 경계를 정의하는 어휘를 제공한다: 외부 액터, 주고받는 아이템(payload), 경계 포트,
     * 그리고 관심 시스템 자체(EgasSystem)를 블랙박스로, 시스템+외부 액터 전체를 컨텍스트(EgasContext)로 정의한다.
     * 내부 컴포넌트(EngineControlUnit/AccelerationPedal/ThrottleValve)는 05/06번 파일에서 그레이박스 유스케이스의
     * subject나 요구사항의 allocationBudget 대상으로 참조되지만, 이 파일의 EgasSystem 정의 자체는 포트만 노출하는
     * 순수 블랙박스이며 내부 배선(어떻게 연결되는지)은 "02. Functional Viewpoint"가 책임진다.
     */

    private import ReqCommon::*;
    public import RV_InterfaceModel::*;
    public import RV_OperationalModel::*;
    public import RV_ActorModel::*;
    private import ViewAndViewpintCommon::*;

    @MetaInformation {
        version = "v0.2";
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
        port ignitionPort : IgnitionPort;
        port dashboardPort : DashboardPort;

        // 복합(Composition) 관계: 내부 구성요소 존재만 이 레벨에서 선언하고, 배선/연결은 기능 뷰포인트("02. Functional Viewpoint")가 책임진다
        part ecu : EngineControlUnit;
        part pedal : AccelerationPedal;
        part throttle : ThrottleValve;

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

        // 시스템이 해당 운용 요구사항 기능들을 수행함을 명시
        perform action manageTorque
            : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
        perform action manageEmergency
            : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
        perform action manageFailSafe : EgasOperationalRequirements_UC3::ManageHardwareFailSafe;
        perform action manageCalibration
            : EgasOperationalRequirements_UC4::ManagePowertrainCalibration;
        perform action manageDiagnostics
            : EgasOperationalRequirements_UC5::ManageDiagnosticsAndMaintenance;

        action def EgasMainContinuousOperation {
            doc
            /* 시스템 전원이 켜진 상태에서 모든 UC 운용 로직을 병렬로 무한 반복 수행 */

            then action uc1 : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            then action uc2 : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            then action uc3 : EgasOperationalRequirements_UC3::ManageHardwareFailSafe;
            then action uc4 : EgasOperationalRequirements_UC4::ManagePowertrainCalibration;
            then action uc5 : EgasOperationalRequirements_UC5::ManageDiagnosticsAndMaintenance;

            fork mainLoop;
                then uc1;
                then uc2;
                then uc3;
                then uc4;
                then uc5;
        }

        exhibit state egasBehavior : RV_BehavioralModel::EgasBehavior;

        @MetaInformation {
            version = "v0.5";
        }
    }

    // ==========================================
    // 2. 시스템 컨텍스트 (System Context)
    // ==========================================

    part def EgasContext {
        // [Step 1] 외부 환경(액터) 및 관심 시스템 인스턴스화
        part driver : Driver;
        part ccLever : CruiseControlLever [0..1];
        part brake : Brake;
        part addEcu : AddEcu;
        part sensors : AddSensorComponents;
        part fuelSys : FuelInjectionIgnitionSystem;
        part engine : Engine;
        part calTool : CalibrationTool;
        part diagTool : DiagnosticTool;
        part powerSys : VehiclePowerSystem;
        part dashboard : DashboardHMI;

        part egas : EgasSystem;

        // [Step 2] 명시적인 구조적 연결 (Connections)
        // 외부 액터와 EgasSystem의 포트 간의 상호작용 경로(경계 인터페이스)를 공식적으로 개통합니다.
        connect driver.driverPort to egas.accelPort {
            flow of AccelerationIntent from driver.driverPort to egas.accelPort;
        }
        connect ccLever.ccPort to egas.ccPort {
            flow of CruiseControlCommand from ccLever.ccPort to egas.ccPort;
        }
        connect brake.brakePort to egas.brakePort {
            flow of BrakePedalPosition from brake.brakePort to egas.brakePort;
        }
        connect addEcu.addEcuPort to egas.torqueInterventionPort {
            flow of TorqueInterventionRequest from addEcu.addEcuPort to egas.torqueInterventionPort;
        }
        connect sensors.sensorPort to egas.sensorPort {
            flow of EngineSensorData from sensors.sensorPort to egas.sensorPort;
        }

        // fuelSys는 명령어 수신용 포트와 상태 송신용 포트 두 곳에 모두 연결됩니다.
        connect fuelSys.cmdPort to egas.fuelCmdPort {
            flow of FuelIgnitionCommand from egas.fuelCmdPort to fuelSys.cmdPort;
        }
        connect fuelSys.statusPort to egas.combustionStatusPort {
            flow of CombustionSystemStatus from fuelSys.statusPort to egas.combustionStatusPort;
        }
        connect engine.intakePort to egas.airIntakePort {
            flow of IntakeAirFlow from egas.airIntakePort to engine.intakePort;
        }

        // 툴과의 양방향 통신 경로 연결
        connect calTool.calPort to egas.calibrationPort {
            flow of CalibrationRequest from calTool.calPort to egas.calibrationPort;
            flow of CalibrationStatus from egas.calibrationPort to calTool.calPort;
        }
        connect diagTool.diagPort to egas.diagPort {
            flow of DiagnosticRequest from diagTool.diagPort to egas.diagPort;
            flow of DiagnosticStatus from egas.diagPort to diagTool.diagPort;
        }

        connect powerSys.ignitionPort to egas.ignitionPort {
            flow of IgnitionState from powerSys.ignitionPort to egas.ignitionPort;
        }
        connect egas.dashboardPort to dashboard.dashboardPort {
            flow of DashboardWarning from egas.dashboardPort to dashboard.dashboardPort;
        }

        @MetaInformation {
            version = "v0.7";
        }
    } // package EgasSystemContext
} // package RV_ContextModel
