package EgasArch_Safety_Goal {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import ScalarValues::*;

    requirement def UnintendedAccelerationGoal {
        doc
        /* Prevent unintended acceleration of the vehicle (EGAS safety goal SZ-01). */

        attribute asil : AsilLevel = AsilLevel::B {
            @SourceRef {
                document = "EGAS v6.0";
                itemId = "EGAS_e83";
            }
            @ValueStatus {
                status = ValueStatusKind::Standard;
                rationale = "ASIL B is assigned to SZ-01 by EGAS.";
            }
        }

        attribute ftti : String = "tbd" {
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
    }
} // package EgasArch_Safety_Goal
