package EgasArch_Ctx_Context {
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Needs_Stakeholder::Driver;
    private import EgasArch_Beh_Behavior::*;

    // Port Definitions (EGAS-System Boundary & Internal Interfaces)

    port def TorqueMonitorPort {
        doc
        /* ECU 내부 감시 포트. 감시 토크 값을 노출하며 EgasContext의 외부 connect 대상이 아니다. */
    }
    port def DriverPedalActuationPort {
        doc
        /* Driver physical actuation -> AccelerationPedal (mechanical/human input) */
        in item actuation : DriverPedalActuation;
    }
    port def AccelerationInputPort {
        doc
        /* Internal EGAS: AccelerationPedal -> EngineControlUnit (PVS1, PVS2) */

        in item pedalPosition : AccelerationPedalPosition;
    }

    port def ThrottleControlPort {
        doc
        /* ECU와 스로틀 밸브 간 제어 명령 및 이중 위치 센서(TPS1/TPS2) 피드백 포트. 
         * (추후 Common_Signals에 ThrottleCommand / ThrottlePosition 추가 시 item 바인딩)
         * Internal EGAS: EngineControlUnit <-> ThrottleValve (actuator drive & TPS1/TPS2 feedback)
         */
        out item command : ThrottleControlCommand;
        in item feedback : ThrottlePositionFeedback;
    }

    port def CruiseControlPort {
        doc
        /* 크루즈 컨트롤 레버(옵션) 입력 포트 (EGAS v6.0 Fig 1).
         * External: Cruise Control Lever (opt) -> EngineControlUnit
         */
        in item ccRequest : CruiseControlRequest;
    }

    port def BrakeInputPort {
        doc
        /* External: Brake -> EngineControlUnit */
        in item brakePosition : BrakePedalPosition;
    }

    port def SensorInputPort {
        doc
        /* External: Engine / Additional Torque-Affecting Sensors -> EngineControlUnit */
        in item engineSensor : EngineSensorData;
    }

    port def TorqueInterventionPort {
        doc
        /* External: Add. ECU (TCU, ESP, AC, etc.) -> EngineControlUnit */
        in item torqueRequest : TorqueInterventionRequest;
    }

    port def AirIntakePort {
        doc
        /* External: ThrottleValve -> Engine (air path) */
        out item airFlow : IntakeAirFlow;
    }

    port def FuelCommandPort {
        doc
        /* External: EngineControlUnit -> Fuel Injection / Ignition System */
        out item fuelCommand : FuelIgnitionCommand;
    }

    port def DashboardPort {
        doc
        /* External: EngineControlUnit -> Dashboard HMI (EGAS_e52 optical driver warning) */
        out item warning : DashboardWarning;
    }

    port def DriverBrakeActuationPort {
        doc
        /* 운전자가 브레이크 페달을 물리적으로 조작하는 인터페이스. */
    }

    // Top-level Vehicle Safe States (Single Source of Truth; Beh_Behavior imports these)
    state def OffState;
    state def DrivingState;
    state def SafeState;
    state def TorqueLimited :> SafeState; // 1단계: 제어 가능한 출력/토크 제한 주행
    state def FuelCutOff :> SafeState; // 2단계: 추진력 차단 (연료 분사 차단 ICO 등)
    state def FullCutOff :> SafeState; // 3단계: 출력단 완전 차단 / 엔진 정지 / 시동 차단

    // EGAS-System Internal Subsystems (EGAS v6.0 Chapter 7, EGAS_e74~e78, Fig 1)

    part def AccelerationPedal {
        doc
        /* EGAS 내부 서브시스템 (EGAS_e75, SReq-01): 운전자의 가속 조작을 이중 채널(PVS1/PVS2) 신호로 ECU에 전달한다. */
        port driverInput : DriverPedalActuationPort;
        port pedalOutput : ~AccelerationInputPort;
    }

    part def EngineControlUnit {
        doc
        /* EGAS 내부 서브시스템 (EGAS_e76, SReq-03~07): 3-Level 모니터링(L1/L2/L3) 및 토크 제어를 수행하는 엔진 제어기. */
        port torqueMonitor : TorqueMonitorPort;
        port accelerationInput : AccelerationInputPort;
        port throttleControl : ThrottleControlPort;
        port cruiseControlInput : CruiseControlPort;
        port brakeInput : BrakeInputPort;
        port sensorInput : SensorInputPort;
        port torqueIntervention : TorqueInterventionPort;
        port fuelCommand : FuelCommandPort;
        port dashboardOutput : DashboardPort;
    }

    part def ThrottleValve {
        doc
        /* EGAS 내부 서브시스템 (EGAS_e77, SReq-02): ECU 명령으로 흡기 공기량을 제어하고 이중 위치 센서(TPS1/TPS2)를 피드백한다. */
        port throttleControl : ~ThrottleControlPort;
        port airIntake : AirIntakePort;
    }

    // System of Interest: EGAS-System (EGAS v6.0 Fig 1 dashed boundary)
    part def EgasSystem {
        doc
        /* EGAS v6.0 Fig 1 기준 시스템 경계: AccelerationPedal, EngineControlUnit, ThrottleValve 3개 서브시스템으로 구성된다. */

        // System Boundary Ports
        port driverPedalInput : DriverPedalActuationPort;
        port cruiseControlInput : CruiseControlPort;
        port brakeInput : BrakeInputPort;
        port sensorInput : SensorInputPort;
        port torqueIntervention : TorqueInterventionPort;
        port airIntake : AirIntakePort;
        port fuelCommand : FuelCommandPort;
        port dashboardOutput : DashboardPort;

        // Internal Subsystems (EGAS_e75~e77)
        part accelerationPedal : AccelerationPedal;
        part ecu : EngineControlUnit;
        part throttleValve : ThrottleValve;

        // Boundary Port Delegations
        bind driverPedalInput = accelerationPedal.driverInput;
        bind cruiseControlInput = ecu.cruiseControlInput;
        bind brakeInput = ecu.brakeInput;
        bind sensorInput = ecu.sensorInput;
        bind torqueIntervention = ecu.torqueIntervention;
        bind airIntake = throttleValve.airIntake;
        bind fuelCommand = ecu.fuelCommand;
        bind dashboardOutput = ecu.dashboardOutput;

        // Internal Subsystem Interconnections (Fig 1)
        connect accelerationPedal.pedalOutput to ecu.accelerationInput;
        connect ecu.throttleControl to throttleValve.throttleControl;

        // Observable System Fault / Mode Events
        event occurrence unintendedAcceleration : UnintendedAccelerationEvent;
        event occurrence sensorOrActuatorFault : SensorOrActuatorFaultEvent;
        event occurrence externalRequestFault : ExternalRequestFaultEvent;
        event occurrence controllerFault : ControllerFaultEvent;
        event occurrence interventionReleased : InterventionReleasedEvent;

        // Boundary Message Event Occurrences (Used by EgasArch_Scn_Scenario messages)
        event occurrence pedalActuationReceived;
        event occurrence ccRequestReceived;
        event occurrence brakePositionReceived;
        event occurrence externalRequestReceived;
        event occurrence engineSensorReceived;
        event occurrence airFlowSent;
        event occurrence fuelCommandSent;
        event occurrence warningSent;

        exhibit state behavior : EgasBehavior;
    }

    // External Actors / Systems (Outside EGAS-System Boundary, Fig 1)
    part def CruiseControlLever {
        doc
        /* 크루즈 컨트롤 조작 레버 (옵션, EGAS v6.0 Fig 1). */
        port ccOutput : ~CruiseControlPort;
        event occurrence ccRequestSent;
    }

    part def Brake {
        doc
        /* 제동 의지를 ECU에 전달하는 브레이크 시스템/스위치 (EGAS v6.0 Fig 1). */
        port driverInput : DriverBrakeActuationPort;
        port brakeOutput : ~BrakeInputPort;
        event occurrence brakeActuationReceived;
        event occurrence brakePositionSent;
    }

    part def AddEcu {
        doc
        /* 외부 제어기(TCU, ESP, AC 등)로 ECU에 토크 개입을 요청한다 (EGAS v6.0 Fig 1). */
        port requestOutput : ~TorqueInterventionPort;
        event occurrence externalRequestSent;
    }

    part def Engine {
        doc
        /* 추가 토크 영향 센서(엔진 회전수, 부하 등) 정보를 ECU에 전달하고 스로틀 밸브로부터 흡기 공기를 받는 물리적 엔진
         * (EGAS v6.0 Fig 1: Add. Sensors/Components + Combustion Engine).
         */
        port sensorOutput : ~SensorInputPort;
        port airInput : ~AirIntakePort;
        event occurrence engineSensorSent;
        event occurrence airFlowReceived;
    }

    part def FuelInjectionIgnitionSystem {
        doc
        /* ECU의 연료 분사·점화 명령을 받는 외부 액추에이터 시스템 (EGAS v6.0 Fig 1). */
        port commandInput : ~FuelCommandPort;
        event occurrence fuelCommandReceived;
    }

    part def DashboardHMI {
        doc
        /* ECU의 경고 상태를 운전자에게 광학적으로 표시한다 (EGAS_e52). */
        port warningInput : ~DashboardPort;
        event occurrence warningReceived;
    }

    // System Context (EGAS-System + External Environment)
    part def EgasContext {
        doc
        /* System context aligned with EGAS v6.0 Fig 1: EGAS-System boundary and its external actors. */
        part egas : EgasSystem;
        part driver : Driver;
        part ccLever : CruiseControlLever [0..1];
        part brake : Brake;
        part externalEcu : AddEcu;
        part engine : Engine;
        part fuelSystem : FuelInjectionIgnitionSystem;
        part dashboard : DashboardHMI;

        connect driver.pedalActuation to egas.driverPedalInput;
        connect driver.brakeActuation to brake.driverInput;
        connect brake.brakeOutput to egas.brakeInput;
        connect ccLever.ccOutput to egas.cruiseControlInput;
        connect externalEcu.requestOutput to egas.torqueIntervention;
        connect engine.sensorOutput to egas.sensorInput;
        connect egas.airIntake to engine.airInput;
        connect egas.fuelCommand to fuelSystem.commandInput;
        connect egas.dashboardOutput to dashboard.warningInput;
    }
} // package EgasArch_Ctx_Context
