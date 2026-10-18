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
        /* Safety-first torque arbitration & Brake Override. 
         * 이 조건은 가속과 제동 입력의 선후 순서(제동 선입력, 가속 선입력, 한쪽 선해제)와 무관하게 입력 상태만으로 성립해야 한다.
         */
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
                egas.ecu.ccState,
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
            rationale = "Needs steady-state precision (SHR-02-1) & misfire prevention (SHR-02-2). 
            정상상태 오차(SHR-02-1)와 실화 방지(SHR-02-2)를 모두 충족해야만
             '정밀 폐루프 제어'라는 상위 목표가 달성됨
              (Soft 상위 목표를 검증 가능한 Hard 하위 목표로 조작화(operationalization)한 구조임)";
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
            /* [EGAS] Fuel/ign cmd <=10ms after sensor rx. 
             * 보정은 정상 주행 중 CF1 기준 명령에 직렬로 적용하는 후처리이며, 
             * 보정 결과가 최종 출력에 반영되어야 한다(SYSR-22).
             */
            egas.fuelCmdPort.fuelCmd.responseTime <=
            TimingConceptsAndLimits::compensationResponseBudget
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
            /* 가속 페달 센서(PVS1/PVS2) 또는 스로틀 위치 센서(TPS1/TPS2)의 편차가 한계를 초과한 상태가 확정 시간 이상 지속되어
             * 치명 고장으로 확정되면(SYSR-21), 시스템은 즉시 안전 상태 L3(공기/연료 전면 차단)로 진입해야 한다.
             * 과열은 센서 결함이 아니므로 SHR-09에서 다룬다.
             */
            (egas.ecu.confirmedFaultCause == FaultCause::PedalSensorDeviation or
                egas.ecu.confirmedFaultCause == FaultCause::ThrottleSensorDeviation) implies
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
            formula = "(SHR-04-1 AND SHR-04-2) OR SHR-04-3";
            rationale =
                "정상 경로(AND)에서는 공기량 저감 명령(SHR-04-1)과 연료/점화 저감 명령(SHR-04-2)을 함께 출력하고, 
                스로틀 고착이 확정되면 대체 경로(OR, SHR-04-3)로 연료 차단만으로 상위 목표를 달성한다 ... 
                (Soft 상위 목표를 검증 가능한 Hard 하위 목표로 조작화(operationalization)한 구조임)";
        }
        @MetaInformation { version = "v0.3"; }
        @SoftGoal;
    }

    requirement def <'SHR-04-1'> ReqTorqueInterventionByAirflow :> 'SHR-04' {
        :>> criticalityLevel = CriticalityLevel::Major;
        assume constraint normalCommunication {
            doc
            /* 외부 제어기 요청이 정상 통신 범위(messageAge가 commDelayThreshold 이하)로 도착한다고 가정한다. */
            egas.torqueInterventionPort.torqueReq.messageAge <=
            TimingConceptsAndLimits::commDelayThreshold
        }
        require constraint :>> acceptanceCriteria {
            doc
            /* Reduce airflow mass <= 15ms upon ESP/TCU req. 응답 한계는 interventionResponseBudget이다. */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            (egas.airIntakePort.airFlow.responseTime <=
                TimingConceptsAndLimits::interventionResponseBudget and
                egas.airIntakePort.airFlow.massFlow < egas.airIntakePort.airFlow.previousMassFlow)
        }
        @Rationale {
            doc
            /* ESP/TCU의 토크 저감 요청 시, EGAS는 스로틀 공기량 저감 명령을 15ms 이내에 출력해야 한다.
             * (이 요구는 명령 출력 시점을 규정하며, 물리적 토크 응답은 연료/점화 경로인 SHR-04-2가 담당한다.)
             */
        }
        @HardGoal;
    }

    requirement def <'SHR-04-2'> ReqTorqueInterventionByFuelIgnition :> 'SHR-04' {
        :>> criticalityLevel = CriticalityLevel::Major;
        assume constraint normalCommunication {
            doc
            /* 외부 제어기 요청이 정상 통신 범위(messageAge가 commDelayThreshold 이하)로 도착한다고 가정한다. */
            egas.torqueInterventionPort.torqueReq.messageAge <=
            TimingConceptsAndLimits::commDelayThreshold
        }
        require constraint :>> acceptanceCriteria {
            doc
            /* Reduce fuel injection <= 15ms upon ESP/TCU req. */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            (egas.fuelCmdPort.fuelCmd.responseTime <=
                TimingConceptsAndLimits::interventionResponseBudget and
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth <
                egas.fuelCmdPort.fuelCmd.previousPulseWidth)
        }
        @Rationale {
            doc
            /* Mandatory for urgent events. 
             * 흡기 매니폴드의 구조적 체적으로 인해 공기량 제어만으로는 15ms 이내의 물리적 토크 응답을 보장하기 어려우므로,
             * 연료 분사/점화 저감 명령을 병행해야 한다. (명령 출력 시점은 SHR-04-1과 같은 15ms 한도)
             */
        }
        @HardGoal;
    }

    requirement def <'SHR-04-3'> ReqTorqueInterventionFallbackFuelOnly :> 'SHR-04' {
        :>> criticalityLevel = CriticalityLevel::Critical;

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
                egas.fuelCmdPort.fuelCmd.responseTime <=
                TimingConceptsAndLimits::stuckCutResponseBudget)
        }
        @Rationale {
            doc
            /* Ensure torque reduction despite air path failure. 본 요구는 상위 SHR-04의 논리식에서 OR 항(대체 경로)이다. */
        }
        @HardGoal;
    }

    requirement def <'SHR-04-4'> ReqTorqueInterventionRelease :> 'SHR-04' {
        :>> criticalityLevel = CriticalityLevel::Major;
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

        attribute calibrationAuthorized : Boolean = DtcStroage::IsCalibrationAuthorized(
            egas.calibrationPort.calReq.targetMemoryAddress,
            egas.calibrationPort.calReq.accessCredential,
            egas.ecu.expectedAccessCredential,
            egas.calibrationPort.calReq.operation,
            egas.ignitionPort.ignitionStatus.status,
            egas.sensorPort.dynamicsStatus.vehicleSpeed
        );

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
            rationale =
                "Requires memory access control (SHR-05-1) & data integrity (SHR-05-2)…상위 목표가 달성됨 (Soft 상위 목표를 검증 가능한 Hard 하위 목표로 조작화(operationalization)한 구조임)";
        }
        @MetaInformation { version = "v0.3"; }
        @SoftGoal;
    }

    requirement def <'SHR-05-1'> ReqCalibrationMemoryAccess :> 'SHR-05' {
        require constraint :>> acceptanceCriteria {
            doc
            /* 인가되지 않은 접근(잘못된 주소, 자격 불일치, 점화 OFF, 주행 중 쓰기)에는 오류 코드(200 이외)를 반환하고,
             * 인가된 읽기에는 정상 코드(200)를 반환해야 한다.
             */
            (not calibrationAuthorized implies
                egas.calibrationPort.calStatus.responseCode != 200) and
            ((calibrationAuthorized and
                    egas.calibrationPort.calReq.operation == CalibrationOperationEnum::Read) implies
                egas.calibrationPort.calStatus.responseCode == 200)
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
            /* 인가된 쓰기에서 EGAS가 계산한 체크섬이 요청 체크섬과 같으면 정상 코드와 롤백 없음을, 다르면 오류 코드와 롤백을 반환해야 한다.
             * (구 식 address > 0 ⇒ checksum > 0은 검증 실패 경로를 막았다)
             */
            (calibrationAuthorized and
                egas.calibrationPort.calReq.operation == CalibrationOperationEnum::Write) implies
            ((egas.calibrationPort.calStatus.verifiedChecksum ==
                    egas.calibrationPort.calReq.payloadChecksum implies
                    (egas.calibrationPort.calStatus.responseCode == 200 and
                        egas.calibrationPort.calStatus.rolledBack == false)) and
                (egas.calibrationPort.calStatus.verifiedChecksum !=
                    egas.calibrationPort.calReq.payloadChecksum implies
                    (egas.calibrationPort.calStatus.responseCode != 200 and
                        egas.calibrationPort.calStatus.rolledBack == true)))
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
            private import DtcStroage::*;
            doc
            /* DTC 조회는 저장된 DTC가 있으면 그 값을, 없으면 정상 응답과 DTC 0을 반환한다.
             * 영점 조정(RoutineControl)은 점화 ON과 정차 상태에서만 수행하고, 그 외 상태와 미지원 서비스에는 오류 코드를 반환한다.
             */
            ((egas.diagPort.diagReq.serviceId == diagServiceReadDtc and
                    egas.ecu.storedDtcCode > 0) implies
                (egas.diagPort.diagStatus.responseCode == 200 and
                    egas.diagPort.diagStatus.dtcCode == egas.ecu.storedDtcCode)) and
            ((egas.diagPort.diagReq.serviceId == diagServiceReadDtc and
                    egas.ecu.storedDtcCode == 0) implies
                (egas.diagPort.diagStatus.responseCode == 200 and
                    egas.diagPort.diagStatus.dtcCode == 0)) and
            ((egas.diagPort.diagReq.serviceId == diagServiceRoutineControl and
                    IsServiceModeAllowed(
                        egas.ignitionPort.ignitionStatus.status,
                        egas.sensorPort.dynamicsStatus.vehicleSpeed
                    )) implies
                egas.diagPort.diagStatus.responseCode == 200) and
            ((egas.diagPort.diagReq.serviceId == diagServiceRoutineControl and
                    not IsServiceModeAllowed(
                        egas.ignitionPort.ignitionStatus.status,
                        egas.sensorPort.dynamicsStatus.vehicleSpeed
                    )) implies
                egas.diagPort.diagStatus.responseCode != 200) and
            ((egas.diagPort.diagReq.serviceId != diagServiceReadDtc and
                    egas.diagPort.diagReq.serviceId != diagServiceRoutineControl) implies
                egas.diagPort.diagStatus.responseCode != 200)
        }
        @Rationale {
            doc
            /* [목표 유형] 관련 관심사는 Soft이지만 본 요구는 정량 인수 조건을 가지므로 Hard로 조작화(operationalization)함
             * Reduce repair time.
             */
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
            /* 1. [EGAS 보장] 가속 페달 입력(>0) 수신 후 pedalResponseBudget 이내에 공기/연료 제어 명령을 출력한다.
             * 2. [관측 기준] 종방향 Jerk 한계는 차량(플랜트) 결과이므로 SYSR-26과 TestDriverPedalResponsiveness에서 판정한다.
             * 3. [예외 조항] 제동 오버라이드(SHR-01), 치명 고장(SHR-03, SHR-09), 외부 토크 개입(SHR-04) 중에는
             *    안전이 우선하며 Jerk 기준을 적용하지 않는다.
             */
            egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm] implies
            (egas.airIntakePort.airFlow.responseTime <=
                TimingConceptsAndLimits::pedalResponseBudget and
                egas.fuelCmdPort.fuelCmd.responseTime <=
                TimingConceptsAndLimits::pedalResponseBudget)
        }
        @Rationale {
            doc
            /* [목표 유형] 관련 관심사는 Soft이지만 본 요구는 정량 인수 조건을 가지므로 Hard로 조작화(operationalization)함 
             * [충돌 해소] SHR-01/03/04의 안전 개입은 급격한 토크 변화를 수반하므로, Jerk 기준은 정상 주행에서만 적용한다.
             * 관계는 Concern 모델의 GoalRelationship(Negative)에 선언되어 있다. 
             * Overcome human perception limit.
             */
        }
        @HardGoal;
    }

    requirement def <'SHR-09'> ReqEngineOverheatProtection :> SystemRelatedSR {
        doc
        /* 엔진 냉각수 온도가 안전 한계를 초과하면 엔진 파손을 막기 위해 안전 상태로 진입하여 열 보호를 수행한다. 
         * (구 SHR-03 acceptance에서 분리)
         */

        frame concern hardwareFailure : HardwareFailureConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "엔진 열 보호 요구 (구 SHR-03 acceptance에서 이관)";

        require constraint :>> acceptanceCriteria {
            doc
            /* 냉각수 온도가 한계(120 °C = 393.15 K)를 초과한 상태가 확정 시간 이상 지속되어 과열로 확정되면,
             * 안전 상태 L3(공기/연료 전면 차단)로 진입해야 한다.
             */
            egas.ecu.confirmedFaultCause == FaultCause::Overheat implies
            SafeStateLogic::IsFullCutOff(
                egas.airIntakePort.airFlow.massFlow,
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth
            )
        }

        @Rationale {
            doc
            /* 과열은 센서 고장이 아니라 열 보호 조건이므로 별도 고장 원인으로 관리한다. 
             * 현행 거동(전면 차단)을 보존했으며, 토크 제한(L1) 등으로 완화할지는 안전 정책 결정 사항이다.
             */
        }

        @MetaInformation { version = "v0.1"; }
        @HardGoal;
    }

    requirement def <'SHR-10'> ReqCruiseSpeedHold :> SystemRelatedSR {
        doc
        /* 크루즈 컨트롤이 활성화되면 설정 속도를 정상 상태 오차 이내로 유지하고, 
         * 운전자의 제동/가속 조작에는 안전하게 우선권을 양보한다.
         */

        frame concern preciseControl : PreciseControlConcern;

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "UC1 대안 시나리오 VC#04 (정속 주행 정밀도)에서 분리";

        require constraint :>> acceptanceCriteria {
            doc
            /* [EgasContext 수준 폐루프 성과 기준 - 판정: TestCruiseSpeedHold]
             * 크루즈 Active 상태에서 설정 속도 대비 속도 오차율이 cruiseSpeedErrorLimitPct(2.0%) 이내로 수렴해야 한다.
             * 차속은 차량(플랜트)의 결과이므로 EGAS 경계 값의 보장식으로 쓰지 않는다.
             * EGAS 소유 보장(크루즈 상태 전이와 우선순위)은 SYSR-23이 담당한다.
             */
        }

        @Rationale {
            doc
            /* 정속 주행 편의 기능이며, 제동/가속 안전 요구(SHR-01)와 충돌 시 안전이 우선한다. */
        }

        @MetaInformation { version = "v0.1"; }
        @SoftGoal;
    }

    // 3. Project Related Requirements
    requirement def <'SHR-P01'> ReqIso26262SafetyCompliance :> ProjectRelatedSR {
        doc
        /* ISO 26262 compliance & ASIL certification. */
        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::InReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "Legal & Compliance Strategy";

        require constraint :>> acceptanceCriteria {
            doc
            /* [Process] Artifacts meet ASIL-D & pass audit. */
        }
        @Rationale {
            doc
            /* 시장 진입 리스크 해소 및 대규모 리콜 사태를 원천 차단하기 위한 필수 비즈니스 제약
             * [M6] 기능안전 관심사(FunctionalSafetyConcern)가 Hard이므로 본 요구도 Hard이다.
             */
        }
        frame concern functionalSafety : FunctionalSafetyConcern;
        @MetaInformation { version = "v0.1"; }
        @HardGoal;
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
        requirement <'SHR-09'> reqEngineOverheatProtection : ReqEngineOverheatProtection;
        requirement <'SHR-10'> reqCruiseSpeedHold : ReqCruiseSpeedHold;
    }
} // package RV_StakeholderRequirementModel
