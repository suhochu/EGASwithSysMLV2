package EgasArch_Ctx_Context {
    port def TorqueMonitorPort;

    part def EgasSystem {
        doc
        /* Black box of the EGAS engine control system. Internal structure belongs to the functional and logical viewpoints. */
        port torqueMonitor : TorqueMonitorPort;
    }
} // package EgasArch_Ctx_Context
