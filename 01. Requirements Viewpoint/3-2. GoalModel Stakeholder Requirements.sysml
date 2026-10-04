package RV_StakeholderRequirementModel {
    doc
    /* Stakeholder Req Viewpoint: Biz/op needs (SHR-xx, SHR-Pxx) & acceptance criteria. */

    private import ModelingMetadata::*;
    private import RV_StakeHolderModel::*;
    private import RV_StakeHolderConcernModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation { version = "v0.1"; }

    // 1. Core Definitions
    abstract requirement def StakeholderRequirement {
        doc
        /* Biz/op needs with acceptance criteria. */
        subject egas : RV_ContextModel::EgasSystem;
        attribute priorityLevel : PriorityLevel [1];
        attribute criticalityLevel : CriticalityLevel [1];
        attribute reqValidationStatus : ReqValidationStatus [1];
        attribute description;
        require constraint acceptanceCriteria; // Acceptance criteria
        attribute author : ProjectMember;
        attribute owner : ProjectMember;
        attribute traceToSource : String [1..*];
        @MetaInformation { version = "v0.2"; }
    }

    abstract requirement def SystemRelatedSR :> StakeholderRequirement;
    abstract requirement def ProjectRelatedSR :> StakeholderRequirement;

    // 2. System Related Requirements
    requirement def <'SHR-01'> ReqSafeTorqueArbitration :> SystemRelatedSR {
        doc
        /* Safety-first torque arbitration & Brake Override. */
        frame concern torqueArbitration : TorqueArbitrationConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "NHTSA Unintended Acceleration Guidelines";
        :>> description = "Safety-first torque arbitration & Brake Override.";

        require constraint :>> acceptanceCriteria {
            private import SafeStateLogic::*;
            doc
            /* 가속 페달 또는 크루즈 요구가 활성인 상태에서 브레이크 입력이 발생하면(IsBrakeOverrideTriggered),
             * 시스템은 브레이크를 우선하여 최종 출력을 토크 제한(L1: 공회전 수준 이하)으로 제한해야 한다.
             */
            IsBrakeOverrideTriggered(
                egas.accelPort.accelIntent.pedalDisplacement,
                egas.ccPort.ccCmd.setSpeed,
                egas.brakePort.brakeInput.pressure
            ) implies
            IsTorqueLimited(
                egas.airIntakePort.airFlow.massFlow,
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth
            )
        }
        @Rationale {
            doc
            /* Driving stability over other requests. */
        }
        @MetaInformation { version = "v0.2"; }
        @HardGoal;
    }

    requirement def <'SHR-02'> ReqPreciseClosedLoopControl :> SystemRelatedSR {
        doc
        /* Closed-loop throttle/fuel/ign control for target torque. */
        frame concern preciseControl : PreciseControlConcern;
        frame concern hardwareTolerance : HardwareToleranceHandlingConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Tier 1 Supplier Interview";

        @Rationale {
            doc
            /* Convert target torque to actual power accurately. */
        }
        @GoalRefinement {
            kind = RefinementKind::AND;
            rationale = "Needs steady-state precision (SHR-02-1) & misfire prevention (SHR-02-2).";
        }
        @MetaInformation { version = "v0.3"; }
        @SoftGoal;
    }

    requirement def <'SHR-02-1'> ReqSteadyStatePrecision :> 'SHR-02' {
        require constraint :>> acceptanceCriteria {
            doc
            /* [Context] Steady-state error <=2%, overshoot <=5% on dyno. (DemonstrateSteadyStatePrecision). SYSR-08 handles response time. */
        }
        @Rationale {
            doc
            /* Precision for torque tracking. */
        }
        @MetaInformation { version = "v0.1"; }
        @HardGoal;
    }

    requirement def <'SHR-02-2'> ReqMisfirePrevention :> 'SHR-02' {
        require constraint :>> acceptanceCriteria {
            doc
            /* [EGAS] Fuel/ign cmd <=10ms after sensor rx. */
            egas.fuelCmdPort.fuelCmd.responseTime <= 10.0 [milli * s]
        }
        @Rationale {
            doc
            /* Prevent combustion failures. */
        }
        @MetaInformation { version = "v0.1"; }
        @HardGoal;
    }

    requirement def <'SHR-03'> ReqFailSafeSensorMonitoring :> SystemRelatedSR {
        doc
        /* Fail-safe via redundant sensor monitoring. */
        frame concern hardwareFailure : HardwareFailureConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "ISO 26262 Requirements";

        require constraint :>> acceptanceCriteria {
            doc
            /* Cut air/fuel if coolant temp > 120C. */
            egas.sensorPort.sensorData.coolantTemp > 120.0 ['°'] implies
            SafeStateLogic::IsFullCutOff(
                egas.airIntakePort.airFlow.massFlow,
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth
            )
        }
        @Rationale {
            doc
            /* Safe state against single point failures. */
        }
        @MetaInformation { version = "v0.1"; }
        @HardGoal;
    }

    requirement def <'SHR-04'> ReqDynamicResponsiveness :> SystemRelatedSR {
        doc
        /* Fast torque response for driver & external (ESP/TCU) reqs. */
        frame concern interventionResponse : TorqueInterventionResponsivenessConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Chassis Control (ESP/TCU) Meeting Minutes";

        @Rationale {
            doc
            /* Essential for emergency maneuvers. */
        }
        @GoalRefinement {
            kind = RefinementKind::AND;
            rationale =
                "Requires airflow (SHR-04-1) & fuel/ign (SHR-04-2) reduction for 15ms response.";
        }
        @MetaInformation { version = "v0.3"; }
        @SoftGoal;
    }

    requirement def <'SHR-04-1'> ReqTorqueInterventionByAirflow :> 'SHR-04' {
        assume constraint normalCommunication {
            doc
            /* External req latency <= 15ms. */
            egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s]
        }
        require constraint :>> acceptanceCriteria {
            doc
            /* Reduce airflow mass <= 15ms upon ESP/TCU req. */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            (egas.airIntakePort.airFlow.responseTime <= 15.0 [milli * s] and
                egas.airIntakePort.airFlow.massFlow < egas.airIntakePort.airFlow.previousMassFlow)
        }
        @Rationale {
            doc
            /* Primary torque reduction without side-effects. */
        }
        @HardGoal;
    }

    requirement def <'SHR-04-2'> ReqTorqueInterventionByFuelIgnition :> 'SHR-04' {
        assume constraint normalCommunication {
            doc
            /* External req latency <= 15ms. */
            egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s]
        }
        require constraint :>> acceptanceCriteria {
            doc
            /* Reduce fuel injection <= 15ms upon ESP/TCU req. */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            (egas.fuelCmdPort.fuelCmd.responseTime <= 15.0 [milli * s] and
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth <
                egas.fuelCmdPort.fuelCmd.previousPulseWidth)
        }
        @Rationale {
            doc
            /* Mandatory for urgent events. */
        }
        @HardGoal;
    }

    requirement def <'SHR-04-3'> ReqTorqueInterventionFallbackFuelOnly :> 'SHR-04' {
        @GoalRefinement {
            kind = RefinementKind::OR;
            rationale = "If airflow stuck, fuel cut alone (SHR-04-2) meets goal.";
        }

        require constraint :>> acceptanceCriteria {
            private import ThrottleStuckLogic::*;
            doc
            /* 긴급 토크 저감 요청 중 스로틀 고착(IsThrottleStuck: 목표/실제 개도 편차 지속)이 확정되면,
             * 확정 후 10ms 이내에 연료 차단만으로 토크를 안전 수준으로 저감해야 한다.
             */
            IsThrottleStuck(
                egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m],
                egas.throttle.positionCommand.openingPercentage,
                egas.throttle.positionFeedback.openingPercentage,
                stuckDeviationLimit,
                egas.throttle.deviationDuration,
                stuckConfirmTime
            ) implies
            (SafeStateLogic::IsFuelCutOff(egas.fuelCmdPort.fuelCmd.injectionPulseWidth) and
                egas.fuelCmdPort.fuelCmd.responseTime <= 10.0 [milli * s])
        }
        @Rationale {
            doc
            /* Ensure torque reduction despite air path failure. */
        }
        @HardGoal;
    }

    requirement def <'SHR-04-4'> ReqTorqueInterventionRelease :> 'SHR-04' {
        assume constraint normalCommunication {
            doc
            /* 외부 제어기 해제 요청 시의 통신 지연은 15ms 이하 정상 통신으로 가정한다. */
            egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s]
        }
        require constraint :>> acceptanceCriteria {
            doc
            /* 외부 제어기가 개입 해제(delta >= 0)를 요청하면, 공기량/연료량 제어가 
             * 운전자 요구 기반 제어로 복귀할 수 있도록 지연 없이 응답해야 한다.
             */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta >= 0.0 [N * m] implies
            (egas.airIntakePort.airFlow.responseTime <= 15.0 [milli * s] and
                egas.fuelCmdPort.fuelCmd.responseTime <= 15.0 [milli * s])
        }
        @Rationale {
            doc
            /* 긴급 개입 상황이 종료되었을 때 신속하게 제어권을 복귀시켜 차량 구동력을 정상화해야 함 */
        }
        @HardGoal;
    }

    requirement def <'SHR-05'> ReqPowertrainCalibrationSupport :> SystemRelatedSR {
        doc
        /* Support calibration map tuning. */
        frame concern calibration : PowertrainCalibrationConcern;

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Calibration Engineering Team";

        @Rationale {
            doc
            /* Maximize combustion efficiency. */
        }
        @GoalRefinement {
            kind = RefinementKind::AND;
            rationale = "Requires memory access control (SHR-05-1) & data integrity (SHR-05-2).";
        }
        @MetaInformation { version = "v0.3"; }
        @SoftGoal;
    }

    requirement def <'SHR-05-1'> ReqCalibrationMemoryAccess :> 'SHR-05' {
        require constraint :>> acceptanceCriteria {
            doc
            /* OK (200) for valid memory access. */
            egas.calibrationPort.calReq.targetMemoryAddress > 0 implies
            egas.calibrationPort.calStatus.responseCode == 200
        }
        @Rationale {
            doc
            /* Authorized tool connection. */
        }
        @HardGoal;
    }

    requirement def <'SHR-05-2'> ReqCalibrationDataIntegrity :> 'SHR-05' {
        require constraint :>> acceptanceCriteria {
            doc
            /* Valid checksum post tuning update. */
            egas.calibrationPort.calReq.targetMemoryAddress > 0 implies
            egas.calibrationPort.calStatus.verifiedChecksum > 0
        }
        @Rationale {
            doc
            /* Prevent corrupted map overwrites. */
        }
        @HardGoal;
    }

    requirement def <'SHR-06'> ReqDiagnosticAndMaintenanceSupport :> SystemRelatedSR {
        doc
        /* Clear DTCs & zero-point cal for A/S. */
        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "A/S Center VOC Report";

        require constraint :>> acceptanceCriteria {
            doc
            /* Handle ReadDTC (svc=1) & ZeroCal (svc=2) with positive responses. */
            (egas.sensorPort.sensorData.coolantTemp > 120.0 ['°'] and
                egas.diagPort.diagReq.serviceId == 1) implies
            (egas.diagPort.diagStatus.responseCode == 200 and
                egas.diagPort.diagStatus.dtcCode > 0 and
                (egas.diagPort.diagReq.serviceId == 2 implies
                    egas.diagPort.diagStatus.responseCode == 200))
        }
        @Rationale {
            doc
            /* Reduce repair time. */
        }
        frame concern diagnostics : DiagnosticsAndMaintenanceConcern;
        @MetaInformation { version = "v0.3"; }
        @HardGoal;
    }

    requirement def <'SHR-07'> ReqModularInterfaceArchitecture :> SystemRelatedSR {
        doc
        /* Modular architecture for future ECU integration. */
        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::InReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "R&D Platform Arch Guidelines";

        require constraint :>> acceptanceCriteria {
            doc
            /* [Design] ECU integration via Port expansion without core logic change. */
        }
        @Rationale {
            doc
            /* Minimize regression testing. */
        }
        frame concern architectureFlexibility : ArchitectureFlexibilityConcern;
        @MetaInformation { version = "v0.2"; }
        @SoftGoal;
    }

    requirement def <'SHR-08'> ReqDriverPedalResponsiveness :> SystemRelatedSR {
        doc
        /* Instant acceleration response to pedal. */
        frame concern drivability : DrivabilityAndResponseConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Vehicle Dynamics & Ergonomics Guidelines";

        require constraint :>> acceptanceCriteria {
            doc
            /* [EGAS] Air/fuel cmds <=50ms upon accel. */
            egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm] implies
            (egas.airIntakePort.airFlow.responseTime <= 50.0 [milli * s] and
                egas.fuelCmdPort.fuelCmd.responseTime <= 50.0 [milli * s])
        }
        @Rationale {
            doc
            /* Overcome human perception limit. */
        }
        @HardGoal;
    }

    // 3. Project Related Requirements
    requirement def <'SHR-P01'> ReqIso26262SafetyCompliance :> ProjectRelatedSR {
        doc
        /* ISO 26262 compliance & ASIL certification. */
        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Validated;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Legal & Compliance Strategy";

        require constraint :>> acceptanceCriteria {
            doc
            /* [Process] Artifacts meet ASIL-D & pass audit. */
        }
        @Rationale {
            doc
            /* Mitigate market entry risks. */
        }
        frame concern functionalSafety : FunctionalSafetyConcern;
        @MetaInformation { version = "v0.1"; }
        @SoftGoal;
    }

    requirement def <'SHR-P02'> ReqEfficientPlatformDevelopment :> ProjectRelatedSR {
        doc
        /* Reduce R&D lead time via core logic reuse. */
        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Exec Cost Reduction Goal (2025)";

        require constraint :>> acceptanceCriteria {
            doc
            /* [Biz] Software core logic reuse >= 80%. */
        }
        @Rationale {
            doc
            /* Lower re-validation costs. */
        }
        frame concern architectureFlexibilityBiz : ArchitectureFlexibilityConcern;
        @MetaInformation { version = "v0.1"; }
        @SoftGoal;
    }

    // 4. Usage Definitions
    requirement stakeholderRequirementSet {
        requirement <'SHR-01'> reqSafeTorqueArbitration : ReqSafeTorqueArbitration;
        requirement <'SHR-02'> reqPreciseClosedLoopControl : ReqPreciseClosedLoopControl;
        requirement <'SHR-02-1'> reqSteadyStatePrecision : ReqSteadyStatePrecision;
        requirement <'SHR-02-2'> reqMisfirePrevention : ReqMisfirePrevention;
        requirement <'SHR-03'> reqFailSafeSensorMonitoring : ReqFailSafeSensorMonitoring;
        requirement <'SHR-04'> reqDynamicResponsiveness : ReqDynamicResponsiveness;
        requirement <'SHR-04-1'> reqTorqueInterventionByAirflow : ReqTorqueInterventionByAirflow;
        requirement <'SHR-04-2'> reqTorqueInterventionByFuelIgnition
            : ReqTorqueInterventionByFuelIgnition;
        requirement <'SHR-04-3'> reqTorqueInterventionFallbackFuelOnly
            : ReqTorqueInterventionFallbackFuelOnly;
        requirement <'SHR-04-4'> reqTorqueInterventionRelease : ReqTorqueInterventionRelease;
        requirement <'SHR-05'> reqPowertrainCalibrationSupport : ReqPowertrainCalibrationSupport;
        requirement <'SHR-05-1'> reqCalibrationMemoryAccess : ReqCalibrationMemoryAccess;
        requirement <'SHR-05-2'> reqCalibrationDataIntegrity : ReqCalibrationDataIntegrity;
        requirement <'SHR-06'> reqDiagnosticAndMaintenanceSupport
            : ReqDiagnosticAndMaintenanceSupport;
        requirement <'SHR-07'> reqModularInterfaceArchitecture : ReqModularInterfaceArchitecture;
        requirement <'SHR-08'> reqDriverPedalResponsiveness : ReqDriverPedalResponsiveness;
        requirement <'SHR-P01'> reqIso26262SafetyCompliance : ReqIso26262SafetyCompliance;
        requirement <'SHR-P02'> reqEfficientPlatformDevelopment : ReqEfficientPlatformDevelopment;
    }
} // package RV_StakeholderRequirementModel
