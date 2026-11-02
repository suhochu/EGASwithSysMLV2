package EgasArch_Fbb_Function {
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Sysr_Requirement::*;

    action def L2MonitorFunction {
        doc
        /* UF: monitor the torque by comparing the actual with the permissible value. Observable at the system boundary. */
        in permissibleTorque : TorqueQuantity;
        in actualTorque : TorqueQuantity;
        out excessDetected : Boolean;
    }

    action l2Monitor : L2MonitorFunction;
    satisfy requirement torqueComparison : TorqueComparisonRequirement by l2Monitor;
} // package EgasArch_Fbb_Function
