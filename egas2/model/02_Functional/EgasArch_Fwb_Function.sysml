package EgasArch_Fwb_Function {
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Fbb_Function::*;

    action def CompareTorqueFunction {
        doc
        /* FN: compare the actual torque with the permissible torque and set the excess flag. Inner function of the L2 monitor UF. */
        in permissibleTorque : TorqueQuantity;
        in actualTorque : TorqueQuantity;
        out excessDetected : Boolean;
    }

    action l2MonitorWb : L2MonitorFunction {
        action compareTorque : CompareTorqueFunction;
    }
} // package EgasArch_Fwb_Function
