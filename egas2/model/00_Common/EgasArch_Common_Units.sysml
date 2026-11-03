package EgasArch_Common_Units {
    private import ISQ::*;
    private import ScalarValues::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;

    attribute def DurationQuantity :> ISQ::DurationValue;
    attribute def TorqueQuantity :> ISQ::TorqueValue;
    attribute def SpeedQuantity :> ISQ::SpeedValue;
    attribute def MassFlowRateQuantity :> ISQ::MassFlowRateValue;
    attribute def FailureRateQuantity :> ISQ::FrequencyValue;
    attribute def PercentQuantity :> Real;
    attribute def AngularVelocityQuantity :> ISQ::AngularVelocityValue;

    attribute fitToFailuresPerHourFactor : Real = 0.000000001 {
        @SourceRef {
            document = "EGAS SysML pilot DESIGN_MAP.md";
            itemId = "Common_Units/FIT";
        }
        @ValueStatus {
            status = ValueStatusKind::project;
            rationale = "Project conversion convention: 1 FIT equals 1e-9 failures per hour.";
        }
    }
} // package EgasArch_Common_Units
