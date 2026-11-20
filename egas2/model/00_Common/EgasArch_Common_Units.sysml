package EgasArch_Common_Units {
    private import ISQ::*;
    private import ScalarValues::*;

    attribute def DurationQuantity :> ISQ::DurationValue;
    attribute def TorqueQuantity :> ISQ::TorqueValue;
    attribute def MassFlowRateQuantity :> ISQ::MassFlowRateValue;
    attribute def AngularVelocityQuantity :> ISQ::AngularVelocityValue;
    attribute def PressureQuantity :> ISQ::PressureValue;
    attribute def SpeedQuantity :> ISQ::SpeedValue;

    alias PercentQuantity for Real;
} // package EgasArch_Common_Units
