package EgasArch_Lwb_Logical {
    private import Allocations::*;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Catalog_SafetyTargets::sg01Asil;
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

    part def AsilAllocatedComponent {
        doc
        /* LC with its ASIL. B is inherited from SG-01 (A-03); there is no decomposition because the independence of L1 and L2 is not demonstrated. */
        attribute asil : AsilLevel = sg01Asil;
        attribute asilOrigin : AsilOrigin = AsilOrigin::inherited;
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e90";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "ASIL B follows SG-01 and the FSR (A-03); the allocation to the LCs is pending user approval (OI-07).";
        }
    }

    part def L1InputDiagnosticsComponent :> AsilAllocatedComponent {
        doc
        /* LC: L1 input diagnostics of the pedal value sensor channels (UF-04). */
        @SafetyMechanism {
            kind = MechanismKind::plausibility;
            monitoringLevel = MonitoringLevel::L1;
            detects = "Fault of a pedal value sensor channel";
            derivedFrom = "sysrPedalSensorFaultDetection";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e105, EGAS_e107";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "EGAS requires the plausibility check (SReq-01, SReq-03); the level and the kind are a pilot assignment (OI-07).";
        }
        port accelerationInput : AccelerationInputPort;
        port pedalFaultOut : PedalFaultPort;
    }

    part def L1ControlComponent :> AsilAllocatedComponent {
        doc
        /* LC: L1 function that arbitrates the pedal, brake and intervention inputs, applies the limp home limit and gives the torque demand (UF-05, UF-06). */
        port accelerationInput : AccelerationInputPort;
        port brakeInput : BrakeInputPort;
        port torqueIntervention : TorqueInterventionPort;
        port pedalFaultIn : ~PedalFaultPort;
        port safeStateRequestIn : ~SafeStateRequestPort;
        port modeChannelOut : ModeChannelPort;
        port demandOut : TorqueDemandPort;
    }

    part def L2MonitorComponent :> AsilAllocatedComponent {
        doc
        /* LC: L2 function monitor that compares the torques and confirms an excess; it is intended to be independent of the L1 function, which is not demonstrated (UF-01, UF-02). */
        @SafetyMechanism {
            kind = MechanismKind::monitor;
            monitoringLevel = MonitoringLevel::L2;
            detects = "Torque excess caused by the L1 function";
            derivedFrom = "sysrTorqueComparison";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e117~e128";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "EGAS describes the L2 function monitoring; the assignment to this LC is a pilot choice (OI-07).";
        }
        port accelerationInput : AccelerationInputPort;
        port sensorInput : SensorInputPort;
        port torqueMonitor : TorqueMonitorPort;
        port safeStateRequestOut : SafeStateRequestPort;
    }

    part def L2ReactionComponent :> AsilAllocatedComponent {
        doc
        /* LC: L2 reaction that forces the safe state demand and warns the driver (UF-03). */
        port dashboardOutput : DashboardPort;
        port safeStateRequestIn : ~SafeStateRequestPort;
        port modeChannelIn : ~ModeChannelPort;
        port demandIn : ~TorqueDemandPort;
        port safeDemandOut : TorqueDemandPort;
    }

    part def L2OutputComponent :> AsilAllocatedComponent {
        doc
        /* LC: output stage of the air and fuel commands (UF-07). It is an independent reaction path, not an EGAS L2 monitoring function: the safe state demand reaches the actuators without passing the L1 function (EGAS e127). */
        port sensorInput : SensorInputPort;
        port airIntake : AirIntakePort;
        port fuelCommand : FuelCommandPort;
        port modeChannelIn : ~ModeChannelPort;
        port demandIn : ~TorqueDemandPort;
    }

    part logicalEgasWb : LogicalEgasSystem {
        part l1InputDiagnostics : L1InputDiagnosticsComponent;
        part l1Control : L1ControlComponent;
        part l2Monitor : L2MonitorComponent;
        part l2Reaction : L2ReactionComponent;
        part l2Output : L2OutputComponent;

        // Boundary ports delegate to the logical components.
        connect accelerationInput to l1InputDiagnostics.accelerationInput;
        connect accelerationInput to l1Control.accelerationInput;
        connect accelerationInput to l2Monitor.accelerationInput;
        connect brakeInput to l1Control.brakeInput;
        connect torqueIntervention to l1Control.torqueIntervention;
        connect sensorInput to l2Output.sensorInput;
        connect sensorInput to l2Monitor.sensorInput;
        connect torqueMonitor to l2Monitor.torqueMonitor;
        connect l2Output.airIntake to airIntake;
        connect l2Output.fuelCommand to fuelCommand;
        connect l2Reaction.dashboardOutput to dashboardOutput;

        // Channels between the logical components, projected from the UF flows.
        // The demand reaches l2Output only through l2Reaction, so the safe state demand does not pass l1Control; modeChannel, demand and safeStateRequest between L1 and L2 are FFI review targets.
        connect l1InputDiagnostics.pedalFaultOut to l1Control.pedalFaultIn;
        connect l2Monitor.safeStateRequestOut to l1Control.safeStateRequestIn;
        connect l2Monitor.safeStateRequestOut to l2Reaction.safeStateRequestIn;
        connect l1Control.modeChannelOut to l2Reaction.modeChannelIn;
        connect l1Control.modeChannelOut to l2Output.modeChannelIn;
        connect l1Control.demandOut to l2Reaction.demandIn;
        connect l2Reaction.safeDemandOut to l2Output.demandIn;
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
    allocation uf07 : Allocation allocate egasUf.pedalOutputResponse to logicalEgasWb.l2Output;

    // LCs satisfy the SYSRs of their UFs; FNs do not satisfy directly.
    satisfy sysrTorqueComparison by logicalEgasWb.l2Monitor;
    satisfy sysrExcessConfirmation by logicalEgasWb.l2Monitor;
    satisfy sysrSafeStateEnforcement by logicalEgasWb.l2Reaction;
    satisfy sysrSafeStateEnforcement by logicalEgasWb.l2Output;
    satisfy sysrPedalSensorFaultDetection by logicalEgasWb.l1InputDiagnostics;
    satisfy sysrLimpHomeTorqueLimit by logicalEgasWb.l1Control;
    satisfy sysrBrakeOverrideTorque by logicalEgasWb.l1Control;
    satisfy sysrArbitrationPriority by logicalEgasWb.l1Control;
    satisfy sysrInterventionReduction by logicalEgasWb.l1Control;
    satisfy sysrInterventionRelease by logicalEgasWb.l1Control;
    satisfy sysrSteadyStateTracking by logicalEgasWb.l1Control;
    satisfy sysrPedalOutputResponse by logicalEgasWb.l2Output;
} // package EgasArch_Lwb_Logical
