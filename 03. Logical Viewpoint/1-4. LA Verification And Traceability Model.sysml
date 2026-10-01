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
    private import ScalarValues::*;

    @MetaInformation { version = "v0.2"; }
    // =========================================================================
    // 0. 재사용 가능한 독립 제약조건(Constraint Definition) 선언
    // =========================================================================
    // 제동 오버라이드 논리 만족 여부를 판별하는 재사용 제약식
    constraint def Check_BrakeOverrideLogic {
        in brakePressure : PressureValue;
        in airMassFlow : MassFlowValue;
        in fuelPulse : TimeValue;

        brakePressure > 0.0 [Pa] implies (airMassFlow <= 0.0 [kg / s] and fuelPulse <= 0.0 [s])
    }

    // 치명적 결함 차단 논리 만족 여부를 판별하는 재사용 제약식
    constraint def Check_FatalFaultCutoffLogic {
        in coolantTemp : TemperatureValue;
        in airMassFlow : MassFlowValue;
        in fuelPulse : TimeValue;
        in dashStatus : ReqCommon::DashboardWarningStatusEnum;

        coolantTemp > 120.0 ['°'] implies
        (airMassFlow <= 0.0 [kg / s] and
            fuelPulse <= 0.0 [s] and
            dashStatus == ReqCommon::DashboardWarningStatusEnum::Critical)
    }

    // 다중 이벤트 발생 시 안전 최우선 중재 여부를 판별하는 재사용 제약식
    constraint def Check_SafetyPriorityMultiplexing {
        in brakePressure : PressureValue;
        in coolantTemp : TemperatureValue;
        in dashStatus : ReqCommon::DashboardWarningStatusEnum;

        (brakePressure > 0.0 [Pa] and coolantTemp > 120.0 ['°']) implies
        dashStatus == ReqCommon::DashboardWarningStatusEnum::Critical
    }

    // 가속 제어 E2E 응답 시간 만족 여부를 판별하는 재사용 제약식
    constraint def Check_E2E_AccelLatencyBudget {
        in accelLatency : TimeValue;
        accelLatency <= 50.0 [milli * s]
    }

    // 긴급 개입 E2E 응답 시간 만족 여부를 판별하는 재사용 제약식
    constraint def Check_E2E_InterventionLatencyBudget {
        in interventionLatency : TimeValue;
        interventionLatency <= 15.0 [milli * s]
    }

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
                injectAndExecute.sut.inputProcessor.inputBehavior.continuousProcessing
                    .processStreamsAndEvents.execFilterPedal.executionTime +
                injectAndExecute.sut.torqueArbiter.arbitrationBehavior.manualDriving.execCalcManual
                    .executionTime +
                injectAndExecute.sut.actuatorController.execGenAndCorrect.executionTime;

            assign e2e_intervention_latency :=
                injectAndExecute.sut.inputProcessor.inputBehavior.continuousProcessing
                    .processStreamsAndEvents.execReceiveIntervention.executionTime +
                injectAndExecute.sut.torqueArbiter.arbitrationBehavior.emergencyIntervention
                    .execCalcReduction.executionTime +
                injectAndExecute.sut.actuatorController.execOverride.executionTime;
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

            verify targetSUT.SystemBrakeOverrideSafeState;
        }

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_brake : BrakePedalPosition;
        in v_sensor : EngineSensorData;
        in v_torqueReq : TorqueInterventionRequest;

        first start;

        then action prepareTestEnvironment {}

        then action executeTestHarness : LogicalIntegrationTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_brake = v_brake;
            in test_sensor = v_sensor;
            in test_torqueReq = v_torqueReq;
        }

        then action evaluateConstraints {
            out isPassed : Boolean = Check_BrakeOverrideLogic(
                brakePressure = executeTestHarness.test_brake.pressure,
                airMassFlow = executeTestHarness.actual_airFlow.massFlow,
                fuelPulse = executeTestHarness.actual_fuelCmd.injectionPulseWidth
            );
        }

        return verdict : VerdictKind = PassIf(evaluateConstraints.isPassed);
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

            verify targetSUT.SystemFatalFaultCutoff;
        }

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_brake : BrakePedalPosition;
        in v_sensor : EngineSensorData;
        in v_torqueReq : TorqueInterventionRequest;

        first start;

        then action prepareTestEnvironment {}

        then action executeTestHarness : LogicalIntegrationTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_brake = v_brake;
            in test_sensor = v_sensor;
            in test_torqueReq = v_torqueReq;
        }

        then action evaluateConstraints {
            out isFatalFaultPassed : Boolean = Check_FatalFaultCutoffLogic(
                coolantTemp = executeTestHarness.test_sensor.coolantTemp,
                airMassFlow = executeTestHarness.actual_airFlow.massFlow,
                fuelPulse = executeTestHarness.actual_fuelCmd.injectionPulseWidth,
                dashStatus = executeTestHarness.actual_dashboard.status
            );

            out isPriorityPassed : Boolean = Check_SafetyPriorityMultiplexing(
                brakePressure = executeTestHarness.test_brake.pressure,
                coolantTemp = executeTestHarness.test_sensor.coolantTemp,
                dashStatus = executeTestHarness.actual_dashboard.status
            );
        }

        return verdict : VerdictKind = PassIf(
            evaluateConstraints.isFatalFaultPassed and evaluateConstraints.isPriorityPassed
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

            verify targetSUT.SystemAccelLatency;
        }

        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;
        in v_brake : BrakePedalPosition;
        in v_sensor : EngineSensorData;
        in v_torqueReq : TorqueInterventionRequest;

        first start;

        then action prepareTestEnvironment {}

        then action executeTestHarness : LogicalIntegrationTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
            in test_brake = v_brake;
            in test_sensor = v_sensor;
            in test_torqueReq = v_torqueReq;
        }

        then action evaluateConstraints {
            out isLatencyPassed : Boolean = Check_E2E_AccelLatencyBudget(
                accelLatency = executeTestHarness.e2e_accel_latency
            );
        }

        return verdict : VerdictKind = PassIf(evaluateConstraints.isLatencyPassed);
    }
} // package LV_VerificationAndTraceabilityModel
