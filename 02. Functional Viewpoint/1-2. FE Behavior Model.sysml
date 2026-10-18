package FE_BehaviorModel {
    private import RV_InterfaceModel::*;
    private import FB_FunctionalBlackBoxModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;
    private import RV_BehavioralModel::*;
    private import SafeStateLogic::*;

    @MetaInformation {
        version = "v0.2";
    }

    state rvEgasState : RV_BehavioralModel::EgasBehavior;

    // Transition의 경우 부모 상태(rvEgasState.drivingControlRegion)의 트랜지션을 그대로 상속 받아야 하는데, Syside Tool의 이슈로 아직 처리 못함.
    // Tool 이 업데이트 되면 별도 작업 필요.

    // ==========================================
    // 1. DrivingTorqueBehavior
    // ==========================================
    state def DrivingTorqueBehavior :> DrivingControlRegion {
        doc
        /* 주행 토크 제어 통합 상태 머신 */

        dependency self to CF1::CF1_1, CF1::CF1_2, CF1::CF1_3, CF3::CF3_1;

        // 다른 패키지의 서브타입(ExtendedDrivingTorqueBehavior 등)에서도 참조할 수 있도록 protected로 선언
        in In_Sensor : EngineSensorData;
        in In_Ignition : IgnitionState;
        in In_CombustionSystemStatus : CombustionSystemStatus;
        in In_Accel : AccelerationIntent;
        in In_Brake : BrakePedalPosition;
        in In_CcCmd : CruiseControlCommand;
        in In_VehicleDynamics : VehicleDynamicsFeedback; // 차속 피드백

        out Out_AirCmd : IntakeAirFlow;
        out Out_FuelCmd : FuelIgnitionCommand;
        out Out_CcState : CruiseControlStateEnum; // EGAS 내부 크루즈 상태 (시스템 레벨 제약/요구에서 참조)
        out Out_CcSetSpeed :> ISQ::speed;

        // CF1 기준 명령(보정 전). active 상태에서만 쓰이며, UF3_1 후처리를 거쳐 Out_*로 나간다.
        private item driveAirCmd : IntakeAirFlow;
        private item driveFuelCmd : FuelIgnitionCommand;
        private attribute ccState : CruiseControlStateEnum = CruiseControlStateEnum::Off;
        private attribute ccSetSpeed :> ISQ::speed;

        bind Out_CcState = ccState;
        bind Out_CcSetSpeed = ccSetSpeed;

        // 시작 상태를 standby에서 powerOff로 변경하여 미정의 구간(Under-specification) 제거
        first start then powerOff;

        // ==========================================
        // 상태 0: 전원 차단 (PowerOff)
        // ==========================================
        state redefines powerOff :> rvEgasState.drivingControlRegion.powerOff {
            // 시동이 꺼져있는(Off) 상태.
            // 물리적으로 불가능한 공회전 출력을 요구하지 않도록 공기량과 연료량을 완벽히 0으로 강제합니다.

            entry action {
                assign Out_AirCmd := new IntakeAirFlow(massFlow=0.0 [kg / s]);
                assign Out_FuelCmd := new FuelIgnitionCommand(injectionPulseWidth=0.0 [s]);
                assign ccState := CruiseControlStateEnum::Off;
                assign ccSetSpeed := 0.0 [km / h];
            }
        }

        // PowerOff -> Standby (시동 On)
        transition powerOnTrigger
            first powerOff
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::On then standby {
            dependency self to t_powerOn;
        }

        // Standby -> PowerOff (대기 중 시동 Off)
        transition powerOffFromStandby
            first standby
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff {
            dependency self to t_powerOffStandby;
        }

        // Active -> PowerOff (주행 중 시동 Off 긴급 차단)
        transition powerOffFromActive
            first active
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff {
            dependency self to t_powerOffActive;
        }

        // BrakeOverridden -> PowerOff (제동 중 시동 Off)
        transition powerOffFromOverride
            first brakeOverridden
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff {
            dependency self to t_powerOffOverride;
        }

        // WaitForPedalRelease -> PowerOff (래치 대기 중 시동 Off)
        transition powerOffFromWait
            first waitForPedalRelease
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff {
            dependency self to t_powerOffWait;
        }

        // ==========================================
        // 상태 1: 공회전 (Standby)
        // ==========================================
        state redefines standby :> rvEgasState.drivingControlRegion.standby {
            entry action {
                // 시동이 켜져 있으나 조작이 없을 때의 물리적 공회전 기본값 출력
                assign Out_AirCmd := new IntakeAirFlow(massFlow=SafeStateLogic::idleAirMassFlow);
                assign Out_FuelCmd :=
                    new FuelIgnitionCommand(injectionPulseWidth=SafeStateLogic::idleFuelPulseWidth);
            }
        }

        // Standby -> Active : 가속 페달이 밟혀 있고 제동 오버라이드 트리거가 아닐 때 (제동 없음)
        transition standbyToActive
            first standby
            accept AccelerationIntent
            if (
                In_Ignition.status == IgnitionStatusEnum::On and
                In_Accel.pedalDisplacement > 0.0 [mm] and
                not IsBrakeOverrideTriggered(In_Accel.pedalDisplacement, ccState, In_Brake.pressure)
            )
                then active {
            dependency self to t_standbyToActive;
        }

        // Standby -> BrakeOverridden : 제동이 먼저 입력된 상태에서 가속이 들어오는 경우
        transition standbyToOverride
            first standby
            accept AccelerationIntent
            if (
                In_Ignition.status == IgnitionStatusEnum::On and
                In_Accel.pedalDisplacement > 0.0 [mm] and
                IsBrakeOverrideTriggered(In_Accel.pedalDisplacement, ccState, In_Brake.pressure)
            )
                then brakeOverridden {
            dependency self to t_standbyToBrake;
        }

        // ==========================================
        // 상태 2: 통합 가속 제어 (Active) - 계층형 복합 상태
        // ==========================================
        state redefines active :> rvEgasState.drivingControlRegion.active {
            // 정상 주행 중에만 CF1 기준 명령에 CF3_1 보정을 직렬 후처리로 적용
            do action compensate : CF3::CF3_1 {
                assign baseAirCmd := driveAirCmd;
                assign baseFuelCmd := driveFuelCmd;
                assign sensor := In_Sensor;
                assign combustionStatus := In_CombustionSystemStatus;
                bind airIntake = Out_AirCmd;
                bind fuelCmd = Out_FuelCmd;
            }

            // 수동 가속(CF1.1)과 크루즈 컨트롤(CF1.2)을 캡슐화한 복합 상태. 내부에서 목표 속도 설정 여부에 따라 수동과 자동 모드를 스위칭합니다.
            first start then manualDriving;

            // 서브 상태 2-1: 수동 주행 (CF1.1)
            state redefines manualDriving :> rvEgasState.drivingControlRegion.active.manualDriving {
                do action manualAccel : CF1::CF1_1 {
                    assign ignition := In_Ignition;
                    assign accel := In_Accel;
                    assign combustionSystemStatus := In_CombustionSystemStatus;
                    assign dynamics := In_VehicleDynamics;
                    bind airCmd = driveAirCmd;
                    bind fuelCmd = driveFuelCmd;
                }
            }

            // 서브 상태 2-2: 크루즈 활성화 (CF1.2)
            state redefines cruiseDriving :> rvEgasState.drivingControlRegion.active.cruiseDriving {
                entry action { assign ccState := CruiseControlStateEnum::Active; }
                exit action { assign ccState := CruiseControlStateEnum::Suspended; }

                do action cruisePidControl : CF1::CF1_2 {
                    assign targetSpeed := ccSetSpeed;
                    assign dynamics := In_VehicleDynamics;
                    assign combustionSystemStatus := In_CombustionSystemStatus;
                    bind airCmd = driveAirCmd;
                    bind fuelCmd = driveFuelCmd;
                }
            }

            // [내부 트랜지션] 가속 페달 → 크루즈 일시 중단(Suspended, 설정 속도 기억). 우선순위: 가속 페달 > 크루즈
            transition cruiseToManual_Cancel
                first cruiseDriving
                accept AccelerationIntent
                if In_Accel.pedalDisplacement > 0.0 [mm] then manualDriving {
                dependency self to t_cruiseToManual;
            }

            // 설정 속도 변경 (Set 재입력)
            transition cruiseReSet
                first cruiseDriving
                accept CruiseControlCommand
                if (
                    In_CcCmd.request == CruiseControlRequestEnum::Set and
                    In_CcCmd.setSpeed > 0.0 [km / h]
                )
                    do action { assign ccSetSpeed := In_CcCmd.setSpeed; }
                then cruiseDriving {
                dependency self to t_cruiseReSet;
            }

            // Cancel → 일시 중단 (exit action이 Suspended 대입)
            transition cruiseCancel
                first cruiseDriving
                accept CruiseControlCommand
                if In_CcCmd.request == CruiseControlRequestEnum::Cancel then standby {
                dependency self to t_cruiseCancel;
            }

            // Off → 설정 속도 삭제 (exit 이후 전이 효과가 Off로 덮어씀)
            transition cruiseOff
                first cruiseDriving
                accept CruiseControlCommand
                if In_CcCmd.request == CruiseControlRequestEnum::Off
                    do action {
                        assign ccState := CruiseControlStateEnum::Off;
                        assign ccSetSpeed := 0.0 [km / h];
                    }
                then standby {
                dependency self to t_cruiseOff;
            }

            // 수동 주행에서 페달 해제 시에만 대기. 크루즈 중에는 대기로 가지 않음
            transition manualToStandby
                first // Before: activeToStandby (active 전체, 레버 setSpeed 조건)
                    manualDriving
                accept AccelerationIntent
                if In_Accel.pedalDisplacement == 0.0 [mm] then standby {
                dependency self to t_manualToStandby;
            }
        }

        // Standby -> Cruise (Set): 페달/제동이 없고 지정 속도가 유효할 때
        transition standbyToCruiseSet
            first standby
            accept CruiseControlCommand
            if (
                In_Ignition.status == IgnitionStatusEnum::On and
                In_CcCmd.request == CruiseControlRequestEnum::Set and
                In_CcCmd.setSpeed > 0.0 [km / h] and
                In_Accel.pedalDisplacement == 0.0 [mm] and
                In_Brake.pressure == 0.0 [Pa]
            )
                do action { assign ccSetSpeed := In_CcCmd.setSpeed; }
            then active.cruiseDriving {
            dependency self to t_standbyToCruiseSet;
        }

        // Standby -> Cruise (Resume): 기억된 설정 속도가 유효할 때
        transition standbyToCruiseResume
            first standby
            accept CruiseControlCommand
            if (
                In_Ignition.status == IgnitionStatusEnum::On and
                In_CcCmd.request == CruiseControlRequestEnum::Resume and
                ccSetSpeed > 0.0 [km / h] and
                In_Accel.pedalDisplacement == 0.0 [mm] and
                In_Brake.pressure == 0.0 [Pa]
            )
                then active.cruiseDriving {
            dependency self to t_standbyToCruiseResume;
        }

        // Active -> BrakeOverridden : active는 구동 요구 활성 상태이며, 최신 입력 상태로 트리거를 평가
        transition activeToOverride
            first active
            accept BrakePedalPosition
            if (
                In_Ignition.status == IgnitionStatusEnum::On and
                IsBrakeOverrideTriggered(In_Accel.pedalDisplacement, ccState, In_Brake.pressure)
            )
                then brakeOverridden {
            dependency self to t_activeToBrake;
        }

        // ==========================================
        // 상태 3: 제동 오버라이드 (BrakeOverridden) - UF1.3
        // ==========================================
        state redefines brakeOverridden :> rvEgasState.drivingControlRegion.brakeOverridden {
            // 브레이크 밟힘 감지 시 안전 최우선 차단 로직(UF1_3) 실행
            do action brakeOverride : CF1::CF1_3 {
                assign overrideTriggered := true;
                bind airCmd = Out_AirCmd;
                bind fuelCmd = Out_FuelCmd;
            }
        }

        // 제동 해제 시점의 가속 페달 "현재" 상태로 분기 (오래된 currentAccel 사용 금지)
        transition overrideToWait
            first brakeOverridden
            accept BrakePedalPosition
            if In_Brake.pressure == 0.0 [Pa] and In_Accel.pedalDisplacement > 0.0 [mm]
                then waitForPedalRelease {
            dependency self to t_brakeToWait;
        }

        transition overrideToStandby
            first brakeOverridden
            accept BrakePedalPosition
            if In_Brake.pressure == 0.0 [Pa] and In_Accel.pedalDisplacement == 0.0 [mm]
                then standby {
            dependency self to t_brakeToStandby;
        }

        // ==========================================
        // 상태 4: 래칭 대기 (WaitForPedalRelease)
        // ==========================================
        state
            redefines waitForPedalRelease :> rvEgasState.drivingControlRegion.waitForPedalRelease {
            entry action {
                assign Out_AirCmd.massFlow := SafeStateLogic::idleAirMassFlow;
                assign Out_FuelCmd.injectionPulseWidth := SafeStateLogic::idleFuelPulseWidth;
            }
        }

        transition waitToStandby
            first waitForPedalRelease
            accept AccelerationIntent
            if In_Accel.pedalDisplacement == 0.0 [mm] then standby {
            dependency self to t_waitToStandby;
        }
    }

    // ==========================================
    // 2. EmergencyInterventionBehavior
    // ==========================================
    state def EmergencyInterventionBehavior :> EmergencyInterventionRegion {
        doc
        /* 외부 능동안전 제어기(ESP/TCU) 긴급 토크 저감 요구 수용 상태 머신 */
        dependency self to CF2::CF2_1, CF2::CF2_2, CF2::CF2_3, CF3::CF3_4;

        in In_ThrottleCmd : ThrottlePositionCommand; // 스로틀 목표 개도 (EGAS 내부 스로틀 루프 신호)
        // 실제 개도(ThrottlePositionFeedback)는 accept 이벤트로 수신한다.

        out Out_AirCmd : IntakeAirFlow;
        out Out_FuelCmd : FuelIgnitionCommand;
        out Out_Active : Boolean; // 중재기에 전달할 개입 활성 플래그

        // 고착 판단을 위해 진입 시점의 공기량을 저장하는 로컬 프로퍼티
        private item currentTorqueReq : TorqueInterventionRequest;

        first start then emergencyStandby;

        // ==========================================
        // 상태 1: 대기 (EmergencyStandby)
        // ==========================================
        state redefines emergencyStandby { // Before: state redefines emergencyStandby;
            entry action { assign Out_Active := false; }
        }

        // Standby -> InterventionActive (토크 저감 요구 발생 시)
        transition triggerIntervention
            first emergencyStandby
            accept req : TorqueInterventionRequest
            if req.requestedTorqueDelta < 0.0 [N * m] do action { assign currentTorqueReq := req; }
            then InterventionActive {
            dependency self to t_triggerIntervention;
        }

        // 점화 OFF → 고착 래치를 포함한 모든 하위 상태 초기화
        transition ignitionOffReset
            first InterventionActive
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then emergencyStandby {
            dependency self to t_ignitionOffReset;
        }

        // ==========================================
        // 상태 2: 긴급 개입 활성화 (InterventionActive) - 긴급 제어 로직을 캡슐화한 복합 상태
        // ==========================================
        state
            redefines InterventionActive
            :> rvEgasState.emergencyInterventionRegion.InterventionActive {
            // 진입 시 지연(Latency) 상황에 따라 초기 상태 분기

            entry action { assign Out_Active := true; }
            exit action { assign Out_Active := false; }

            first start then initialCheck;

            state redefines initialCheck; // 분기를 위한 임시 상태(Pseudo-state 역할)

            transition checkToNormal
                first initialCheck
                if currentTorqueReq.messageAge <= TimingConceptsAndLimits::commDelayThreshold
                then parallelReduction {
                dependency self to t_checkToNormal;
            }

            transition checkToDelay
                first initialCheck
                if currentTorqueReq.messageAge > TimingConceptsAndLimits::commDelayThreshold
                then delayCompensating {
                dependency self to t_checkToDelay;
            }

            // -----------------------------------------
            // 서브 상태 2-1: 정상 토크 저감 (UF2.1)
            // -----------------------------------------
            state
                redefines parallelReduction
                :> rvEgasState.emergencyInterventionRegion.InterventionActive.parallelReduction {
                private import ThrottleStuckLogic::*;
                do action normalReduct : CF2::CF2_1 {
                    assign torqueIntervention := currentTorqueReq;
                    bind airIntake = Out_AirCmd;
                    bind fuelCmd = Out_FuelCmd;
                }

                // [S4] 스로틀 추종 감시 (디바운스)
                first start then tracking;
                state redefines tracking;
                state redefines stuckSuspected;

                transition trackingLost
                    first tracking
                    accept fb : ThrottlePositionFeedback
                    if (
                        currentTorqueReq.requestedTorqueDelta < 0.0 [N * m] and
                        IsThrottleDeviated(
                            In_ThrottleCmd.openingPercentage,
                            fb.openingPercentage,
                            stuckDeviationLimit
                        )
                    )
                        then stuckSuspected {
                    dependency self to t_trackingLost;
                }

                transition trackingRecovered
                    first stuckSuspected
                    accept fb : ThrottlePositionFeedback
                    if (
                        not IsThrottleDeviated(
                            In_ThrottleCmd.openingPercentage,
                            fb.openingPercentage,
                            stuckDeviationLimit
                        )
                    )
                        then tracking {
                    dependency self to t_trackingRecovered;
                }

                // 타이머는 stuckSuspected 진입 시 시작되고, 회복 전이로 나가면 폐기된다
                transition stuckConfirm
                    first stuckSuspected accept after stuckConfirmTime then actuatorStuckFallback {
                    dependency self to t_stuckDetect;
                }
            }

            // -----------------------------------------
            // 서브 상태 2-2: 통신 지연 보상 (UF2.2)
            // -----------------------------------------
            state
                redefines delayCompensating
                :> rvEgasState.emergencyInterventionRegion.InterventionActive.delayCompensating {
                do action delayComp : CF2::CF2_2 {
                    assign torqueIntervention := currentTorqueReq;
                    bind airIntake = Out_AirCmd;
                    bind fuelCmd = Out_FuelCmd;
                }
            }

            // -----------------------------------------
            // 서브 상태 2-3: 액추에이터 고착 연료 차단 (UF2.3) - 단방향 최종 안전 상태
            // -----------------------------------------
            state
                redefines actuatorStuckFallback
                :> rvEgasState.emergencyInterventionRegion.InterventionActive.actuatorStuckFallback {
                do action stuckCut : CF2::CF2_3 {
                    assign stuckConfirmed := true;
                    bind fuelCmd = Out_FuelCmd;

                    // [래치] 해제 요청(delta >= 0)으로 나가지 않는다. 스로틀이 열린 채 고착됐을 수 있으므로
                    // 점화 OFF(ignitionOffReset)로만 해제한다.

                    dependency
                        self
                        to
                            RV_SystemRequirementsModel::Functional_Requirements
                                ::reqInterventionReleaseAndReset; // SYSR-19
                }
            }

            // [내부 트랜지션] 정상 저감 <-> 지연 보상 스위칭
            transition normalToDelay
                first parallelReduction
                accept req : TorqueInterventionRequest
                if (
                    req.requestedTorqueDelta < 0.0 [N * m] and
                    req.messageAge > TimingConceptsAndLimits::commDelayThreshold
                )
                    do action { assign currentTorqueReq := req; }
                then delayCompensating {
                dependency self to t_normalToDelay;
            }

            transition delayToNormal
                first delayCompensating
                accept req : TorqueInterventionRequest
                if (
                    req.requestedTorqueDelta < 0.0 [N * m] and
                    req.messageAge <= TimingConceptsAndLimits::commDelayThreshold
                )
                    do action { assign currentTorqueReq := req; }
                then parallelReduction {
                dependency self to t_delayToNormal;
            }

            transition finishNormalIntervention
                first parallelReduction
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m]
                    do action { assign currentTorqueReq := req; }
                then emergencyStandby {
                dependency self to t_finishNormal;
            }

            transition finishDelayIntervention
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m]
                    do action { assign currentTorqueReq := req; }
                then emergencyStandby {
                dependency self to t_finishDelay;
            }
        }
    }

    // ==========================================
    // 3. SafetyMonitoringBehavior
    // ==========================================
    state def SafetyMonitoringBehavior :> SafetyMonitoringRegion {
        doc
        /* 차량 주행 시스템과 완전히 독립적으로 동작하는 최고 우선순위의 안전 감시(Safety Monitor) 상태 머신.
         * 평상시 실시간 보정(UF3.1)을 수행하며, 확정 시간 이상 지속된 치명 고장 확정 시 
         * 단방향 페일세이프(UF3.2) 상태로 래칭(Latching)되어 물리적인 시스템 차단을 수행합니다.
         * 점화 OFF로만 해제되는 래치
         */

        dependency self to CF3::CF3_2, CF3::CF3_3;

        in In_Sensor : EngineSensorData;
        in In_PedalPosition : AccelerationPedalPosition;
        in In_ThrottleFeedback : ThrottlePositionFeedback;
        in In_Ignition : IgnitionState;

        out Out_AirCmd : IntakeAirFlow;
        out Out_FuelCmd : FuelIgnitionCommand;
        out Out_Dashboard : DashboardWarning; // 클러스터 경고등 출력 추가
        out Out_FaultActive : Boolean;
        out Out_ConfirmedFaultCause : FaultCause; // 확정 원인 (UF3_2, DTC에서 사용)
        out Out_FaultMemory : FaultMemoryRecord;

        first start then normalMonitoring;

        // ==========================================
        // 상태 1: 정상 상태 감시 및 보정 (NormalMonitoring)
        // ==========================================
        state redefines normalMonitoring :> rvEgasState.safetyMonitoringRegion.normalMonitoring {
            entry action {
                assign Out_FaultActive := false;
                assign Out_ConfirmedFaultCause := FaultCause::NoFault;
                assign Out_AirCmd.massFlow := 0.0 [kg / s]; // 요구 없음 값. 중재기는 FailSafe일 때만 cf3를 사용
                assign Out_FuelCmd.injectionPulseWidth := 0.0 [s];
                assign Out_Dashboard.status := DashboardWarningStatusEnum::Normal; // SYSR-25: 고장이 없으면 Normal
            }
        }

        // ==========================================
        // 상태 2: 치명적 결함 페일세이프 (CriticalFault) - UF3.2
        // ==========================================
        state redefines criticalFault :> rvEgasState.safetyMonitoringRegion.criticalFault {
            // 엔진 파손 및 급발진을 막기 위한 하드 차단 상태. 점화 OFF(criticalFaultIgnitionOffReset)로만 해제한다.
            entry action { assign Out_FaultActive := true; }
            do action failSafeAndRecord {
                action fatalFailSafe : CF3::CF3_2 {
                    assign faultCause := Out_ConfirmedFaultCause;
                    bind airIntake = Out_AirCmd;
                    bind fuelCmd = Out_FuelCmd;
                    bind dashboard = Out_Dashboard;
                }
                action storeFault : CF5::CF5_4 { // [R2] 고장 확정 시 DTC를 NVM에 기록 (SYSR-09)
                    assign confirmedFaultCause := Out_ConfirmedFaultCause;
                    bind dtcRecord = Out_FaultMemory;
                }
            }
        }

        // ---- 페달 센서 체인 (SYSR-02) ----
        transition pedalDeviationObserved
            first normalMonitoring
            accept AccelerationPedalPosition
            if (
                IsChannelDeviated(
                    In_PedalPosition.pvs1Percentage,
                    In_PedalPosition.pvs2Percentage,
                    redundancyDeviationLimit
                )
            )
                then pedalFaultSuspected {
            dependency self to t_pedalObserved;
        }
        transition pedalDeviationRecovered
            first pedalFaultSuspected
            accept AccelerationPedalPosition
            if (
                not IsChannelDeviated(
                    In_PedalPosition.pvs1Percentage,
                    In_PedalPosition.pvs2Percentage,
                    redundancyDeviationLimit
                )
            )
                then normalMonitoring {
            dependency self to t_pedalRecovered;
        }
        transition pedalFaultConfirm
            first pedalFaultSuspected
            accept after sensorFaultConfirmTime
            do action { assign Out_ConfirmedFaultCause := FaultCause::PedalSensorDeviation; }
            then criticalFault {
            dependency self to t_pedalConfirm;
        }
        transition pedalSuspectedIgnitionOff
            first pedalFaultSuspected
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring {
            dependency self to t_pedalIgnitionOff;
        }

        // ---- 스로틀 센서 체인 (SYSR-06): 위 체인에서 표의 값으로 교체 ----
        transition throttleDeviationObserved
            first normalMonitoring
            accept ThrottlePositionFeedback
            if (
                IsChannelDeviated(
                    In_ThrottleFeedback.tps1Percentage,
                    In_ThrottleFeedback.tps2Percentage,
                    redundancyDeviationLimit
                )
            )
                then throttleFaultSuspected;
        transition throttleDeviationRecovered
            first throttleFaultSuspected
            accept ThrottlePositionFeedback
            if (
                not IsChannelDeviated(
                    In_ThrottleFeedback.tps1Percentage,
                    In_ThrottleFeedback.tps2Percentage,
                    redundancyDeviationLimit
                )
            )
                then normalMonitoring;
        transition throttleFaultConfirm
            first throttleFaultSuspected
            accept after sensorFaultConfirmTime
            do action { assign Out_ConfirmedFaultCause := FaultCause::ThrottleSensorDeviation; }
            then criticalFault;
        transition throttleSuspectedIgnitionOff
            first throttleFaultSuspected
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring;

        // ---- 과열 체인 (SHR-09) ----
        transition overheatObserved
            first normalMonitoring
            accept EngineSensorData
            if IsOverheated(In_Sensor.coolantTemp, coolantOverheatLimit) then overheatSuspected;
        transition overheatRecovered
            first overheatSuspected
            accept EngineSensorData
            if not IsOverheated(In_Sensor.coolantTemp, coolantOverheatLimit) then normalMonitoring;
        transition overheatConfirm
            first overheatSuspected
            accept after overheatConfirmTime
            do action { assign Out_ConfirmedFaultCause := FaultCause::Overheat; }
            then criticalFault;
        transition overheatSuspectedIgnitionOff
            first overheatSuspected
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring;

        // ---- 래치 해제: 점화 OFF에서만 (S3의 ignitionOffReset과 같은 패턴) ----
        transition criticalFaultIgnitionOffReset
            first criticalFault
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring {
            dependency self to t_safetyIgnitionOffReset;
        }
        // [설계 의도] criticalFault -> normalMonitoring 은 점화 OFF 외에 생성하지 않는다 (센서가 회복돼도 자동 복귀 금지).
    }

    // ==========================================
    // 4. CalibrationSupportBehavior
    // ==========================================
    state def CalibrationSupportBehavior :> CalibrationHandling {
        doc
        /* 캘리브레이션 요청을 받아 CF4를 실행한다. 인가, 검증, 롤백 분기는 CF4 안(BB ResponseSelection, WB)에서 처리하며 자기 출력을 받지 않는다. */
        dependency self to CF4::CF4_1, CF4::CF4_2, CF4::CF4_3;

        in In_Ignition : IgnitionState; // [F4] 점화 상태
        in In_VehicleSpeed : ISQ::SpeedValue; // [F4] 차속 (쓰기 허용 판정)
        in In_ExpectedCredential : Integer; // 인가 기준 자격
        out Out_CalRes : CalibrationStatus;

        private item currentCalReq : CalibrationRequest;

        first start then cal_Idle;
        state redefines cal_Idle;

        state
            redefines processing
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.calibrationHandling
                    .processing {
            do action calibrate : CF4 {
                assign calibration_Req := currentCalReq;
                assign expectedCredential := In_ExpectedCredential;
                assign ignition := In_Ignition;
                assign vehicleSpeed := In_VehicleSpeed;
                bind calibration_Res = Out_CalRes;
            }
        }

        transition calRequest
            first cal_Idle
            accept calReq : CalibrationRequest
            do action { assign currentCalReq := calReq; }
            then processing {
            dependency self to t_calRequest;
        }
        transition calDone first processing then cal_Idle { dependency self to t_calDone; }
    }

    // ==========================================
    // 5. DiagnosticsAndMaintenanceSupportBehavior
    // ==========================================
    state def DiagnosticsAndMaintenanceSupportBehavior :> DiagnosticsHandling {
        doc
        /* 정비사(A/S Service Center)가 진단기를 연결했을 때 고장 진단 코드(DTC)를 제공하고
         * 센서 영점 조정을 자동화하며, 유효하지 않은 요청은 거절하는 복합 진단/유지보수 상태 머신.
         * 수신된 서비스 ID(serviceId)에 따라 분기하여 
         * 각각의 원자적 기능(Atomic Action)으로 처리를 위임합니다.
         */

        private import DtcStroage::*;

        in In_FaultMemory : FaultMemoryRecord; // Before: In_FaultCause (S7)
        in In_Ignition : IgnitionState; // [F4]
        in In_VehicleSpeed : ISQ::SpeedValue;
        out Out_DiagRes : DiagnosticStatus;

        private item currentDiagReq : DiagnosticRequest;

        first start then Diag_Idle;

        // ==========================================
        // 상태 1: 대기 (Diag_Idle)
        // ==========================================
        state
            redefines Diag_Idle
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.diagnosticsHandling.Diag_Idle; // 진단기의 서비스 요청을 기다리는 기본 상태

        transition reqReadDTC
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if diagReq.serviceId == diagServiceReadDtc
                do action { assign currentDiagReq := diagReq; }
            then ReadingDTC {
            dependency self to t_reqDTC;
        }

        transition reqZeroPoint
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if (
                diagReq.serviceId == diagServiceRoutineControl and
                IsServiceModeAllowed(In_Ignition.status, In_VehicleSpeed)
            )
                do action { assign currentDiagReq := diagReq; }
            then CalibratingZeroPoint {
            dependency self to t_reqZero;
        }

        transition reqInvalid
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if diagReq.serviceId != 1 and diagReq.serviceId != 2
                do action { assign currentDiagReq := diagReq; }
            then RejectingRequest {
            dependency self to t_reqInvalid;
        }

        // ==========================================
        // 상태 2: 고장 진단 코드(DTC) 조회 제어 (ReadingDTC) - UF5.1
        // ==========================================
        state
            redefines ReadingDTC
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
                    .ReadingDTC {
            // 진단기 조회 요청 시 센서 상태를 확인하여 DTC 값과 정상 응답(200)을 반환 */
            do action readDTC : CF5::CF5_1 {
                assign faultMemory := In_FaultMemory; // Before: assign sensorPort := In_SensorPort;
            }
        }

        // DTC 조회 처리 완료 후 대기 상태로 복귀
        transition readToIdle first ReadingDTC then Diag_Idle {
            dependency self to t_readToIdle;
        }

        // ==========================================
        // 상태 3: 센서 영점 조정 루틴 제어 (CalibratingZeroPoint) - UF5.2
        // ==========================================
        state
            redefines CalibratingZeroPoint
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
                    .CalibratingZeroPoint {
            // 부품 교체 후 진단기 영점 조정 요청 수신 시, 루틴 수행 후 완료 응답 반환
            do action zeroPointCal : CF5::CF5_2 {
                assign ignition := In_Ignition;
                assign vehicleSpeed := In_VehicleSpeed;
            }
        }

        // 영점 조정 처리 완료 후 대기 상태로 복귀
        transition calToIdle first CalibratingZeroPoint then Diag_Idle {
            dependency self to t_calToIdle;
        }

        // ==========================================
        // 상태 4: 비유효 진단 요청 거절 제어 (RejectingRequest) - UF5.3
        // ==========================================
        state
            redefines RejectingRequest
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
                    .RejectingRequest {
            // 시스템이 지원하지 않는 서비스 ID 요청 시, 에러 응답 반환 및 통신 종료
            do action rejectDiag : CF5::CF5_3 {
                assign ignition := In_Ignition;
                assign vehicleSpeed := In_VehicleSpeed;
            }
        }

        // 거절 처리 완료 후 다음 요청을 위해 대기 상태로 복귀
        transition rejectToIdle first RejectingRequest then Diag_Idle {
            dependency self to t_rejectToIdle;
        }
    }
} // package FE_BehaviorModel
