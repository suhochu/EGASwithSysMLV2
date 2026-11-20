package EgasArch_Safety_Goal {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Ctx_Context::*;
    private import ScalarValues::*;

    attribute def SecRating {
        attribute severity : SeverityClass;
        attribute exposure : ExposureClass;
        attribute controllability : ControllabilityClass;
    }

    item def HazardousEvent {
        doc
        /* One HARA row. rating is left out when EGAS excludes the hazardous event from consideration. */
        attribute safetyGoalId : SafetyGoalId;
        attribute hazard : String;
        attribute asil : AsilLevel;
        attribute rating : SecRating [0..1];
        attribute exclusionReason : String [0..1];
    }

    item haraSz01 : HazardousEvent {
        attribute :>> safetyGoalId = SafetyGoalId::'SZ-01';
        attribute :>> hazard = "Unintended vehicle acceleration";
        attribute :>> asil = AsilLevel::B;
        attribute :>> rating {
            attribute :>> severity = SeverityClass::S2;
            attribute :>> exposure = ExposureClass::E4;
            attribute :>> controllability = ControllabilityClass::C2;
            @SourceRef {
                document = "ISO 26262-3:2018";
                itemId = "Table 4";
            }
            @ValueStatus {
                status = ValueStatusKind::pilotAssumed;
                rationale =
                    "EGAS gives no S/E/C; S2, E4, C2 are chosen so that ISO 26262-3 Table 4 yields the EGAS ASIL B. Pending user approval.";
            }
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e83";
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "The safety goal, hazardous event, and ASIL are given by EGAS.";
        }
    }

    item haraSz02 : HazardousEvent {
        attribute :>> safetyGoalId = SafetyGoalId::'SZ-02';
        attribute :>> hazard = "Missing vehicle acceleration";
        attribute :>> asil = AsilLevel::QM;
        attribute :>> exclusionReason =
            "Controllable by the driver, so excluded from consideration.";
        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e84", "EGAS-e88");
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "ASIL QM and the exclusion are given by EGAS; S/E/C are not evaluated.";
        }
    }

    item haraSz03 : HazardousEvent {
        attribute :>> safetyGoalId = SafetyGoalId::'SZ-03';
        attribute :>> hazard = "Unintended vehicle deceleration";
        attribute :>> asil = AsilLevel::QM;
        attribute :>> exclusionReason =
            "Controllable by the driver, so excluded from consideration.";
        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e85", "EGAS-e88");
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "ASIL QM and the exclusion are given by EGAS; S/E/C are not evaluated.";
        }
    }

    item haraSz04 : HazardousEvent {
        attribute :>> safetyGoalId = SafetyGoalId::'SZ-04';
        attribute :>> hazard = "Missing vehicle deceleration";
        attribute :>> asil = AsilLevel::QM;
        attribute :>> exclusionReason =
            "Controllable by the driver, so excluded from consideration.";
        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e86", "EGAS-e88");
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale = "ASIL QM and the exclusion are given by EGAS; S/E/C are not evaluated.";
        }
    }

    requirement def SafetyGoal {
        subject egas : EgasSystem;
        attribute ftti : DurationQuantity;
        attribute asil : AsilLevel;
        item hazardousEvent : HazardousEvent;
        ref state safeState : SafeState [1..*];
    }

    requirement <sg01> UnintendedAccelerationGoal : SafetyGoal {
        doc
        /* Prevent unintended acceleration of the vehicle (EGAS safety goal SZ-01); ASIL and FTTI come from Catalog_SafetyTargets. */
        frame concern unintendedAcceleration
            : EgasArch_Needs_Concern::UnintendedAccelerationConcern;

        subject :>> egas : EgasSystem;
        :>> ftti : DurationQuantity = EgasArch_Common_Catalog_SafetyTargets::sg01Ftti;
        :>> hazardousEvent : HazardousEvent = haraSz01;
        :>> asil : AsilLevel = hazardousEvent.asil;
        :>> safeState = (egas.torqueLimited, egas.fuelCutOff, egas.fullCutOff);

        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS-e87";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "Covers safeState only; ASIL and FTTI status are in the catalog. EGAS requires a safe state but does not name the stage. TorqueLimited is a pilot choice and may not remove the hazard if the torque path itself fails; T12 and T19 must confirm. Pending user approval.";
        }
    }
} // package EgasArch_Safety_Goal
