package FV_FunctionalEquivalenceVerificationModel {
    doc
    /* [기능 동등성 검증 모델 (Functional Equivalence Verification Model)]
     * 본 패키지는 블랙박스 유저 기능(FB)과 화이트박스 소기능(FW) 간의 
     * 입출력 변환 로직이 100% 동일하게 동작하는지를 검증합니다.
     * 수정 사항: VerdictKind 및 PassIf 등 SysML v2 검증 시맨틱에 맞춘 구조 전면 리팩토링
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import FB_ModeArbitrationModel::*;
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
    // 1. CF1 (주행 토크 제어 및 중재 기능) 동등성 검증
    // =========================================================================

    // 1.1 수동 가속 제어 (UF1_1)
    action def UF1_1_EquivalenceTestHarness {
        in test_ignition : IgnitionState;
        in test_accel : AccelerationIntent;

        // 등가성 여부를 Boolean 속성으로 산출
        out isEquivalent : Boolean = (bb.airCmd == wb.airCmd and bb.fuelCmd == wb.fuelCmd);

        // 블랙박스 실행 및 인풋 주입
        action bb : CF1::UF1_1 {
            in ignition = test_ignition;
            in accel = test_accel;
        }
        
        // 화이트박스 실행 및 동일 인풋 주입
        action wb : FW_UF1_WhiteBoxModel::ManualAccelerationControl_WhiteBox {
            in ignition = test_ignition;
            in accel = test_accel;
        }

        // 등가성 조건 단정 (불일치 시 제약조건 위반)
        assert constraint { isEquivalent }
    }

    verification def Verify_UF1_1 {
        // 1) 검증 대상 시스템(Subject) 지정
        subject uF1_1_EquivalenceTestHarness : UF1_1_EquivalenceTestHarness;

        // 2) 검증 입력 파라미터 선언
        in v_ignition : IgnitionState;
        in v_accel : AccelerationIntent;

        // 3) 검증 목적(Objective) 및 검증 대상 요구사항 지정
        objective equivalenceObjective {
           requirement {
            doc /* UF1_1 기능 동등성 검증 요구사항 */
           }
        }

        // 4) 테스트 하네스 실행 및 입력값 주입
        action harness : UF1_1_EquivalenceTestHarness {
            in test_ignition = v_ignition;
            in test_accel = v_accel;
        }

        // 5) PassIf를 사용하여 VerdictKind 타입 결과 반환
        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 1.2 정속 주행 제어 (UF1_2)
    action def UF1_2_EquivalenceTestHarness {
        in test_ccCmd : CruiseControlCommand;
        in test_combustionSystemStatus : CombustionSystemStatus;

        out isEquivalent : Boolean = (bb.airCmd == wb.airCmd and bb.fuelCmd == wb.fuelCmd);

        action bb : CF1::UF1_2 {
            in ccCmd = test_ccCmd;
            in combustionSystemStatus = test_combustionSystemStatus;
        }
        action wb : FW_UF1_WhiteBoxModel::CruiseControlDriving_WhiteBox {
            in ccCmd = test_ccCmd;
            in combustionSystemStatus = test_combustionSystemStatus;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF1_2 {
        subject uF1_2_EquivalenceTestHarness : UF1_2_EquivalenceTestHarness;

        in v_ccCmd : CruiseControlCommand;
        in v_combustionSystemStatus : CombustionSystemStatus;

        objective equivalenceObjective {
           requirement { doc /* UF1_2 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF1_2_EquivalenceTestHarness {
            in test_ccCmd = v_ccCmd;
            in test_combustionSystemStatus = v_combustionSystemStatus;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 1.3 제동 우선 오버라이드 제어 (UF1_3)
    action def UF1_3_EquivalenceTestHarness {
        in test_brakeCmd : BrakePedalPosition;

        out isEquivalent : Boolean = (bb.airCmd == wb.airCmd and bb.fuelCmd == wb.fuelCmd);

        action bb : CF1::UF1_3 {
            in brakeCmd = test_brakeCmd;
        }
        action wb : FW_UF1_WhiteBoxModel::BrakeOverrideIntervention_WhiteBox {
            in brakeCmd = test_brakeCmd;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF1_3 {
        subject uF1_3_EquivalenceTestHarness : UF1_3_EquivalenceTestHarness;

        in v_brakeCmd : BrakePedalPosition;

        objective equivalenceObjective {
           requirement { doc /* UF1_3 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF1_3_EquivalenceTestHarness {
            in test_brakeCmd = v_brakeCmd;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 1.4 시스템 모드 중재자 (Arbiter)
    action def Arbiter_EquivalenceTestHarness {
        in t_cf1_air : IntakeAirFlow;     in t_cf1_fuel : FuelIgnitionCommand;
        in t_cf2_air : IntakeAirFlow;     in t_cf2_fuel : FuelIgnitionCommand;
        in t_cf3_air : IntakeAirFlow;     in t_cf3_fuel : FuelIgnitionCommand;

        out isEquivalent : Boolean = (
            bb.final_airCmd == wb.final_airCmd and 
            bb.final_fuelCmd == wb.final_fuelCmd and 
            bb.modeChannelBroadcaster == wb.modeChannelBroadcaster
        );

        action bb : FB_ModeArbitrationModel::SystemModeControllerAndArbiter {
            in cf1_airCmd = t_cf1_air;    in cf1_fuelCmd = t_cf1_fuel;
            in cf2_airCmd = t_cf2_air;    in cf2_fuelCmd = t_cf2_fuel;
            in cf3_airCmd = t_cf3_air;    in cf3_fuelCmd = t_cf3_fuel;
        }
        action wb : FW_UF1_WhiteBoxModel::SystemArbiter_WhiteBox {
            in cf1_airCmd = t_cf1_air;    in cf1_fuelCmd = t_cf1_fuel;
            in cf2_airCmd = t_cf2_air;    in cf2_fuelCmd = t_cf2_fuel;
            in cf3_airCmd = t_cf3_air;    in cf3_fuelCmd = t_cf3_fuel;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_Arbiter {
        subject arbiter_EquivalenceTestHarness : Arbiter_EquivalenceTestHarness;

        in v_cf1_air : IntakeAirFlow;     in v_cf1_fuel : FuelIgnitionCommand;
        in v_cf2_air : IntakeAirFlow;     in v_cf2_fuel : FuelIgnitionCommand;
        in v_cf3_air : IntakeAirFlow;     in v_cf3_fuel : FuelIgnitionCommand;

        objective equivalenceObjective {
           requirement { doc /* 시스템 모드 중재자(Arbiter) 동등성 검증 요구사항 */ }
        }

        action harness : Arbiter_EquivalenceTestHarness {
            in t_cf1_air = v_cf1_air;     in t_cf1_fuel = v_cf1_fuel;
            in t_cf2_air = v_cf2_air;     in t_cf2_fuel = v_cf2_fuel;
            in t_cf3_air = v_cf3_air;     in t_cf3_fuel = v_cf3_fuel;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // =========================================================================
    // 2. CF2 (긴급 토크 개입 및 보상 기능) 동등성 검증
    // =========================================================================

    // 2.1 병렬 토크 저감 제어 (UF2_1)
    action def UF2_1_EquivalenceTestHarness {
        in test_req : TorqueInterventionRequest;

        out isEquivalent : Boolean = (bb.airIntake == wb.airIntake and bb.fuelCmd == wb.fuelCmd);

        action bb : CF2::UF2_1 {
            in torqueIntervention = test_req;
        }
        action wb : FW_CF2_WhiteBoxModel::ParallelTorqueReduction_WhiteBox {
            in torqueIntervention = test_req;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF2_1 {
        subject uF2_1_EquivalenceTestHarness : UF2_1_EquivalenceTestHarness;

        in v_req : TorqueInterventionRequest;

        objective equivalenceObjective {
           requirement { doc /* UF2_1 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF2_1_EquivalenceTestHarness {
            in test_req = v_req;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 2.2 통신 지연 보상 제어 (UF2_2)
    action def UF2_2_EquivalenceTestHarness {
        in test_req : TorqueInterventionRequest;

        out isEquivalent : Boolean = (bb.airIntake == wb.airIntake and bb.fuelCmd == wb.fuelCmd);

        action bb : CF2::UF2_2 {
            in torqueIntervention = test_req;
        }
        action wb : FW_CF2_WhiteBoxModel::CommunicationDelayCompensation_WhiteBox {
            in torqueIntervention = test_req;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF2_2 {
        subject uF2_2_EquivalenceTestHarness : UF2_2_EquivalenceTestHarness;

        in v_req : TorqueInterventionRequest;

        objective equivalenceObjective {
           requirement { doc /* UF2_2 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF2_2_EquivalenceTestHarness {
            in test_req = v_req;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 2.3 고착 대응 연료 차단 제어 (UF2_3)
    action def UF2_3_EquivalenceTestHarness {
        in test_airFeedback : IntakeAirFlow;

        out isEquivalent : Boolean = (bb.fuelCmd == wb.fuelCmd);

        action bb : CF2::UF2_3 {
            in airIntakeFeedback = test_airFeedback;
        }
        action wb : FW_CF2_WhiteBoxModel::ActuatorStuckFuelCut_WhiteBox {
            in airIntakeFeedback = test_airFeedback;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF2_3 {
        subject uF2_3_EquivalenceTestHarness : UF2_3_EquivalenceTestHarness;

        in v_airFeedback : IntakeAirFlow;

        objective equivalenceObjective {
           requirement { doc /* UF2_3 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF2_3_EquivalenceTestHarness {
            in test_airFeedback = v_airFeedback;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // =========================================================================
    // 3. CF3 (하드웨어 안전 모니터링 및 페일세이프) 동등성 검증
    // =========================================================================

    // 3.1 하드웨어 마찰 및 지연 보정 제어 (UF3_1)
    action def UF3_1_EquivalenceTestHarness {
        in test_sensor : EngineSensorData;
        in test_combustion : CombustionSystemStatus;

        out isEquivalent : Boolean = (bb.airIntake == wb.airIntake and bb.fuelCmd == wb.fuelCmd);

        action bb : CF3::UF3_1 {
            in sensor = test_sensor;
            in combustionStatus = test_combustion;
        }
        action wb : FW_CF3_WhiteBoxModel::HardwareDelayAndFrictionCompensation_WhiteBox {
            in sensor = test_sensor;
            in combustionStatus = test_combustion;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF3_1 {
        subject uF3_1_EquivalenceTestHarness : UF3_1_EquivalenceTestHarness;

        in v_sensor : EngineSensorData;
        in v_combustion : CombustionSystemStatus;

        objective equivalenceObjective {
           requirement { doc /* UF3_1 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF3_1_EquivalenceTestHarness {
            in test_sensor = v_sensor;
            in test_combustion = v_combustion;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

    // 3.2 치명적 센서 결함 페일세이프 제어 (UF3_2)
    action def UF3_2_EquivalenceTestHarness {
        in test_sensor : EngineSensorData;

        out isEquivalent : Boolean = (bb.airIntake == wb.airIntake and bb.fuelCmd == wb.fuelCmd and bb.dashboard == wb.dashboard);

        action bb : CF3::UF3_2 {
            in sensor = test_sensor;
        }
        action wb : FW_CF3_WhiteBoxModel::CriticalSensorFaultFailSafe_WhiteBox {
            in sensor = test_sensor;
        }

        assert constraint { isEquivalent }
    }

    verification def Verify_UF3_2 {
        subject uF3_2_EquivalenceTestHarness : UF3_2_EquivalenceTestHarness;

        in v_sensor : EngineSensorData;

        objective equivalenceObjective {
           requirement { doc /* UF3_2 기능 동등성 검증 요구사항 */ }
        }

        action harness : UF3_2_EquivalenceTestHarness {
            in test_sensor = v_sensor;
        }

        return verdict : VerdictKind = PassIf(harness.isEquivalent);
    }

} // package FV_FunctionalEquivalenceVerificationModel