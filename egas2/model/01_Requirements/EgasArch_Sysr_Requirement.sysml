package EgasArch_Sysr_Requirement {
    private import RequirementDerivation::*;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Beh_Behavior::*;

    requirement def TorqueComparisonRequirement {
        doc
        /* The L2 monitor shall compare the actual torque with the permissible torque and report an excess. Parent: MonitorTorqueRequirement. */
    }

    requirement parentShr : MonitorTorqueRequirement;
    requirement sysrTorqueComparison : TorqueComparisonRequirement;

    #derivation connection sysrDerivesFromShr {
        end #original ::> parentShr;
        end #derive ::> sysrTorqueComparison;
    }
    #derivation connection sysrDerivesFromBehavior {
        end #original ::> l2Behavior;
        end #derive ::> sysrTorqueComparison;
    }
} // package EgasArch_Sysr_Requirement
