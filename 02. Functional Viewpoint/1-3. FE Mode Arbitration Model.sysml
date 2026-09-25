package FB_ModeArbitrationModel {
    private import FB_FunctionalBlackBoxModel::*;
    private import FE_BehaviorModel::*;
    private import RV_InterfaceModel::*;
    private import ScalarValues::*;
    private import ReqCommon::*;
    private import SI::*;

    // -----------------------------------------
    // 1. Mode Channel 데이터 타입 정의
    // -----------------------------------------
    enum def SystemOperatingMode {
        Normal_Mode; // CF1(가속/크루즈/제동)이 자체 중재하여 제어하는 정상 주행 상태
        Emergency_Mode; // CF2(ESP/TCU 등)가 개입하여 CF1을 차단하는 긴급 상태
        FailSafe_Mode; // CF3(치명적 결함)이 감지되어 시스템을 물리적으로 차단하는 안전 상태
    }

    item def ModeChannelData {
        attribute currentMode : SystemOperatingMode;
        attribute inhibitDrivingControl : Boolean;
    }

    // -----------------------------------------
    // 2. 확장된 Atomic User Function (Mode Channel 적용)
    // -----------------------------------------
    action def <UF1_1_Ext> ManualAccelerationControl_Extended :> CF1::UF1_1 {
        // 기존 포트에 모드 채널 입력 추가
        in modeCtrl : ModeChannelData;

        // Inhibit 신호 수신 시 출력 차단 제약조건 추가
        constraint ModeInhibitConstraint {
            modeCtrl.inhibitDrivingControl == true implies
            (airCmd.massFlow == 0.0 [kg / s] and fuelCmd.injectionPulseWidth == 0.0 [s])
        }
    }

    // -----------------------------------------
    // 3. 중재자 (Arbiter / Mode Controller) 정의
    // -----------------------------------------
    action def <Arbiter> SystemModeControllerAndArbiter {
        doc
        /* 각 복합 기능(CF)에서 산출된 요구사항을 수집하여 우선순위에 따라 최종 출력을 결정하고 모드 채널 신호를 발송합니다. */

        // 입력: 기능별 산출 토크/공기/연료 제어값
        in cf1_airCmd : IntakeAirFlow;
        in cf1_fuelCmd : FuelIgnitionCommand;
        in cf2_airCmd : IntakeAirFlow;
        in cf2_fuelCmd : FuelIgnitionCommand;
        in cf3_airCmd : IntakeAirFlow;
        in cf3_fuelCmd : FuelIgnitionCommand;

        // 출력: 최종 액추에이터 명령 및 모드 채널 방송
        out final_airCmd : IntakeAirFlow;
        out final_fuelCmd : FuelIgnitionCommand;
        out modeChannelBroadcaster : ModeChannelData;

        // 우선순위 중재 로직 (Constraint 기반 라우팅)
        constraint ArbiterPriorityLogic {
            modeChannelBroadcaster.currentMode == SystemOperatingMode::FailSafe_Mode implies
            (final_airCmd == cf3_airCmd and
                final_fuelCmd == cf3_fuelCmd and
                modeChannelBroadcaster.inhibitDrivingControl == true and
                modeChannelBroadcaster.currentMode == SystemOperatingMode::Emergency_Mode) implies
            (final_airCmd == cf2_airCmd and
                final_fuelCmd == cf2_fuelCmd and
                modeChannelBroadcaster.inhibitDrivingControl == true and
                modeChannelBroadcaster.currentMode == SystemOperatingMode::Normal_Mode) implies
            (final_airCmd == cf1_airCmd and
                final_fuelCmd == cf1_fuelCmd and
                modeChannelBroadcaster.inhibitDrivingControl == false)
        }
    }

    // -----------------------------------------
    // 4. 확장된 State Machine (Mode Channel에 의한 묵음/안전 상태 전환)
    // -----------------------------------------
    state def ExtendedDrivingTorqueBehavior :> DrivingTorqueBehavior {
        // 1. 부모의 1, 2번째 파라미터가 out인 경우, out부터 순서대로 위치 고정
        out Out_AirCmd : IntakeAirFlow :>> DrivingTorqueBehavior::Out_AirCmd;
        out Out_FuelCmd : FuelIgnitionCommand :>> DrivingTorqueBehavior::Out_FuelCmd;

        // 2. 그 다음 in 파라미터들 순서대로 위치 고정
        in In_Ignition : IgnitionState :>> DrivingTorqueBehavior::In_Ignition;
        in In_CombustionSystemStatus
            : CombustionSystemStatus :>> DrivingTorqueBehavior::In_CombustionSystemStatus;

        // 3. 맨 마지막 위치에 자식 전용 새로운 in 파라미터 추가
        in In_ModeCtrl : ModeChannelData;

        state redefines active :> DrivingTorqueBehavior::active {
            // Mode 채널로부터 Inhibit 신호 수신 시, 운전자 조작과 무관하게 강제 대기(Pass-through) 상태로 전환
            transition forceInhibit
                first active
                accept mode : ModeChannelData
                if mode.inhibitDrivingControl == true then forcedInhibitedStandby;

            transition activeToOverrideExt
                first active
                accept brake : BrakePedalPosition
                // 브레이크 입력이 들어와도, 강제 차단(inhibit) 상태가 아닐 때만 전이되도록 우선순위 명시
                if (
                    In_Ignition.status == ReqCommon::IgnitionStatusEnum::On and
                    brake.pressure > 0.0 [Pa] and
                    In_ModeCtrl.inhibitDrivingControl == false
                ) // <--- 명시적 배타성 확보
                    do action { assign currentBrake := brake; }
                then brakeOverridden;
        }

        // 새로운 안전 묵음 상태 추가 (Inhibited)
        state forcedInhibitedStandby {
            entry action {
                assign Out_AirCmd.massFlow := 0.0 [kg / s];
                assign Out_FuelCmd.injectionPulseWidth := 0.0 [s];
            }
        }

        transition releaseInhibit
            first forcedInhibitedStandby
            accept mode : ModeChannelData
            if mode.inhibitDrivingControl == false then standby;
    }
} // package FB_ModeArbitrationModel
