package EgasArch_Common_Catalog_SafetyTargets {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import SI::*;
    private import EgasArch_Common_Catalog_EgasStandard::torqueMonitorDetectionReactionBenchmark;

    attribute sg01Asil : AsilLevel = AsilLevel::B {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e83";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale = "ASIL B is assigned to SZ-01 by EGAS.";
        }
    }

    attribute sg01Ftti : DurationQuantity = 1 [s] {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e87";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "EGAS requires a safe-state transition within a permissible time but gives no FTTI value; 1 s is a pilot value chosen by the AI at the T16 Gate-F on user request, above the 500 ms detection and reaction benchmark, and not approved.";
        }
    }

    // Timing budget of path P1 (torque excess to TorqueLimited), requirement level only: FDTI + FRTI <= FTTI.
    // Path P2 (pedal fault to limp home) has no timing in SG-01, so its FDTI, FRTI and FTTI stay tbd and have no value.
    attribute p1Fdti : DurationQuantity = torqueMonitorDetectionReactionBenchmark {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e435";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The pilot reads the EGAS detection and reaction benchmark as the fault detection time; with the pilot FRTI and FTTI the budget is a self-fulfilling assumption, not approved.";
        }
    }

    attribute p1Frti : DurationQuantity = 300 [milli * s] {
        @SourceRef {
            document = "ISO 26262-1:2018";
            itemId = "FTTI, FDTI and FRTI definitions";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The standard gives the relation, not a value. EGAS gives no fault reaction time; 300 ms leaves a 200 ms margin to the pilot FTTI sg01Ftti and is not approved.";
        }
    }

    attribute l3Fdti : DurationQuantity {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::tbd;
            rationale =
                "SG-01 path P3 (Q&A wrong answer to shut off): EGAS gives no value; it depends on the Q&A cycle qnaCycleMax and the confirmation count (OI-23, OI-27).";
        }
    }

    attribute l3Frti : DurationQuantity {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::tbd;
            rationale =
                "SG-01 path P3: EGAS gives no shut off reaction time; the constraint l3Fdti + l3Frti <= sg01Ftti is added when both are set (OI-23).";
        }
    }

    constraint p1TimingBudget {
        doc
        /* SG-01 path P1: FDTI plus FRTI stay within the FTTI. */
        p1Fdti + p1Frti <= sg01Ftti
    }
} // package EgasArch_Common_Catalog_SafetyTargets
