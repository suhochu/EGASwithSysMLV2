package EgasArch_Common_Catalog_SafetyTargets {
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;

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

    attribute sg01Ftti : DurationQuantity {
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e87";
        }
        @ValueStatus {
            status = ValueStatusKind::tbd;
            rationale =
                "EGAS requires a safe-state transition within a permissible time but gives no FTTI value.";
        }
    }
} // package EgasArch_Common_Catalog_SafetyTargets
