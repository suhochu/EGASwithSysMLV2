package EgasArch_Lbb_Logical {
    private import EgasArch_Ctx_Context::*;

    part def LogicalEgasSystem {
        doc
        /* Logical black box. It adopts the boundary of the functional black box and contains only ports. */
        port torqueMonitor : TorqueMonitorPort;
    }
} // package EgasArch_Lbb_Logical
