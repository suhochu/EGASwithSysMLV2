package EgasArch_Lwb_L2Monitor {
    private import Allocations::*;
    private import EgasArch_Common_Units::TorqueQuantity;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Ctx_Context::*;
    private import EgasArch_Sysr_L2Monitor::*;
    private import EgasArch_Fwb_Function::*;
    private import EgasArch_Lwb_Logical::L2MonitorComponent;
    private import EgasArch_Lwb_Logical::AsilAllocatedComponent;
    private import EgasArch_Lwb_Logical::SafeStateRequestPort;

    // A value channel; Common_Signals has no torque item, so the port carries an attribute.
    port def TorqueValuePort {
        out attribute torque : TorqueQuantity;
    }

    part def L2MonitorUnitComponent :> AsilAllocatedComponent {
        doc
        /* LC: one unit of the L2 monitor SUD. ASIL B is inherited with no ASIL decomposition; independence between units, FFI, FIT and DC are not modeled. */
        @AbstractionLayer { layer = 1; }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e117~e128";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "The split of the L2 monitor into three units is a pilot choice; ASIL B is inherited (OI-07).";
        }
    }

    part def L2MonitorSudComponent :> L2MonitorComponent {
        doc
        /* SUD l2Monitor: the BB is the L2MonitorComponent, the functional WB is UF-01, UF-02 and FN-01~05 reused unchanged. The ports of the parent are delegated to the units. The shared input CCFs are those of l2Monitor (ccfShared*); the independence of L1 and L2 stays undemonstrated. */
        @AbstractionLayer { layer = 1; }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e117~e128";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "SPES 3.4.1 abstraction step applied to one LC as a pilot demonstration (T22); not an EGAS requirement.";
        }
        part permissibleTorqueUnit : L2MonitorUnitComponent {
            port accelerationInput : AccelerationInputPort;
            port permissibleOut : TorqueValuePort;
        }
        part actualTorqueUnit : L2MonitorUnitComponent {
            port sensorInput : SensorInputPort;
            port actualOut : TorqueValuePort;
        }
        part excessJudgeUnit : L2MonitorUnitComponent {
            port permissibleIn : ~TorqueValuePort;
            port actualIn : ~TorqueValuePort;
            port torqueMonitor : TorqueMonitorPort;
            port safeStateRequestOut : SafeStateRequestPort;
        }

        bind accelerationInput = permissibleTorqueUnit.accelerationInput;
        bind sensorInput = actualTorqueUnit.sensorInput;
        bind torqueMonitor = excessJudgeUnit.torqueMonitor;
        bind safeStateRequestOut = excessJudgeUnit.safeStateRequestOut;
        connect permissibleTorqueUnit.permissibleOut to excessJudgeUnit.permissibleIn;
        connect actualTorqueUnit.actualOut to excessJudgeUnit.actualIn;
    }

    // l2MonitorSud refines logicalEgasWb.l2Monitor one level down; it is not a second monitor, and sudFn01~05 refine fn01~05.
    part l2MonitorSud : L2MonitorSudComponent;

    allocation sudFn01 : Allocation
        allocate torqueComparisonWb.derivePermissibleTorque to l2MonitorSud.permissibleTorqueUnit;
    allocation sudFn02 : Allocation
        allocate torqueComparisonWb.estimateActualTorque to l2MonitorSud.actualTorqueUnit;
    allocation sudFn03 : Allocation
        allocate torqueComparisonWb.compareTorque to l2MonitorSud.excessJudgeUnit;
    allocation sudFn04 : Allocation
        allocate excessConfirmationWb.confirmExcessPersistence to l2MonitorSud.excessJudgeUnit;
    allocation sudFn05 : Allocation
        allocate excessConfirmationWb.issueSafeStateRequest to l2MonitorSud.excessJudgeUnit;

    satisfy sudTorqueComparison by l2MonitorSud.permissibleTorqueUnit;
    satisfy sudTorqueComparison by l2MonitorSud.actualTorqueUnit;
    satisfy sudTorqueComparison by l2MonitorSud.excessJudgeUnit;
    satisfy sudExcessConfirmation by l2MonitorSud.excessJudgeUnit;
} // package EgasArch_Lwb_L2Monitor
