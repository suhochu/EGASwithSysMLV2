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

    port def ShutOffPort {
        out item shutOffRequest : ShutOffRequest;
    }

    port def QnaPort {
        out item question : QnaQuestion;
        in item answer : QnaAnswer;
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
        /* LC: L1 function that arbitrates the pedal, brake and intervention inputs, applies the limp home limit and gives the torque demand (UF-05, UF-06) and answers the Q&A of l3Monitor (UF-09). */
        port accelerationInput : AccelerationInputPort;
        port brakeInput : BrakeInputPort;
        port torqueIntervention : TorqueInterventionPort;
        port pedalFaultIn : ~PedalFaultPort;
        port safeStateRequestIn : ~SafeStateRequestPort;
        port demandOut : TorqueDemandPort;
        port qnaPartnerPort : ~QnaPort;
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
        port demandIn : ~TorqueDemandPort;
        port safeDemandOut : TorqueDemandPort;
    }

    part def L2OutputComponent :> AsilAllocatedComponent {
        doc
        /* LC: output stage of the air and fuel commands (UF-07). It is an independent reaction path, not an EGAS L2 monitoring function: the safe state demand reaches the actuators without passing the L1 function (EGAS e127), and the shut off request of l3Monitor reaches it without passing L1 or L2. The output stage itself is shared by both paths. */
        port sensorInput : SensorInputPort;
        port airIntake : AirIntakePort;
        port fuelCommand : FuelCommandPort;
        port shutOffIn : ~ShutOffPort;
        port demandIn : ~TorqueDemandPort;
    }

    part def L3MonitorComponent :> AsilAllocatedComponent {
        doc
        /* LC: independent monitoring module that asks the function controller questions and shuts the engine off on a wrong answer (UF-08). It has no channel from the L1 or L2 components and no shared input port, except the Q&A channel to l1Control; an L1 fault that corrupts or stops the answering is detected by a wrong or missing answer; wrong L1 torque values are L2 targets. */
        @SafetyMechanism {
            kind = MechanismKind::questionAnswer;
            monitoringLevel = MonitoringLevel::L3;
            detects = "Wrong or missing answers of the function controller to the Q&A";
            derivedFrom = "sysrControllerMonitoring";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e111, EGAS_e117~e128, EGAS_e340, EGAS_e369, EGAS_e383";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "EGAS describes the L3 controller monitoring by Q&A (SReq-07); the assignment to this LC and the level are a pilot choice (OI-07).";
        }
        port qnaPort : QnaPort;
        port shutOffOut : ShutOffPort;
    }

    part logicalEgasWb : LogicalEgasSystem {
        part l1InputDiagnostics : L1InputDiagnosticsComponent;
        part l1Control : L1ControlComponent;
        part l2Monitor : L2MonitorComponent;
        part l2Reaction : L2ReactionComponent;
        part l2Output : L2OutputComponent;
        part l3Monitor : L3MonitorComponent;

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
        // The demand reaches l2Output only through l2Reaction, so the safe state demand does not pass l1Control; demand and safeStateRequest between L1 and L2 are FFI review targets.
        // The shut off request reaches l2Output only from l3Monitor and does not pass l1 or l2; the path is independent only up to the l2Output input. The Q&A is a separate channel between l3Monitor and l1Control and is also an FFI review target.
        connect l1InputDiagnostics.pedalFaultOut to l1Control.pedalFaultIn;
        connect l2Monitor.safeStateRequestOut to l1Control.safeStateRequestIn;
        connect l2Monitor.safeStateRequestOut to l2Reaction.safeStateRequestIn;
        connect l1Control.demandOut to l2Reaction.demandIn;
        connect l2Reaction.safeDemandOut to l2Output.demandIn;
        connect l3Monitor.shutOffOut to l2Output.shutOffIn;
        connect l3Monitor.qnaPort to l1Control.qnaPartnerPort;
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
    allocation fn12 : Allocation allocate controllerMonitoringWb.checkQnaAnswer to logicalEgasWb.l3Monitor;
    allocation fn13 : Allocation allocate controllerMonitoringWb.requestShutOff to logicalEgasWb.l3Monitor;

    // UF to LC mapping; UF-06, UF-07 and UF-09 have no FN decomposition.
    allocation uf01 : Allocation allocate egasUf.torqueComparison to logicalEgasWb.l2Monitor;
    allocation uf02 : Allocation allocate egasUf.excessConfirmation to logicalEgasWb.l2Monitor;
    allocation uf03 : Allocation allocate egasUf.safeStateEnforcement to logicalEgasWb.l2Reaction;
    allocation uf04 : Allocation allocate egasUf.pedalSensorFaultDetection to logicalEgasWb.l1InputDiagnostics;
    allocation uf05 : Allocation allocate egasUf.limpHomeTorqueLimit to logicalEgasWb.l1Control;
    allocation uf06 : Allocation allocate egasUf.torqueArbitration to logicalEgasWb.l1Control;
    allocation uf07 : Allocation allocate egasUf.pedalOutputResponse to logicalEgasWb.l2Output;
    allocation uf08 : Allocation allocate egasUf.controllerMonitoring to logicalEgasWb.l3Monitor;
    allocation uf09 : Allocation allocate egasUf.qnaAnswering to logicalEgasWb.l1Control;

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
    satisfy sysrControllerMonitoring by logicalEgasWb.l3Monitor;
    satisfy sysrControllerMonitoring by logicalEgasWb.l2Output;
    satisfy sysrControllerMonitoring by logicalEgasWb.l1Control;

    // Common cause failures: a name here shows the shared cause and does not show independence, so there is no ASIL decomposition.
    attribute ccfSharedAccelerationInput {
        @FailureMode {
            mode = "Wrong value on the shared accelerationInput";
            effect = "L1 and L2 act on the same wrong pedal value";
            propagatesTo = "l1InputDiagnostics, l1Control, l2Monitor";
            detectedBy = "l1InputDiagnostics for a deviation of PVS1 and PVS2 only; l3Monitor has no accelerationInput, so a common wrong value is not detected";
        }
        @SourceRef { document = "EGAS v6.0"; itemId = "EGAS_e101"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "Pilot analysis of the shared inputs in this model; e101 is only the context of systematic independence; the mitigation is open (OI-07).";
        }
    }

    attribute ccfSharedSensorInput {
        @FailureMode {
            mode = "Wrong value on the shared sensorInput";
            effect = "The torque estimate of l2Monitor and the output commands of l2Output use the same wrong sensor value";
            propagatesTo = "l2Monitor, l2Output";
            detectedBy = "none in the pilot";
        }
        @SourceRef { document = "EGAS v6.0"; itemId = "EGAS_e101"; }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "Pilot analysis of the shared inputs in this model; the mitigation is open (OI-07).";
        }
    }

    attribute ccfSharedEcu {
        @FailureMode {
            mode = "Failure of the shared ECU hardware (supply, clock, memory)";
            effect = "All logical components fail together";
            propagatesTo = "l1InputDiagnostics, l1Control, l2Monitor, l2Reaction, l2Output, l3Monitor";
            detectedBy = "none in the pilot: l3Monitor runs on the same ECU and is itself affected; the ECU hardware integrity check is not modeled";
        }
        @SourceRef {
            document = "EGAS v6.0";
            itemId = "EGAS_e101, EGAS_e102";
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale = "EGAS requires the ECU hardware integrity check (e102); the independence of the monitoring module is not demonstrated (OI-07).";
        }
    }
} // package EgasArch_Lwb_Logical
