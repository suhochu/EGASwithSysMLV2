package EgasArch_Scn_Scenario {
    private import ModelingMetadata::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Obj_Objective::*;
    private import EgasArch_Shr_Requirement::*;

    use case def L2TorqueMonitorScenario {
        doc
        /* GP-A: the L2 monitor compares actual with permissible torque and triggers the safe state on an excess. */
        @ScenarioData {
            kind = ScenarioKind::main;
            preCondition = "Engine is running and the driver requests torque.";
            postCondition = "A torque excess is detected and the safe state is reached.";
        }
    }

    use case def BrakeOverrideScenario {
        doc
        /* The driver presses the accelerator and then the brake; the system reduces the propulsion torque whatever the input order. */
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
        @ScenarioData {
            kind = ScenarioKind::alternative;
            preCondition = "The safety goal and its verification evidence exist.";
            postCondition =
                "The assessment confirms that the evidence meets the ASIL of the safety goal.";
        }
    }

    #refinement dependency scenarioRefinesObjective
        from L2TorqueMonitorScenario
        to SafeTorqueObjective;
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
} // package EgasArch_Scn_Scenario
