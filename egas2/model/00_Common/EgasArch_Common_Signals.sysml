package EgasArch_Common_Signals {
    doc
    /* EGAS 시스템 경계 신호, 내부 3대 서브시스템(Pedal/ECU/ThrottleValve) 간 신호, ECU 내부 신호를 정의한다. 
     * 수치 한계와 시간 값은 두지 않는다.
     */
    private import ISQ::*;
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;

    // 1. System Boundary Signals (External Actors <-> EGAS-System, EGAS Fig 1)
    item def DriverPedalActuation {
        doc
        /* Driver -> AccelerationPedal (physical actuation) */
        attribute pedalTravel : PercentQuantity;
    }
    item def CruiseControlRequest {
        doc
        /* CruiseControlLever (opt) -> ECU (EGAS Fig 1, FSR-03/04/08) */
        attribute active : Boolean;
        attribute cancelRequested : Boolean;
        attribute targetSpeed : SpeedQuantity [0..1];
    }
    item def BrakePedalPosition {
        doc
        /* Brake -> ECU (EGAS_e38 SS/BTS redundant brake signals, EGAS_e198, 11.1.5) */
        attribute pressure : ISQ::PressureValue;
        attribute stopLightSwitchActive : Boolean;
        attribute brakeTestSwitchActive : Boolean;
    }
    item def EngineSensorData {
        doc
        /* Engine (Add. Sensors/Components) -> ECU (EGAS_e137~e138, e228~e229) */
        attribute engineSpeed : AngularVelocityQuantity;
        attribute intakeAirMassFlow : MassFlowRateQuantity [0..1];
    }

    item def TorqueInterventionRequest {
        doc
        /* External ECU (TCU, ESP, AC) -> ECU (EGAS_e51, SReq-04: transmission & actuality check) */
        attribute requestedTorqueDelta : TorqueQuantity;
        attribute interventionType : InterventionKind;
        attribute aliveCounter : Integer;
        attribute checksum : Integer;
    }
    item def IntakeAirFlow {
        doc
        /* ThrottleValve -> Engine (air path) */
        attribute massFlow : MassFlowRateQuantity;
    }
    item def FuelIgnitionCommand {
        doc
        /* ECU -> Fuel Injection & Ignition System */
        attribute injectionPulseWidth : DurationQuantity;
    }
    item def DashboardWarning {
        doc
        /* ECU -> Dashboard HMI (EGAS_e52 optical driver warning) */
        attribute warningActive : Boolean;
    }

    // 2. EGAS Internal Subsystem Signals (Pedal <-> ECU <-> ThrottleValve)
    item def AccelerationPedalPosition {
        doc
        /* AccelerationPedal -> ECU: redundant channels PVS1 and PVS2 (SReq-01, 10.1.2.2) */
        attribute pvs1Percentage : PercentQuantity;
        attribute pvs2Percentage : PercentQuantity;
    }
    item def ThrottleControlCommand {
        doc
        /* ECU -> ThrottleValve: target angle & power-stage enable (11.1.2 throttle actuator currentless) */
        attribute targetAngle : PercentQuantity;
        attribute powerStageEnabled : Boolean;
    }
    item def ThrottlePositionFeedback {
        doc
        /* ThrottleValve -> ECU: redundant channels TPS1 and TPS2 (SReq-02, 10.1.2.1) */
        attribute tps1Percentage : PercentQuantity;
        attribute tps2Percentage : PercentQuantity;
    }

    // 3. ECU Internal Signals (L1 / L2 / L3 & User Functions)
    item def TorqueDemand {
        doc
        /* Internal absolute torque demand (differs from relative TorqueInterventionRequest at boundary) */
        attribute requestedTorque : TorqueQuantity;
    }
    item def TorqueExcessFlag {
        doc
        /* L2: result of permissible vs. actual torque comparison */
        attribute excessDetected : Boolean;
    }
    item def SafeStateRequest {
        doc
        /* L2: confirmed torque excess or sensor/actuator fault requesting safe state */
        attribute requested : Boolean;
    }
    item def PedalFaultStatus {
        doc
        /* L1/L2: confirmed fault of pedal value sensor channels (FSR-03) */
        attribute faultConfirmed : Boolean;
    }
    item def ThrottleFaultStatus {
        doc
        /* L1/L2: confirmed fault of throttle position sensor or actuator (FSR-03, FSR-05) */
        attribute faultConfirmed : Boolean;
    }
    item def ExternalRequestFaultStatus {
        doc
        /* L1/L2: faulty/missing external torque request (FSR-04) */
        attribute faultConfirmed : Boolean;
    }
    item def InjectionCutOffRequest {
        doc
        /* L1/L2: Injection Cut Off request (EGAS_e34, FuelCutOff stage) */
        attribute icoRequested : Boolean;
        attribute irreversible : Boolean;
    }
    item def QnaQuestion {
        doc
        /* L3: Q&A question from independent monitoring module (L3_MM) to function controller (L3_SW) */
        attribute questionId : Integer;
    }
    item def QnaAnswer {
        doc
        /* L3: Q&A answer from function controller (L3_SW) to monitoring module (L3_MM) */
        attribute answerId : Integer;
    }
    item def ShutOffRequest {
        doc
        /* L3/L2: power output stage shutoff / engine stop request (FullCutOff stage) */
        attribute requested : Boolean;
    }

    // Todo
    // ※ EgasArch_Common_Enums에서 OperatingMode가 주석 처리되어 있어,
    //   Fbb_Function / Fwb_Function에서 ModeChannel을 계속 쓰신다면 OperatingMode를 복원하거나 아래를 제거하세요.
    // item def ModeChannel {
    //     attribute mode : OperatingMode;
    // }
} // package EgasArch_Common_Signals
