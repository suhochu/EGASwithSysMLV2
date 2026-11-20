package EgasArch_Sysr_L2Monitor {
    private import RequirementDerivation::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Catalog_SafetyTargets::sg01Asil;
    private import EgasArch_Sysr_Requirement::sysrTorqueComparison;
    private import EgasArch_Sysr_Requirement::sysrExcessConfirmation;

    // SUD l2Monitor: the second abstraction level. Its functional decomposition is UF-01, UF-02 and FN-01~05, reused from Fbb and Fwb.
    requirement def SudTorqueComparisonRequirement {
        doc
        /* The L2 monitor shall judge a torque excess when the estimated actual torque exceeds the permissible torque derived from the pedal position. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "sysrTorqueComparison";
        }
        @AbstractionLayer { layer = 1; }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e105", "EGAS-e106", "EGAS-e107", "EGAS-e108", "EGAS-e109",
                "EGAS-e110", "EGAS-e111", "EGAS-e117", "EGAS-e118", "EGAS-e119",
                "EGAS-e120", "EGAS-e121", "EGAS-e122", "EGAS-e123", "EGAS-e124",
                "EGAS-e125", "EGAS-e126", "EGAS-e127", "EGAS-e128"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::reviewed;
            rationale =
                "ASIL B is inherited from the TSR it refines (FSR-01, SG-01, EGAS e83); the split into SUD level requirements is a pilot derivation approved by A-18.";
        }
    }

    requirement def SudExcessConfirmationRequirement {
        doc
        /* The L2 monitor shall confirm a judged excess before it issues the safe state request. Persistence over a confirmation time is a pilot design choice; the time is the pilotAssumed catalog value sudConfirmationTime and is part of the detection time p1Fdti. */
        @SafetyRequirementData {
            level = SafetyRequirementLevel::TSR;
            asil = sg01Asil;
            asilOrigin = AsilOrigin::inherited;
            derivedFrom = "sysrExcessConfirmation";
        }
        @AbstractionLayer { layer = 1; }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e105", "EGAS-e106", "EGAS-e107", "EGAS-e108", "EGAS-e109",
                "EGAS-e110", "EGAS-e111"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B is inherited from the TSR it refines (FSR-01, SG-01, EGAS e83); EGAS gives no confirmation time; sudConfirmationTime is a pilot candidate. Not approved (A-18, A-19).";
        }
    }

    requirement sudTorqueComparison : SudTorqueComparisonRequirement;
    requirement sudExcessConfirmation : SudExcessConfirmationRequirement;

    #derivation connection sudTorqueComparisonFromSysr {
        end #original ::> sysrTorqueComparison;
        end #derive ::> sudTorqueComparison;
    }
    #derivation connection sudExcessConfirmationFromSysr {
        end #original ::> sysrExcessConfirmation;
        end #derive ::> sudExcessConfirmation;
    }
} // package EgasArch_Sysr_L2Monitor
