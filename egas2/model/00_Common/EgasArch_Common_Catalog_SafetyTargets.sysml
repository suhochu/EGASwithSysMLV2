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

    attribute sudConfirmationTime : DurationQuantity = 100 [milli * s] {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "SUD excess confirmation time inside p1Fdti: EGAS gives no value; pilot candidate slightly above qnaCycleMax 80 ms, not approved (A-19).";
        }
    }

    attribute l3Fdti : DurationQuantity = 240 [milli * s] {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "SG-01 path P3 (Q&A wrong answer to shut off): EGAS gives no value; pilot candidate 3 wrong answers x qnaCycleMax 80 ms = 240 ms, the count 3 is an assumption, not approved (A-19).";
        }
    }

    attribute l3Frti : DurationQuantity = 300 [milli * s] {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "SG-01 path P3: EGAS gives no shut off reaction time; pilot candidate equal to p1Frti 300 ms, not approved (A-19). The sum 540 ms leaves 460 ms to sg01Ftti.";
        }
    }

    constraint p1TimingBudget {
        doc
        /* SG-01 path P1: FDTI plus FRTI stay within the FTTI. */
        p1Fdti + p1Frti <= sg01Ftti
    }

    constraint p3TimingBudget { l3Fdti + l3Frti <= sg01Ftti }
} // package EgasArch_Common_Catalog_SafetyTargets
