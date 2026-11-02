package EgasArch_Beh_Behavior {
    private import ModelingMetadata::*;

    state def L2MonitorBehavior {
        doc
        /* Monitoring state: compare torque values and move to the safe state when the excess is confirmed. */
        entry action;
        state monitoring;
        state excessSuspected;
        state safeState;

        transition first monitoring then excessSuspected;
        transition first excessSuspected then safeState;
    }

    state l2Behavior : L2MonitorBehavior;

    #refinement dependency behaviorRefinesShr
        from L2MonitorBehavior
        to EgasArch_Shr_Requirement::MonitorTorqueRequirement;
} // package EgasArch_Beh_Behavior
