package FV_FunctionalEquivalenceVerificationModel {
    doc
    /* [기능 동등성 검증 모델 (Functional Equivalence Verification Model)]
     * 본 패키지는 블랙박스 기능의 제약을 화이트박스 구현이 만족하는지 정제(refinement)하거나,
     * 출력 등가성이 요구되는 기능의 입출력을 비교하여 검증합니다.
     * 수정 사항: VerdictKind 및 PassIf 등 SysML v2 검증 시맨틱에 맞춘 구조 전면 리팩토링
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import FB_ModeArbitrationModel::*;
    private import FW_UF1_WhiteBoxModel::*;
    private import FW_UF2_WhiteBoxModel::*;
    private import FW_UF3_WhiteBoxModel::*;
    private import FW_CalibrationDiagnosticsWhiteBoxModel::*;
    private import RV_ContextModel::*;
    private import RV_InterfaceModel::*;
    private import VerificationCases::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // =========================================================================
    // 1. CF1 (주행 토크 제어 및 중재 기능) 정제 검증
    // =========================================================================

    // 1.1 수동 가속 제어 (UF1_1)
    action def UF1_1_RefinementTestHarness {
        in test_ignition : IgnitionState;
        in test_accel : AccelerationIntent;
        in test_normalDriving : Boolean;
        in test_combustion : CombustionSystemStatus; // 관측 입력 (판정에는 미사용)
        in test_dynamics : VehicleDynamicsFeedback;

        action wb : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox {
            in ignition = test_ignition;
            in accel = test_accel;
            in combustionSystemStatus = test_combustion;
            in dynamics = test_dynamics;
            in normalDriving = test_normalDriving;
        }

        out isRefined : Boolean =
            (test_ignition.status == IgnitionStatusEnum::On and
                test_accel.pedalDisplacement > 0.0 [mm]) implies
            (wb.filterPedalInput.executionTime +
                wb.calcManualTorque.executionTime +
                wb.genEngineCommand.executionTime <= TimingConceptsAndLimits::cf1PathBudget);

        assert constraint { isRefined }
    }

    verification def Verify_CF1_1 {
        subject cF1_1_EquivalenceTestHarness : UF1_1_RefinementTestHarness;

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_normalDriving : Boolean;
        in v_test_combustion : CombustionSystemStatus;
        in v_test_dynamics : VehicleDynamicsFeedback;

        objective equivalenceObjective {
            verify requirement 'SYSR-13';
            verify requirement 'SYSR-08';
        }

        action harness : UF1_1_RefinementTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_normalDriving = v_normalDriving;
            in test_combustion = v_test_combustion;
            in test_dynamics = v_test_dynamics;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 1.2 정속 주행 제어 (UF1_2)
    action def UF1_2_RefinementTestHarness {
        in test_targetSpeed : ISQ::SpeedValue;
        in test_dynamics : VehicleDynamicsFeedback;
        in test_combustion : CombustionSystemStatus;

        action wb : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox {
            in targetSpeed = test_targetSpeed;
            in dynamics = test_dynamics;
            in combustionSystemStatus = test_combustion;
        }

        @TestOracle {
            requiresCoSimulation = true;
            plantModelDependency = "Engine_Dynamics_Plant_FMU_v2.0";
            description = "정속 주행 속도 유지 한계는 차량 플랜트 연동 관측 오라클로 판정합니다.";
        }
        out isRefined : Boolean =
            (test_targetSpeed > 0.0 [km / h]) implies
            (CruiseControlLogic::IsCruiseSpeedHeld(
                    test_targetSpeed,
                    test_dynamics.vehicleSpeed,
                    CruiseControlLogic::cruiseSpeedErrorLimitPct
                ) and
                wb.genEngineCommandOut.executionTime <=
                    TimingConceptsAndLimits::combustionComputeBudget);

        assert constraint { isRefined }
    }

    verification def Verify_CF1_2 {
        subject cF1_2_EquivalenceTestHarness : UF1_2_RefinementTestHarness;

        in v_targetSpeed : ISQ::SpeedValue;
        in v_dynamics : VehicleDynamicsFeedback;
        in v_combustion : CombustionSystemStatus;

        objective equivalenceObjective {
            verify requirement 'SYSR-23';
            verify requirement 'SYSR-08';
        }

        action harness : UF1_2_RefinementTestHarness {
            in test_targetSpeed = v_targetSpeed;
            in test_dynamics = v_dynamics;
            in test_combustion = v_combustion;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 1.3 제동 우선 오버라이드 제어 (UF1_3)
    action def CF1_3_EquivalenceTestHarness {
        in test_overrideTriggered : Boolean;

        // BB는 상한(L1)만 규정하므로 값 일치가 아니라 정제(refinement) 판정: WB 출력이 BB의 SafeStateConstraints를 만족하는가

        out isEquivalent : Boolean =
            test_overrideTriggered implies
            SafeStateLogic::IsTorqueLimited(wb.airCmd.massFlow, wb.fuelCmd.injectionPulseWidth);

        action bb : CF1::CF1_3 { in overrideTriggered = test_overrideTriggered; }
        action wb : FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox {
            in overrideTriggered = test_overrideTriggered;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_CF1_3 {
        subject cF1_3_EquivalenceTestHarness : CF1_3_EquivalenceTestHarness;

        in v_overrideTriggered : Boolean;

        objective equivalenceObjective {
            verify requirement 'SYSR-01a';
            verify requirement 'SYSR-01b';
            verify requirement 'SYSR-10';
            verify requirement 'SYSR-20';
        }
        action harness : CF1_3_EquivalenceTestHarness {
            in test_overrideTriggered = v_overrideTriggered;
        }
        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 1.4 시스템 모드 중재자 (Arbiter)
    action def Arbiter_RefinementTestHarness {
        in t_cf1_air : IntakeAirFlow;
        in t_cf1_fuel : FuelIgnitionCommand;
        in t_cf2_air : IntakeAirFlow;
        in t_cf2_fuel : FuelIgnitionCommand;
        in t_cf3_air : IntakeAirFlow;
        in t_cf3_fuel : FuelIgnitionCommand;
        in t_cf2_active : Boolean;
        in t_cf3_fault : Boolean;

        out isRefined : Boolean =
            (t_cf3_fault implies
                (wb.modeChannelBroadcaster.currentMode == SystemOperatingMode::FailSafe_Mode and
                    wb.modeChannelBroadcaster.inhibitDrivingControl and
                    wb.final_airCmd == t_cf3_air and
                    wb.final_fuelCmd == t_cf3_fuel)) and
            ((not t_cf3_fault and t_cf2_active) implies
                (wb.modeChannelBroadcaster.currentMode == SystemOperatingMode::Emergency_Mode and
                    not wb.modeChannelBroadcaster.inhibitDrivingControl and
                    ((wb.final_airCmd == t_cf1_air and t_cf1_air.massFlow <= t_cf2_air.massFlow) or
                        (wb.final_airCmd == t_cf2_air and t_cf2_air.massFlow < t_cf1_air.massFlow)) and
                    ((wb.final_fuelCmd == t_cf1_fuel and
                            t_cf1_fuel.injectionPulseWidth <= t_cf2_fuel.injectionPulseWidth) or
                        (wb.final_fuelCmd == t_cf2_fuel and
                            t_cf2_fuel.injectionPulseWidth < t_cf1_fuel.injectionPulseWidth)))) and
            ((not t_cf3_fault and not t_cf2_active) implies
                (wb.modeChannelBroadcaster.currentMode == SystemOperatingMode::Normal_Mode and
                    not wb.modeChannelBroadcaster.inhibitDrivingControl and
                    wb.final_airCmd == t_cf1_air and
                    wb.final_fuelCmd == t_cf1_fuel));

        action wb : FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox {
            in cf1_airCmd = t_cf1_air;
            in cf1_fuelCmd = t_cf1_fuel;
            in cf2_airCmd = t_cf2_air;
            in cf2_fuelCmd = t_cf2_fuel;
            in cf3_airCmd = t_cf3_air;
            in cf3_fuelCmd = t_cf3_fuel;
            in cf2_active = t_cf2_active;
            in cf3_faultActive = t_cf3_fault;
        }

        assert constraint { isRefined }
    }

    verification def Verify_Arbiter {
        subject arbiter_RefinementTestHarness : Arbiter_RefinementTestHarness;

        in v_cf1_air : IntakeAirFlow;
        in v_cf1_fuel : FuelIgnitionCommand;
        in v_cf2_air : IntakeAirFlow;
        in v_cf2_fuel : FuelIgnitionCommand;
        in v_cf3_air : IntakeAirFlow;
        in v_cf3_fuel : FuelIgnitionCommand;
        in v_cf2_active : Boolean;
        in v_cf3_fault : Boolean;

        objective equivalenceObjective {
            verify requirement 'SYSR-18';
            verify requirement 'SYSR-07';
        }

        action harness : Arbiter_RefinementTestHarness {
            in t_cf1_air = v_cf1_air;
            in t_cf1_fuel = v_cf1_fuel;
            in t_cf2_air = v_cf2_air;
            in t_cf2_fuel = v_cf2_fuel;
            in t_cf3_air = v_cf3_air;
            in t_cf3_fuel = v_cf3_fuel;
            in t_cf2_active = v_cf2_active;
            in t_cf3_fault = v_cf3_fault;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // =========================================================================
    // 2. CF2 (긴급 토크 개입 및 보상 기능) 정제·등가성 검증
    // =========================================================================

    // 2.1 병렬 토크 저감 제어 (UF2_1)
    action def UF2_1_RefinementTestHarness {
        in test_req : TorqueInterventionRequest;

        action wb : FW_UF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox {
            in torqueIntervention = test_req;
        }

        out isRefined : Boolean =
            (test_req.requestedTorqueDelta < 0.0 [N * m] and
                test_req.messageAge <= TimingConceptsAndLimits::commDelayThreshold) implies
            (wb.airCmd.massFlow < wb.airCmd.previousMassFlow and
                wb.fuelCmd.injectionPulseWidth < wb.fuelCmd.previousPulseWidth and
                wb.receiveInterventionReq.executionTime +
                    wb.calcReductionTorque.executionTime +
                    wb.limitActuatorOutput.executionTime <=
                    TimingConceptsAndLimits::interventionStageBudget);

        assert constraint { isRefined }
    }

    verification def Verify_UF2_1 {
        subject uF2_1_RefinementTestHarness : UF2_1_RefinementTestHarness;

        in v_req : TorqueInterventionRequest;

        objective equivalenceObjective {
            verify requirement 'SYSR-03';
        }

        action harness : UF2_1_RefinementTestHarness {
            in test_req = v_req;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 2.2 통신 지연 보상 제어 (UF2_2)
    action def UF2_2_RefinementTestHarness {
        in test_req : TorqueInterventionRequest;

        action wb : FW_UF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox {
            in torqueIntervention = test_req;
        }

        out isRefined : Boolean =
            (test_req.messageAge > TimingConceptsAndLimits::commDelayThreshold and
                test_req.messageAge <= TimingConceptsAndLimits::commTimeout) implies
            (wb.airIntake.massFlow == wb.airIntake.previousMassFlow and
                wb.fuelCmd.injectionPulseWidth == wb.fuelCmd.previousPulseWidth);

        assert constraint { isRefined }
    }

    verification def Verify_UF2_2 {
        subject uF2_2_RefinementTestHarness : UF2_2_RefinementTestHarness;

        in v_req : TorqueInterventionRequest;

        objective equivalenceObjective {
            verify requirement 'SYSR-15';
        }

        action harness : UF2_2_RefinementTestHarness {
            in test_req = v_req;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 2.3 고착 대응 연료 차단 제어 (UF2_3)
    action def UF2_3_RefinementTestHarness {
        in test_stuckConfirmed : Boolean;
        action wb : FW_UF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox {
            in stuckConfirmed = test_stuckConfirmed;
        }
        out isRefined : Boolean =
            test_stuckConfirmed implies
            (SafeStateLogic::IsFuelCutOff(wb.fuelCmd.injectionPulseWidth) and
                wb.detectActuatorStuck.executionTime + wb.executeEmergencyFuelCut.executionTime <=
                TimingConceptsAndLimits::stuckCutStageBudget);
        assert constraint { isRefined }
    }

    verification def Verify_UF2_3 {
        subject uF2_3_RefinementTestHarness : UF2_3_RefinementTestHarness;

        in v_stuckConfirmed : Boolean;

        objective equivalenceObjective {
            verify requirement 'SYSR-14';
        }

        action harness : UF2_3_RefinementTestHarness { in test_stuckConfirmed = v_stuckConfirmed; }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // =========================================================================
    // 3. CF3 (하드웨어 안전 모니터링 및 페일세이프) 정제·등가성 검증
    // =========================================================================

    // 2.4 긴급 개입 해제 및 제어 복귀 (UF2_4)
    action def UF2_4_RefinementTestHarness {
        in test_req : TorqueInterventionRequest;

        action wb : FW_UF2_WhiteBoxModel::InterventionReleaseControl_WhiteBox {
            in torqueIntervention = test_req;
        }

        out isRefined : Boolean =
            test_req.requestedTorqueDelta >= 0.0 [N * m] implies
            (wb.detectReleaseReq.isReleased and wb.executeRelease.releaseFlag);

        assert constraint { isRefined }
    }

    verification def Verify_UF2_4 {
        subject uF2_4_RefinementTestHarness : UF2_4_RefinementTestHarness;

        in v_req : TorqueInterventionRequest;

        objective equivalenceObjective {
            verify requirement 'SYSR-19';
        }

        action harness : UF2_4_RefinementTestHarness {
            in test_req = v_req;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 2.5 개입 요청 무결성 가드 (UF2_5)
    action def UF2_5_EquivalenceTestHarness {
        in test_req : TorqueInterventionRequest;
        in test_integrityError : Boolean;

        out isEquivalent : Boolean = bb.validatedRequest == wb.validatedRequest;

        action bb : CF2::CF2_5 {
            in torqueIntervention = test_req;
            in integrityError = test_integrityError;
        }
        action wb : FW_UF2_WhiteBoxModel::InterventionRequestIntegrityGuard_WhiteBox {
            in torqueIntervention = test_req;
            in integrityError = test_integrityError;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF2_5 {
        subject uF2_5_EquivalenceTestHarness : UF2_5_EquivalenceTestHarness;

        in v_req : TorqueInterventionRequest;
        in v_integrityError : Boolean;

        objective equivalenceObjective {
            verify requirement 'SYSR-05';
        }

        action harness : UF2_5_EquivalenceTestHarness {
            in test_req = v_req;
            in test_integrityError = v_integrityError;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // =========================================================================
    // 3. CF3 (하드웨어 안전 모니터링 및 페일세이프) 정제·등가성 검증
    // =========================================================================

    // 3.1 하드웨어 마찰 및 지연 보정 제어 (UF3_1)
    action def UF3_1_EquivalenceTestHarness {
        private import SafeStateLogic::*;

        in test_baseAir : IntakeAirFlow;
        in test_baseFuel : FuelIgnitionCommand;
        in test_sensor : EngineSensorData;
        in test_combustion : CombustionSystemStatus;

        out isEquivalent : Boolean =
            wb.airIntake.massFlow >= test_baseAir.massFlow - maxAirCorrection and
            wb.airIntake.massFlow <= test_baseAir.massFlow + maxAirCorrection and
            wb.fuelCmd.injectionPulseWidth >=
            test_baseFuel.injectionPulseWidth - maxFuelCorrection and
            wb.fuelCmd.injectionPulseWidth <= test_baseFuel.injectionPulseWidth + maxFuelCorrection;

        action bb : CF3::CF3_1 {
            in baseAirCmd = test_baseAir;
            in baseFuelCmd = test_baseFuel;
            in sensor = test_sensor;
            in combustionStatus = test_combustion;
        }
        action wb : FW_UF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox {
            in baseAirCmd = test_baseAir;
            in baseFuelCmd = test_baseFuel;
            in sensor = test_sensor;
            in combustionStatus = test_combustion;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF3_1 {
        subject uF3_1_EquivalenceTestHarness : UF3_1_EquivalenceTestHarness;

        in v_baseAir : IntakeAirFlow;
        in v_baseFuel : FuelIgnitionCommand;
        in v_sensor : EngineSensorData;
        in v_combustion : CombustionSystemStatus;

        objective equivalenceObjective {
            verify requirement 'SYSR-22';
            verify requirement 'SYSR-08';
        }

        action harness : UF3_1_EquivalenceTestHarness {
            in test_baseAir = v_baseAir;
            in test_baseFuel = v_baseFuel;
            in test_sensor = v_sensor;
            in test_combustion = v_combustion;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 3.2 치명적 센서 결함 페일세이프 제어 (UF3_2)
    action def UF3_2_RefinementTestHarness {
        in test_faultCause : FaultCause;

        action wb : FW_UF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox {
            in faultCause = test_faultCause;
        }

        out isRefined : Boolean =
            test_faultCause != FaultCause::NoFault implies
            (SafeStateLogic::IsFullCutOff(
                    wb.airIntake.massFlow,
                    wb.fuelCmd.injectionPulseWidth
                ) and
                wb.dashboard.status == DashboardWarningStatusEnum::Critical and
                wb.classifyFault.executionTime + wb.shutdownSystem.executionTime <=
                    TimingConceptsAndLimits::failSafeStageBudget);

        assert constraint { isRefined }
    }

    verification def Verify_UF3_2 {
        subject uF3_2_RefinementTestHarness : UF3_2_RefinementTestHarness;

        in v_faultCause : FaultCause;

        objective equivalenceObjective {
            verify requirement 'SYSR-07';
            verify requirement 'SYSR-25';
            verify requirement 'SYSR-20';
        }

        action harness : UF3_2_RefinementTestHarness { in test_faultCause = v_faultCause; }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 3.3 이중화 센서 편차 감시 (UF3_3)
    action def UF3_3_RefinementTestHarness {
        private import SafeStateLogic::*;

        in test_pedalPosition : AccelerationPedalPosition;
        in test_throttleFeedback : ThrottlePositionFeedback;

        action wb : FW_UF3_WhiteBoxModel::RedundantSensorDeviationMonitoring_WhiteBox {
            in pedalPosition = test_pedalPosition;
            in throttleFeedback = test_throttleFeedback;
        }

        out isRefined : Boolean =
            wb.pedalFaultFlag ==
                IsChannelDeviated(
                    test_pedalPosition.pvs1Percentage,
                    test_pedalPosition.pvs2Percentage,
                    redundancyDeviationLimit
                ) and
            wb.throttleFaultFlag ==
                IsChannelDeviated(
                    test_throttleFeedback.tps1Percentage,
                    test_throttleFeedback.tps2Percentage,
                    redundancyDeviationLimit
                );

        assert constraint { isRefined }
    }

    verification def Verify_UF3_3 {
        subject uF3_3_RefinementTestHarness : UF3_3_RefinementTestHarness;

        in v_pedalPosition : AccelerationPedalPosition;
        in v_throttleFeedback : ThrottlePositionFeedback;

        objective equivalenceObjective {
            verify requirement 'SYSR-02';
            verify requirement 'SYSR-06';
        }

        action harness : UF3_3_RefinementTestHarness {
            in test_pedalPosition = v_pedalPosition;
            in test_throttleFeedback = v_throttleFeedback;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // 3.4 스로틀 추종 편차 감시 (UF3_4)
    action def UF3_4_RefinementTestHarness {
        private import ThrottleStuckLogic::*;

        in test_throttleCmd : ThrottlePositionCommand;
        in test_throttleFeedback : ThrottlePositionFeedback;

        action wb : FW_UF3_WhiteBoxModel::ThrottleTrackingMonitoring_WhiteBox {
            in throttleCmd = test_throttleCmd;
            in throttleFeedback = test_throttleFeedback;
        }

        out isRefined : Boolean =
            wb.trackingFaultFlag ==
            IsThrottleDeviated(
                test_throttleCmd.openingPercentage,
                test_throttleFeedback.openingPercentage,
                stuckDeviationLimit
            );

        assert constraint { isRefined }
    }

    verification def Verify_UF3_4 {
        subject uF3_4_RefinementTestHarness : UF3_4_RefinementTestHarness;

        in v_throttleCmd : ThrottlePositionCommand;
        in v_throttleFeedback : ThrottlePositionFeedback;

        objective equivalenceObjective {
            verify requirement 'SYSR-04';
        }

        action harness : UF3_4_RefinementTestHarness {
            in test_throttleCmd = v_throttleCmd;
            in test_throttleFeedback = v_throttleFeedback;
        }

        return verdict : VerdictKind = PassIf(harness.isRefined);
    }

    // =========================================================================
    // 4. CF4 (파워트레인 캘리브레이션) 및 CF5 (진단·유지보수) 검증
    // =========================================================================

    // 4.1 메모리 접근 인가 (UF4_1)
    action def UF4_1_EquivalenceTestHarness {
        in test_calibrationReq : CalibrationRequest;
        in test_expectedCredential : Integer;
        in test_ignition : IgnitionState;
        in test_vehicleSpeed : ISQ::SpeedValue;

        out isEquivalent : Boolean =
            bb.isAuthorized == wb.isAuthorized and bb.authStatus == wb.authStatus;

        action bb : CF4::CF4_1 {
            in calibration_Req = test_calibrationReq;
            in expectedCredential = test_expectedCredential;
            in ignition = test_ignition;
            in vehicleSpeed = test_vehicleSpeed;
        }
        action wb : FW_CalibrationDiagnosticsWhiteBoxModel::MemoryAccessAuthorization_WhiteBox {
            in calibration_Req = test_calibrationReq;
            in expectedCredential = test_expectedCredential;
            in ignition = test_ignition;
            in vehicleSpeed = test_vehicleSpeed;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF4_1 {
        subject uF4_1_EquivalenceTestHarness : UF4_1_EquivalenceTestHarness;

        in v_calibrationReq : CalibrationRequest;
        in v_expectedCredential : Integer;
        in v_ignition : IgnitionState;
        in v_vehicleSpeed : ISQ::SpeedValue;

        objective equivalenceObjective {
            verify requirement 'SYSR-16';
        }

        action harness : UF4_1_EquivalenceTestHarness {
            in test_calibrationReq = v_calibrationReq;
            in test_expectedCredential = v_expectedCredential;
            in test_ignition = v_ignition;
            in test_vehicleSpeed = v_vehicleSpeed;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 4.2 맵 데이터 무결성 검증 (UF4_2)
    action def UF4_2_EquivalenceTestHarness {
        in test_calibrationReq : CalibrationRequest;
        in test_isAuthorized : Boolean;

        out isEquivalent : Boolean =
            bb.isIntegrityOk == wb.isIntegrityOk and bb.verifyStatus == wb.verifyStatus;

        action bb : CF4::CF4_2 {
            in calibration_Req = test_calibrationReq;
            in isAuthorized = test_isAuthorized;
        }
        action wb : FW_CalibrationDiagnosticsWhiteBoxModel::DataIntegrityVerification_WhiteBox {
            in calibration_Req = test_calibrationReq;
            in isAuthorized = test_isAuthorized;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF4_2 {
        subject uF4_2_EquivalenceTestHarness : UF4_2_EquivalenceTestHarness;

        in v_calibrationReq : CalibrationRequest;
        in v_isAuthorized : Boolean;

        objective equivalenceObjective {
            verify requirement 'SYSR-11';
        }

        action harness : UF4_2_EquivalenceTestHarness {
            in test_calibrationReq = v_calibrationReq;
            in test_isAuthorized = v_isAuthorized;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 4.3 비유효 접근 거절 및 롤백 (UF4_3)
    action def UF4_3_EquivalenceTestHarness {
        in test_calibrationReq : CalibrationRequest;
        in test_isAuthorized : Boolean;
        in test_integrityFailed : Boolean;

        out isEquivalent : Boolean = bb.errorStatus == wb.errorStatus;

        action bb : CF4::CF4_3 {
            in calibration_Req = test_calibrationReq;
            in isAuthorized = test_isAuthorized;
            in integrityFailed = test_integrityFailed;
        }
        action wb
            : FW_CalibrationDiagnosticsWhiteBoxModel::InvalidAccessRejectionAndRollback_WhiteBox {
            in calibration_Req = test_calibrationReq;
            in isAuthorized = test_isAuthorized;
            in integrityFailed = test_integrityFailed;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF4_3 {
        subject uF4_3_EquivalenceTestHarness : UF4_3_EquivalenceTestHarness;

        in v_calibrationReq : CalibrationRequest;
        in v_isAuthorized : Boolean;
        in v_integrityFailed : Boolean;

        objective equivalenceObjective {
            verify requirement 'SYSR-16';
        }

        action harness : UF4_3_EquivalenceTestHarness {
            in test_calibrationReq = v_calibrationReq;
            in test_isAuthorized = v_isAuthorized;
            in test_integrityFailed = v_integrityFailed;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 5.2 센서 영점 조정 루틴 (UF5_2)
    action def UF5_2_EquivalenceTestHarness {
        in test_diagReq : DiagnosticRequest;
        in test_ignition : IgnitionState;
        in test_vehicleSpeed : ISQ::SpeedValue;

        out isEquivalent : Boolean = bb.zeroStatus == wb.zeroStatus;

        action bb : CF5::CF5_2 {
            in diag_Req = test_diagReq;
            in ignition = test_ignition;
            in vehicleSpeed = test_vehicleSpeed;
        }
        action wb : FW_CalibrationDiagnosticsWhiteBoxModel::ZeroPointCalibrationRoutine_WhiteBox {
            in diag_Req = test_diagReq;
            in ignition = test_ignition;
            in vehicleSpeed = test_vehicleSpeed;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF5_2 {
        subject uF5_2_EquivalenceTestHarness : UF5_2_EquivalenceTestHarness;

        in v_diagReq : DiagnosticRequest;
        in v_ignition : IgnitionState;
        in v_vehicleSpeed : ISQ::SpeedValue;

        objective equivalenceObjective {
            verify requirement 'SYSR-17';
        }

        action harness : UF5_2_EquivalenceTestHarness {
            in test_diagReq = v_diagReq;
            in test_ignition = v_ignition;
            in test_vehicleSpeed = v_vehicleSpeed;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 5.4 고장 메모리 저장 (UF5_4)
    action def UF5_4_EquivalenceTestHarness {
        in test_faultCause : FaultCause;

        out isEquivalent : Boolean =
            bb.dtcRecord.dtcCode == wb.dtcRecord.dtcCode and
            bb.dtcRecord.storageTime == wb.dtcRecord.storageTime;

        action bb : CF5::CF5_4 {
            in confirmedFaultCause = test_faultCause;
        }
        action wb : FW_CalibrationDiagnosticsWhiteBoxModel::FaultMemoryStorage_WhiteBox {
            in confirmedFaultCause = test_faultCause;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF5_4 {
        subject uF5_4_EquivalenceTestHarness : UF5_4_EquivalenceTestHarness;

        in v_faultCause : FaultCause;

        objective equivalenceObjective {
            verify requirement 'SYSR-09';
        }

        action harness : UF5_4_EquivalenceTestHarness {
            in test_faultCause = v_faultCause;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // =========================================================================
    // 6. FE 수준 상태 및 아키텍처 검증
    // =========================================================================

    verification def Verify_IgnitionOffReset {
        doc
        /* 크루즈 활성, 긴급 개입, 치명 고장 상태에서 점화 OFF를 인가한 HILS
         * 시나리오의 관측값을 검사합니다. DTC 메모리는 리셋 전후 값을 대조합니다.
         */
        subject egas : EgasSystem;

        in v_storedDtcCodeBefore : Integer;

        objective resetObjective {
            verify requirement 'SYSR-24';
            verify requirement 'SYSR-19';
            verify requirement 'SYSR-21';
            verify requirement 'SYSR-23';
        }

        return verdict : VerdictKind = PassIf(
            egas.ecu.ccState == CruiseControlStateEnum::Off and
            egas.ecu.confirmedFaultCause == FaultCause::NoFault and
            egas.ecu.storedDtcCode == v_storedDtcCodeBefore
        );
    }

    verification def Verify_CruiseStateTransitions_Off {
        doc
        /* 점화 OFF 또는 Off 요청 시나리오 절차를 실행한 뒤 Off 상태를 확인합니다. */
        subject egas : EgasSystem;

        objective cruiseOffObjective {
            verify requirement 'SYSR-23';
        }

        return verdict : VerdictKind = PassIf(
            egas.ecu.ccState == CruiseControlStateEnum::Off
        );
    }

    verification def Verify_CruiseStateTransitions_Active {
        doc
        /* 제동·가속 페달이 없는 상태에서 유효한 Set 또는 Resume 절차를 실행한 뒤 Active를 확인합니다. */
        subject egas : EgasSystem;

        objective cruiseActiveObjective {
            verify requirement 'SYSR-23';
        }

        return verdict : VerdictKind = PassIf(
            egas.ecu.ccState == CruiseControlStateEnum::Active
        );
    }

    verification def Verify_CruiseStateTransitions_Suspended {
        doc
        /* Active에서 Cancel, 제동 또는 가속 페달 입력 절차를 실행한 뒤 Suspended를 확인합니다. */
        subject egas : EgasSystem;

        objective cruiseSuspendedObjective {
            verify requirement 'SYSR-23';
        }

        return verdict : VerdictKind = PassIf(
            egas.ecu.ccState == CruiseControlStateEnum::Suspended
        );
    }

    verification def Verify_ExtensibilityInspection {
        doc
        /* 신규 외부 제어기 인터페이스 추가 후 중재 핵심 로직 변경 라인 수와 경로 예산 검사 결과를 입력받아 검사합니다. */
        subject egas : EgasSystem;

        in arbiterCoreChangedLineCount : Integer;
        in pathBudgetsMet : Boolean;

        objective extensibilityObjective {
            verify requirement 'SYSR-12';
        }

        return verdict : VerdictKind = PassIf(
            arbiterCoreChangedLineCount == 0 and pathBudgetsMet
        );
    }
} // package FV_FunctionalEquivalenceVerificationModel
