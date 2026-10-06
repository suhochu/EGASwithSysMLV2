package FV_PerformanceConstraintsVerificationModel {
    doc
    /* [성능 제약조건 정합성 검증 모델 (Performance Constraints Conformance Model)]
     * 본 패키지는 블랙박스 수준에서 정의된 전체 성능/지연시간 제약조건(Latency Budget)이 
     * 화이트박스 파이프라인의 하위 소기능 실행 시간(Execution Time) 합산에 의해 
     * 정합성 있게 충족(Conformance)되는지를 검증합니다.
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import FW_UF1_WhiteBoxModel::*;
    private import FW_CF2_WhiteBoxModel::*;
    private import FW_CF3_WhiteBoxModel::*;
    private import RV_InterfaceModel::*;
    private import VerificationCases::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // =========================================================================
    // 1. UF1_1 수동 가속 제어 성능 정합성 검증 (총 지연시간 50ms)
    // =========================================================================

    action def UF1_1_PerformanceTestHarness {
        in test_ignition : IgnitionState;
        in test_accel : AccelerationIntent;

        // 블랙박스 및 화이트박스 실행
        action bb : CF1::CF1_1 {
            in ignition = test_ignition;
            in accel = test_accel;
        }
        action wb : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox {
            in ignition = test_ignition;
            in accel = test_accel;
        }

        // 성능 정합성 여부 산출: 하위 기능 실행 시간 합이 전체 허용 지연시간(latency) 이하인지 확인
        out isPerformanceMet : Boolean =
            wb.filterPedalInput.executionTime +
            wb.calcManualTorque.executionTime +
            wb.genEngineCommand.executionTime <=
            50.0 [milli * s]; // bb.accel.latency → 상수

        // 성능 제약조건 단정 (초과 시 위반)
        assert constraint { isPerformanceMet }
    }

    verification def Verify_UF1_1_Performance {
        // 1) 검증 대상 시스템(Subject) 지정
        subject uF1_1_PerformanceTestHarness : UF1_1_PerformanceTestHarness;

        // 2) 검증 입력 파라미터 선언
        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;

        // 3) 검증 목적(Objective) 지정
        objective performanceObjective {
            requirement {
                doc
                /* UF1_1: 입력 센싱부터 액추에이터 제어 명령까지의 총 지연시간(50ms) 예산 충족 검증 */
            }
        }

        // 4) 테스트 하네스 실행 및 입력값 주입
        action harness : UF1_1_PerformanceTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
        }

        // 5) PassIf를 사용하여 VerdictKind 타입 결과 반환
        return verdict : VerdictKind = PassIf(harness.isPerformanceMet);
    }

    // =========================================================================
    // 2. UF2_1 병렬 토크 저감 제어 성능 정합성 검증 (총 지연시간 15ms)
    // =========================================================================

    action def UF2_1_PerformanceTestHarness {
        in test_req : TorqueInterventionRequest;

        action bb : CF2::CF2_1 {
            in torqueIntervention = test_req;
        }
        action wb : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox {
            in torqueIntervention = test_req;
        }

        out isPerformanceMet : Boolean =
            wb.receiveInterventionReq.executionTime +
            wb.calcReductionTorque.executionTime +
            wb.limitActuatorOutput.executionTime <=
            15.0 [milli * s];

        assert constraint { isPerformanceMet }
    }

    verification def Verify_UF2_1_Performance {
        subject uF2_1_PerformanceTestHarness : UF2_1_PerformanceTestHarness;

        in v_req : TorqueInterventionRequest;

        objective performanceObjective {
            requirement {
                doc
                /* UF2_1: 외부 제어기의 긴급 개입 요구 수용부터 토크 저감 명령까지의 총 지연시간(15ms) 충족 검증 */
            }
        }

        action harness : UF2_1_PerformanceTestHarness {
            in test_req = v_req;
        }

        return verdict : VerdictKind = PassIf(harness.isPerformanceMet);
    }

    // =========================================================================
    // 3. UF3_1 하드웨어 마찰 및 지연 보정 제어 성능 정합성 검증 (총 지연시간 10ms)
    // =========================================================================

    action def UF3_1_PerformanceTestHarness {
        private import SafeStateLogic::*;

        in test_baseAir : IntakeAirFlow;
        in test_baseFuel : FuelIgnitionCommand;
        in test_sensor : EngineSensorData;
        in test_combustion : CombustionSystemStatus;

        action bb : CF3::CF3_1 {
            in baseAirCmd = test_baseAir;
            in baseFuelCmd = test_baseFuel;
            in sensor = test_sensor;
            in combustionStatus = test_combustion;
        }
        action wb : FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox {
            in baseAirCmd = test_baseAir;
            in baseFuelCmd = test_baseFuel;
            in sensor = test_sensor;
            in combustionStatus = test_combustion;
        }

        out isPerformanceMet : Boolean =
            wb.monitorSensorError.executionTime +
            wb.calcCorrectionValue.executionTime +
            wb.applyCorrection.executionTime <=
            compensationBudget;

        assert constraint { isPerformanceMet }
    }

    verification def Verify_UF3_1_Performance {
        subject uF3_1_PerformanceTestHarness : UF3_1_PerformanceTestHarness;

        in v_sensor : EngineSensorData;
        in v_combustion : CombustionSystemStatus;

        objective performanceObjective {
            requirement {
                doc
                /* UF3_1: 정상 상태에서 마찰 보정 및 액추에이터 제어 인가까지의 지연시간(10ms) 충족 검증 */
            }
        }

        action harness : UF3_1_PerformanceTestHarness {
            in v_baseAir : IntakeAirFlow;
            in v_baseFuel : FuelIgnitionCommand;
            in test_sensor = v_sensor;
            in test_combustion = v_combustion;
        }

        return verdict : VerdictKind = PassIf(harness.isPerformanceMet);
    }

    action def DrivePathSeries_BudgetCheckHarness {
        private import SafeStateLogic::*;
        doc
        /* CF1 주행 경로(UF1_1) + 보정 후처리(UF3_1) + 중재기 처리시간 합이 SHR-08의 50ms 이내인지 예산 수준에서 검사 */
        out isSeriesBudgetMet : Boolean =
            cf1PathBudget + compensationBudget + arbiterBudget <= 50.0 [milli * s];
        assert constraint { isSeriesBudgetMet }
    }
} // package FV_PerformanceConstraintsVerificationModel
