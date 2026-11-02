package EgasArch_Obj_Objective {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;

    requirement def SafeTorqueObjective {
        doc
        /* EGAS torque control shall provide the requested torque without unintended acceleration. */
        @GoalData {
            kind = GoalKind::hard;
            refinement = GoalRefinementKind::AND;
        }
    }
} // package EgasArch_Obj_Objective
