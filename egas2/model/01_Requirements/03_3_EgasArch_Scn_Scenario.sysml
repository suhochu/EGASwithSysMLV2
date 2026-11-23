package EgasArch_Scn_Scenario {
    private import ScalarValues::*;
    private import Time::DurationOf;
    private import EgasArch_Common_Enums::AsilLevel;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Common_Catalog_SafetyTargets::*;
    private import EgasArch_Common_Catalog_RequirementTargets::*;
    private import EgasArch_Needs_Stakeholder::Driver;
    private import EgasArch_Ctx_Context::*;
    private import EgasArch_Shr_Requirement::*;
    private import EgasArch_Shr_Fsr::*;
    private import EgasArch_Beh_Behavior::*;
    private import EgasArch_Common_Calc::*;

    // Constraint roles for preconditions, postconditions, and invariants
    constraint def Precondition;
    constraint def Postcondition;
    constraint def Invariant;

    // -------------------------------------------------------------------------
    // Use Case Templates (Definitions)
    // -------------------------------------------------------------------------
    use case def <NominalUC> NominalUseCase {
        doc
        /* Template for nominal operational capabilities of the EGAS system. */
        subject egasSystem : EgasSystem;
    }

    use case def <SafetyUC> SafetyUseCase {
        doc
        /* Template for safety-critical operational capabilities subject to ISO 26262 ASIL. */
        subject egasSystem : EgasSystem;
        attribute asil : AsilLevel;
        attribute ftti : DurationQuantity;
    }

    // -------------------------------------------------------------------------
    // UC_Common: Safe State Transition & Driver Warning (Included Utility UC)
    // -------------------------------------------------------------------------
    use case <UC_Common> transitionToSafeState : SafetyUseCase {
        doc
        /* Reusable black-box safety capability: limit or cut off propulsion output
         * and optically warn the driver upon a confirmed fault (EGAS_e52, EGAS_e87).
         * ASIL and FTTI are governed by the parent SafetyUseCase that includes this UC.
         */
        subject :>> egasSystem : EgasSystem {
            perform limitPower;
            perform cutOff;
            perform warn;
            perform sendLimitedAir;
            perform sendLimitedFuel;
            perform sendCutOffAir;
            perform sendCutOffFuel;
            perform sendDriverWarning;
        }
        actor engine : Engine;
        actor fuelSystem : FuelInjectionIgnitionSystem;
        actor dashboard : DashboardHMI;

        // Parameters passed from parent UC (UC2 / UC3) on include
        in item ucEngineSensor : EngineSensorData;
        in attribute ucCutOffRequired : Boolean;
        out item ucWarning : DashboardWarning;

        assert constraint inv_systemOperational : Invariant {
            doc
            /* The EGAS system power supply and safety reaction paths remain operational throughout the transition. */
            isInState(egasSystem.behavior)
        }

        objective reachSafeStateObjective {
            doc
            /* Limit or cut off propulsion output and warn the driver optically. */
        }

        // 1. 시스템 내부 안전 반응 액션
        action limitPower : LimitPropulsionPower {
            in :>> engineSensor = ucEngineSensor;
        }
        action cutOff : CutOffPropulsion;
        action warn : WarnDriver;

        bind warn.warning = ucWarning;

        // 2. 경계 출력 송신 (Send Actions)
        action sendLimitedAir send limitPower.airFlow via egasSystem.airIntake to engine;
        action sendLimitedFuel send limitPower.fuelCommand via egasSystem.fuelCommand to fuelSystem;

        action sendCutOffAir send cutOff.airFlow via egasSystem.airIntake to engine;
        action sendCutOffFuel send cutOff.fuelCommand via egasSystem.fuelCommand to fuelSystem;

        action sendDriverWarning send warn.warning via egasSystem.dashboardOutput to dashboard;

        // 3. Send Action -> Actor Event Occurrence 간 Message 연결
        message limitedAirOutput of IntakeAirFlow from sendLimitedAir to engine.airFlowReceived;
        message limitedFuelOutput of FuelIgnitionCommand
            from sendLimitedFuel to fuelSystem.fuelCommandReceived;

        message cutOffAirOutput of IntakeAirFlow from sendCutOffAir to engine.airFlowReceived;
        message cutOffFuelOutput of FuelIgnitionCommand
            from sendCutOffFuel to fuelSystem.fuelCommandReceived;

        message driverWarningOutput of DashboardWarning
            from sendDriverWarning to dashboard.warningReceived;

        // 4. 제어 흐름 (Control Flow)
        decide selectStage;
        fork sendLimitedOutputs;
        join limitedOutputsSent;
        fork sendCutOffOutputs;
        join cutOffOutputsSent;
        merge stageDone;

        first start then selectStage;

        // Branch 1: Stage 1 (TorqueLimited)
        first selectStage if not ucCutOffRequired then limitPower;
        first limitPower then sendLimitedOutputs;
        first sendLimitedOutputs then sendLimitedAir;
        first sendLimitedOutputs then sendLimitedFuel;
        first sendLimitedAir then limitedOutputsSent;
        first sendLimitedFuel then limitedOutputsSent;
        first limitedOutputsSent then stageDone;

        // Branch 2: Stage 2/3 (FuelCutOff / FullCutOff)
        first selectStage if ucCutOffRequired then cutOff;
        first cutOff then sendCutOffOutputs;
        first sendCutOffOutputs then sendCutOffAir;
        first sendCutOffOutputs then sendCutOffFuel;
        first sendCutOffAir then cutOffOutputsSent;
        first sendCutOffFuel then cutOffOutputsSent;
        first cutOffOutputsSent then stageDone;

        first stageDone then warn;
        first warn then sendDriverWarning;
        first sendDriverWarning then done;
    }

    // -------------------------------------------------------------------------
    // UC1: Deliver Driver Torque (Nominal Capability)
    // -------------------------------------------------------------------------
    use case <UC1> deliverDriverTorque : NominalUseCase {
        doc
        /* Nominal capability: respond to the driver's accelerator pedal input by delivering
         * the requested engine torque accurately and predictably.
         */
        subject :>> egasSystem : EgasSystem {
            perform receivePedal;
            perform receiveEngineSensor;
            perform deliver;
            perform sendAirFlow;
            perform sendFuelCommand;
        }
        actor driver : Driver;
        actor engine : Engine;
        actor fuelSystem : FuelInjectionIgnitionSystem;

        objective deliverDriverTorqueObjective {
            doc
            /* Track driver torque demand in steady state and respond within the pedal response budget. */
            assume constraint pre_drivingMode : Precondition {
                isInState(egasSystem.behavior.normalDriving.driverDemand)
            }
            require constraint post_nominalDelivery : Postcondition {
                DurationOf(deliver) <= pedalResponseBudget and
                deliver.trackingError <= steadyStateTrackingLimit
            }
        }

        // 1. 경계 입력 수신 (Accept Actions)
        action receivePedal accept pedal : DriverPedalActuation via egasSystem.driverPedalInput;
        action receiveEngineSensor accept sensor : EngineSensorData via egasSystem.sensorInput;

        // 2. 시스템 내부 기능 수행
        action deliver : DeliverRequestedPropulsion;

        // 3. 경계 출력 송신 (Send Actions)
        action sendAirFlow send deliver.airFlow via egasSystem.airIntake to engine;
        action sendFuelCommand send deliver.fuelCommand via egasSystem.fuelCommand to fuelSystem;

        // 4. Actor Event Occurrence <-> Accept/Send Action 간 Message 연결
        message pedalInput of DriverPedalActuation from driver.pedalActuationSent to receivePedal;
        message engineSensorInput of EngineSensorData
            from engine.engineSensorSent to receiveEngineSensor;
        message airFlowOutput of IntakeAirFlow from sendAirFlow to engine.airFlowReceived;
        message fuelCommandOutput of FuelIgnitionCommand
            from sendFuelCommand to fuelSystem.fuelCommandReceived;

        // 5. 데이터 흐름 (Accept 출력 -> DeliverRequestedPropulsion 입력)
        flow receivePedal.pedal to deliver.driverActuation;
        flow receiveEngineSensor.sensor to deliver.engineSensor;

        // 6. 제어 흐름 (Control Flow)
        merge loopEntry;
        fork receiveInputs;
        join inputsReady;
        fork sendOutputs;
        join outputsSent;
        decide continueDriving;

        first start then loopEntry;
        first loopEntry then receiveInputs;

        first receiveInputs then receivePedal;
        first receiveInputs then receiveEngineSensor;
        first receivePedal then inputsReady;
        first receiveEngineSensor then inputsReady;

        first inputsReady then deliver;
        first deliver then sendOutputs;

        first sendOutputs then sendAirFlow;
        first sendOutputs then sendFuelCommand;
        first sendAirFlow then outputsSent;
        first sendFuelCommand then outputsSent;

        first outputsSent then continueDriving;
        first continueDriving
            if isInState(egasSystem.behavior.normalDriving.driverDemand) then loopEntry;
        first continueDriving
            if not isInState(egasSystem.behavior.normalDriving.driverDemand) then done;

        dependency uc1RefinesShrs
            from deliverDriverTorque
            to SteadyStatePrecisionRequirement, PedalResponseRequirement;
    }

    // -------------------------------------------------------------------------
    // UC2: Arbitrate Conflicting Torque Requests (Intervention & Brake Override)
    // -------------------------------------------------------------------------
    use case <UC2> arbitrateTorqueRequests : SafetyUseCase {
        doc
        /* Arbitration capability: resolve conflicting torque requests from the driver,
         * cruise control, service brake, and external ECUs, operating across normalDriving
         * (externalIntervention, brakeOverride) and safeState on faulty external requests
         * (Shr-02, Shr-05, FSR-04).
         */
        subject :>> egasSystem : EgasSystem;
        actor driver : Driver;
        actor ccLever : CruiseControlLever [0..1];
        actor brake : Brake;
        actor externalEcu : AddEcu;
        actor engine : Engine;
        actor fuelSystem : FuelInjectionIgnitionSystem;
        actor dashboard : DashboardHMI;

        :>> asil = sg01Asil;
        :>> ftti = sg01Ftti;

        assert constraint inv_systemOperational : Invariant {
            doc
            /* The EGAS system remains operational throughout arbitration or fault transition. */
            isInState(egasSystem.behavior)
        }

        // 1. 경계 입력 수신 (기본 입력과 이벤트별 트리거 입력 분리)
        action receivePedal accept actuation : DriverPedalActuation via egasSystem.driverPedalInput;
        action receiveEngineSensor accept sensorData : EngineSensorData via egasSystem.sensorInput;
        action receiveBrake accept brakePos : BrakePedalPosition via egasSystem.brakeInput;
        action receiveExternalRequest
            accept extReq : TorqueInterventionRequest via egasSystem.torqueIntervention;
        action waitInterventionRelease accept rel : InterventionReleasedEvent;

        // 2. 시스템 내부 중재/안전 액션 및 Included UC
        action rejectExternal : RejectFaultyExternalRequest;
        action overrideOnBrake : ApplyBrakeOverride;
        action reduceByExternalEcu : ApplyExternalTorqueReduction;

        include use case enterSafeState :> transitionToSafeState {
            subject :>> egasSystem : EgasSystem;
            in :>> ucEngineSensor = receiveEngineSensor.sensorData;
            in :>> ucCutOffRequired = false;
        }

        // 3. 경계 출력 송신
        action sendOverrideAir send overrideOnBrake.airFlow via egasSystem.airIntake to engine;
        action sendOverrideFuel
            send overrideOnBrake.fuelCommand via egasSystem.fuelCommand to fuelSystem;

        action sendReducedAir send reduceByExternalEcu.airFlow via egasSystem.airIntake to engine;
        action sendReducedFuel
            send reduceByExternalEcu.fuelCommand via egasSystem.fuelCommand to fuelSystem;

        // 4. Actor Event Occurrence <-> Accept/Send Action 간 Message 연결
        message pedalInput of DriverPedalActuation from driver.pedalActuationSent to receivePedal;
        message pressBrakePedal from driver.brakeActuationSent to brake.brakeActuationReceived;
        message brakeInput of BrakePedalPosition from brake.brakePositionSent to receiveBrake;
        message externalRequestInput of TorqueInterventionRequest
            from externalEcu.externalRequestSent to receiveExternalRequest;
        message engineSensorInput of EngineSensorData
            from engine.engineSensorSent to receiveEngineSensor;

        message overrideAirOutput of IntakeAirFlow from sendOverrideAir to engine.airFlowReceived;
        message overrideFuelOutput of FuelIgnitionCommand
            from sendOverrideFuel to fuelSystem.fuelCommandReceived;

        message reducedAirOutput of IntakeAirFlow from sendReducedAir to engine.airFlowReceived;
        message reducedFuelOutput of FuelIgnitionCommand
            from sendReducedFuel to fuelSystem.fuelCommandReceived;

        // 5. 데이터 흐름
        flow receiveExternalRequest.extReq to rejectExternal.externalRequest;

        flow receivePedal.actuation to overrideOnBrake.driverActuation;
        flow receiveBrake.brakePos to overrideOnBrake.brakePosition;
        flow receiveEngineSensor.sensorData to overrideOnBrake.engineSensor;

        flow receiveExternalRequest.extReq to reduceByExternalEcu.externalRequest;
        flow receiveEngineSensor.sensorData to reduceByExternalEcu.engineSensor;

        objective arbitrateTorqueObjective {
            doc
            /* Enforce brake override priority (Shr-05), reject faulty external torque-increasing requests within FTTI (FSR-04),
             * and apply valid torque reductions within budget before returning to driver demand on release (Shr-02).
             */
            assume constraint pre_activeArbitration : Precondition {
                isInState(egasSystem.behavior.normalDriving)
            }
            require constraint post_onExternalFault : Postcondition {
                isInState(egasSystem.behavior.safeState) implies
                (isInState(egasSystem.behavior.safeState.torqueLimited) and
                    DurationOf(rejectExternal) + DurationOf(enterSafeState) <= ftti and
                    enterSafeState.ucWarning.warningActive)
            }
            require constraint post_onBrakeOverride : Postcondition {
                (receiveBrake.brakePos.stopLightSwitchActive or
                    receiveBrake.brakePos.brakeTestSwitchActive) implies
                (DurationOf(overrideOnBrake) <= interventionResponseBudget and
                    isInState(egasSystem.behavior.normalDriving.driverDemand))
            }
            require constraint post_onExternalReduction : Postcondition {
                (not isInState(egasSystem.behavior.safeState) and
                    not (receiveBrake.brakePos.stopLightSwitchActive or
                        receiveBrake.brakePos.brakeTestSwitchActive)) implies
                (DurationOf(reduceByExternalEcu) <= interventionResponseBudget and
                    isInState(egasSystem.behavior.normalDriving.driverDemand))
            }
        }

        // 6. 제어 흐름 (Deadlock 해소 및 개입 해제 복귀 경로 포함)
        fork receiveBaseInputs;
        join baseInputsReady;
        decide selectTrigger;
        decide checkExternalValidity;
        fork sendOverrideOutputs;
        join overrideOutputsSent;
        fork sendReducedOutputs;
        join reducedOutputsSent;
        merge releaseWaitEntry;
        merge arbitrationDone;

        first start then receiveBaseInputs;
        first receiveBaseInputs then receivePedal;
        first receiveBaseInputs then receiveEngineSensor;
        first receivePedal then baseInputsReady;
        first receiveEngineSensor then baseInputsReady;

        first baseInputsReady then selectTrigger;

        // Branch 1: Brake override (Shr-05) -> send override outputs -> wait release -> driverDemand
        first selectTrigger
            if isInState(egasSystem.behavior.normalDriving.brakeOverride) then receiveBrake;
        first receiveBrake then overrideOnBrake;
        first overrideOnBrake then sendOverrideOutputs;
        first sendOverrideOutputs then sendOverrideAir;
        first sendOverrideOutputs then sendOverrideFuel;
        first sendOverrideAir then overrideOutputsSent;
        first sendOverrideFuel then overrideOutputsSent;
        first overrideOutputsSent then releaseWaitEntry;

        // Branch 2: External ECU request -> check validity (Faulty: FSR-04 / Valid: Shr-02)
        first selectTrigger
            if not isInState(egasSystem.behavior.normalDriving.brakeOverride)
                then receiveExternalRequest;
        first receiveExternalRequest then checkExternalValidity;

        // Branch 2a: Faulty external request -> reject & enterSafeState
        first checkExternalValidity if isInState(egasSystem.behavior.safeState) then rejectExternal;
        first rejectExternal then enterSafeState;
        first enterSafeState then arbitrationDone;

        // Branch 2b: Valid external ECU reduction -> send reduced outputs -> wait release -> driverDemand
        first checkExternalValidity
            if isInState(egasSystem.behavior.normalDriving.externalIntervention)
                then reduceByExternalEcu;
        first reduceByExternalEcu then sendReducedOutputs;
        first sendReducedOutputs then sendReducedAir;
        first sendReducedOutputs then sendReducedFuel;
        first sendReducedAir then reducedOutputsSent;
        first sendReducedFuel then reducedOutputsSent;
        first reducedOutputsSent then releaseWaitEntry;

        // Common release path back to driverDemand
        first releaseWaitEntry then waitInterventionRelease;
        first waitInterventionRelease then arbitrationDone;
        first arbitrationDone then done;

        dependency uc2RefinesReqs
            from arbitrateTorqueRequests
            to
                TorqueInterventionRequirement,
                BrakeOverrideRequirement,
                fsr04_ExternalTorqueRequestProtection;
    }

    // -------------------------------------------------------------------------
    // UC3: Monitor and Protect Against Unintended Acceleration
    // -------------------------------------------------------------------------
    use case <UC3> monitorAndProtectTorque : SafetyUseCase {
        doc
        /* Core safety capability: prevent unintended vehicle acceleration under sensor,
         * actuator, torque-excess, or controller faults by detecting/confirming the fault
         * and transitioning into a controllable safe state within FTTI (FSR-01~03, 05~07).
         */
        subject :>> egasSystem : EgasSystem;
        actor driver : Driver;
        actor brake : Brake;
        actor ccLever : CruiseControlLever [0..1];
        actor engine : Engine;
        actor fuelSystem : FuelInjectionIgnitionSystem;
        actor dashboard : DashboardHMI;

        :>> asil = sg01Asil;
        :>> ftti = sg01Ftti;

        assert constraint inv_systemOperational : Invariant {
            doc
            /* The EGAS system remains operational with independent monitoring hardware active. */
            isInState(egasSystem.behavior)
        }

        // 1. 경계 입력 수신 (필수 센서 입력)
        action receivePedal accept actuation : DriverPedalActuation via egasSystem.driverPedalInput;
        action receiveEngineSensor accept sensorData : EngineSensorData via egasSystem.sensorInput;
        action receiveBrake accept brakePos : BrakePedalPosition via egasSystem.brakeInput;

        // 2. 시스템 내부 기능 수행, 결함 감지/확인(FDTI) 및 Included Safe State UC(FRTI)
        action deliver : DeliverRequestedPropulsion;
        action detectFault : DetectAndConfirmFault;

        include use case enterSafeState :> transitionToSafeState {
            subject :>> egasSystem : EgasSystem;
            in :>> ucEngineSensor = receiveEngineSensor.sensorData;
            in :>> ucCutOffRequired =
                isInState(egasSystem.behavior.safeState.fuelCutOff) or
                isInState(egasSystem.behavior.safeState.fullCutOff);
        }

        // 3. 경계 출력 송신 (Normal Path)
        action sendAirFlow send deliver.airFlow via egasSystem.airIntake to engine;
        action sendFuelCommand send deliver.fuelCommand via egasSystem.fuelCommand to fuelSystem;

        // 4. Actor Event Occurrence <-> Accept/Send Action 간 Message 연결
        message pedalInput of DriverPedalActuation from driver.pedalActuationSent to receivePedal;
        message brakeInput of BrakePedalPosition from brake.brakePositionSent to receiveBrake;
        message engineSensorInput of EngineSensorData
            from engine.engineSensorSent to receiveEngineSensor;
        message airFlowOutput of IntakeAirFlow from sendAirFlow to engine.airFlowReceived;
        message fuelCommandOutput of FuelIgnitionCommand
            from sendFuelCommand to fuelSystem.fuelCommandReceived;

        // 5. 데이터 흐름
        flow receivePedal.actuation to deliver.driverActuation;
        flow receiveEngineSensor.sensorData to deliver.engineSensor;

        flow receivePedal.actuation to detectFault.driverActuation;
        flow receiveEngineSensor.sensorData to detectFault.engineSensor;
        flow receiveBrake.brakePos to detectFault.brakePosition;

        objective protectAgainstUnintendedAccelerationObjective {
            doc
            /* Prevent unintended acceleration upon confirmed fault by detecting and transitioning
             * to safeState within FTTI (FDTI + FRTI <= FTTI) and warning the driver.
             */
            assume constraint pre_monitoringActive : Precondition {
                isInState(egasSystem.behavior.normalDriving)
            }
            require constraint post_safeStateWithinFtti : Postcondition {
                isInState(egasSystem.behavior.safeState) and
                DurationOf(detectFault) + DurationOf(enterSafeState) <= ftti and
                enterSafeState.ucWarning.warningActive
            }
        }

        // 6. 제어 흐름
        merge monitorLoop;
        fork receiveInputs;
        join inputsReady;
        decide faultCheck;
        fork sendNormalOutputs;
        join normalOutputsSent;

        first start then monitorLoop;
        first monitorLoop then receiveInputs;

        first receiveInputs then receivePedal;
        first receiveInputs then receiveEngineSensor;
        first receiveInputs then receiveBrake;
        first receivePedal then inputsReady;
        first receiveEngineSensor then inputsReady;
        first receiveBrake then inputsReady;

        first inputsReady then deliver;
        first deliver then detectFault;
        first detectFault then faultCheck;

        // Normal path: send air & fuel commands and continue monitoring loop
        first faultCheck
            if not detectFault.faultConfirmed and isInState(egasSystem.behavior.normalDriving)
                then sendNormalOutputs;
        first sendNormalOutputs then sendAirFlow;
        first sendNormalOutputs then sendFuelCommand;
        first sendAirFlow then normalOutputsSent;
        first sendFuelCommand then normalOutputsSent;
        first normalOutputsSent then monitorLoop;

        // Fault path: execute included transitionToSafeState (handles safe air/fuel & warning)
        first faultCheck
            if detectFault.faultConfirmed or isInState(egasSystem.behavior.safeState)
                then enterSafeState;
        first enterSafeState then done;

        dependency uc3RefinesFsrs
            from monitorAndProtectTorque
            to
                fsr01_PedalSensorPlausibility,
                fsr02_ThrottleSensorPlausibility,
                fsr03_SensorSystemFaultDetection,
                fsr05_ActuatorErrorDetection,
                fsr06_TorqueExcessSafeState,
                fsr07_FunctionControllerMonitoring;
    }
} // package EgasArch_Scn_Scenario
