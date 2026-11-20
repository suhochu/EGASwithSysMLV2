package EgasArch_Scn_Scenario {
    private import ModelingMetadata::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Ctx_Context::*;
    private import EgasArch_Needs_Stakeholder::SafetyRegulator;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Shr_Fsr::*;

    use case def L2TorqueMonitorScenario {
        doc
        /* GP-A: the L2 monitor compares actual with permissible torque and triggers the safe state on an excess. */
        subject egasSystem : EgasSystem;
        actor pedal : AccelerationPedal;
        actor engine : Engine;
        actor dashboard : DashboardHMI;
        @ScenarioData {
            kind = ScenarioKind::main;
            preCondition = "Engine is running and the driver requests torque.";
            postCondition = "A torque excess is detected and the safe state is reached.";
        }
    }

    use case def BrakeOverrideScenario {
        doc
        /* The driver presses the accelerator and then the brake; the system reduces the propulsion torque whatever the input order. */
        subject egasSystem : EgasSystem;
        actor pedal : AccelerationPedal;
        actor brake : Brake;
        @ScenarioData {
            kind = ScenarioKind::alternative;
            preCondition =
                "Engine is running and the driver or cruise control requests propulsion.";
            postCondition = "The propulsion torque is reduced while the brake is applied.";
        }
    }

    use case def TorqueInterventionScenario {
        doc
        /* Another ECU (TCU or ESP) requests a torque reduction; the system reduces the air and fuel commands and returns to driver-request control when the request is released. */
        subject egasSystem : EgasSystem;
        actor externalEcu : AddEcu;
        actor engine : Engine;
        actor fuelSystem : FuelInjectionIgnitionSystem;
        @ScenarioData {
            kind = ScenarioKind::alternative;
            preCondition = "Engine is running and no intervention is active.";
            postCondition =
                "The torque is reduced during the request and driver-request control is restored after the release.";
        }
    }

    use case def SafetyAssessmentScenario {
        doc
        /* The safety regulator assesses that the evidence for the safety goal meets the ASIL of the goal. */
        subject egasSystem : EgasSystem;
        actor regulator : SafetyRegulator;
        @ScenarioData {
            kind = ScenarioKind::alternative;
            preCondition = "The safety goal and its verification evidence exist.";
            postCondition =
                "The assessment confirms that the evidence meets the ASIL of the safety goal.";
        }
    }

    use case def DriverTorqueDemandScenario {
        doc
        /* The driver presses the accelerator pedal and the engine delivers the requested torque precisely in steady state and with a predictable response to pedal changes. */
        subject egasSystem : EgasSystem;
        actor pedal : AccelerationPedal;
        actor engine : Engine;
        actor fuelSystem : FuelInjectionIgnitionSystem;
        @ScenarioData {
            kind = ScenarioKind::main;
            preCondition =
                "Engine is running, no fault is confirmed and no intervention is active.";
            postCondition = "The delivered torque follows the requested torque.";
        }
    }

    use case def PvsFaultLimpHomeScenario {
        doc
        /* GP-B: both pedal value sensor channels fail; the system stops using the driver request and continues in limp home with limited torque (EGAS 11.1.1). The limit value is the pilotAssumed catalog entry limpHomeTorqueLimit. */
        subject egasSystem : EgasSystem;
        actor pedal : AccelerationPedal;
        actor engine : Engine;
        @ScenarioData {
            kind = ScenarioKind::exception;
            preCondition = "Engine is running and the driver requests torque.";
            postCondition = "Limp home is active and the torque stays limited.";
        }
    }

    #refinement dependency scenarioRefinesShr
        from L2TorqueMonitorScenario
        to MonitorTorqueRequirement;
    #refinement dependency brakeScenarioRefinesShr
        from BrakeOverrideScenario
        to BrakeOverrideRequirement;
    #refinement dependency interventionScenarioRefinesShr
        from TorqueInterventionScenario
        to TorqueInterventionRequirement;
    #refinement dependency assessmentScenarioRefinesShr
        from SafetyAssessmentScenario
        to FunctionalSafetyComplianceRequirement;
    #refinement dependency demandScenarioRefinesPrecisionShr
        from DriverTorqueDemandScenario
        to SteadyStatePrecisionRequirement;
    #refinement dependency demandScenarioRefinesResponseShr
        from DriverTorqueDemandScenario
        to PedalResponseRequirement;
    #refinement dependency limpHomeScenarioRefinesShr
        from PvsFaultLimpHomeScenario
        to MonitorTorqueRequirement;
    #refinement dependency monitorScenarioRefinesTorqueExcessFsr
        from L2TorqueMonitorScenario
        to fsrTorqueExcessSafeState;
    #refinement dependency limpHomeScenarioRefinesPedalFaultFsr
        from PvsFaultLimpHomeScenario
        to fsrPedalSensorFaultLimpHome;
    #refinement dependency brakeScenarioRefinesBrakeOverrideFsr
        from BrakeOverrideScenario
        to fsrBrakeOverride;
    #refinement dependency monitorScenarioRefinesControllerFaultFsr
        from L2TorqueMonitorScenario
        to fsrControllerFaultShutOff;
    #refinement dependency monitorScenarioRefinesThrottleFaultFsr
        from L2TorqueMonitorScenario
        to fsrThrottleSensorFaultSafeState;
} // package EgasArch_Scn_Scenario
