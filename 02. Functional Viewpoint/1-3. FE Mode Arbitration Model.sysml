package FB_ModeArbitrationModel {
    private import FB_FunctionalBlackBoxModel::*;
    private import FE_BehaviorModel::*;
    private import RV_InterfaceModel::*;
    private import ScalarValues::*;
    private import ReqCommon::*;
    private import SI::*;
    private import RV_SystemRequirementsModel::Functional_Requirements::*;
    private import RV_SystemRequirementsModel::Performance_Requirements::*;
    private import RV_SystemRequirementsModel
            ::Diagnostics_Maintainability_Security_Architecture_Requirements::*;

    @MetaInformation {
        version = "v0.2";
    }
    // -----------------------------------------
    // 1. Mode Channel 데이터 타입 정의
    // -----------------------------------------
    enum def SystemOperatingMode {
        Normal_Mode; // UF1(가속/크루즈/제동)이 자체 중재하여 제어하는 정상 주행 상태
        Emergency_Mode; // UF2(ESP/TCU 등)가 개입 중인 긴급 상태. 최종 출력은 UF1과 UF2 중 더 제한적인 값이며 UF1은 계속 동작한다(브레이크 오버라이드 유지)
        FailSafe_Mode; // UF3(치명적 결함)이 감지되어 시스템을 물리적으로 차단하는 안전 상태
    }

    item def ModeChannelData {
        attribute currentMode : SystemOperatingMode;
        attribute inhibitDrivingControl : Boolean;
    }

    // -----------------------------------------
    // 2. 확장된 Atomic User Function (Mode Channel 적용)
    // -----------------------------------------
    action def <UF1_1_Ext> ManualAccelerationControl_Extended :> CF1::CF1_1 {
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
        in cf2_active : Boolean;
        in cf3_faultActive : Boolean;

        // 출력: 최종 액추에이터 명령 및 모드 채널 방송
        out final_airCmd : IntakeAirFlow;
        out final_fuelCmd : FuelIgnitionCommand;
        out modeChannelBroadcaster : ModeChannelData;

        // 우선순위 중재 로직 (Constraint 기반 라우팅)
        constraint ArbiterPriorityLogic {
            // 1순위: CF3 결함 → 안전 출력, 주행 제어 억제
            (cf3_faultActive == true implies
                (modeChannelBroadcaster.currentMode == SystemOperatingMode::FailSafe_Mode and
                    modeChannelBroadcaster.inhibitDrivingControl == true and
                    final_airCmd == cf3_airCmd and
                    final_fuelCmd == cf3_fuelCmd)) and
            (// 2순위: CF2 개입 → 채널별로 더 제한적인 쪽(동률이면 CF1)을 항목째 선택, CF1은 억제하지 않음
                (cf3_faultActive == false and cf2_active == true) implies
                (modeChannelBroadcaster.currentMode == SystemOperatingMode::Emergency_Mode and
                    modeChannelBroadcaster.inhibitDrivingControl == false and
                    ((final_airCmd == cf1_airCmd and cf1_airCmd.massFlow <= cf2_airCmd.massFlow) or
                        (final_airCmd == cf2_airCmd and
                            cf2_airCmd.massFlow < cf1_airCmd.massFlow)) and
                    ((final_fuelCmd == cf1_fuelCmd and
                            cf1_fuelCmd.injectionPulseWidth <= cf2_fuelCmd.injectionPulseWidth) or
                        (final_fuelCmd == cf2_fuelCmd and
                            cf2_fuelCmd.injectionPulseWidth <
                            cf1_fuelCmd.injectionPulseWidth)))) and
            (// 3순위: 결함도 개입도 없으면 CF1 그대로
                (cf3_faultActive == false and cf2_active == false) implies
                (modeChannelBroadcaster.currentMode == SystemOperatingMode::Normal_Mode and
                    modeChannelBroadcaster.inhibitDrivingControl == false and
                    final_airCmd == cf1_airCmd and
                    final_fuelCmd == cf1_fuelCmd))
        }

        satisfy requirement 'SYSR-07'; // FailSafe 시 cf3 선택 (reqSafeStateEnforcementOnFault)
        satisfy requirement 'SYSR-01a'; // Emergency 중에도 CF1 오버라이드 유지 (min 선택)
        satisfy requirement 'SYSR-12'; // 구조 요구 (검증: Inspection, UC6)
        satisfy RV_SystemRequirementsModel::Functional_Requirements::reqArbitrationPriority; // SYSR-18
    }

    // -----------------------------------------
    // 4. 확장된 State Machine (Mode Channel에 의한 묵음/안전 상태 전환)
    // -----------------------------------------
    state def ExtendedDrivingTorqueBehavior :> DrivingTorqueBehavior {
        out Out_AirCmd : IntakeAirFlow :>> DrivingTorqueBehavior::Out_AirCmd;
        out Out_FuelCmd : FuelIgnitionCommand :>> DrivingTorqueBehavior::Out_FuelCmd;
        out Out_CcState : CruiseControlStateEnum :>> DrivingTorqueBehavior::Out_CcState;

        in In_Ignition : IgnitionState :>> DrivingTorqueBehavior::In_Ignition;
        in In_CombustionSystemStatus
            : CombustionSystemStatus :>> DrivingTorqueBehavior::In_CombustionSystemStatus;

        in In_Accel : AccelerationIntent :>> DrivingTorqueBehavior::In_Accel;
        in In_Brake : BrakePedalPosition :>> DrivingTorqueBehavior::In_Brake;
        in In_CcCmd : CruiseControlCommand :>> DrivingTorqueBehavior::In_CcCmd;
        in In_Sensor : EngineSensorData :>> DrivingTorqueBehavior::In_Sensor;
        in In_VehicleDynamics
            : VehicleDynamicsFeedback :>> DrivingTorqueBehavior::In_VehicleDynamics;

        in In_ModeCtrl : ModeChannelData;

        state redefines active :> DrivingTorqueBehavior::active {
            // FailSafe 시 강제 차단
            transition forceInhibit
                first active
                accept mode : ModeChannelData
                if mode.inhibitDrivingControl == true then forcedInhibitedStandby;

            transition activeToOverrideExt
                first active
                accept BrakePedalPosition
                if (
                    In_Ignition.status == ReqCommon::IgnitionStatusEnum::On and
                    SafeStateLogic::IsBrakeOverrideTriggered(
                        In_Accel.pedalDisplacement,
                        Out_CcState,
                        In_Brake.pressure
                    ) and // ccState
                    In_ModeCtrl.inhibitDrivingControl == false
                )
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

        // ForcedInhibitedStandby -> PowerOff (재시동으로 초기화)
        transition powerOffFromInhibited
            first forcedInhibitedStandby
            accept ign : IgnitionState
            if ign.status == ReqCommon::IgnitionStatusEnum::Off then powerOff;
    }
} // package FB_ModeArbitrationModel
