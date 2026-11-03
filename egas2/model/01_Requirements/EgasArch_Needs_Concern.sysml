package EgasArch_Needs_Concern {
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Obj_Objective::*;
    private import EgasArch_Needs_Stakeholder::*;

    // hard concerns refine SafeTorqueObjective, soft concerns refine ResponsiveTorqueObjective
    concern def UnintendedAccelerationConcern :> SafeTorqueObjective {
        doc
        /* Occupants and the safety regulator are concerned that the engine accelerates without a driver request. */
        subject egasSystem;
        stakeholder driver : Driver;
        stakeholder safetyRegulator : SafetyRegulator;
    }

    concern def HardwareFailureConcern :> SafeTorqueObjective {
        doc
        /* A sensor or actuator fault shall not cause unintended acceleration; a safe state shall be guaranteed. */
        subject egasSystem;
        stakeholder safetyRegulator : SafetyRegulator;
    }

    concern def FunctionalSafetyConcern :> SafeTorqueObjective {
        doc
        /* Compliance with the functional safety standard shall be demonstrated so that faults do not injure people. */
        subject egasSystem;
        stakeholder safetyRegulator : SafetyRegulator;
    }

    concern def TorqueArbitrationConcern :> SafeTorqueObjective {
        doc
        /* Conflicting torque requests and simultaneous brake and accelerator operation shall not cost the driver control of the vehicle. */
        subject egasSystem;
        stakeholder driver : Driver;
        stakeholder platformEngineer : PlatformEngineer;
    }

    concern def PreciseControlConcern :> ResponsiveTorqueObjective {
        doc
        /* The error between the requested torque and the engine torque shall be small and without delay. */
        subject egasSystem;
        stakeholder driver : Driver;
    }

    concern def DrivabilityAndResponseConcern :> ResponsiveTorqueObjective {
        doc
        /* The vehicle shall respond to pedal input immediately and predictably, without jerk. */
        subject egasSystem;
        stakeholder driver : Driver;
    }

    #GoalConflict dependency arbitrationConflictsDrivability
        from TorqueArbitrationConcern
        to DrivabilityAndResponseConcern {
        doc
        /* Brake override limits output at once and causes jerk. Safety wins; the jerk criterion is waived during the intervention. */
    }
    #GoalConflict dependency hardwareFailureConflictsDrivability
        from HardwareFailureConcern
        to DrivabilityAndResponseConcern {
        doc
        /* A fault reaction cuts air and fuel at once and causes jerk. Safety wins once a critical fault is confirmed. */
    }
    #GoalContribution dependency preciseControlSupportsDrivability
        from PreciseControlConcern
        to DrivabilityAndResponseConcern {
        doc
        /* Less steady-state error and overshoot also reduce jerk during acceleration and deceleration. */
    }
} // package EgasArch_Needs_Concern
