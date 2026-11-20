package EgasArch_Common_Catalog_EgasStandard {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import ScalarValues::*;
    private import SI::*;

    attribute qnaCycleMax : DurationQuantity = 80 [milli * s] {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e369";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "Maximum Q&A repetition interval specified by EGAS.";
        }
    }

    attribute qnaQuestionCountMin : Integer = 10 {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e340", "EGAS-e383");
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "Minimum number of Q&A questions specified by EGAS.";
        }
    }

    attribute torqueMonitorDetectionReactionBenchmark : DurationQuantity = 500 [milli * s] {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e435";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "Example benchmark only; not a generally applicable response-time limit.";
        }
    }

    attribute shutdownPathTestIntervalDriveCycles : Integer = 1 {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e403";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "Shutdown-path test is performed once per driving cycle.";
        }
    }

    attribute romIntegrityTestIntervalDriveCycles : Integer = 1 {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e642";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale =
                "Full ROM integrity test is performed before startup once per driving cycle.";
        }
    }

    attribute engineStartRequiresSuccessfulShutdownPathTest : Boolean = true {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e404";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "Engine operation is permitted only after the shutdown-path test succeeds.";
        }
    }
} // package EgasArch_Common_Catalog_EgasStandard
