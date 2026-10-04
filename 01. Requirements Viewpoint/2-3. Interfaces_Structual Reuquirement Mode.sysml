package RV_InterfaceModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // 1. Items (Payloads)
    item def CruiseControlCommand {
        // Target speed and CC On/Off/Cancel status
        attribute setSpeed :> ISQ::speed;
        @MetaInformation { version = "v0.2"; }
    }

    item def BrakePedalPosition {
        attribute pressure :> ISQ::pressure; // Physical depth/pressure of brake pedal
        attribute latency :> ISQ::duration; // [Input Obs.] External factor. Use only in assume/if, NOT require
        @MetaInformation { version = "v0.3"; }
    }

    item def TorqueInterventionRequest {
        attribute requestedTorqueDelta :> ISQ::torque; // Torque delta requested by external ECU (TCU/ESP)
        attribute latency :> ISQ::duration; // [Input Obs.] External factor. Use only in assume/if, NOT require
        attribute interventionType : InterventionTypeEnum; // Resolves arbitration ambiguity (Absolute/Relative)
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
        @MetaInformation { version = "v0.2"; }
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
        assert constraint { openingPercentage >= 0.0 and openingPercentage <= 100.0 }
        @MetaInformation { version = "v0.3"; }
    }

    item def FuelIgnitionCommand {
        attribute injectionPulseWidth :> ISQ::duration; // Injector fuel pulse width
        attribute responseTime :> ISQ::duration; // [EGAS Owned] Processing time from trigger rx to cmd tx start
        attribute previousPulseWidth :> ISQ::duration; // Prev cycle injection time for torque reduction check
        @MetaInformation { version = "v0.6"; }
    }

    item def CombustionSystemStatus {
        attribute misfireRate :> ISQ::frequency; // Engine misfire frequency/rate
        attribute steadyStateError : Real; // Error between target control and actual measurement
        attribute actualTorqueValue :> ISQ::torque; // Estimated/measured torque based on current combustion
        attribute torqueOvershoot : Real; // Overshoot value exceeding target torque
        @MetaInformation { version = "v0.4"; }
    }

    item def AccelerationIntent {
        attribute pedalDisplacement :> ISQ::length; // Physical displacement of pedal
        attribute pedalPositionPercentage : Real; // Pedal position in percentage (0~100%)
        attribute latency :> ISQ::duration; // [Input Obs.] External factor. Use only in assume/if, NOT require

        assert constraint { pedalPositionPercentage >= 0.0 and pedalPositionPercentage <= 100.0 }
        @MetaInformation { version = "v0.5"; }
    }

    item def VehicleDynamicsFeedback {
        attribute longitudinalJerk : Real; // Jerk (rate of change of acceleration) in m/s³
        @MetaInformation { version = "v0.1"; }
    }

    item def IntakeAirFlow {
        attribute massFlow :> ISQ::massFlowRate; // Air mass flow based on throttle angle
        attribute previousMassFlow :> ISQ::massFlowRate; // Prev cycle mass flow for torque reduction check
        attribute responseTime :> ISQ::duration; // [EGAS Owned] Processing time from trigger rx to cmd tx start
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
        attribute responseTime :> ISQ::duration; // Processing time from request rx to response tx
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
        attribute responseTime :> ISQ::duration; // Processing time from request rx to response tx
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
