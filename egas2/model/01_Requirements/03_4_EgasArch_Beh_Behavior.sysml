package EgasArch_Beh_Behavior {
    private import ScalarValues::*;
    private import SI::*;
    private import ModelingMetadata::*;
    private import EgasArch_Common_Units::PercentQuantity;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Ctx_Context::*;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Shr_Fsr::*;

    // System-Level Observable Events
    occurrence def IgnitionOnEvent {
        doc
        /* Terminal 15 (ignition) switched on; system enters normalDriving. */
    }
    occurrence def IgnitionOffEvent {
        doc
        /* Terminal 15 (ignition) switched off; independent safe engine stop (FSR-06). */
    }
    occurrence def UnintendedAccelerationEvent {
        doc
        /* Observable onset of impermissible driving torque or unintended vehicle acceleration (EGAS SReq-06). */
    }
    occurrence def SensorOrActuatorFaultEvent {
        doc
        /* Confirmed fault of accelerator pedal, throttle valve, brake sensor, or actuator (EGAS SReq-01~03, 05). */
        attribute cutOffRequired : Boolean;
    }
    occurrence def ExternalRequestFaultEvent {
        doc
        /* Faulty, corrupted, or missing torque-increasing request from an external ECU (EGAS SReq-04). */
    }
    occurrence def ControllerFaultEvent {
        doc
        /* Confirmed integrity fault of the engine function controller (EGAS SReq-07). */
    }
    occurrence def InterventionReleasedEvent {
        doc
        /* External torque reduction request or brake override is released. */
    }

    // Externally Observable Black-Box Actions
    action def DeliverRequestedPropulsion {
        doc
        /* Delivers air and fuel/ignition commands matching the driver's pedal actuation. */
        in driverActuation : DriverPedalActuation;
        in engineSensor : EngineSensorData;
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
        out trackingError : PercentQuantity;
    }

    action def DetectAndConfirmFault {
        doc
        /* Detects and confirms sensor, actuator, torque-excess, or controller faults (FDTI scope; FSR-01~03, 05~07). */
        in driverActuation : DriverPedalActuation;
        in engineSensor : EngineSensorData;
        in brakePosition : BrakePedalPosition [0..1];
        in ccRequest : CruiseControlRequest [0..1];
        out faultConfirmed : Boolean;
    }

    action def ApplyBrakeOverride {
        doc
        /* Limits propulsion power to a controllable maximum while brake and propulsion demand overlap (Shr-05, EGAS 10.1.2.4). */
        in driverActuation : DriverPedalActuation;
        in ccRequest : CruiseControlRequest [0..1];
        in brakePosition : BrakePedalPosition;
        in engineSensor : EngineSensorData;
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
    }

    action def ApplyExternalTorqueReduction {
        doc
        /* Reduces air and fuel/ignition output per a valid external ECU torque-reduction request (Shr-02). */
        in externalRequest : TorqueInterventionRequest;
        in engineSensor : EngineSensorData;
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
    }

    action def RejectFaultyExternalRequest {
        doc
        /* Inhibits a faulty or missing external torque-increasing request (EGAS SReq-04). */
        in externalRequest : TorqueInterventionRequest;
    }

    action def LimitPropulsionPower {
        doc
        /* Stage 1 Safe State (TorqueLimited): limits vehicle propulsion output (limp-home / idle demand). */
        in engineSensor : EngineSensorData;
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
    }

    action def CutOffPropulsion {
        doc
        /* Stage 2/3 Safe State (FuelCutOff / FullCutOff): cuts off fuel injection (ICO) or switches off power stages. */
        out airFlow : IntakeAirFlow;
        out fuelCommand : FuelIgnitionCommand;
    }

    action def WarnDriver {
        doc
        /* Raises an optical warning on the dashboard HMI upon fault reaction (EGAS_e52; invoked by UC_Common). */
        out warning : DashboardWarning;
    }

    // System-Level Black-Box State Machine
    state def EgasBehavior {
        doc
        /* System-level black-box behavior of the EGAS system:
         * off, normalDriving (driverDemand / externalIntervention / brakeOverride),
         * and staged safeState (TorqueLimited / FuelCutOff / FullCutOff).
         */
        entry;
        then off;

        state off : OffState {
            doc
            /* Ignition off / engine stopped. */
        }

        state normalDriving : DrivingState {
            doc
            /* Normal vehicle operation: serves driver demand and handles nominal external intervention or brake override. */
            entry;
            then driverDemand;

            state driverDemand {
                do action deliver : DeliverRequestedPropulsion;
            }

            state externalIntervention {
                do action reduce : ApplyExternalTorqueReduction;
            }

            state brakeOverride {
                do action overrideOnBrake : ApplyBrakeOverride;
            }

            transition enterInterventionByEcu
                first driverDemand
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0 [N * m] then externalIntervention;

            transition enterOverrideByBrakeFromDriver
                first driverDemand
                accept brake : BrakePedalPosition
                if brake.stopLightSwitchActive or brake.brakeTestSwitchActive then brakeOverride;

            transition enterOverrideByBrakeFromIntervention
                first externalIntervention
                accept brake : BrakePedalPosition
                if brake.stopLightSwitchActive or brake.brakeTestSwitchActive then brakeOverride;

            transition returnFromIntervention
                first externalIntervention accept rel : InterventionReleasedEvent then driverDemand;

            transition returnFromBrakeOverride
                first brakeOverride accept rel : InterventionReleasedEvent then driverDemand;
        }

        state safeState : SafeState {
            doc
            /* Confirmed fault: vehicle is held in a controllable safe state (driver optical warning is handled by UC_Common). */

            state torqueLimited : TorqueLimited {
                do action limitPower : LimitPropulsionPower;
            }
            state fuelCutOff : FuelCutOff {
                do action cutOffFuel : CutOffPropulsion;
            }
            state fullCutOff : FullCutOff {
                do action shutOffPower : CutOffPropulsion;
            }

            transition escalateToFuelCutOff
                first torqueLimited
                accept ev : SensorOrActuatorFaultEvent
                if ev.cutOffRequired then fuelCutOff;

            transition escalateTorqueLimitedToFullCutOff
                first torqueLimited accept ev : ControllerFaultEvent then fullCutOff;

            transition escalateToFullCutOff
                first fuelCutOff accept ev : ControllerFaultEvent then fullCutOff;
        }

        // Ignition On / Off transitions
        transition startDriving first off accept ev : IgnitionOnEvent then normalDriving;

        transition stopFromNormalDriving first normalDriving accept ev : IgnitionOffEvent then off;

        transition stopFromSafeState first safeState accept ev : IgnitionOffEvent then off;

        // Transitions from normalDriving (covers driverDemand, externalIntervention, and brakeOverride) to SafeState
        transition enterTorqueLimitedByExcess
            first normalDriving
            accept ev : UnintendedAccelerationEvent
            then safeState.torqueLimited;

        transition enterTorqueLimitedByExternalFault
            first normalDriving
            accept ev : ExternalRequestFaultEvent
            do action rejectExternal : RejectFaultyExternalRequest
            then safeState.torqueLimited;

        transition enterTorqueLimitedBySensorFault
            first normalDriving
            accept ev : SensorOrActuatorFaultEvent
            if not ev.cutOffRequired then safeState.torqueLimited;

        transition enterFuelCutOffByActuatorFault
            first normalDriving
            accept ev : SensorOrActuatorFaultEvent
            if ev.cutOffRequired then safeState.fuelCutOff;

        transition enterFullCutOffByControllerFault
            first normalDriving accept ev : ControllerFaultEvent then safeState.fullCutOff;
    }

    state l2Behavior : EgasBehavior;

    // Refinement Traceability: Behavior -> Runtime SHRs & All FSRs
    #refinement dependency behaviorRefinesRuntimeShrs
        from EgasBehavior
        to
            SteadyStatePrecisionRequirement,
            PedalResponseRequirement,
            TorqueInterventionRequirement,
            BrakeOverrideRequirement;

    #refinement dependency behaviorRefinesAllFsrs
        from EgasBehavior
        to
            fsr01_PedalSensorPlausibility,
            fsr02_ThrottleSensorPlausibility,
            fsr03_SensorSystemFaultDetection,
            fsr04_ExternalTorqueRequestProtection,
            fsr05_ActuatorErrorDetection,
            fsr06_TorqueExcessSafeState,
            fsr07_FunctionControllerMonitoring;

    // Action-level fine-grained refinement links
    #refinement dependency deliverRefinesPrecisionShr
        from DeliverRequestedPropulsion
        to SteadyStatePrecisionRequirement;
    #refinement dependency deliverRefinesResponseShr
        from DeliverRequestedPropulsion
        to PedalResponseRequirement;
    #refinement dependency reductionRefinesInterventionShr
        from ApplyExternalTorqueReduction
        to TorqueInterventionRequirement;
    #refinement dependency brakeOverrideRefinesShr05
        from ApplyBrakeOverride
        to BrakeOverrideRequirement;
    #refinement dependency detectFaultRefinesDetectionFsrs
        from DetectAndConfirmFault
        to
            fsr01_PedalSensorPlausibility,
            fsr02_ThrottleSensorPlausibility,
            fsr03_SensorSystemFaultDetection,
            fsr05_ActuatorErrorDetection,
            fsr06_TorqueExcessSafeState,
            fsr07_FunctionControllerMonitoring;
    #refinement dependency rejectExternalRefinesFsr04
        from RejectFaultyExternalRequest
        to fsr04_ExternalTorqueRequestProtection;
    #refinement dependency limitPowerRefinesFsr03AndFsr06
        from LimitPropulsionPower
        to fsr03_SensorSystemFaultDetection, fsr06_TorqueExcessSafeState;
    #refinement dependency cutOffRefinesFsr05Fsr06Fsr07
        from CutOffPropulsion
        to
            fsr05_ActuatorErrorDetection,
            fsr06_TorqueExcessSafeState,
            fsr07_FunctionControllerMonitoring;
    #refinement dependency warnDriverRefinesFsr06 from WarnDriver to fsr06_TorqueExcessSafeState;
} // package EgasArch_Beh_Behavior
