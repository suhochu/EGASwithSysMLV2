package FW_UF1_WhiteBoxModel {
    doc
    /* [CF1 주행 토크 제어 - 화이트박스 모델 파트 1]
     * 본 패키지는 UF1 기능 블랙박스(FB)의 각 원자적 유저 기능 내부를
     * Sensing -> Core Logic -> Actuation의 3단계 파이프라인으로 분해합니다.
     * 상위 제약조건의 중복 선언을 배제하고, 하위 기능으로의 제약 할당(Budgeting) 및
     * 내부 데이터 흐름(Internal Flow) 로직만을 명세하여 결합도를 낮추고 응집도를 높였습니다.
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import FB_ModeArbitrationModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.3";
    }

    // ==========================================
    //  테스트 오라클 검증을 위한 메타데이터 정의
    // ==========================================
    metadata def TestOracle {
        doc
        /* 테스트 오라클 속성 정의: 
         * 해당 제약조건이 단독 소프트웨어 시뮬레이션(MiL/SiL)으로 검증 가능한지, 
         * 아니면 물리 플랜트(FMU 등)와의 연동(Co-Simulation)이 필수적인지 명시합니다.
         */
        attribute requiresCoSimulation : Boolean;
        attribute plantModelDependency : String;
        attribute description : String;
    }

    // ==========================================
    // 0. 화이트박스 내부 공용 데이터 타입 (Internal Items)
    // ==========================================
    item def InternalTorqueDemand {
        // 내부 논리 연산을 위해 산출된 타겟 물리 토크량
        attribute targetTorque : TorqueValue;
        attribute calculationTimestamp : TimeValue;
    }

    item def InternalErrorData {
        attribute frictionError : Real;
        attribute latencyError : TimeValue;
    }
    item def InternalCorrectionCmd {
        attribute targetAirAdjust : MassFlowValue;
        attribute targetFuelAdjust : TimeValue;
    }

    item def InternalCutoffSignal {
        attribute isCutoffActive : Boolean; // 제동 우선순위에 따른 강제 차단 활성화 플래그
    }

    // ==========================================
    // 1. UF1_1 수동 가속 제어 화이트박스 분해
    // ==========================================
    action def <UF1_1_WB> ManualAccelerationControl_WhiteBox :> CF1::CF1_1 {
        doc
        /* 상위 블랙박스(CF1::UF1_1)의 포트 및 제약조건을 상속받아 내부 흐름을 구현합니다. */

        // 명시적 가시성을 위해 상속받은 in/out 파라미터를 다시 선언 (bind 및 flow 연결용)
        in ignition : IgnitionState :>> CF1::CF1_1::ignition;
        in accel : AccelerationIntent :>> CF1::CF1_1::accel;
        out airCmd : IntakeAirFlow :>> CF1::CF1_1::airCmd;
        out fuelCmd : FuelIgnitionCommand :>> CF1::CF1_1::fuelCmd;

        // [Step 1: Sensing] 페달 입력 필터링 소기능
        action filterPedalInput {
            in rawAccel : AccelerationIntent;
            out validAccel : AccelerationIntent;
            attribute executionTime : TimeValue;

            // [로컬 제약] 입력 센싱 단계의 물리적 노이즈 제거 필터링에 허용된 최대 지연시간 (예산 10ms)
            constraint Local_FilterLatency { executionTime <= 10.0 [milli * s] }
        }

        // [Step 2: Core Logic] 목표 토크 산출 소기능
        action calcManualTorque {
            in ignStatus : IgnitionState;
            in filteredAccel : AccelerationIntent;
            out torqueDemand : InternalTorqueDemand;
            attribute executionTime : TimeValue;

            // [로컬 제약] 페달 값을 물리적 목표 토크로 변환하는 코어 알고리즘 연산 지연시간 (예산 20ms)
            constraint Local_CalcLatency { executionTime <= 20.0 [milli * s] }
            // [로컬 제약] 상위 블랙박스의 Precondition을 연산 단계의 필수 선행 조건으로 할당 (시동 On & 페달 변위 > 0)
            constraint Local_Precondition {
                ignStatus.status == IgnitionStatusEnum::On and
                filteredAccel.pedalDisplacement > 0.0 [mm]
            }
        }

        // [Step 3: Actuation] 엔진 제어 명령 변환 소기능
        action genEngineCommand {
            in torqueReq : InternalTorqueDemand;
            out outAir : IntakeAirFlow;
            out outFuel : FuelIgnitionCommand;
            attribute executionTime : TimeValue;

            // [로컬 제약] 산출된 토크를 스로틀/인젝터 제어 펄스로 변환하는 액추에이션 지연시간 (예산 20ms)
            constraint Local_CmdGenLatency { executionTime <= 20.0 [milli * s] }
        }

        attribute pipelineLatency : TimeValue =
            filterPedalInput.executionTime +
            calcManualTorque.executionTime +
            genEngineCommand.executionTime;

        assert constraint redefines PerformanceConstraints {
            out redefines result =
                airCmd.responseTime == pipelineLatency and
                fuelCmd.responseTime == pipelineLatency and
                pipelineLatency <= 50.0 [milli * s];
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 (Internal Flows & Bindings) ---

        // 1. 외부 입력을 필터링 단계와 연산 단계로 전달
        bind accel = filterPedalInput.rawAccel;
        bind ignition = calcManualTorque.ignStatus;

        // 2. 소기능 간의 직렬 파이프라인 연결
        flow filterPedalInput.validAccel to calcManualTorque.filteredAccel;
        flow calcManualTorque.torqueDemand to genEngineCommand.torqueReq;

        // 3. 최종 산출물을 외부 출력으로 바인딩
        bind genEngineCommand.outAir = airCmd;
        bind genEngineCommand.outFuel = fuelCmd;
    }

    // ==========================================
    // 2. UF1_2 정속 주행 제어(크루즈) 화이트박스 분해
    // ==========================================
    action def <UF1_2_WB> CruiseControlDriving_WhiteBox :> CF1::CF1_2 {
        in targetSpeed : ISQ::SpeedValue :>> CF1::CF1_2::targetSpeed;
        in dynamics : VehicleDynamicsFeedback :>> CF1::CF1_2::dynamics;
        in combustionSystemStatus : CombustionSystemStatus :>> CF1::CF1_2::combustionSystemStatus;
        out airCmd : IntakeAirFlow :>> CF1::CF1_2::airCmd;
        out fuelCmd : FuelIgnitionCommand :>> CF1::CF1_2::fuelCmd;

        // [Step 1: Sensing] 설정 속도 검증
        action validateTarget {
            in rawTarget : ISQ::SpeedValue;
            out validTarget : ISQ::SpeedValue;
            constraint Local_Precondition { rawTarget > 0.0 [km / h] }
        }

        // [Step 2: Core Logic] 속도 오차 기반 PID 목표 토크 연산
        action calcCruiseTorque {
            in validTarget : ISQ::SpeedValue;
            in vehicleSpeed : ISQ::SpeedValue; // 속도 오차 계산의 피드백
            in engineStatus : CombustionSystemStatus; // 토크 추종 피드백
            out torqueDemand : InternalTorqueDemand;

            @TestOracle {
                requiresCoSimulation = true;
                plantModelDependency = "Engine_Dynamics_Plant_FMU_v2.0";
                description =
                    "정속 주행의 속도 오차(Steady-State Speed Error)는 소프트웨어 로직만으로 판별 불가. 차량/엔진 플랜트 모델 연동(Co-Simulation) 환경에서 측정되어야 하는 오라클입니다.";
            }

            constraint Local_PidSpeedErrorLimit {
                // Before: Local_PidErrorLimit { engineStatus.steadyStateError <= 2.0 }
                CruiseControlLogic::IsCruiseSpeedHeld(
                    validTarget,
                    vehicleSpeed,
                    CruiseControlLogic::cruiseSpeedErrorLimitPct
                )
            }
        }

        // [Step 3: Actuation] 엔진 제어 명령 변환 (수동 가속과 동일한 로직 구조 활용)
        action genEngineCommandOut {
            in torqueReq : InternalTorqueDemand;
            out outAir : IntakeAirFlow;
            out outFuel : FuelIgnitionCommand;
        }

        // 상위 블랙박스 제약을 재정의(redefines)하는 assert constraint에도 TestOracle 속성 전파
        @TestOracle {
            requiresCoSimulation = true;
            plantModelDependency = "Engine_Dynamics_Plant_FMU_v2.0";
            description =
                "상위 블랙박스(UF1_2)의 steadyStateErrorLimit 제약을 검증하기 위한 Co-Simulation 오라클";
        }

        assert constraint redefines cruiseSpeedHoldLimit {
            out redefines result = CruiseControlLogic::IsCruiseSpeedHeld(
                targetSpeed,
                dynamics.vehicleSpeed,
                CruiseControlLogic::cruiseSpeedErrorLimitPct
            );
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 (Internal Flows & Bindings) ---

        // 1. 외부 입력 연결
        bind targetSpeed = validateTarget.rawTarget;
        bind dynamics.vehicleSpeed = calcCruiseTorque.vehicleSpeed;
        bind combustionSystemStatus = calcCruiseTorque.engineStatus;

        // 2. 소기능 간 파이프라인 연결
        flow validateTarget.validTarget to calcCruiseTorque.validTarget;
        flow calcCruiseTorque.torqueDemand to genEngineCommandOut.torqueReq;

        // 3. 최종 출력 바인딩
        bind genEngineCommandOut.outAir = airCmd;
        bind genEngineCommandOut.outFuel = fuelCmd;
    }

    // ==========================================
    // 3. UF1_3 제동 우선 오버라이드 화이트박스 분해
    // ==========================================
    action def <UF1_3_WB> BrakeOverrideIntervention_WhiteBox :> CF1::CF1_3 {
        private import SafeStateLogic::*;
        in overrideTriggered : Boolean :>> CF1::CF1_3::overrideTriggered;
        out airCmd : IntakeAirFlow :>> CF1::CF1_3::airCmd;
        out fuelCmd : FuelIgnitionCommand :>> CF1::CF1_3::fuelCmd;

        // [Step 1: Sensing] 구동 요구 중 제동 감지
        action detectBrake {
            in triggered : Boolean;
            out cutoffTrigger : InternalCutoffSignal;

            constraint Local_TriggerGen {
                triggered == true implies cutoffTrigger.isCutoffActive == true
            }

            // 브레이크 센싱 단계의 실행 시간 예산 할당 (4ms)
            attribute executionTime : TimeValue;
            constraint Local_DetectLatency { executionTime <= 4.0 [milli * s] }
        }

        // [Step 2 & 3: Logic & Actuation] 트리거 수신 시 공회전 출력 생성 (Zero-Torque → Idle-Torque)
        action arbitrateOverride {
            in trigger : InternalCutoffSignal;
            out limitedAirOut : IntakeAirFlow; // 구 zeroAirOut
            out limitedFuelOut : FuelIgnitionCommand; // 구 zeroFuelOut

            constraint Local_ForceIdleOutput {
                // 구 Local_ForceZeroOutput
                trigger.isCutoffActive == true implies
                (limitedAirOut.massFlow == idleAirMassFlow and
                    limitedFuelOut.injectionPulseWidth == idleFuelPulseWidth)
            }

            // 긴급 제한 로직 연산 및 액추에이터 제어 명령 하달 단계의 실행 시간 예산 할당 (6ms)
            attribute executionTime : TimeValue;
            constraint Local_OverrideLatency { executionTime <= 6.0 [milli * s] }
        }

        // 10ms 이내 응답 요구(uc1_vc05)를 두 소기능의 지연시간 합산으로 논리적 증명 (기존 그대로)
        assert constraint OverrideLatencyBudget {
            detectBrake.executionTime + arbitrateOverride.executionTime <= 10.0 [milli * s]
        }

        assert constraint redefines SafeStateConstraints {
            out redefines result =
                detectBrake.cutoffTrigger.isCutoffActive == true implies
                IsTorqueLimited(
                    arbitrateOverride.limitedAirOut.massFlow,
                    arbitrateOverride.limitedFuelOut.injectionPulseWidth
                );
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind overrideTriggered = detectBrake.triggered;
        flow detectBrake.cutoffTrigger to arbitrateOverride.trigger;
        bind arbitrateOverride.limitedAirOut = airCmd;
        bind arbitrateOverride.limitedFuelOut = fuelCmd;
    }

    // ==========================================
    // 4. Arbiter 중재자 화이트박스 분해
    // ==========================================
    action def <Arbiter_WB> SystemArbiter_WhiteBox
        :> FB_ModeArbitrationModel::SystemModeControllerAndArbiter {
        in cf1_airCmd
            : IntakeAirFlow :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf1_airCmd;
        in cf1_fuelCmd
            : FuelIgnitionCommand
            :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf1_fuelCmd;
        in cf2_airCmd
            : IntakeAirFlow :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf2_airCmd;
        in cf2_fuelCmd
            : FuelIgnitionCommand
            :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf2_fuelCmd;
        in cf3_airCmd
            : IntakeAirFlow :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf3_airCmd;
        in cf3_fuelCmd
            : FuelIgnitionCommand
            :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf3_fuelCmd;

        in cf2_active
            : Boolean :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf2_active;
        in cf3_faultActive
            : Boolean :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::cf3_faultActive;

        out final_airCmd
            : IntakeAirFlow
            :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::final_airCmd;
        out final_fuelCmd
            : FuelIgnitionCommand
            :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::final_fuelCmd;
        out modeChannelBroadcaster
            : ModeChannelData
            :>> FB_ModeArbitrationModel::SystemModeControllerAndArbiter::modeChannelBroadcaster;

        action collectInputs {
            in inCF1_Air : IntakeAirFlow;
            in inCF1_Fuel : FuelIgnitionCommand;
            in inCF2_Air : IntakeAirFlow;
            in inCF2_Fuel : FuelIgnitionCommand;
            in inCF3_Air : IntakeAirFlow;
            in inCF3_Fuel : FuelIgnitionCommand;
            in inCF2_Active : Boolean;
            in inCF3_Fault : Boolean;

            out outCF1_Air : IntakeAirFlow;
            out outCF1_Fuel : FuelIgnitionCommand;
            out outCF2_Air : IntakeAirFlow;
            out outCF2_Fuel : FuelIgnitionCommand;
            out outCF3_Air : IntakeAirFlow;
            out outCF3_Fuel : FuelIgnitionCommand;
            out outCF2_Active : Boolean;
            out outCF3_Fault : Boolean;
        }

        action evaluatePriority {
            in evalCF1_Air : IntakeAirFlow;
            in evalCF1_Fuel : FuelIgnitionCommand;
            in evalCF2_Air : IntakeAirFlow;
            in evalCF2_Fuel : FuelIgnitionCommand;
            in evalCF3_Air : IntakeAirFlow;
            in evalCF3_Fuel : FuelIgnitionCommand;
            in evalCF2_Active : Boolean;
            in evalCF3_Fault : Boolean;

            out selectedAir : IntakeAirFlow;
            out selectedFuel : FuelIgnitionCommand;
            out selectedMode : SystemOperatingMode;
            out inhibitFlag : Boolean;

            // [논리 분해 1순위] CF3 안전 감시기가 차단(Air=0)을 요구할 경우, 최고 우선순위로 페일세이프(FailSafe) 모드 전환 및 타 기능 억제(Inhibit)
            constraint Local_RouteFailSafe {
                evalCF3_Fault == true implies
                (selectedAir == evalCF3_Air and
                    selectedFuel == evalCF3_Fuel and
                    selectedMode == SystemOperatingMode::FailSafe_Mode and
                    inhibitFlag == true)
            }
            // [논리 분해 2순위] CF3는 정상이나, CF2가 긴급 저감을 요구(현재 요구량 < 정상 주행 요구량)할 경우, 긴급(Emergency) 모드 전환 및 CF1 억제
            constraint Local_RouteEmergency {
                (evalCF3_Fault == false and evalCF2_Active == true) implies
                (selectedMode == SystemOperatingMode::Emergency_Mode and
                    inhibitFlag == false and
                    ((selectedAir == evalCF1_Air and
                            evalCF1_Air.massFlow <= evalCF2_Air.massFlow) or
                        (selectedAir == evalCF2_Air and
                            evalCF2_Air.massFlow < evalCF1_Air.massFlow)) and
                    ((selectedFuel == evalCF1_Fuel and
                            evalCF1_Fuel.injectionPulseWidth <= evalCF2_Fuel.injectionPulseWidth) or
                        (selectedFuel == evalCF2_Fuel and
                            evalCF2_Fuel.injectionPulseWidth < evalCF1_Fuel.injectionPulseWidth)))
            }
            // [논리 분해 3순위] 페일세이프 및 긴급 요구가 없을 시, 기본 상태인 정상 주행(Normal) 모드를 유지하고 CF1 제어 허용
            constraint Local_RouteNormal {
                (evalCF3_Fault == false and evalCF2_Active == false) implies
                (selectedAir == evalCF1_Air and
                    selectedFuel == evalCF1_Fuel and
                    selectedMode == SystemOperatingMode::Normal_Mode and
                    inhibitFlag == false)
            }
        }

        action broadcastOutput {
            in resAir : IntakeAirFlow;
            in resFuel : FuelIgnitionCommand;
            in modeStatus : SystemOperatingMode;
            in inhibitStatus : Boolean;

            out finalOutAir : IntakeAirFlow;
            out finalOutFuel : FuelIgnitionCommand;
            out finalModeChannel : ModeChannelData;
        }

        assert constraint redefines ArbiterPriorityLogic {
            out redefines result =
                (cf3_faultActive == true implies
                    (modeChannelBroadcaster.currentMode == SystemOperatingMode::FailSafe_Mode and
                        modeChannelBroadcaster.inhibitDrivingControl == true and
                        final_airCmd == cf3_airCmd and
                        final_fuelCmd == cf3_fuelCmd)) and
                ((cf3_faultActive == false and cf2_active == true) implies
                    (modeChannelBroadcaster.currentMode == SystemOperatingMode::Emergency_Mode and
                        modeChannelBroadcaster.inhibitDrivingControl == false and
                        ((final_airCmd == cf1_airCmd and
                                cf1_airCmd.massFlow <= cf2_airCmd.massFlow) or
                            (final_airCmd == cf2_airCmd and
                                cf2_airCmd.massFlow < cf1_airCmd.massFlow)) and
                        ((final_fuelCmd == cf1_fuelCmd and
                                cf1_fuelCmd.injectionPulseWidth <=
                                cf2_fuelCmd.injectionPulseWidth) or
                            (final_fuelCmd == cf2_fuelCmd and
                                cf2_fuelCmd.injectionPulseWidth <
                                cf1_fuelCmd.injectionPulseWidth)))) and
                ((cf3_faultActive == false and cf2_active == false) implies
                    (modeChannelBroadcaster.currentMode == SystemOperatingMode::Normal_Mode and
                        modeChannelBroadcaster.inhibitDrivingControl == false and
                        final_airCmd == cf1_airCmd and
                        final_fuelCmd == cf1_fuelCmd));
        }

        bind cf1_airCmd = collectInputs.inCF1_Air;
        bind cf1_fuelCmd = collectInputs.inCF1_Fuel;
        bind cf2_airCmd = collectInputs.inCF2_Air;
        bind cf2_fuelCmd = collectInputs.inCF2_Fuel;
        bind cf3_airCmd = collectInputs.inCF3_Air;
        bind cf3_fuelCmd = collectInputs.inCF3_Fuel;

        flow collectInputs.outCF1_Air to evaluatePriority.evalCF1_Air;
        flow collectInputs.outCF1_Fuel to evaluatePriority.evalCF1_Fuel;
        flow collectInputs.outCF2_Air to evaluatePriority.evalCF2_Air;
        flow collectInputs.outCF2_Fuel to evaluatePriority.evalCF2_Fuel;
        flow collectInputs.outCF3_Air to evaluatePriority.evalCF3_Air;
        flow collectInputs.outCF3_Fuel to evaluatePriority.evalCF3_Fuel;

        flow evaluatePriority.selectedAir to broadcastOutput.resAir;
        flow evaluatePriority.selectedFuel to broadcastOutput.resFuel;
        flow evaluatePriority.selectedMode to broadcastOutput.modeStatus;
        flow evaluatePriority.inhibitFlag to broadcastOutput.inhibitStatus;

        bind broadcastOutput.finalOutAir = final_airCmd;
        bind broadcastOutput.finalOutFuel = final_fuelCmd;
        bind broadcastOutput.finalModeChannel = modeChannelBroadcaster;

        bind cf2_active = collectInputs.inCF2_Active;
        bind cf3_faultActive = collectInputs.inCF3_Fault;
        flow collectInputs.outCF2_Active to evaluatePriority.evalCF2_Active;
        flow collectInputs.outCF3_Fault to evaluatePriority.evalCF3_Fault;
    }
} // package FW_UF1_WhiteBoxModel
