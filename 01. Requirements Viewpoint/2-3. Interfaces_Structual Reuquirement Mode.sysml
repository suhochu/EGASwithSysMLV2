package RV_InterfaceModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // 1. Items (Payloads)
    item def CruiseControlCommand {
        // 운전자의 크루즈 요청 (순간 명령). 크루즈 활성 상태는 EGAS 내부 상태(ccState)이며 이 아이템이 아니다.
        attribute request : CruiseControlRequestEnum; // Set / Resume / Cancel / Off
        attribute setSpeed :> ISQ::speed; // Set 요청 시 지정 속도
        @MetaInformation { version = "v0.3"; }
    }

    item def BrakePedalPosition {
        attribute pressure :> ISQ::pressure; // Physical depth/pressure of brake pedal
        attribute latency :> ISQ::duration; // [Input Obs.] External factor. Use only in assume/if, NOT require
        attribute messageAge :> ISQ::duration; // [입력 관측치] 송신 ~ EGAS 수신 완료 (외부 요인). assume/가드/분기에서만 사용, 보장 대상 아님

        @MetaInformation { version = "v0.3"; }
    }

    item def TorqueInterventionRequest {
        attribute requestedTorqueDelta :> ISQ::torque; // Torque delta requested by external ECU (TCU/ESP)
        attribute latency :> ISQ::duration; // [Input Obs.] External factor. Use only in assume/if, NOT require
        attribute interventionType : InterventionTypeEnum; // Resolves arbitration ambiguity (Absolute/Relative)
        attribute messageAge :> ISQ::duration; // [입력 관측치] 외부 제어기 메시지의 송신 ~ EGAS 수신 완료

        @MetaInformation { version = "v0.4"; }
    }

    item def EngineSensorData {
        attribute engineRpm :> ISQ::frequency;
        attribute coolantTemp :> ISQ::thermodynamicTemperature;
        @MetaInformation { version = "v0.3"; }
    }

    item def AccelerationPedalPosition {
        // Redundant electrical signal (PVS1/PVS2) from AccelerationPedal.
        // Internal conversion of Driver AccelerationIntent, stays within system boundary.
        attribute pvs1Percentage : Real; // PVS1 채널 값 [% of full scale]
        attribute pvs2Percentage : Real; // PVS2 채널 값 [% of full scale]
        assert constraint {
            pvs1Percentage >= 0.0 and
            pvs1Percentage <= 100.0 and
            pvs2Percentage >= 0.0 and
            pvs2Percentage <= 100.0
        }
        @MetaInformation { version = "v0.3"; }
    }

    item def ThrottlePositionCommand {
        // ECU가 스로틀 밸브 모터에 내리는 목표 개도각(Angle) 제어 신호 (ECU → ThrottleValve, EGAS 내부 신호)
        attribute openingPercentage : Real; // [추가] 목표 개도 (0~100%, 0: 전폐 / 100: 전개)
        assert constraint { openingPercentage >= 0.0 and openingPercentage <= 100.0 }
        @MetaInformation { version = "v0.3"; }
    }

    item def ThrottlePositionFeedback {
        // 스로틀 밸브의 현재 위치 센서(TPS) 피드백 값 (ThrottleValve → ECU, EGAS 내부 신호)
        attribute openingPercentage : Real; // [추가] 실제 개도 (0~100%)
        attribute tps1Percentage : Real; // [추가] TPS1 채널 값
        attribute tps2Percentage : Real; // [추가] TPS2 채널 값
        assert constraint {
            openingPercentage >= 0.0 and
            openingPercentage <= 100.0 and
            tps1Percentage >= 0.0 and
            tps1Percentage <= 100.0 and
            tps2Percentage >= 0.0 and
            tps2Percentage <= 100.0
        }
        @MetaInformation { version = "v0.4"; }
    }

    item def FuelIgnitionCommand {
        attribute injectionPulseWidth :> ISQ::duration; // Injector fuel pulse width
        attribute responseTime :> ISQ::duration; // [EGAS 보장] 트리거 입력 수신 완료 ~ 이 명령 출력 시작 (messageAge 미포함). 한계는 ...Budget 상수
        attribute previousPulseWidth :> ISQ::duration; // Prev cycle injection time for torque reduction check
        @MetaInformation { version = "v0.6"; }
    }

    item def CombustionSystemStatus {
        attribute misfireRate :> ISQ::frequency; // Engine misfire frequency/rate
        attribute steadyStateError : Real; // 목표 토크 대비 실제 토크의 정상 상태 오차(토크 루프)
        attribute actualTorqueValue :> ISQ::torque; // Estimated/measured torque based on current combustion
        attribute torqueOvershoot : Real; // Overshoot value exceeding target torque
        @MetaInformation { version = "v0.4"; }
    }

    item def AccelerationIntent {
        attribute pedalDisplacement :> ISQ::length; // Physical displacement of pedal
        attribute pedalPositionPercentage : Real; // Pedal position in percentage (0~100%)
        attribute latency :> ISQ::duration; // [Input Obs.] External factor. Use only in assume/if, NOT require
        attribute messageAge :> ISQ::duration; // [입력 관측치] 현재 제약에서 미사용 (SHR-08 정의 확정 시 assume에 사용 가능)

        assert constraint { pedalPositionPercentage >= 0.0 and pedalPositionPercentage <= 100.0 }
        @MetaInformation { version = "v0.5"; }
    }

    item def VehicleDynamicsFeedback {
        // 차량 거동 피드백 (차속, 종방향 Jerk)
        attribute vehicleSpeed :> ISQ::speed; // 크루즈 속도 폐루프의 피드백
        attribute longitudinalJerk : Real;
        @MetaInformation { version = "v0.2"; }
    }

    item def IntakeAirFlow {
        attribute massFlow :> ISQ::massFlowRate; // Air mass flow based on throttle angle
        attribute previousMassFlow :> ISQ::massFlowRate; // Prev cycle mass flow for torque reduction check
        attribute responseTime :> ISQ::duration; // [EGAS 보장] 트리거 입력 수신 완료 ~ 이 명령 출력 시작 (messageAge 미포함). 한계는 ...Budget 상수
        @MetaInformation { version = "v0.4"; }
    }

    item def ExternalToolRequest {
        // Common supertype for external tool (cal/diag) request packets to ECU
        @MetaInformation { version = "v0.1"; }
    }

    item def ExternalToolResponse {
        // Common supertype for ECU response packets to external tools
        @MetaInformation { version = "v0.1"; }
    }

    item def CalibrationRequest :> ExternalToolRequest {
        attribute targetMemoryAddress : Integer; // Target internal memory address
        attribute mapDataPayload : Real; // Engine map parameter value to write/update
        @MetaInformation { version = "v0.3"; }
    }

    item def CalibrationStatus :> ExternalToolResponse {
        attribute responseCode : Integer; // e.g., 200 (OK), 401 (Locked)
        attribute verifiedChecksum : Integer; // Verified memory checksum after map update
        attribute responseTime :> ISQ::duration; // [EGAS 보장] 트리거 입력 수신 완료 ~ 이 명령 출력 시작 (messageAge 미포함). 한계는 ...Budget 상수
        @MetaInformation { version = "v0.4"; }
    }

    item def DiagnosticRequest :> ExternalToolRequest {
        // UDS protocol based diagnostic service request packet
        attribute serviceId : Integer; // e.g., 1 (ReadDTC), 2 (RoutineControl)
        attribute dataRecord : Integer; // Diagnostic sub-command or routine ID payload
        @MetaInformation { version = "v0.3"; }
    }

    item def DiagnosticStatus :> ExternalToolResponse {
        attribute responseCode : Integer; // e.g., 200 (Positive Response), 400 (Negative Response)
        attribute dtcCode : Integer; // Actual output fault code (0 if none)
        attribute responseTime :> ISQ::duration; // [EGAS 보장] 트리거 입력 수신 완료 ~ 이 명령 출력 시작 (messageAge 미포함). 한계는 ...Budget 상수
        @MetaInformation { version = "v0.4"; }
    }

    item def IgnitionState {
        attribute status : IgnitionStatusEnum;
        @MetaInformation { version = "v0.1"; }
    }

    item def DashboardWarning {
        attribute status : DashboardWarningStatusEnum;
        @MetaInformation { version = "v0.1"; }
    }

    item def FaultMemoryRecord {
        // 확정된 치명 고장의 비휘발성 메모리(NVM) 기록 (EGAS 내부 신호)
        attribute dtcCode : Integer; // 기록된 DTC (0: 미기록)
        attribute storageTime :> ISQ::duration; // 고장 확정 ~ NVM 기록 완료까지의 시간
        @MetaInformation { version = "v0.1"; }
    }

    // 2. Ports (EgasSystem Boundary Definitions)
    port def CruiseControlPort {
        in ccCmd : CruiseControlCommand;
        @MetaInformation { version = "v0.2"; }
    }
    port def BrakeInputPort {
        in brakeInput : BrakePedalPosition;
        @MetaInformation { version = "v0.2"; }
    }
    port def TorqueInterventionPort {
        in torqueReq : TorqueInterventionRequest;
        @MetaInformation { version = "v0.2"; }
    }
    port def SensorInputPort {
        in sensorData : EngineSensorData;
        in dynamicsStatus : VehicleDynamicsFeedback;
        @MetaInformation { version = "v0.2"; }
    }
    port def FuelCommandPort {
        out fuelCmd : FuelIgnitionCommand;
        @MetaInformation { version = "v0.2"; }
    }
    port def CombustionStatusPort {
        in combustionStatus : CombustionSystemStatus;
        @MetaInformation { version = "v0.2"; }
    }
    port def AccelerationInputPort {
        in accelIntent : AccelerationIntent;
        @MetaInformation { version = "v0.2"; }
    }
    port def AirIntakePort {
        out airFlow : IntakeAirFlow;
        @MetaInformation { version = "v0.2"; }
    }
    port def CalibrationPort {
        in calReq : CalibrationRequest;
        out calStatus : CalibrationStatus;
        @MetaInformation { version = "v0.2"; }
    }
    port def DiagnosticPort {
        in diagReq : DiagnosticRequest;
        out diagStatus : DiagnosticStatus;
        @MetaInformation { version = "v0.2"; }
    }
    port def IgnitionPort {
        in ignitionStatus : IgnitionState;
        @MetaInformation { version = "v0.1"; }
    }
    port def DashboardPort {
        out dashboardWarning : DashboardWarning;
        @MetaInformation { version = "v0.1"; }
    }
} // package RV_InterfaceModel
