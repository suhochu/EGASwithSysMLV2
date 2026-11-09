package EgasArch_Lwb_Logical {
    private import Allocations::*;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Beh_Behavior::TorqueDemand;
    private import EgasArch_Ctx_Context::*;
    private import EgasArch_Sysr_Requirement::*;
    private import EgasArch_Fbb_Function::*;
    private import EgasArch_Fwb_Function::*;
    private import EgasArch_Lbb_Logical::LogicalEgasSystem;

    // Channel ports between logical components; the receiver uses the conjugate.
    port def PedalFaultPort {
        out item pedalFault : PedalFaultStatus;
    }

    port def SafeStateRequestPort {
        out item safeStateRequest : SafeStateRequest;
    }

    port def ModeChannelPort {
        out item modeChannel : ModeChannel;
    }

    port def TorqueDemandPort {
        out item demand : TorqueDemand;
    }

    part def L1InputDiagnosticsComponent {
        doc
        /* LC: L1 input diagnostics of the pedal value sensor channels (UF-04). */
        port accelerationInput : AccelerationInputPort;
        port pedalFaultOut : PedalFaultPort;
    }

    part def L1ControlComponent {
        doc
        /* LC: L1 function that arbitrates, limits and outputs the torque demand (UF-05, UF-06, UF-07). */
        port accelerationInput : AccelerationInputPort;
        port brakeInput : BrakeInputPort;
        port torqueIntervention : TorqueInterventionPort;
        port sensorInput : SensorInputPort;
        port airIntake : AirIntakePort;
        port fuelCommand : FuelCommandPort;
        port pedalFaultIn : ~PedalFaultPort;
        port safeStateRequestIn : ~SafeStateRequestPort;
        port safeDemandIn : ~TorqueDemandPort;
        port modeChannelOut : ModeChannelPort;
        port demandOut : TorqueDemandPort;
    }

    part def L2MonitorComponent {
        doc
        /* LC: L2 function monitor that compares the torques and confirms an excess independently of the L1 function (UF-01, UF-02). */
        port accelerationInput : AccelerationInputPort;
        port sensorInput : SensorInputPort;
        port torqueMonitor : TorqueMonitorPort;
        port safeStateRequestOut : SafeStateRequestPort;
    }

    part def L2ReactionComponent {
        doc
        /* LC: L2 reaction that forces the safe state demand and warns the driver (UF-03). */
        port dashboardOutput : DashboardPort;
        port safeStateRequestIn : ~SafeStateRequestPort;
        port modeChannelIn : ~ModeChannelPort;
        port demandIn : ~TorqueDemandPort;
        port safeDemandOut : TorqueDemandPort;
    }

    part logicalEgasWb : LogicalEgasSystem {
        part l1InputDiagnostics : L1InputDiagnosticsComponent;
        part l1Control : L1ControlComponent;
        part l2Monitor : L2MonitorComponent;
        part l2Reaction : L2ReactionComponent;

        // Boundary ports delegate to the logical components.
        connect accelerationInput to l1InputDiagnostics.accelerationInput;
        connect accelerationInput to l1Control.accelerationInput;
        connect accelerationInput to l2Monitor.accelerationInput;
        connect brakeInput to l1Control.brakeInput;
        connect torqueIntervention to l1Control.torqueIntervention;
        connect sensorInput to l1Control.sensorInput;
        connect sensorInput to l2Monitor.sensorInput;
        connect torqueMonitor to l2Monitor.torqueMonitor;
        connect l1Control.airIntake to airIntake;
        connect l1Control.fuelCommand to fuelCommand;
        connect l2Reaction.dashboardOutput to dashboardOutput;

        // Channels between the logical components, projected from the UF flows.
        connect l1InputDiagnostics.pedalFaultOut to l1Control.pedalFaultIn;
        connect l2Monitor.safeStateRequestOut to l1Control.safeStateRequestIn;
        connect l2Monitor.safeStateRequestOut to l2Reaction.safeStateRequestIn;
        connect l1Control.modeChannelOut to l2Reaction.modeChannelIn;
        connect l1Control.demandOut to l2Reaction.demandIn;
        connect l2Reaction.safeDemandOut to l1Control.safeDemandIn;
    }

    // FN allocation: every FN is allocated to one LC.
    allocation fn01 : Allocation allocate torqueComparisonWb.derivePermissibleTorque to logicalEgasWb.l2Monitor;
    allocation fn02 : Allocation allocate torqueComparisonWb.estimateActualTorque to logicalEgasWb.l2Monitor;
    allocation fn03 : Allocation allocate torqueComparisonWb.compareTorque to logicalEgasWb.l2Monitor;
    allocation fn04 : Allocation allocate excessConfirmationWb.confirmExcessPersistence to logicalEgasWb.l2Monitor;
    allocation fn05 : Allocation allocate excessConfirmationWb.issueSafeStateRequest to logicalEgasWb.l2Monitor;
    allocation fn06 : Allocation allocate safeStateEnforcementWb.forceSafeStateDemand to logicalEgasWb.l2Reaction;
    allocation fn07 : Allocation allocate safeStateEnforcementWb.raiseDriverWarning to logicalEgasWb.l2Reaction;
    allocation fn08 : Allocation allocate pedalSensorFaultDetectionWb.comparePedalChannels to logicalEgasWb.l1InputDiagnostics;
    allocation fn09 : Allocation allocate pedalSensorFaultDetectionWb.confirmPedalFault to logicalEgasWb.l1InputDiagnostics;
    allocation fn10 : Allocation allocate limpHomeTorqueLimitWb.evaluateLimpHomeCondition to logicalEgasWb.l1Control;
    allocation fn11 : Allocation allocate limpHomeTorqueLimitWb.limitTorqueDemand to logicalEgasWb.l1Control;

    // UF to LC mapping; UF-06 and UF-07 have no FN decomposition.
    allocation uf01 : Allocation allocate egasUf.torqueComparison to logicalEgasWb.l2Monitor;
    allocation uf02 : Allocation allocate egasUf.excessConfirmation to logicalEgasWb.l2Monitor;
    allocation uf03 : Allocation allocate egasUf.safeStateEnforcement to logicalEgasWb.l2Reaction;
    allocation uf04 : Allocation allocate egasUf.pedalSensorFaultDetection to logicalEgasWb.l1InputDiagnostics;
    allocation uf05 : Allocation allocate egasUf.limpHomeTorqueLimit to logicalEgasWb.l1Control;
    allocation uf06 : Allocation allocate egasUf.torqueArbitration to logicalEgasWb.l1Control;
    allocation uf07 : Allocation allocate egasUf.pedalOutputResponse to logicalEgasWb.l1Control;

    // LCs satisfy the SYSRs of their UFs; FNs do not satisfy directly.
    satisfy sysrTorqueComparison by logicalEgasWb.l2Monitor;
    satisfy sysrExcessConfirmation by logicalEgasWb.l2Monitor;
    satisfy sysrSafeStateEnforcement by logicalEgasWb.l2Reaction;
    satisfy sysrPedalSensorFaultDetection by logicalEgasWb.l1InputDiagnostics;
    satisfy sysrLimpHomeTorqueLimit by logicalEgasWb.l1Control;
    satisfy sysrBrakeOverrideTorque by logicalEgasWb.l1Control;
    satisfy sysrArbitrationPriority by logicalEgasWb.l1Control;
    satisfy sysrInterventionReduction by logicalEgasWb.l1Control;
    satisfy sysrInterventionRelease by logicalEgasWb.l1Control;
    satisfy sysrSteadyStateTracking by logicalEgasWb.l1Control;
    satisfy sysrPedalOutputResponse by logicalEgasWb.l1Control;
} // package EgasArch_Lwb_Logical
