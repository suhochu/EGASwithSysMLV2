package EgasArch_Lwb_Logical {
    private import Allocations::*;
    private import EgasArch_Sysr_Requirement::*;
    private import EgasArch_Fwb_Function::*;

    part def L2MonitorComponent {
        doc
        /* LC: logical component that runs the L2 torque monitor independently of the L1 function. */
    }

    part l2MonitorComponent : L2MonitorComponent;
    satisfy requirement lcTorqueComparison : TorqueComparisonRequirement by l2MonitorComponent;
    allocation compareTorqueToMonitor : Allocation allocate l2MonitorWb.compareTorque to l2MonitorComponent;
} // package EgasArch_Lwb_Logical
