package EgasArch_Shr_Requirement {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Needs_Concern::*;
    private import EgasArch_Safety_Goal::*;

    requirement def MonitorTorqueRequirement :> UnintendedAccelerationGoal {
        doc
        /* The system shall detect an actual torque above the permissible torque and move to a safe state (derived from EGAS SReq-06). */
        frame concern unintendedAcceleration : UnintendedAccelerationConcern;
        @GoalData {
            kind = GoalKind::hard;
            refinement = GoalRefinementKind::AND;
        }
    }
} // package EgasArch_Shr_Requirement
