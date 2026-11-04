package EgasArch_Common_Signals {
    doc
    /* 시스템 경계를 넘는 신호만 정의한다. 내부 신호는 T14에서 추가한다. 수치 한계와 시간 값은 두지 않는다. */
    private import ISQ::*;
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;

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
} // package EgasArch_Common_Signals
