package EgasArch_Common_Catalog_EgasStandard {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import ScalarValues::*;
    private import SI::*;

    @SourceRef {
        document = "EGAS v6.0";
        itemId = "EGAS_e369";
    }
    @ValueStatus {
        status = ValueStatusKind::Standard;
        rationale = "Maximum Q&A repetition interval specified by EGAS.";
    }
    attribute qnaCycleMax : DurationQuantity = 80 [milli * s];

    @SourceRef {
        document = "EGAS v6.0";
        itemId = "EGAS_e340, EGAS_e383";
    }
    @ValueStatus {
        status = ValueStatusKind::Standard;
        rationale = "Minimum number of Q&A questions specified by EGAS.";
    }
    attribute qnaQuestionCountMin : Integer = 10;

    @SourceRef {
        document = "EGAS v6.0";
        itemId = "EGAS_e435";
    }
    @ValueStatus {
        status = ValueStatusKind::Standard;
        rationale = "Example benchmark only; not a generally applicable response-time limit.";
    }
    attribute torqueMonitorDetectionReactionBenchmark : DurationQuantity = 500 [milli * s];

    @SourceRef {
        document = "EGAS v6.0";
        itemId = "EGAS_e403";
    }
    @ValueStatus {
        status = ValueStatusKind::Standard;
        rationale = "Shutdown-path test is performed once per driving cycle.";
    }
    attribute shutdownPathTestIntervalDriveCycles : Integer = 1;

    @SourceRef {
        document = "EGAS v6.0";
        itemId = "EGAS_e642";
    }
    @ValueStatus {
        status = ValueStatusKind::Standard;
        rationale = "Full ROM integrity test is performed before startup once per driving cycle.";
    }
    attribute romIntegrityTestIntervalDriveCycles : Integer = 1;

    @SourceRef {
        document = "EGAS v6.0";
        itemId = "EGAS_e404";
    }
    @ValueStatus {
        status = ValueStatusKind::Standard;
        rationale = "Engine operation is permitted only after the shutdown-path test succeeds.";
    }
    attribute engineStartRequiresSuccessfulShutdownPathTest : Boolean = true;
} // package EgasArch_Common_Catalog_EgasStandard
