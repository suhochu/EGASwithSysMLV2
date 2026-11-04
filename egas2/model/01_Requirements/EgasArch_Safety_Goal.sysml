package EgasArch_Safety_Goal {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Common_Catalog_SafetyTargets::*;
    private import ScalarValues::*;

    attribute def SecRating {
        attribute severity : SeverityClass;
        attribute exposure : ExposureClass;
        attribute controllability : ControllabilityClass;
    }

    item def HazardousEvent {
        doc
        /* One HARA row. rating is left out when EGAS excludes the hazardous event from consideration. */
        attribute zone : String;
        attribute hazard : String;
        attribute asil : AsilLevel;
        attribute rating : SecRating [0..1];
        attribute exclusionReason : String [0..1];
    }

    item haraSz01 : HazardousEvent {
        attribute :>> zone = "SZ-01";
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
        item pedalInput : AccelerationPedalPosition;
        item airOutput : IntakeAirFlow;
        item fuelOutput : FuelIgnitionCommand;
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e83";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale = "The zone, hazardous event, and ASIL are given by EGAS.";
        }
    }

    item haraSz02 : HazardousEvent {
        attribute :>> zone = "SZ-02";
        attribute :>> hazard = "Missing vehicle acceleration";
        attribute :>> asil = AsilLevel::QM;
        attribute :>> exclusionReason =
            "Controllable by the driver, so excluded from consideration.";
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e84, EGAS_e88";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale = "ASIL QM and the exclusion are given by EGAS; S/E/C are not evaluated.";
        }
    }

    item haraSz03 : HazardousEvent {
        attribute :>> zone = "SZ-03";
        attribute :>> hazard = "Unintended vehicle deceleration";
        attribute :>> asil = AsilLevel::QM;
        attribute :>> exclusionReason =
            "Controllable by the driver, so excluded from consideration.";
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e85, EGAS_e88";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale = "ASIL QM and the exclusion are given by EGAS; S/E/C are not evaluated.";
        }
    }

    item haraSz04 : HazardousEvent {
        attribute :>> zone = "SZ-04";
        attribute :>> hazard = "Missing vehicle deceleration";
        attribute :>> asil = AsilLevel::QM;
        attribute :>> exclusionReason =
            "Controllable by the driver, so excluded from consideration.";
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e86, EGAS_e88";
        }
        @ValueStatus {
            status = ValueStatusKind::Standard;
            rationale = "ASIL QM and the exclusion are given by EGAS; S/E/C are not evaluated.";
        }
    }

    requirement def UnintendedAccelerationGoal {
        doc
        /* Prevent unintended acceleration of the vehicle (EGAS safety goal SZ-01); ASIL and FTTI come from Catalog_SafetyTargets. */
        attribute asil : AsilLevel = sg01Asil;
        attribute ftti : DurationQuantity = sg01Ftti;
        @SafetyGoalData {
            asil = sg01Asil;
            hazardousEvent = "SZ-01";
            safeState = SafeStateStage::TorqueLimited;
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e87";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "Covers safeState only; ASIL and FTTI status are in the catalog. EGAS requires a safe state but does not name the stage. TorqueLimited is a pilot choice and may not remove the hazard if the torque path itself fails; T12 and T19 must confirm. Pending user approval.";
        }
    }
} // package EgasArch_Safety_Goal
