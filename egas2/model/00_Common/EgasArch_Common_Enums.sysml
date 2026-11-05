package EgasArch_Common_Enums {
    enum def AsilLevel {
        enum QM;
        enum A;
        enum B;
        enum C;
        enum D;
    }

    enum def SeverityClass {
        enum S0;
        enum S1;
        enum S2;
        enum S3;
    }

    enum def ExposureClass {
        enum E0;
        enum E1;
        enum E2;
        enum E3;
        enum E4;
    }

    enum def ControllabilityClass {
        enum C0;
        enum C1;
        enum C2;
        enum C3;
    }

    enum def MonitoringLevel {
        enum L1;
        enum L2;
        enum L3;
    }

    enum def SafeStateStage {
        enum TorqueLimited;
        enum FuelCutOff;
        enum FullCutOff;
    }

    enum def FaultClass {
        enum single;
        enum dual;
        enum double;
        enum latent;
    }

    enum def DefectState {
        enum assumed;
        enum confirmed;
    }

    enum def ReactionKind {
        enum limpHome;
        enum injectionCutOff;
        enum softwareReset;
        enum hardwareReset;
        enum powerStageShutoff;
    }

    enum def ValueStatusKind {
        enum Standard;
        enum project;
        enum pilotAssumed;
        enum tbd;
        enum reviewed;
    }

    enum def GoalKind {
        enum hard;
        enum soft;
    }

    enum def GoalRefinementKind {
        enum AND;
        enum OR;
    }

    enum def ScenarioKind {
        enum main;
        enum alternative;
        enum exception;
    }
} // package EgasArch_Common_Enums
