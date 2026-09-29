package LV_VerificationAndTraceabilityModel {
    doc
    /* [논리 관점 5단계: 통합 시스템 시뮬레이션 및 검증 모델]
     * 본 패키지는 FinalBehavioralEgasSystem을 대상으로 시스템 검증(Verification)을 
     * 수행하기 위한 하네스를 명세하고, 23개 모든 하위 소기능에 대한 논리 컴포넌트 
     * 할당(Allocation) 추적성을 100% 수립합니다.
     */

    private import LA_RootComponentModel::*;
    private import LA_DecompositionModel::*;
    private import LA_BehaviorModel::*;
    private import FW_UF1_WhiteBoxModel::*;
    private import FW_CF2_WhiteBoxModel::*;
    private import FW_CF3_WhiteBoxModel::*;
    private import RV_InterfaceModel::*;
    private import VerificationCases::*;
    private import ReqCommon::*;
    private import SI::*;

    @MetaInformation { version = "v0.1"; }

    // =========================================================================
    // 1. 논리 아키텍처 통합 테스트 하네스 (Logical E2E Test Harness)
    // =========================================================================
    action def LogicalIntegrationTestHarness {
        in test_ignition : IgnitionState;
        in test_accel : AccelerationIntent;
        in test_brake : BrakePedalPosition;
        in test_sensor : EngineSensorData;
        in test_torqueReq : TorqueInterventionRequest;

        out actual_airFlow : IntakeAirFlow;
        out actual_fuelCmd : FuelIgnitionCommand;
        out actual_dashboard : DashboardWarning;

        out e2e_accel_latency : TimeValue;
        out e2e_intervention_latency : TimeValue;

       // [순차적 실행 단계 1: SUT 실행]
        first start;
        then action injectAndExecute {
            action sut : LA_BehaviorModel::FinalBehavioralEgasSystem {
                in p_inIgnition = test_ignition;
                in p_inAccel = test_accel;
                in p_inBrake = test_brake;
                in p_inSensor = test_sensor;
                in p_inTorqueReq = test_torqueReq;
            }
        }
        
        // [순차적 실행 단계 2: 결과 캡처 및 연산]
then action captureResults {
            // EgasSystem 포트 명칭(airIntakePort, fuelCmdPort, dashboardPort)을 통한 출력 캡처
            assign actual_airFlow := injectAndExecute.sut.airIntakePort.airFlow;
            assign actual_fuelCmd := injectAndExecute.sut.fuelCmdPort.fuelCmd;
            assign actual_dashboard := injectAndExecute.sut.dashboardPort.dashboardWarning;

            // 종단 간 지연시간(E2E Latency) 합산 산출 (내부 논리 파이프라인의 executionTime 예산 합산)
            assign e2e_accel_latency := 
                injectAndExecute.sut.inputProcessor.inputBehavior.continuousProcessing.processStreamsAndEvents.execFilterPedal.executionTime + 
                injectAndExecute.sut.torqueArbiter.arbitrationBehavior.manualDriving.execCalcManual.executionTime + 
                injectAndExecute.sut.actuatorController.execGenAndCorrect.executionTime;
                                        
          assign e2e_intervention_latency := 
                injectAndExecute.sut.inputProcessor.inputBehavior.continuousProcessing.processStreamsAndEvents.execReceiveIntervention.executionTime + 
                injectAndExecute.sut.torqueArbiter.arbitrationBehavior.emergencyIntervention.execCalcReduction.executionTime + 
                injectAndExecute.sut.actuatorController.execOverride.executionTime;
        }

        // [제약조건 평가식 정의]
        constraint Check_BrakeOverrideLogic {
            test_brake.pressure > 0.0 [Pa] implies 
            (actual_airFlow.massFlow <= 0.0 [kg/s] and actual_fuelCmd.injectionPulseWidth <= 0.0 [s])
        }

        constraint Check_FatalFaultCutoffLogic {
            test_sensor.coolantTemp > 120.0 ['°'] implies 
            (actual_airFlow.massFlow <= 0.0 [kg/s] and 
             actual_fuelCmd.injectionPulseWidth <= 0.0 [s] and 
             actual_dashboard.status == ReqCommon::DashboardWarningStatusEnum::Critical)
        }

        constraint Check_SafetyPriorityMultiplexing {
            (test_brake.pressure > 0.0 [Pa] and test_sensor.coolantTemp > 120.0 ['°']) implies
            (actual_dashboard.status == ReqCommon::DashboardWarningStatusEnum::Critical)
        }

        constraint Check_E2E_AccelLatencyBudget {
            e2e_accel_latency <= 50.0 [milli * s]
        }

        constraint Check_E2E_InterventionLatencyBudget {
            e2e_intervention_latency <= 15.0 [milli * s]
        }
    }

    // =========================================================================
    // 2. SysML v2 검증 케이스 (Verification Cases)
    // =========================================================================

    verification def Verify_Logical_BrakeOverride {
        subject targetSUT : LA_BehaviorModel::FinalBehavioralEgasSystem;

        objective overrideObjective {
            doc 
            /* [Language: English]
             * Objective: To verify that the FinalBehavioralEgasSystem enforces the SystemBrakeOverrideSafeState 
             * requirement. It ensures that when brake pressure is applied (> 0 Pa), the system correctly 
             * overrides any ongoing acceleration or cruise commands and forces the actuators (air flow and fuel) 
             * to zero (Safe State), preventing unintended acceleration.
             */
        }

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_brake : BrakePedalPosition;
        in v_sensor : EngineSensorData;
        in v_torqueReq : TorqueInterventionRequest;

        first action prepareTestEnvironment { }
        
        then action executeTestHarness : LogicalIntegrationTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_brake = v_brake;
            in test_sensor = v_sensor;
            in test_torqueReq = v_torqueReq;
        }
        
        then action evaluateConstraints {
            assert constraint { executeTestHarness.Check_BrakeOverrideLogic }
        }

        return verdict : VerdictKind = PassIf(executeTestHarness.Check_BrakeOverrideLogic);
    }

    verification def Verify_Logical_FatalFaultAndPriority {
        subject targetSUT : LA_BehaviorModel::FinalBehavioralEgasSystem;

        objective fatalFaultObjective {
            doc 
            /* [Language: English]
             * Objective: To verify the SystemFatalFaultCutoff requirement and the safety priority multiplexing. 
             * It ensures that an engine coolant temperature exceeding 120 degrees Celsius irreversibly 
             * triggers a critical latching state (FatalFault), and this state correctly preempts all 
             * other inputs (including brake overrides), projecting a 'Critical' dashboard warning.
             */
        }

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_brake : BrakePedalPosition;
        in v_sensor : EngineSensorData;
        in v_torqueReq : TorqueInterventionRequest;

        first action prepareTestEnvironment { }
        
        then action executeTestHarness : LogicalIntegrationTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_brake = v_brake;
            in test_sensor = v_sensor;
            in test_torqueReq = v_torqueReq;
        }
        
        then action evaluateConstraints {
            assert constraint { executeTestHarness.Check_FatalFaultCutoffLogic }
            assert constraint { executeTestHarness.Check_SafetyPriorityMultiplexing }
        }

        return verdict : VerdictKind = PassIf(
            executeTestHarness.Check_FatalFaultCutoffLogic and 
            executeTestHarness.Check_SafetyPriorityMultiplexing
        );
    }

    verification def Verify_Logical_AccelLatency {
        subject targetSUT : LA_BehaviorModel::FinalBehavioralEgasSystem;

        objective accelLatencyObjective {
            doc 
            /* [Language: English]
             * Objective: To verify the SystemAccelLatency constraint. It calculates the End-to-End (E2E) 
             * execution time from the input processing (filtering) through torque arbitration to the final 
             * actuator control generation, ensuring the combined latency does not exceed the 50ms budget.
             */
        }

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_brake : BrakePedalPosition;
        in v_sensor : EngineSensorData;
        in v_torqueReq : TorqueInterventionRequest;

        first action prepareTestEnvironment { }
        
        then action executeTestHarness : LogicalIntegrationTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_brake = v_brake;
            in test_sensor = v_sensor;
            in test_torqueReq = v_torqueReq;
        }
        
        then action evaluateConstraints {
            assert constraint { executeTestHarness.Check_E2E_AccelLatencyBudget }
        }

        return verdict : VerdictKind = PassIf(executeTestHarness.Check_E2E_AccelLatencyBudget);
    }

    // =========================================================================
    // 3. 엔드투엔드 추적성 수립 (Traceability Model - 23개 기능 전체 매핑)
    // =========================================================================

    // [UF1.1] 수동 가속 제어
    allocate FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox::filterPedalInput to LA_DecompositionModel::InputProcessingComponent;
    allocate FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox::calcManualTorque to LA_DecompositionModel::TorqueArbitrationComponent;
    allocate FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox::genEngineCommand to LA_DecompositionModel::ActuatorControlComponent;

    // [UF1.2] 정속 주행 제어
    allocate FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox::processCruiseCommand to LA_DecompositionModel::InputProcessingComponent;
    allocate FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox::calcCruiseTorque to LA_DecompositionModel::TorqueArbitrationComponent;
    allocate FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox::genEngineCommandOut to LA_DecompositionModel::ActuatorControlComponent;

    // [UF1.3] 제동 우선 오버라이드 제어
    allocate FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox::detectBrake to LA_DecompositionModel::InputProcessingComponent;
    allocate FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox::arbitrateOverride to LA_DecompositionModel::ActuatorControlComponent;

    // [Arbiter] 시스템 모드 중재자
    allocate FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox::collectInputs to LA_DecompositionModel::TorqueArbitrationComponent;
    allocate FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox::evaluatePriority to LA_DecompositionModel::TorqueArbitrationComponent;
    allocate FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox::broadcastOutput to LA_DecompositionModel::TorqueArbitrationComponent;

    // [UF2.1] 병렬 토크 저감 제어
    allocate FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox::receiveInterventionReq to LA_DecompositionModel::InputProcessingComponent;
    allocate FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox::calcReductionTorque to LA_DecompositionModel::TorqueArbitrationComponent;
    allocate FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox::limitActuatorOutput to LA_DecompositionModel::ActuatorControlComponent;

    // [UF2.2] 통신 지연 보상 제어
    allocate FW_CF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox::monitorCommLatency to LA_DecompositionModel::InputProcessingComponent;
    allocate FW_CF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox::holdPreviousState to LA_DecompositionModel::ActuatorControlComponent;

    // [UF2.3] 고착 대응 연료 차단 제어
    allocate FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox::detectActuatorStuck to LA_DecompositionModel::InputProcessingComponent;
    allocate FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox::executeEmergencyFuelCut to LA_DecompositionModel::ActuatorControlComponent;

    // [UF3.1] 하드웨어 마찰 및 지연 보정 제어
    allocate FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox::monitorSensorError to LA_DecompositionModel::SafetyMonitorComponent;
    allocate FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox::calcCorrectionValue to LA_DecompositionModel::SafetyMonitorComponent;
    allocate FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox::applyCorrection to LA_DecompositionModel::ActuatorControlComponent;

    // [UF3.2] 치명적 센서 결함 페일세이프 제어
    allocate FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox::checkCriticalLimits to LA_DecompositionModel::SafetyMonitorComponent;
    allocate FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox::shutdownSystem to LA_DecompositionModel::ActuatorControlComponent;

} // package LV_VerificationAndTraceabilityModel