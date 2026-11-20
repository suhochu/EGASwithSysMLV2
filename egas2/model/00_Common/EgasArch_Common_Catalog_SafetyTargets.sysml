package EgasArch_Common_Catalog_SafetyTargets {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import SI::*;
    private import EgasArch_Common_Catalog_EgasStandard::torqueMonitorDetectionReactionBenchmark;
    private import ScalarValues::Integer;
    private import EgasArch_Common_Catalog_EgasStandard::qnaCycleMax;

    attribute sg01Asil : AsilLevel = AsilLevel::B {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e83";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "ASIL B is assigned to SZ-01 by EGAS.";
        }
    }

    attribute sg01Ftti : DurationQuantity = 1 [s] {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e87";
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
            itemId = "EGAS-e435";
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

    attribute l3WrongAnswerThreshold : Integer = 3 {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "Number of consecutive wrong Q&A answers to confirm an L3 fault; pilot assumption (A-19).";
        }
    }

    attribute l3Fdti : DurationQuantity = 240 [milli * s] {
        @SourceRef { document = "ISO 26262-1:2018"; itemId = "FTTI, FDTI and FRTI definitions"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "SG-01 path P3: l3WrongAnswerThreshold * qnaCycleMax = 240 ms, not approved (A-19).";
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

    assert constraint sudConfirmationWithinP1Fdti {
        doc
        /* SUD excess confirmation time stays within P1 FDTI. */
        sudConfirmationTime <= p1Fdti
    }

    assert constraint l3FdtiDerivation {
        doc
        /* L3 FDTI equals wrong-answer threshold multiplied by max Q&A cycle. */
        l3Fdti == l3WrongAnswerThreshold * qnaCycleMax
    }

    assert constraint p1TimingBudget {
        doc
        /* SG-01 path P1: FDTI plus FRTI stay within the FTTI. */
        p1Fdti + p1Frti <= sg01Ftti
    }

    assert constraint p3TimingBudget {
        doc
        /* SG-01 path P3: L3 FDTI plus L3 FRTI stay within the FTTI. */
        l3Fdti + l3Frti <= sg01Ftti
    }
} // package EgasArch_Common_Catalog_SafetyTargets
