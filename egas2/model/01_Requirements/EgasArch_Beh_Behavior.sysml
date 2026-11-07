package EgasArch_Beh_Behavior {
    private import ModelingMetadata::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Units::TorqueQuantity;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Scn_Scenario::*;

    item def TorqueDemand {
        doc
        /* Internal absolute torque demand. It differs from the relative TorqueInterventionRequest at the system boundary. */
        attribute requestedTorque : TorqueQuantity;
    }

    action def ArbitrateTorque {
        doc
        /* Turns the driver request into the torque demand. Cruise control and other demand sources are out of the pilot scope. */
        in pedal : AccelerationPedalPosition;
        out demand : TorqueDemand;
    }

    action def ReduceTorque {
        doc
        /* Reduces the demand while an external intervention request or the brake is active. The reduction amount is tbd. */
        in request : TorqueInterventionRequest;
        in brake : BrakePedalPosition;
        in demand : TorqueDemand;
        out reducedDemand : TorqueDemand;
    }

    action def LimitTorque {
        doc
        /* Limits the demand to a reduced torque in limp home (EGAS 11.1.1). The limit value is tbd (OI-10). */
        in demand : TorqueDemand;
        out limitedDemand : TorqueDemand;
    }

    state def EgasBehavior {
        doc
        /* One state machine for the pilot scope. The top-level states are the operating modes; calibration, diagnostics, cruise and latch regions are out of scope. */
        attribute mode : OperatingMode;

        first start then normal;

        state normal {
            doc
            /* Engine runs and the driver request is served; the L2 monitor compares actual and permissible torque. */
            do action arbitrating : ArbitrateTorque;
        }
        state excessSuspected {
            doc
            /* A torque excess is suspected and not yet confirmed. The confirmation time is tbd. */
        }
        state intervention {
            doc
            /* Torque is reduced by an external request or by the brake. */
            do action reducing : ReduceTorque;
        }
        state limpHome {
            doc
            /* Both pedal value sensor channels have failed; torque stays limited. */
            do action limiting : LimitTorque;
        }
        state safeState {
            doc
            /* A torque excess is confirmed and the safe state is reached. The stage value is not fixed here. */
            attribute stage : SafeStateStage;
        }

        transition toExcessSuspected first normal then excessSuspected;
        transition toSafeState first excessSuspected then safeState;
        transition toInterventionByRequest
            first normal accept request : TorqueInterventionRequest then intervention;
        transition toInterventionByBrake
            first normal accept brake : BrakePedalPosition then intervention;
        transition backToNormal first intervention then normal;
        transition toLimpHome first normal accept pedal : AccelerationPedalPosition then limpHome;
    }

    state l2Behavior : EgasBehavior;

    #refinement dependency behaviorRefinesShr from EgasBehavior to MonitorTorqueRequirement;
    #refinement dependency behaviorRefinesMonitorScenario
        from EgasBehavior
        to L2TorqueMonitorScenario;
    #refinement dependency behaviorRefinesLimpHomeScenario
        from EgasBehavior
        to PvsFaultLimpHomeScenario;
    #refinement dependency arbitrateRefinesResponseShr
        from ArbitrateTorque
        to PedalResponseRequirement;
    #refinement dependency arbitrateRefinesDemandScenario
        from ArbitrateTorque
        to DriverTorqueDemandScenario;
    #refinement dependency demandRefinesPrecisionShr
        from TorqueDemand
        to SteadyStatePrecisionRequirement;
    #refinement dependency reduceRefinesInterventionShr
        from ReduceTorque
        to TorqueInterventionRequirement;
    #refinement dependency reduceRefinesBrakeShr from ReduceTorque to BrakeOverrideRequirement;
    #refinement dependency reduceRefinesInterventionScenario
        from ReduceTorque
        to TorqueInterventionScenario;
    #refinement dependency reduceRefinesBrakeScenario from ReduceTorque to BrakeOverrideScenario;
    #refinement dependency limitRefinesLimpHomeScenario
        from LimitTorque
        to PvsFaultLimpHomeScenario;
} // package EgasArch_Beh_Behavior
