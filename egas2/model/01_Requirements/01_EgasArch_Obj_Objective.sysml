package EgasArch_Obj_Objective {
    doc
    /* 문제: 동시에 상충하는 토크 요구와 결함이 의도하지 않은 가속으로 이어질 수 있다. 아이디어: EGAS가 모든 토크 요구를 중앙에서 안전 우선으로 중재한다. */
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

    requirement def ResponsiveTorqueObjective {
        doc
        /* EGAS torque control shall deliver the requested torque precisely and with a predictable pedal response. */
        @GoalData {
            kind = GoalKind::soft;
            refinement = GoalRefinementKind::AND;
        }
    }
} // package EgasArch_Obj_Objective
