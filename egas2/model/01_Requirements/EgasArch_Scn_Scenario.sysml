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

    #refinement dependency scenarioRefinesObjective
        from L2TorqueMonitorScenario
        to SafeTorqueObjective;
    #refinement dependency scenarioRefinesShr
        from L2TorqueMonitorScenario
        to MonitorTorqueRequirement;
} // package EgasArch_Scn_Scenario
