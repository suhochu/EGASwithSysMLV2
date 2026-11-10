package EgasArch_Common_Signals {
    doc
    /* 경계 신호와 UF 사이의 내부 신호를 정의한다. 수치 한계와 시간 값은 두지 않는다. */
    private import ISQ::*;
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::OperatingMode;

    enum def InterventionKind {
        enum absolute;
        enum relative;
    }

    // Pedal to EGAS, redundant channels PVS1 and PVS2.
    item def AccelerationPedalPosition {
        attribute pvs1Percentage : PercentQuantity;
        attribute pvs2Percentage : PercentQuantity;
    }

    // Brake to EGAS.
    item def BrakePedalPosition {
        attribute pressure : ISQ::PressureValue;
    }

    // Engine to EGAS.
    item def EngineSensorData {
        attribute engineSpeed : AngularVelocityQuantity;
    }

    // External ECU (TCU, ESP) to EGAS.
    item def TorqueInterventionRequest {
        attribute requestedTorqueDelta : TorqueQuantity;
        attribute interventionType : InterventionKind;
    }

    // EGAS to Engine (air path).
    item def IntakeAirFlow {
        attribute massFlow : MassFlowRateQuantity;
    }

    // EGAS to fuel injection and ignition system.
    item def FuelIgnitionCommand {
        attribute injectionPulseWidth : DurationQuantity;
    }

    // EGAS to dashboard.
    item def DashboardWarning {
        attribute warningActive : Boolean;
    }

    // Internal: result of the torque comparison.
    item def TorqueExcessFlag {
        attribute excessDetected : Boolean;
    }

    // Internal: confirmed torque excess that requests the safe state.
    item def SafeStateRequest {
        attribute requested : Boolean;
    }

    // Internal: confirmed fault of the pedal value sensor channels.
    item def PedalFaultStatus {
        attribute faultConfirmed : Boolean;
    }

    // Internal: mode channel broadcast by the torque arbitration.
    item def ModeChannel {
        attribute mode : OperatingMode;
    }

    // Internal: Q&A question of the independent monitoring module to the function controller.
    item def QnaQuestion {
        attribute questionId : Integer;
    }

    // Internal: answer of the function controller to the monitoring module.
    item def QnaAnswer {
        attribute answerId : Integer;
    }

    // Internal: request of the independent monitoring module to shut the engine off.
    item def ShutOffRequest {
        attribute requested : Boolean;
    }
} // package EgasArch_Common_Signals
