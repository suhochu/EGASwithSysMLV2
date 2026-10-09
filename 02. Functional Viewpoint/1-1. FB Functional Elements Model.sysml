package FB_FunctionalBlackBoxModel {
    doc
    /* [기능 블랙박스 모델 (Functional Black Box Model)]
     * 본 패키지는 SPES 2020 방법론의 기능 관점(Functional Viewpoint)을 구현합니다.
     * 시스템을 완벽한 블랙박스로 간주하고, 외부 액터와 주고받는 인터페이스(Port/Item)만을 활용하여
     * 사용자에게 독자적인 가치를 제공하는 '유저 기능(User Function)'을 계층적으로 정의합니다.
     * 내부 시스템 컴포넌트(ECU, Throttle Valve 등)에 대한 참조는 철저히 배제됩니다.
     */

    private import ReqCommon::*;
    private import RV_InterfaceModel::*;
    private import RV_StakeholderRequirementModel::*;
    private import RV_SystemRequirementsModel::*;
    private import RV_UseCases::*;
    private import ScalarValues::*;
    private import SI::*;
    private import RV_SystemRequirementsModel::Functional_Requirements::*;
    private import RV_SystemRequirementsModel::Performance_Requirements::*;
    private import RV_SystemRequirementsModel
            ::Diagnostics_Maintainability_Security_Architecture_Requirements::*;
    private import TimingConceptsAndLimits::*;

    @MetaInformation {
        version = "v0.1";
    }

    enum def FunctionalElementCategory {
        Atomic;
        Composite;
    }

    metadata def FunctionalElementsInfo {
        attribute category : FunctionalElementCategory;
        attribute Rationale : String;
        attribute FeatureInteraction : String;
        attribute NextStep : String;
    }

    // =========================================================================
    // Composite 1. 주행 토크 제어 및 중재 기능 (Driving Torque Management)
    // =========================================================================

    action def <CF1> DrivingTorqueManagementAndArbitration {
        doc description
        /* 운전자의 페달 조작 및 크루즈 컨트롤 시스템의 주행 의지를 수용하고, 가속/제동이 상충할 때 
         * 안전 최우선 원칙(제동 우선)에 따라 중재하여 최종 구동계 제어 명령을 출력하는 통합 기능입니다.
         */

        @FunctionalElementsInfo {
            category = FunctionalElementCategory::Composite;
            Rationale =
                "외부 액터(운전자) 관점에서 시스템은 개별 신호 처리기가 아닌, \"내 의도대로 차량을 주행시키고 
                위험 시 멈춰주는 하나의 완결된 주행 동력 제어기\"로 인지되므로 이를 하나의 복합 블랙박스 기능으로 묶어 도출했습니다.";
            FeatureInteraction =
                "UF-1.1(가속)과 UF-1.3(제동)이 동시 발생 시, 출력(airIntakePort, fuelCmdPort) 제어 권한이 충돌합니다.";
            NextStep =
                "기능 화이트박스 설계 시, UF-1.3이 활성화되면 내부 '모드 채널(Mode Channel)'을 통해 'Brake_Override_Active' 
                상태를 UF-1.1과 UF-1.2로 전송하여 가속 출력을 강제 무효화하도록 설계해야 합니다.";
        }

        satisfy requirement 'SYSR-23'; // reqCruiseStateAndPriority (크루즈 상태머신)

        // -----------------------------------------
        // 1.1 수동 가속 제어 (Atomic)
        // -----------------------------------------

        action def <CF1_1> ManualAccelerationControl {
            doc description
            /* 운전자의 물리적 가속 의지를 전자 신호로 변환해 목표 토크를 산출하고 부드럽게 가속합니다. */

            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency
                self
                to 'Driving Torque Demand Arbitration & Control'::UC1_Normal_Manual_Acceleration;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqSafeTorqueArbitration; // SHR-01
            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqDriverPedalResponsiveness; // SHR-08
            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqSteadyStatePrecision; // SHR-02-1

            satisfy requirement 'SYSR-13'; // reqPedalResponseAndRideComfort
            satisfy requirement 'SYSR-08'; // reqCombustionControlExecutionTiming

            in ignition : IgnitionState;
            in accel : AccelerationIntent;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            // 제약식(Constraint) 내의 변수명도 Item 파라미터 이름에 맞춰 업데이트
            constraint Precondition {
                ignition.status == IgnitionStatusEnum::On and accel.pedalDisplacement > 0.0 [mm]
            }
            constraint PerformanceConstraints {
                airCmd.responseTime <= cf1PathBudget and fuelCmd.responseTime <= cf1PathBudget
            }
        }

        // -----------------------------------------
        // 1.2 정속 주행 제어 (Atomic)
        // -----------------------------------------
        action def <CF1_2> CruiseControlDriving {
            doc description
            /* 설정 속도와 실제 차속의 오차를 기반으로 목표 토크를 자동 산출하는 속도 폐루프 정속 주행 제어를 수행합니다. */
            @FunctionalElementsInfo { category = FunctionalElementCategory::Atomic; }

            dependency
                self
                to
                    'Driving Torque Demand Arbitration & Control'
                        ::UC1_Alternative_Cruise_Control_Driving;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqSafeTorqueArbitration; // SHR-01
            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqSteadyStatePrecision; // SHR-02-1 (토크 루프)
            satisfy RV_StakeholderRequirementModel::stakeholderRequirementSet.reqCruiseSpeedHold; // SHR-10 (속도 루프)
            satisfy RV_SystemRequirementsModel::Functional_Requirements::reqCruiseStateAndPriority; // SYSR-23
            satisfy requirement 'SYSR-08';

            in targetSpeed : ISQ::SpeedValue;
            in dynamics : VehicleDynamicsFeedback; // 차속 피드백
            in combustionSystemStatus : CombustionSystemStatus; // 토크 추종 피드백 (내부 토크 루프)
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            constraint Precondition { targetSpeed > 0.0 [km / h] }

            constraint cruiseSpeedHoldLimit {
                // Before: steadyStateErrorLimit (토크 오차를 속도 오차로 오기재)
                @PlantObservation;
                CruiseControlLogic::IsCruiseSpeedHeld(
                    targetSpeed,
                    dynamics.vehicleSpeed,
                    CruiseControlLogic::cruiseSpeedErrorLimitPct
                )
            }
        }

        // -----------------------------------------
        // 1.3 제동 우선 오버라이드 제어 (Atomic)
        // -----------------------------------------
        action def <CF1_3> BrakeOverrideIntervention {
            doc description
            /* 제동 조작 시 가속/크루즈 입력을 무효화하고 스로틀 및 연료 분사를 즉각 제한(L1)합니다. */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency
                self
                to
                    'Driving Torque Demand Arbitration & Control'
                        ::UC1_Exception_Brake_Override_Intervention;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqSafeTorqueArbitration; // SHR-01

            satisfy RV_SystemRequirementsModel::Functional_Requirements::reqBrakeOverrideLogic; // SYSR-01a
            satisfy requirement 'SYSR-01a'; // reqBrakeOverrideLogic
            satisfy requirement 'SYSR-01b'; // reqBrakeOverrideTiming
            satisfy requirement 'SYSR-10'; // reqCruiseControlBrakeCancel
            satisfy requirement 'SYSR-20'; // reqSafeStateLevels (L1)

            in overrideTriggered : Boolean;
            out airCmd : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            constraint Precondition {
                overrideTriggered == true
            }
            constraint SafeStateConstraints {
                SafeStateLogic::IsTorqueLimited(airCmd.massFlow, fuelCmd.injectionPulseWidth)
            }

            // UC1_Exception 시나리오에서 요구하는 10ms 응답 성능 제약 명시
            constraint PerformanceConstraints {
                airCmd.responseTime <= 10.0 [milli * s] and fuelCmd.responseTime <= 10.0 [milli * s]
            }
        }

        // -----------------------------------------
        // 2.4 개입 요청 무결성 검사 (Atomic) [M1 신규]
        // -----------------------------------------
        action def <UF2_4> InterventionRequestIntegrityGuard {
            doc description
            /* 외부 제어기 토크 개입 요청의 프로토콜 무결성(체크섬/Alive counter/타임아웃)을 검사하고,
             * 오류가 감지되면 개입 요청을 0(개입 없음)으로 무효화한 요청을 출력합니다. 정상 요청은 그대로 통과시킵니다.
             */
            @FunctionalElementsInfo { category = FunctionalElementCategory::Atomic; }

            dependency self to 'Emergency Intervention'::UC2_Normal_Emergency_Torque_Reduction;

            satisfy requirement 'SYSR-05'; // reqProtocolIntegrityCheck

            in torqueIntervention : TorqueInterventionRequest;
            in integrityError : Boolean; // 체크섬/Alive counter 오류 또는 타임아웃(SYSR-15의 동결 종료 시점)
            out validatedRequest : TorqueInterventionRequest;

            constraint IntegrityGuard {
                // 오류 시 개입량 0 (SYSR-05: outputValue를 0으로 무효화)
                integrityError == true implies validatedRequest.requestedTorqueDelta == 0.0 [N * m]
            }
            constraint PassThrough {
                integrityError == false implies validatedRequest == torqueIntervention
            }
        }

        // 복합 기능 내 원자 기능 인스턴스화
        action manualAccel : ManualAccelerationControl;
        action cruiseDrive : CruiseControlDriving;
        action brakeOverride : BrakeOverrideIntervention;
        action interventionRequestIntegrityGuard : InterventionRequestIntegrityGuard;
    }
    // =========================================================================
    // Composite 2. 긴급 토크 개입 및 보상 기능 (Emergency Torque Intervention)
    // =========================================================================

    action def <CF2> EmergencyTorqueInterventionAndCompensation {
        doc description
        /* 차량 자세 제어기(ESP), 변속기(TCU) 등 외부 제어기의 긴급 개입 요구를 밀리초 단위로 수용하고,
         * 통신 지연이나 액추에이터 고착 등의 예외 상황을 자체 보상/차단하는 기능입니다.
         */

        @FunctionalElementsInfo {
            category = FunctionalElementCategory::Composite;
            Rationale =
                "외부 능동안전 제어기(AddEcu) 입장에서는 EGAS 시스템이 미끄럼 방지 등 긴급 상황에서 
                \"즉각적으로 동력을 뺏어주는 고신뢰성 구동계 슬레이브(Slave)\"역할을 수행해야 하므로 하나의 상위 복합 기능으로 도출했습니다.";
            FeatureInteraction =
                "UF-2.1(공기량 축소 시도)과 UF-2.3(공기량 고착 시 연료 차단 시도)은 논리적으로 대체(OR) 경로입니다.";
            NextStep =
                "타이머(Timer) 로직을 모드 채널로 구현하여, 토크 저감 요청 후 일정 시간(10ms) 내에 
                공기량 피드백이 줄지 않으면(Stuck), 즉시 모드를 UF-2.3으로 전환하는 내부 상태 머신 설계가 필요합니다.";
        }

        satisfy requirement 'SYSR-19'; // reqInterventionReleaseAndReset

        // -----------------------------------------
        // 2.1 병렬 토크 저감 제어 (Atomic)
        // -----------------------------------------
        action def <CF2_1> ParallelTorqueReduction {
            doc description
            /* ESP/TCU의 긴급 토크 저감 요청을 수신하여 15ms 이내에 목표 공기량을 축소함과 동시에, 
             * 연료 인젝션 펄스 단축 및 점화 시기를 지각시켜 신속하게 토크를 저감합니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Emergency Intervention'::UC2_Normal_Emergency_Torque_Reduction;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqTorqueInterventionByAirflow; // SHR-04-1
            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqTorqueInterventionByFuelIgnition; // SHR-04-2

            satisfy requirement 'SYSR-03'; // reqExternalInterventionLatency

            in torqueIntervention : TorqueInterventionRequest;
            out airIntake : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            constraint Precondition {
                torqueIntervention.requestedTorqueDelta < 0.0 [N * m] and
                torqueIntervention.messageAge <= commDelayThreshold
            }
            constraint InterventionLatency {
                airIntake.responseTime <= interventionResponseBudget and
                fuelCmd.responseTime <= interventionResponseBudget
            }
            constraint ReductionConstraints {
                airIntake.massFlow < airIntake.previousMassFlow and
                fuelCmd.injectionPulseWidth < fuelCmd.previousPulseWidth
            }
        }

        // -----------------------------------------
        // 2.2 통신 지연 보상 제어 (Atomic)
        // -----------------------------------------
        action def <CF2_2> CommunicationDelayCompensation {
            doc description
            /* 외부 제어기와의 통신 지연으로 일시적인 토크 저감 신호 누락 발생 시, 타임아웃 전까지 
             * 직전의 유효한 토크 저감 요구값을 기반으로 자체 보상 제어를 유지합니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency
                self
                to 'Emergency Intervention'::UC2_Alternative_Communication_Delay_Compensation;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqDynamicResponsiveness; // SHR-04

            satisfy requirement 'SYSR-15'; // reqCommDelayControlValueFreeze

            in torqueIntervention : TorqueInterventionRequest;
            out airIntake : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            constraint DelayCompensation {
                (torqueIntervention.messageAge > commDelayThreshold and
                    torqueIntervention.messageAge <= commTimeout) implies
                (airIntake.massFlow == airIntake.previousMassFlow and
                    fuelCmd.injectionPulseWidth == fuelCmd.previousPulseWidth)
            }
        }

        // -----------------------------------------
        // 2.3 고착 대응 연료 차단 제어 (Atomic)
        // -----------------------------------------
        action def <CF2_3> ActuatorStuckFuelCut {
            doc description
            /* 긴급 개입 중 스로틀 밸브 고착이 확정되면(목표/실제 개도 편차 지속 판정 결과),
             * 공기량 제어 시도를 포기하고 엔진 보호를 위해 연료 시스템을 전면 차단합니다.
             * 고착 판정(디바운스)은 FE 상태머신이 수행하며, 본 기능은 확정 플래그를 받아 차단만 수행합니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Emergency Intervention'::UC2_Exception_Actuator_Stuck_Fuel_Cut;

            satisfy RV_SystemRequirementsModel::Functional_Requirements::reqActuatorStuckFuelCut; // SYSR-14
            satisfy requirement 'SYSR-20'; // (L2)

            in stuckConfirmed : Boolean; // 스로틀 고착 확정 플래그 (IsThrottleStuck 판정 결과)
            out fuelCmd : FuelIgnitionCommand;

            constraint StuckFailSafe {
                stuckConfirmed == true implies
                SafeStateLogic::IsFuelCutOff(fuelCmd.injectionPulseWidth)
            }
            constraint StuckResponseTime {
                // SYSR-14의 확정 후 10ms
                stuckConfirmed == true implies fuelCmd.responseTime <= stuckCutResponseBudget
            }
        }

        // -----------------------------------------
        // 2.4 긴급 개입 해제 및 제어권 복귀 (Atomic)
        // -----------------------------------------
        action def <CF2_4> InterventionReleaseControl {
            doc description
            /* 외부 제어기의 토크 저감 해제 요청을 수신하여 긴급 개입을 종료하고, 
             * 공기/연료 제어권을 운전자 요구 기반 제어로 복귀시킵니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Emergency Intervention'::UC2_Alternative_Intervention_Release;

            // Stakeholder 및 System 요구사항을 실현(Satisfy)
            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqTorqueInterventionRelease; // SHR-04-4
            satisfy
                RV_SystemRequirementsModel::Functional_Requirements::reqInterventionReleaseAndReset; // SYSR-19

            in torqueIntervention : TorqueInterventionRequest;
            out airIntake : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            constraint Precondition {
                torqueIntervention.requestedTorqueDelta >= 0.0 [N * m]
            }
        }

        action parallelReduct : ParallelTorqueReduction;
        action delayComp : CommunicationDelayCompensation;
        action stuckCut : ActuatorStuckFuelCut;
        action releaseCtrl : InterventionReleaseControl;
    }

    // =========================================================================
    // Composite 3. 하드웨어 안전 모니터링 및 페일세이프 (Hardware Safety Monitoring)
    // =========================================================================

    action def <CF3> HardwareSafetyMonitoringAndFailSafe {
        doc description
        /* 외부 센서들의 물리적 한계나 결함을 실시간으로 감시하여 정상 시에는 오차를 보정하고, 
         * 온도 초과 등의 치명적 결함 시 즉각 시스템을 차단(페일세이프)하는 기능입니다.
         */

        @FunctionalElementsInfo {
            category = FunctionalElementCategory::Composite;
            Rationale = "ISO 26262 안전 규제 기관 및 탑승자 관점에서 차량 제어 시스템은
                주행(제어) 기능과 완벽히 분리된 독립적인 \"안전 감시자(Safety Monitor)\" 계층을
                제공해야 하므로 별도의 복합 기능으로 도출했습니다.";
        }

        satisfy requirement 'SYSR-21'; // reqFaultConfirmationAndLatch

        // -----------------------------------------
        // 3.1 하드웨어 마찰 및 지연 보정 제어 (Atomic)
        // -----------------------------------------
        action def <CF3_1> HardwareDelayAndFrictionCompensation {
            doc description
            /* 정상 주행 중 CF1이 산출한 기준 명령(공기/연료)에 하드웨어 마찰 및 지연 보정을 직렬로 적용하여 최종 명령을 출력합니다. (후처리 단계) */

            private import SafeStateLogic::*;

            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Hardware Fail-safe'::UC3_Normal_Hardware_Delay_Compensation;

            satisfy RV_StakeholderRequirementModel::stakeholderRequirementSet.reqMisfirePrevention; // SHR-02-2
            satisfy
                RV_SystemRequirementsModel::Functional_Requirements
                        ::reqCompensationAsSeriesPostProcessing; // SYSR-22
            satisfy requirement 'SYSR-08';

            in baseAirCmd : IntakeAirFlow; // CF1 기준 명령
            in baseFuelCmd : FuelIgnitionCommand; //
            in sensor : EngineSensorData; // 회전수 등 보정 파라미터 입력 (과열 게이팅은 SYSR-21로 이동)
            in combustionStatus : CombustionSystemStatus;
            out airIntake : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;

            constraint ResponseTimeConstraint {
                // 이 단계 자체의 처리시간 (S1/S7: 과열 antecedent 삭제)
                fuelCmd.responseTime <= compensationBudget
            }

            constraint BoundedCorrection {
                // 기준 명령에 대한 가감량 제한
                airIntake.massFlow >= baseAirCmd.massFlow - maxAirCorrection and
                airIntake.massFlow <= baseAirCmd.massFlow + maxAirCorrection and
                fuelCmd.injectionPulseWidth >=
                baseFuelCmd.injectionPulseWidth - maxFuelCorrection and
                fuelCmd.injectionPulseWidth <= baseFuelCmd.injectionPulseWidth + maxFuelCorrection
            }

            constraint MisfireObservation {
                @PlantObservation;
                combustionStatus.misfireRate <= 0.0 [Hz]
            }
        }

        // -----------------------------------------
        // 3.2 치명적 센서 결함 페일세이프 제어 (Atomic)
        // -----------------------------------------
        action def <CF3_2> CriticalSensorFaultFailSafe {
            doc description
            /* 치명적인 하드웨어 결함 감지 시 급발진 및 엔진 파손을 막기 위해 즉각 공기 유입을 차단하고 연료 제어를 전면 중단합니다. */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Hardware Fail-safe'::UC3_Exception_Critical_Sensor_Fault_FailSafe;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqFailSafeSensorMonitoring; // SHR-03
            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqEngineOverheatProtection; // SHR-09

            satisfy requirement 'SYSR-07'; // reqSafeStateEnforcementOnFault
            satisfy requirement 'SYSR-20'; // (L3)

            in faultCause : FaultCause;
            out airIntake : IntakeAirFlow;
            out fuelCmd : FuelIgnitionCommand;
            out dashboard : DashboardWarning;

            constraint FatalFaultCutoff {
                faultCause != FaultCause::NoFault implies
                (SafeStateLogic::IsFullCutOff(airIntake.massFlow, fuelCmd.injectionPulseWidth) and
                    dashboard.status == DashboardWarningStatusEnum::Critical)
            }
        }

        // -----------------------------------------
        // 3.3 이중화 센서 편차 감시 (Atomic)
        // -----------------------------------------
        action def <CF3_3> RedundantSensorDeviationMonitoring {
            private import SafeStateLogic::*;
            doc description
            /* 가속 페달 센서(PVS1/PVS2)와 스로틀 위치 센서(TPS1/TPS2)의 이중화 채널 편차를 감시하여 순간 편차 플래그를 산출합니다.
             * 확정 시간 판정과 래치는 CF3 상태머신(SYSR-21)이 담당합니다.
             */
            @FunctionalElementsInfo { category = FunctionalElementCategory::Atomic; }

            dependency self to 'Hardware Fail-safe'::UC3_Exception_Critical_Sensor_Fault_FailSafe;

            satisfy requirement 'SYSR-02'; // reqPvsRedundancyFaultDetection
            satisfy requirement 'SYSR-06'; // reqTpsRedundancyFaultDetection

            in pedalPosition : AccelerationPedalPosition;
            in throttleFeedback : ThrottlePositionFeedback;
            out pedalFaultFlag : Boolean;
            out throttleFaultFlag : Boolean;

            constraint PedalDeviation {
                pedalFaultFlag ==
                IsChannelDeviated(
                    pedalPosition.pvs1Percentage,
                    pedalPosition.pvs2Percentage,
                    redundancyDeviationLimit
                )
            }
            constraint ThrottleDeviation {
                throttleFaultFlag ==
                IsChannelDeviated(
                    throttleFeedback.tps1Percentage,
                    throttleFeedback.tps2Percentage,
                    redundancyDeviationLimit
                )
            }
        }

        // -----------------------------------------
        // 3.4 스로틀 추종 편차 감시 (Atomic)
        // -----------------------------------------
        action def <CF3_4> ThrottleTrackingMonitoring {
            doc description
            /* 스로틀 목표 개도와 실제 개도(TPS)의 편차를 감시하여 순간 추종 편차 플래그를 산출합니다.
             * 긴급 개입 중 고착 확정(디바운스)은 CF2 상태머신(S4)이 같은 판정식(IsThrottleDeviated)으로 수행합니다.
             */
            @FunctionalElementsInfo { category = FunctionalElementCategory::Atomic; }

            dependency self to 'Emergency Intervention'::UC2_Exception_Actuator_Stuck_Fuel_Cut;

            satisfy requirement 'SYSR-04'; // reqThrottleClosedLoopAccuracy

            in throttleCmd : ThrottlePositionCommand;
            in throttleFeedback : ThrottlePositionFeedback;
            out trackingFaultFlag : Boolean;

            constraint TrackingDeviation {
                trackingFaultFlag ==
                ThrottleStuckLogic::IsThrottleDeviated(
                    throttleCmd.openingPercentage,
                    throttleFeedback.openingPercentage,
                    ThrottleStuckLogic::stuckDeviationLimit
                )
            }
        }

        action delayComp : HardwareDelayAndFrictionCompensation;
        action fatalFailSafe : CriticalSensorFaultFailSafe;
        action redundantSensorDeviationMonitoring : RedundantSensorDeviationMonitoring;
        action throttleTrackingMonitoring : ThrottleTrackingMonitoring;
    }

    // =========================================================================
    // Composite 4. 파워트레인 캘리브레이션 지원 기능 (Powertrain Calibration Support)
    // =========================================================================

    action def <CF4> PowertrainCalibrationSupport {
        doc description
        /* 엔지니어가 사용하는 XCP/CCP 튜닝 장비의 유효한 메모리 접근만을 허가하고, 
         * 기록된 튜닝 데이터의 무결성을 검증하여 안전한 성능 최적화 환경을 제공합니다.
         */

        @FunctionalElementsInfo {
            category = FunctionalElementCategory::Composite;
            Rationale =
                "주행이나 안전 모니터링과는 목적과 대상(Calibration Engineer)이 완전히 다른  
                오프라인/정비 환경의 비즈니스 유스케이스이므로 논리적으로 분리된 블랙박스로 정의했습니다.";
        }

        // -----------------------------------------
        // 4.1 메모리 접근 인가 제어 (Atomic)
        // -----------------------------------------
        action def <CF4_1> MemoryAccessAuthorization {
            doc description
            /* 외부 캘리브레이션 툴이 유효한 메모리 주소로 접근 시, 정상 상태 코드를 반환하여 통신 세션 및 접근을 허용합니다. */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Powertrain Calibration'::UC4_Normal_Memory_Access_Authorization;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqCalibrationMemoryAccess; // SHR-05-1
            satisfy requirement 'SYSR-16'; // reqMemoryAccessAuthorizationAndRollback

            in calibration_Req : CalibrationRequest;
            out calibration_Res : CalibrationStatus;

            constraint ValidAccess {
                calibration_Req.targetMemoryAddress > 0 implies
                (calibration_Res.responseCode == 200 and
                    calibration_Res.responseTime <= accessAuthBudget)
            }
        }

        // -----------------------------------------
        // 4.2 맵 데이터 무결성 검증 제어 (Atomic)
        // -----------------------------------------
        action def <CF4_2> DataIntegrityVerification {
            doc description
            /* 파라미터 튜닝 데이터가 기록된 직후, 시스템 자체 검증을 거쳐 유효한 메모리 체크섬을 반환하여 업데이트를 확정합니다. */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Powertrain Calibration'::UC4_Normal_Data_Integrity_Verification;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqCalibrationDataIntegrity; // SHR-05-2
            satisfy requirement 'SYSR-11'; // reqCalibrationMapUpdateLatency

            in calibration_Req : CalibrationRequest;
            out calibration_Res : CalibrationStatus;

            constraint IntegrityCheck {
                calibration_Req.targetMemoryAddress > 0 implies calibration_Res.verifiedChecksum > 0
            }
        }

        // -----------------------------------------
        // 4.3 비유효 접근 거절 및 롤백 제어 (Atomic)
        // -----------------------------------------
        action def <CF4_3> InvalidAccessRejectionAndRollback {
            doc description
            /* 유효하지 않은 메모리 주소로 접근하거나 검증 실패 시, 에러 응답을 반환하고 업데이트된 데이터를 롤백하여 오작동을 차단합니다. */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency
                self
                to 'Powertrain Calibration'::UC4_Exception_Invalid_Access_Or_Verification_Failure;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet.reqCalibrationMemoryAccess; // SHR-05-1
            satisfy requirement 'SYSR-16'; // reqMemoryAccessAuthorizationAndRollback

            in calibration_Req : CalibrationRequest;
            out calibration_Res : CalibrationStatus;

            constraint RejectInvalid {
                calibration_Req.targetMemoryAddress <= 0 implies
                (calibration_Res.responseCode != 200 and
                    calibration_Res.responseTime <= addressRejectBudget)
            }
        }

        action authAccess : MemoryAccessAuthorization;
        action verifyData : DataIntegrityVerification;
        action rejectAccess : InvalidAccessRejectionAndRollback;
    }

    // =========================================================================
    // Composite 5. 진단 및 유지보수 기능 (Diagnostics & Maintenance Support)
    // =========================================================================

    action def <CF5> DiagnosticsAndMaintenanceSupport {
        doc description
        /* 정비사(A/S Service Center)가 진단기를 연결했을 때 고장 진단 코드(DTC)를 제공하고 
         * 센서 영점 조정을 자동화하여 수리 편의성을 제공하는 기능입니다.
         */

        @FunctionalElementsInfo {
            category = FunctionalElementCategory::Composite;
            Rationale =
                "캘리브레이션(개발자 영역)과 명확히 구분되는 '정비 및 A/S' 관점의 외부 인터페이스(UDS 기반)  
                서비스를 제공하기 위해 독자적인 복합 기능으로 도출했습니다.";
        }
        // -----------------------------------------
        // 5.1 고장 진단 코드(DTC) 조회 제어 (Atomic)
        // -----------------------------------------
        action def <CF5_1> ReadDiagnosticTroubleCode {
            doc description
            /* 센서 결함 상태에서 진단기의 조회 요청 수신 시, 
             * ß유효한 고장 진단 코드(DTC)와 정상 응답을 즉시 반환합니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency self to 'Diagnostics & Maintenance'::UC5_Normal_Read_DTC_Scenario;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqDiagnosticAndMaintenanceSupport; // SHR-06

            in diag_Req : DiagnosticRequest;
            in confirmedFaultCause : FaultCause;
            out diag_Res : DiagnosticStatus;

            constraint DtcResponse {
                (diag_Req.serviceId == 1 and confirmedFaultCause != FaultCause::NoFault) implies
                (diag_Res.responseCode == 200 and diag_Res.dtcCode > 0)
            }
        }

        // -----------------------------------------
        // 5.2 센서 영점 조정 루틴 제어 (Atomic)
        // -----------------------------------------
        action def <CF5_2> ZeroPointCalibrationRoutine {
            doc description
            /* 부품 교체 후 진단기로부터 영점 조정 요청 수신 시, 
             * 별도 프로그래밍 없이 완료 응답을 반환하여 수리 절차를 마무리합니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency
                self
                to 'Diagnostics & Maintenance'::UC5_Normal_Zero_Point_Calibration_Scenario;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqDiagnosticAndMaintenanceSupport; // SHR-06
            satisfy requirement 'SYSR-17'; // reqZeroPointCalibrationAutomation

            in diag_Req : DiagnosticRequest;
            out diag_Res : DiagnosticStatus;

            constraint ZeroPointCal {
                diag_Req.serviceId == 2 implies diag_Res.responseCode == 200
            }
        }

        // -----------------------------------------
        // 5.3 비유효 진단 요청 거절 제어 (Atomic)
        // -----------------------------------------
        action def <CF5_3> RejectInvalidDiagnosticRequest {
            doc description
            /* 시스템이 지원하지 않는 서비스 ID나 유효하지 않은 진단 요청 시, 
             * 에러 응답(Negative Response)을 반환하고 통신을 종료합니다.
             */
            @FunctionalElementsInfo {
                category = FunctionalElementCategory::Atomic;
            }

            dependency
                self
                to 'Diagnostics & Maintenance'::UC5_Exception_Invalid_Diagnostic_Request;

            satisfy
                RV_StakeholderRequirementModel::stakeholderRequirementSet
                        .reqDiagnosticAndMaintenanceSupport; // SHR-06

            in diag_Req : DiagnosticRequest;
            out diag_Res : DiagnosticStatus;

            constraint RejectUDS {
                (diag_Req.serviceId != 1 and diag_Req.serviceId != 2) implies
                diag_Res.responseCode != 200
            }
        }

        // -----------------------------------------
        // 5.4 고장 메모리 저장 (Atomic) [M1 신규]
        // -----------------------------------------
        action def <CF5_4> FaultMemoryStorage {
            doc description
            /* 치명 고장이 확정되면 해당 원인을 DTC로 변환하여 비휘발성 메모리(NVM)에 기록합니다. */
            @FunctionalElementsInfo { category = FunctionalElementCategory::Atomic; }

            dependency self to 'Diagnostics & Maintenance'::UC5_Normal_Read_DTC_Scenario;

            satisfy requirement 'SYSR-09'; // reqDtcGenerationLatency

            in confirmedFaultCause : FaultCause; // S7: SYSR-21 확정 원인
            out dtcRecord : FaultMemoryRecord;

            constraint StorageConstraint {
                confirmedFaultCause != FaultCause::NoFault implies
                (dtcRecord.dtcCode > 0 and dtcRecord.storageTime <= DtcStroage::dtcStorageBudget)
            }
        }

        action readDTC : ReadDiagnosticTroubleCode;
        action zeroPointCal : ZeroPointCalibrationRoutine;
        action rejectDiag : RejectInvalidDiagnosticRequest;
        action faultMemoryStorage : FaultMemoryStorage;
    }
} // package FB_FunctionalBlackBoxModel
