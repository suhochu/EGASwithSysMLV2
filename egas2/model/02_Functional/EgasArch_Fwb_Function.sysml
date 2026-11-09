package EgasArch_Fwb_Function {
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Fbb_Function::*;

    action def CompareTorqueFunction {
        doc
        /* FN: compare the actual torque with the permissible torque and set the excess flag. Inner function of the TorqueComparison UF. */
        in permissibleTorque : TorqueQuantity;
        in actualTorque : TorqueQuantity;
        out excessDetected : Boolean;
    }

    action l2MonitorWb : TorqueComparisonFunction {
        action compareTorque : CompareTorqueFunction;
    }
} // package EgasArch_Fwb_Function
