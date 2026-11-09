package EgasArch_Common_Catalog_SafetyTargets {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import SI::*;

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
} // package EgasArch_Common_Catalog_SafetyTargets
