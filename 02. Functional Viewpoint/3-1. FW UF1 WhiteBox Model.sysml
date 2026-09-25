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

    // ==========================================
    // 0. 화이트박스 내부 공용 데이터 타입 (Internal Items)
    // ==========================================
    item def InternalTorqueDemand {
        // 내부 논리 연산을 위해 산출된 타겟 물리 토크량
        attribute targetTorque : TorqueValue;
        attribute calculationTimestamp : TimeValue;
    }

    item def InternalCutoffSignal {
        attribute isCutoffActive : Boolean; // 제동 우선순위에 따른 강제 차단 활성화 플래그
    }

    // ==========================================
    // 1. UF1_1 수동 가속 제어 화이트박스 분해
    // ==========================================
    action def <UF1_1_WB> ManualAccelerationControl_WhiteBox :> CF1::UF1_1 {
        doc
        /* 상위 블랙박스(CF1::UF1_1)의 포트 및 제약조건을 상속받아 내부 흐름을 구현합니다. */

        // 명시적 가시성을 위해 상속받은 in/out 파라미터를 다시 선언 (bind 및 flow 연결용)
        in ignition : IgnitionState :>> CF1::UF1_1::ignition;
        in accel : AccelerationIntent :>> CF1::UF1_1::accel;
        out airCmd : IntakeAirFlow :>> CF1::UF1_1::airCmd;
        out fuelCmd : FuelIgnitionCommand :>> CF1::UF1_1::fuelCmd;

        // [Step 1: Sensing] 페달 입력 필터링 소기능
        action filterPedalInput {
            in rawAccel : AccelerationIntent;
            out validAccel : AccelerationIntent;
            attribute executionTime : Real [milli * s];

            // 노이즈 필터링 지연 시간 할당
            constraint FilterLatency {
                validAccel.latency <= 10.0 [milli * s]
            }
        }

        // [Step 2: Core Logic] 목표 토크 산출 소기능
        action calcManualTorque {
            in ignStatus : IgnitionState;
            in filteredAccel : AccelerationIntent;
            out torqueDemand : InternalTorqueDemand;
            attribute executionTime : Real [milli * s];

            // 토크 산출 알고리즘 연산은 20ms 이내에 완료되어야 함
            constraint CalcLatency {
                executionTime <= 20.0 [milli * s]
            }
        }

        // [Step 3: Actuation] 엔진 제어 명령 변환 소기능
        action genEngineCommand {
            in torqueReq : InternalTorqueDemand;
            out outAir : IntakeAirFlow;
            out outFuel : FuelIgnitionCommand;
            attribute executionTime : Real [milli * s];

            // 액추에이터 제어 명령 변환은 20ms 이내에 완료되어야 함
            constraint CmdGenLatency {
                executionTime <= 20.0 [milli * s]
            }
        }

        // ★ [제약 할당 (Constraint Allocation)] ★
        // 부모의 전체 레이턴시 요구사항(50ms)을 내부 소기능들이 나누어 갖도록 예산(Budget) 할당
        assert constraint redefines PerformanceConstraints {
            out redefines result =
                filterPedalInput.executionTime +
                calcManualTorque.executionTime +
                genEngineCommand.executionTime <=
                50.0 [milli * s];
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
    action def <UF1_2_WB> CruiseControlDriving_WhiteBox :> CF1::UF1_2 {
        in ccCmd : CruiseControlCommand :>> CF1::UF1_2::ccCmd;
        in combustionSystemStatus : CombustionSystemStatus :>> CF1::UF1_2::combustionSystemStatus;
        out airCmd : IntakeAirFlow :>> CF1::UF1_2::airCmd;
        out fuelCmd : FuelIgnitionCommand :>> CF1::UF1_2::fuelCmd;

        // [Step 1: Sensing] 크루즈 명령 상태 확인 및 필터링
        action processCruiseCommand {
            in rawCcCmd : CruiseControlCommand;
            out validCcCmd : CruiseControlCommand;
        }

        // [Step 2: Core Logic] PID 기반 크루즈 목표 토크 연산
        action calcCruiseTorque {
            in validCmd : CruiseControlCommand;
            in engineStatus : CombustionSystemStatus; // 정상 상태 오차 피드백 수신
            out torqueDemand : InternalTorqueDemand;

            // 상위 정상 상태 오차 제약(steadyStateErrorLimit)을 만족시키기 위한 연산 조건
            constraint PidErrorLimit {
                engineStatus.steadyStateError <= 2.0
            }
        }

        // [Step 3: Actuation] 엔진 제어 명령 변환 (수동 가속과 동일한 로직 구조 활용)
        action genEngineCommand {
            in torqueReq : InternalTorqueDemand;
            out outAir : IntakeAirFlow;
            out outFuel : FuelIgnitionCommand;
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 (Internal Flows & Bindings) ---

        // 1. 외부 입력 연결
        bind ccCmd = processCruiseCommand.rawCcCmd;
        bind combustionSystemStatus = calcCruiseTorque.engineStatus;

        // 2. 소기능 간 파이프라인 연결
        flow processCruiseCommand.validCcCmd to calcCruiseTorque.validCmd;
        flow calcCruiseTorque.torqueDemand to genEngineCommand.torqueReq;

        // 3. 최종 출력 바인딩
        bind genEngineCommand.outAir = airCmd;
        bind genEngineCommand.outFuel = fuelCmd;
    }

    // ==========================================
    // 3. UF1_3 제동 우선 오버라이드 화이트박스 분해
    // ==========================================
    action def <UF1_3_WB> BrakeOverrideIntervention_WhiteBox :> CF1::UF1_3 {
        in brakeCmd : BrakePedalPosition :>> CF1::UF1_3::brakeCmd;
        out airCmd : IntakeAirFlow :>> CF1::UF1_3::airCmd;
        out fuelCmd : FuelIgnitionCommand :>> CF1::UF1_3::fuelCmd;

        // [Step 1: Sensing] 브레이크 압력 감지
        action detectBrake {
            in rawBrake : BrakePedalPosition;
            out cutoffTrigger : InternalCutoffSignal;

            // 제약: 브레이크 압력이 0초과일 때 차단 플래그 생성
            constraint TriggerCondition {
                rawBrake.pressure > 0.0 [Pa] implies cutoffTrigger.isCutoffActive == true
            }
        }

        // [Step 2 & 3: Logic & Actuation] 차단 신호 기반 Zero-Torque 강제 생성
        action arbitrateOverride {
            in trigger : InternalCutoffSignal;
            out zeroAirOut : IntakeAirFlow;
            out zeroFuelOut : FuelIgnitionCommand;

            // 제약: 블랙박스의 SafeStateConstraints 상세 로직 구현
            constraint ZeroTorqueOutput {
                trigger.isCutoffActive == true implies
                (zeroAirOut.massFlow == 0.0 [kg / s] and zeroFuelOut.injectionPulseWidth == 0.0 [s])
            }
        }

        // --- 내부 데이터 흐름 및 포트 바인딩 ---
        bind brakeCmd = detectBrake.rawBrake;
        flow detectBrake.cutoffTrigger to arbitrateOverride.trigger;
        bind arbitrateOverride.zeroAirOut = airCmd;
        bind arbitrateOverride.zeroFuelOut = fuelCmd;
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

            out outCF1_Air : IntakeAirFlow;
            out outCF1_Fuel : FuelIgnitionCommand;
            out outCF2_Air : IntakeAirFlow;
            out outCF2_Fuel : FuelIgnitionCommand;
            out outCF3_Air : IntakeAirFlow;
            out outCF3_Fuel : FuelIgnitionCommand;
        }

        action evaluatePriority {
            in evalCF1_Air : IntakeAirFlow;
            in evalCF1_Fuel : FuelIgnitionCommand;
            in evalCF2_Air : IntakeAirFlow;
            in evalCF2_Fuel : FuelIgnitionCommand;
            in evalCF3_Air : IntakeAirFlow;
            in evalCF3_Fuel : FuelIgnitionCommand;

            out selectedAir : IntakeAirFlow;
            out selectedFuel : FuelIgnitionCommand;
            out selectedMode : SystemOperatingMode;
            out inhibitFlag : Boolean;

            // ★ [로컬 제약] Arbiter 내부의 라우팅(Routing) 판단 기준 명세
            constraint FailSafePriorityLogic {
                evalCF3_Air.massFlow <= 0.0 [kg / s] implies
                (selectedAir == evalCF3_Air and
                    selectedFuel == evalCF3_Fuel and
                    selectedMode == SystemOperatingMode::FailSafe_Mode and
                    inhibitFlag == true)
            }
            constraint EmergencyPriorityLogic {
                (evalCF3_Air.massFlow > 0.0 [kg / s] and
                    evalCF2_Air.massFlow < evalCF1_Air.massFlow) implies
                (selectedAir == evalCF2_Air and
                    selectedFuel == evalCF2_Fuel and
                    selectedMode == SystemOperatingMode::Emergency_Mode and
                    inhibitFlag == true)
            }
            constraint NormalPriorityLogic {
                selectedAir == evalCF1_Air and
                selectedFuel == evalCF1_Fuel and
                selectedMode == SystemOperatingMode::Normal_Mode and
                inhibitFlag == false
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
    }
} // package FW_UF1_WhiteBoxModel
