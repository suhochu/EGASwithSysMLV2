package EgasArch_Shr_Fsr {
    private import RequirementDerivation::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Enums::*;
    private import EgasArch_Common_Metadata::*;
    private import EgasArch_Common_Catalog_RequirementTargets::limpHomeTorqueLimit;
    private import EgasArch_Safety_Goal::*;
    private import EgasArch_Beh_Behavior::*; // SafeState, TorqueLimited, FuelCutOff, FullCutOff
    private import EgasArch_Ctx_Context::*; // AccelerationPedal, ThrottleValve, EngineControlUnit, egasSystem
    private import EgasArch_Needs_Concern::*;

    // Common FSR Definition

    requirement def <FSR> FunctionalSafetyRequirement {
        ref requirement safetyGoal : SafetyGoal [1];
        attribute asil : AsilLevel;
        attribute asilOrigin : AsilOrigin = AsilOrigin::inherited;
        attribute ftti : DurationQuantity [0..1];
        ref state safeState : SafeState [0..*];

        @GoalData {
            kind = GoalKind::hard;
        }
    }

    requirement <'FSR-01'> fsr01_PedalSensorPlausibility : FSR {
        doc
        /* EGAS SReq-01: The accelerator pedal sensor assembly shall provide redundant, plausibility-checkable signals 
         * to enable fault detection of driver demand.
         */

        subject pedal : AccelerationPedal;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;

        frame concern hardwareFailure : HardwareFailureConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr01_PedalSensorPlausibility;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e95", "EGAS-e105");
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale =
                "Component allocation (Drive pedal) and ASIL B (EGAS_e90) are directly given by EGAS.";
        }
    }

    requirement <'FSR-02'> fsr02_ThrottleSensorPlausibility : FSR {
        doc
        /* EGAS SReq-02: The throttle valve sensor assembly (gasoline air-measured systems) shall provide redundant, 
         * plausibility-checkable position signals to enable fault detection.
         */

        subject throttle : ThrottleValve;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;

        frame concern hardwareFailure : HardwareFailureConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr02_ThrottleSensorPlausibility;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = ("EGAS-e96", "EGAS-e106", "EGAS-e112");
        }
        @ValueStatus {
            status = ValueStatusKind::'standard';
            rationale =
                "Component allocation (Throttle valve) and ASIL B (EGAS_e90) are directly given by EGAS; applies to gasoline air-measured systems.";
        }
    }

    requirement <'FSR-03'> fsr03_SensorSystemFaultDetection : FSR {
        doc
        /* EGAS SReq-03: The engine control unit shall detect faults in torque-affecting sensors 
         * (accelerator pedal, throttle position, brake, cruise lever, etc.) via plausibility checks and, once confirmed, enter the applicable limp-home 
         * or safe state within the FTTI of SG-01.
         */

        subject ecu : EngineControlUnit;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;
        ref state :>> safeState [1..*] : SafeState;
        attribute torqueLimit : TorqueQuantity = limpHomeTorqueLimit;

        frame concern hardwareFailure : HardwareFailureConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr03_SensorSystemFaultDetection;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e107", "EGAS-e445", "EGAS-e446", "EGAS-e447", "EGAS-e448",
                "EGAS-e449", "EGAS-e450", "EGAS-e451", "EGAS-e452", "EGAS-e453",
                "EGAS-e454", "EGAS-e455", "EGAS-e456", "EGAS-e457", "EGAS-e458",
                "EGAS-e459", "EGAS-e460", "EGAS-e461", "EGAS-e462", "EGAS-e463",
                "EGAS-e464", "EGAS-e465", "EGAS-e468", "EGAS-e469", "EGAS-e470",
                "EGAS-e471", "EGAS-e472", "EGAS-e473", "EGAS-e474", "EGAS-e475",
                "EGAS-e476", "EGAS-e477", "EGAS-e478", "EGAS-e479", "EGAS-e480",
                "EGAS-e481", "EGAS-e482", "EGAS-e483", "EGAS-e484", "EGAS-e485",
                "EGAS-e486", "EGAS-e487", "EGAS-e504", "EGAS-e505", "EGAS-e506"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B and sensor fault reactions (PVS limp-home/idle, TPS limp-home/ICO, brake CC switch-off) are given by EGAS; limpHomeTorqueLimit and sg01Ftti are pilotAssumed (OI-07, OI-10). Pending user approval.";
        }
    }

    requirement <'FSR-04'> fsr04_ExternalTorqueRequestProtection : FSR {
        doc
        /* EGAS SReq-04: The engine control unit shall protect torque-affecting requests received from external ECUs 
         * (e.g., cruise control, ESP, AC, transmission) in the ECU network by checking transmission path 
         * and actuality, and inhibit faulty or missing torque-increasing requests within the FTTI of SG-01.
         */

        subject ecu : EngineControlUnit;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;
        ref state :>> safeState [1] : TorqueLimited;

        frame concern torqueArbitration : TorqueArbitrationConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr04_ExternalTorqueRequestProtection;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e51", "EGAS-e108", "EGAS-e148", "EGAS-e494", "EGAS-e495",
                "EGAS-e496", "EGAS-e508", "EGAS-e509"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B and request inhibition are given by EGAS (SReq-04, 11.1.3, 11.2); sg01Ftti is pilotAssumed (OI-07). Pending user approval.";
        }
    }

    requirement <'FSR-05'> fsr05_ActuatorErrorDetection : FSR {
        doc
        /* EGAS SReq-05: The engine control unit shall detect actuator errors (e.g., throttle-valve regulator/clamping/output-stage faults, 
         * fuel quantity faults) via plausibility checks and transition to the safe state (e.g., irreversible ICO and throttle actuator currentless) within the FTTI of SG-01.
         */

        subject ecu : EngineControlUnit;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;
        ref state :>> safeState [1] : FuelCutOff;

        frame concern hardwareFailure : HardwareFailureConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr05_ActuatorErrorDetection;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e109", "EGAS-e165", "EGAS-e488", "EGAS-e489", "EGAS-e490",
                "EGAS-e491", "EGAS-e492", "EGAS-e493"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B and irreversible ICO / currentless throttle reaction are given by EGAS (SReq-05, 11.1.2); sg01Ftti is pilotAssumed (OI-07). Pending user approval.";
        }
    }

    requirement <'FSR-06'> fsr06_TorqueExcessSafeState : FSR {
        doc
        /* EGAS SReq-06: The engine control unit shall implement an independent safety concept (central functional monitoring) 
         * that detects and confirms impermissible high driving torque or unintended acceleration, monitors programming and power supply, supports independent safe engine stop on ignition off (T15=off), transitions to a safe state within the FTTI of SG-01, and informs the driver when required.
         */

        subject ecu : EngineControlUnit;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;
        ref state :>> safeState [1..*] : SafeState;

        frame concern hardwareFailure : HardwareFailureConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr06_TorqueExcessSafeState;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e52", "EGAS-e87", "EGAS-e110", "EGAS-e127", "EGAS-e439",
                "EGAS-e440", "EGAS-e441", "EGAS-e497", "EGAS-e498", "EGAS-e499",
                "EGAS-e500", "EGAS-e501", "EGAS-e502", "EGAS-e503"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B and staged fault reactions (torque limit, ICO, output-stage shutoff/reset, boot block, safe engine stop) are given by EGAS; sg01Ftti is pilotAssumed (OI-07; EGAS_e435 gives 500 ms only as a torque-monitoring detection-to-reaction-start benchmark). Pending user approval.";
        }
    }

    requirement <'FSR-07'> fsr07_FunctionControllerMonitoring : FSR {
        doc
        /* EGAS SReq-07: The engine control unit shall independently monitor the function controller (Level 3 controller monitoring) 
         * and trigger reset or irreversible power-output-stage shut-off independently of the function controller within the FTTI of SG-01.
         */

        subject ecu : EngineControlUnit;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;
        ref state :>> safeState [1] : FullCutOff;

        frame concern hardwareFailure : HardwareFailureConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr07_FunctionControllerMonitoring;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e111", "EGAS-e117", "EGAS-e118", "EGAS-e119", "EGAS-e120",
                "EGAS-e121", "EGAS-e122", "EGAS-e123", "EGAS-e124", "EGAS-e125",
                "EGAS-e126", "EGAS-e127", "EGAS-e128", "EGAS-e333", "EGAS-e334",
                "EGAS-e335", "EGAS-e336", "EGAS-e337", "EGAS-e338", "EGAS-e339",
                "EGAS-e340", "EGAS-e341", "EGAS-e342", "EGAS-e343", "EGAS-e344",
                "EGAS-e345", "EGAS-e346", "EGAS-e347", "EGAS-e348", "EGAS-e349",
                "EGAS-e350", "EGAS-e351", "EGAS-e352", "EGAS-e353", "EGAS-e354",
                "EGAS-e355", "EGAS-e356", "EGAS-e357", "EGAS-e358", "EGAS-e359",
                "EGAS-e360", "EGAS-e361", "EGAS-e362", "EGAS-e363", "EGAS-e364",
                "EGAS-e365", "EGAS-e366", "EGAS-e367", "EGAS-e368", "EGAS-e369",
                "EGAS-e370", "EGAS-e371", "EGAS-e372", "EGAS-e373", "EGAS-e374",
                "EGAS-e375", "EGAS-e376", "EGAS-e377", "EGAS-e378", "EGAS-e379",
                "EGAS-e380", "EGAS-e381", "EGAS-e382", "EGAS-e383", "EGAS-e384",
                "EGAS-e385", "EGAS-e386", "EGAS-e387", "EGAS-e388", "EGAS-e389",
                "EGAS-e390", "EGAS-e391", "EGAS-e392", "EGAS-e393", "EGAS-e394",
                "EGAS-e395", "EGAS-e396", "EGAS-e397", "EGAS-e398", "EGAS-e399",
                "EGAS-e400", "EGAS-e401", "EGAS-e402", "EGAS-e403", "EGAS-e404",
                "EGAS-e405", "EGAS-e406", "EGAS-e407", "EGAS-e408", "EGAS-e409",
                "EGAS-e410", "EGAS-e411", "EGAS-e412", "EGAS-e413", "EGAS-e414",
                "EGAS-e415", "EGAS-e416", "EGAS-e417", "EGAS-e418", "EGAS-e419",
                "EGAS-e420", "EGAS-e421", "EGAS-e422", "EGAS-e423", "EGAS-e424",
                "EGAS-e425", "EGAS-e426", "EGAS-e427", "EGAS-e428", "EGAS-e429",
                "EGAS-e430", "EGAS-e558", "EGAS-e559", "EGAS-e560", "EGAS-e561",
                "EGAS-e562", "EGAS-e563", "EGAS-e564", "EGAS-e565", "EGAS-e566",
                "EGAS-e567", "EGAS-e568", "EGAS-e569", "EGAS-e570"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B and independent reset / power-stage shutoff (FullCutOff) are given by EGAS (SReq-07, 10.1.5, 11.3); sg01Ftti is pilotAssumed (OI-24). Pending user approval.";
        }
    }

    requirement <'FSR-08'> fsr08_BrakeOverride : FSR {
        doc
        /* EGAS 10.1.2.4: While the vehicle is moving and the driver requests propulsion by accelerator pedal (or cruise control) 
         * while operating the service brake with minimum pedal force, the engine control unit shall reduce propulsion power to a controllable maximum limit,
         *  independent of input order, and monitor the brake signal input.
         */

        subject ecu : EngineControlUnit;
        :>> safetyGoal = sg01;
        :>> asil = safetyGoal.asil;
        :>> ftti = safetyGoal.ftti;
        ref state :>> safeState [1] : TorqueLimited;

        frame concern torqueArbitration : TorqueArbitrationConcern;

        #derivation connection {
            end #original requirement ::> sg01;
            end #derive requirement ::> fsr08_BrakeOverride;
        }

        @SourceRef {
            document = "EGAS v6.0";
            itemId = (
                "EGAS-e197", "EGAS-e198", "EGAS-e199", "EGAS-e246", "EGAS-e247"
            );
        }
        @ValueStatus {
            status = ValueStatusKind::pilotAssumed;
            rationale =
                "ASIL B and brake-override reduction are given by EGAS; no numeric torque limit or reaction time is specified in EGAS, so sg01Ftti is pilotAssumed as the upper bound. Pending user approval.";
        }
    }
} // package EgasArch_Shr_Fsr
