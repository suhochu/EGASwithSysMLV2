package EgasArch_Ctx_Context {
    private import EgasArch_Common_Signals::*;

    port def TorqueMonitorPort;

    // Port definitions are written from the EGAS side; actors use the conjugate.
    port def AccelerationInputPort {
        in item pedalPosition : AccelerationPedalPosition;
    }

    port def BrakeInputPort {
        in item brakePosition : BrakePedalPosition;
    }

    port def SensorInputPort {
        in item engineSensor : EngineSensorData;
    }

    port def TorqueInterventionPort {
        in item torqueRequest : TorqueInterventionRequest;
    }

    port def AirIntakePort {
        out item airFlow : IntakeAirFlow;
    }

    port def FuelCommandPort {
        out item fuelCommand : FuelIgnitionCommand;
    }

    port def DashboardPort {
        out item warning : DashboardWarning;
    }

    part def EgasSystem {
        doc
        /* Black box of the EGAS engine control system. Internal structure belongs to the functional and logical viewpoints. */
        port torqueMonitor : TorqueMonitorPort;
        port accelerationInput : AccelerationInputPort;
        port brakeInput : BrakeInputPort;
        port sensorInput : SensorInputPort;
        port torqueIntervention : TorqueInterventionPort;
        port airIntake : AirIntakePort;
        port fuelCommand : FuelCommandPort;
        port dashboardOutput : DashboardPort;
    }

    part def AccelerationPedal {
        doc
        /* 운전자의 가속 의지를 PVS1·PVS2 신호로 EGAS에 전달하는 경계 밖 페달 센서. */
        port pedalOutput : ~AccelerationInputPort;
    }

    part def Brake {
        doc
        /* 제동 의지를 EGAS에 전달하는 브레이크 페달. */
        port brakeOutput : ~BrakeInputPort;
    }

    part def Engine {
        doc
        /* 엔진 상태를 EGAS에 알리고 공기 경로로 흡기를 받는 물리적 엔진. */
        port sensorOutput : ~SensorInputPort;
        port airInput : ~AirIntakePort;
    }

    part def AddEcu {
        doc
        /* 외부 제어기(TCU, ESP)로 EGAS에 토크 개입을 요청한다. */
        port requestOutput : ~TorqueInterventionPort;
    }

    part def FuelInjectionIgnitionSystem {
        doc
        /* EGAS의 연료 분사·점화 명령을 받는 액추에이터. */
        port commandInput : ~FuelCommandPort;
    }

    part def DashboardHMI {
        doc
        /* EGAS의 경고 상태를 운전자에게 표시한다. */
        port warningInput : ~DashboardPort;
    }

    part def EgasContext {
        doc
        /* System context: the EGAS boundary and the external actors it exchanges signals with. */
        part egas : EgasSystem;
        part pedal : AccelerationPedal;
        part brake : Brake;
        part engine : Engine;
        part externalEcu : AddEcu;
        part fuelSystem : FuelInjectionIgnitionSystem;
        part dashboard : DashboardHMI;

        connect pedal.pedalOutput to egas.accelerationInput;
        connect brake.brakeOutput to egas.brakeInput;
        connect engine.sensorOutput to egas.sensorInput;
        connect externalEcu.requestOutput to egas.torqueIntervention;
        connect egas.airIntake to engine.airInput;
        connect egas.fuelCommand to fuelSystem.commandInput;
        connect egas.dashboardOutput to dashboard.warningInput;
    }
} // package EgasArch_Ctx_Context
