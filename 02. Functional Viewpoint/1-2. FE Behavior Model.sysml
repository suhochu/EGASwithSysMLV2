package FE_BehaviorModel {
    private import RV_InterfaceModel::*;
    private import FB_FunctionalBlackBoxModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;
    private import RV_BehavioralModel::*;

    state rvEgasState : RV_BehavioralModel::EgasBehavior;

    // Transition의 경우 부모 상태(rvEgasState.drivingControlRegion)의 트랜지션을 그대로 상속 받아야 하는데, Syside Tool의 이슈로 아직 처리 못함.
    // Tool 이 업데이트 되면 별도 작업 필요.

    // ==========================================
    // 1. DrivingTorqueBehavior
    // ==========================================
    state def DrivingTorqueBehavior :> DrivingControlRegion {
        doc
        /* 주행 토크 제어 통합 상태 머신 */

        dependency self to CF1::UF1_1, CF1::UF1_2, CF1::UF1_3;

        // 다른 패키지의 서브타입(ExtendedDrivingTorqueBehavior 등)에서도 참조할 수 있도록 protected로 선언
        in In_Ignition : IgnitionState;
        in In_CombustionSystemStatus : CombustionSystemStatus;

        out Out_AirCmd : IntakeAirFlow;
        out Out_FuelCmd : FuelIgnitionCommand;

        // 트랜지션에서 받은 페이로드를 저장해두고 UF에 넘겨줄 내부 Context 변수 선언
        protected item currentAccel : AccelerationIntent;
        protected item currentCcCmd : CruiseControlCommand;
        protected item currentBrake : BrakePedalPosition;

        first start then standby;

        // ==========================================
        // 상태 1: 공회전 (Standby)
        // ==========================================
        state redefines standby :> rvEgasState.drivingControlRegion.standby {
            entry action {
                // 시동이 켜져 있으나 조작이 없을 때의 물리적 공회전 기본값 출력
                assign Out_AirCmd := new IntakeAirFlow(massFlow=0.05 [kg / s]);
                assign Out_FuelCmd := new FuelIgnitionCommand(injectionPulseWidth=0.002 [s]);
            }
        }

        // Standby -> Active (전원이 On이고, 가속 페달이 밟히거나 크루즈 목표 속도가 설정되었을 때)
        transition standbyToActive
            first standby
            accept accel : AccelerationIntent
            if In_Ignition.status == IgnitionStatusEnum::On and accel.pedalDisplacement > 0.0 [mm]
                do action { assign currentAccel := accel; }
            then active {
            dependency self to t_standbyToActive;
        }

        // ==========================================
        // 상태 2: 통합 가속 제어 (Active) - 계층형 복합 상태
        // ==========================================
        state redefines active :> rvEgasState.drivingControlRegion.active {
            // 수동 가속(UF1.1)과 크루즈 컨트롤(UF1.2)을 캡슐화한 복합 상태. 내부에서 목표 속도 설정 여부에 따라 수동과 자동 모드를 스위칭합니다.
            first start then manualDriving;

            // 서브 상태 2-1: 수동 주행 (UF1.1)
            state redefines manualDriving :> rvEgasState.drivingControlRegion.active.manualDriving {
                do action manualAccel : CF1::UF1_1 {
                    assign ignition := In_Ignition;
                    assign accel := currentAccel;
                    bind airCmd = Out_AirCmd;
                    bind fuelCmd = Out_FuelCmd;
                }
            }

            // 서브 상태 2-2: 크루즈 활성화 (UF1.2)
            state redefines cruiseDriving :> rvEgasState.drivingControlRegion.active.cruiseDriving {
                do action cruisePidControl : CF1::UF1_2 {
                    assign ccCmd := currentCcCmd;
                    assign combustionSystemStatus := In_CombustionSystemStatus;
                    bind airCmd = Out_AirCmd;
                    bind fuelCmd = Out_FuelCmd;
                }
            }

            // [내부 트랜지션] 수동 주행 -> 크루즈 활성화
            transition manualToCruise
                first manualDriving
                accept ccCmd : CruiseControlCommand
                if ccCmd.setSpeed > 0.0 [km / h] do action { assign currentCcCmd := ccCmd; }
                then cruiseDriving {
                dependency self to t_manualToCruise;
            }

            // [내부 트랜지션] 크루즈 활성화 -> 수동 주행 (Cancel)
            transition cruiseToManual_Cancel
                first cruiseDriving
                accept accel : AccelerationIntent
                if accel.pedalDisplacement > 0.0 [mm] do action { assign currentAccel := accel; }
                then manualDriving {
                dependency self to t_cruiseToManual;
            }
        }

        // Accelerating -> Standby : 브레이크 조작 없이 단순히 가속/크루즈를 멈춘 경우 Standby로 복귀
        transition activeToStandby
            first active
            accept accel : AccelerationIntent
            if accel.pedalDisplacement == 0.0 [mm] and currentCcCmd.setSpeed == 0.0 [km / h]
                then standby {
            dependency self to t_activeToStandby;
        }

        // Active -> BrakeOverridden : 가속 또는 크루즈 중 언제라도 브레이크 입력이 발생하면 Active 복합 상태를 즉시 탈출
        transition activeToOverride
            first active
            accept brake : BrakePedalPosition
            if In_Ignition.status == IgnitionStatusEnum::On and brake.pressure > 0.0 [Pa]
                do action { assign currentBrake := brake; }
            then brakeOverridden {
            dependency self to t_activeToBrake;
        }

        // ==========================================
        // 상태 3: 제동 오버라이드 (BrakeOverridden) - UF1.3
        // ==========================================
        state redefines brakeOverridden :> rvEgasState.drivingControlRegion.brakeOverridden {
            // 브레이크 밟힘 감지 시 안전 최우선 차단 로직(UF1_3) 실행
            do action brakeOverride : CF1::UF1_3 {
                assign brakeCmd := currentBrake;
                bind airCmd = Out_AirCmd;
                bind fuelCmd = Out_FuelCmd;
            }
        }

        transition overrideToWait
            first brakeOverridden
            accept brake : BrakePedalPosition
            if brake.pressure == 0.0 [Pa] and currentAccel.pedalDisplacement > 0.0 [mm]
                then waitForPedalRelease {
            dependency self to t_brakeToWait;
        }

        transition overrideToStandby
            first brakeOverridden
            accept brake : BrakePedalPosition
            if brake.pressure == 0.0 [Pa] and currentAccel.pedalDisplacement == 0.0 [mm]
                then standby {
            dependency self to t_brakeToStandby;
        }

        // ==========================================
        // 상태 4: 래칭 대기 (WaitForPedalRelease)
        // ==========================================
        state
            redefines waitForPedalRelease :> rvEgasState.drivingControlRegion.waitForPedalRelease {
            entry action {
                assign Out_AirCmd.massFlow := 0.0 [kg / s];
                assign Out_FuelCmd.injectionPulseWidth := 0.0 [s];
            }
        }

        transition waitToStandby
            first waitForPedalRelease
            accept accel : AccelerationIntent
            if accel.pedalDisplacement == 0.0 [mm] then standby {
            dependency self to t_waitToStandby;
        }
    }

    // ==========================================
    // 2. EmergencyInterventionBehavior
    // ==========================================
    state def EmergencyInterventionBehavior :> EmergencyInterventionRegion {
        doc
        /* 외부 능동안전 제어기(ESP/TCU) 긴급 토크 저감 요구 수용 상태 머신 */
        dependency self to CF2::UF2_1, CF2::UF2_2, CF2::UF2_3;

        in In_AirFeedback : IntakeAirFlow; // 고착 여부 판단을 위한 실제 센서 피드백
        // in In_TorqueInterventionRequest : TorqueInterventionRequest;

        out Out_AirCmd : IntakeAirFlow;
        out Out_FuelCmd : FuelIgnitionCommand;

        // 고착 판단을 위해 진입 시점의 공기량을 저장하는 로컬 프로퍼티
        private attribute capturedInitialAirMass : MassFlowValue;
        private item currentTorqueReq : TorqueInterventionRequest;

        first start then emergencyStandby;

        // ==========================================
        // 상태 1: 대기 (EmergencyStandby)
        // ==========================================
        state redefines emergencyStandby; // 긴급 개입 요구가 없는 평시 상태

        // Standby -> InterventionActive (토크 저감 요구 발생 시)
        transition triggerIntervention
            first emergencyStandby
            accept req : TorqueInterventionRequest
            if req.requestedTorqueDelta < 0.0 [N * m] do action { assign currentTorqueReq := req; }
            then InterventionActive {
            dependency self to t_triggerIntervention;
        }

        // ==========================================
        // 상태 2: 긴급 개입 활성화 (InterventionActive) - 긴급 제어 로직을 캡슐화한 복합 상태
        // ==========================================
        state
            redefines InterventionActive
            :> rvEgasState.emergencyInterventionRegion.InterventionActive {
            // 진입 시 지연(Latency) 상황에 따라 초기 상태 분기
            first start then initialCheck;

            state redefines initialCheck; // 분기를 위한 임시 상태(Pseudo-state 역할)

            transition checkToNormal
                first initialCheck
                if currentTorqueReq.latency <= 15.0 [milli * s] then parallelReduction {
                dependency self to t_checkToNormal;
            }

            transition checkToDelay
                first initialCheck
                if currentTorqueReq.latency > 15.0 [milli * s] then delayCompensating {
                dependency self to t_checkToDelay;
            }

            // -----------------------------------------
            // 서브 상태 2-1: 정상 토크 저감 (UF2.1)
            // -----------------------------------------
            state
                redefines parallelReduction
                :> rvEgasState.emergencyInterventionRegion.InterventionActive.parallelReduction {
                entry action {
                    // 고착 판단(Timer)을 위해 진입 시점의 공기량을 캡처
                    assign capturedInitialAirMass := In_AirFeedback.massFlow;
                }
                do action normalReduct : CF2::UF2_1 {
                    assign torqueIntervention := currentTorqueReq;
                    bind airIntake = Out_AirCmd;
                    bind fuelCmd = Out_FuelCmd;
                }
            }

            // -----------------------------------------
            // 서브 상태 2-2: 통신 지연 보상 (UF2.2)
            // -----------------------------------------
            state
                redefines delayCompensating
                :> rvEgasState.emergencyInterventionRegion.InterventionActive.delayCompensating {
                do action delayComp : CF2::UF2_2 {
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
                do action stuckCut : CF2::UF2_3 {
                    assign airIntakeFeedback := In_AirFeedback;
                    bind fuelCmd = Out_FuelCmd;
                }
            }

            // [내부 트랜지션] 정상 저감 <-> 지연 보상 스위칭
            transition normalToDelay
                first parallelReduction
                accept req : TorqueInterventionRequest
                if req.latency > 15.0 [milli * s] do action { assign currentTorqueReq := req; }
                then delayCompensating {
                dependency self to t_normalToDelay;
            }

            transition delayToNormal
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.latency <= 15.0 [milli * s] do action { assign currentTorqueReq := req; }
                then parallelReduction {
                dependency self to t_delayToNormal;
            }

            // [내부 트랜지션] 고착 감지 전환 (Time Event Trigger)
            transition stuckTimeoutTrigger
                first parallelReduction
                accept after 0.01 [s] // 10ms 경과 후
                if In_AirFeedback.massFlow >= capturedInitialAirMass // 공기량이 줄지 않았을 경우
                    then actuatorStuckFallback {
                dependency self to t_stuckDetect;
            }

            transition finishNormalIntervention
                first parallelReduction
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta == 0.0 [N * m] then initialCheck {
                dependency self to t_finishNormal;
            }

            transition finishDelayIntervention
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta == 0.0 [N * m] then initialCheck {
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
         * 평상시 실시간 보정(UF3.1)을 수행하며, 치명적 결함 감지 시 
         * 즉각 단방향 페일세이프(UF3.2) 상태로 래칭(Latching)되어 물리적인 시스템 차단을 수행합니다.
         */

        dependency self to CF3::UF3_1, CF3::UF3_2;

        in In_Sensor : EngineSensorData;
        in In_CombustionStatus : CombustionSystemStatus;

        out Out_AirCmd : IntakeAirFlow;
        out Out_FuelCmd : FuelIgnitionCommand;
        out Out_Dashboard : DashboardWarning; // 클러스터 경고등 출력 추가

        private item currentSensorData : EngineSensorData;

        first start then normalMonitoring;

        // ==========================================
        // 상태 1: 정상 상태 감시 및 보정 (NormalMonitoring)
        // ==========================================
        state redefines normalMonitoring :> rvEgasState.safetyMonitoringRegion.normalMonitoring {
            // 하드웨어의 미세한 마찰 및 지연을 지속적으로 보정하여 엔진 실화(Misfire)를 방지하는 상태

            do action delayComp : CF3::UF3_1 {
                assign sensor := In_Sensor;
                assign combustionStatus := In_CombustionStatus;
                bind airIntake = Out_AirCmd;
                bind fuelCmd = Out_FuelCmd;
            }
        }

        // NormalMonitoring -> CriticalFault (치명적 센서 결함 및 온도 한계치 초과 시)
        transition faultDetection
            first normalMonitoring
            accept sensorData : EngineSensorData
            if sensorData.coolantTemp > 120.0 ['°']
                do action { assign currentSensorData := sensorData; }
            then criticalFault {
            dependency self to faultDetection;
        }

        // ==========================================
        // 상태 2: 치명적 결함 페일세이프 (CriticalFault) - UF3.2
        // ==========================================
        state redefines criticalFault :> rvEgasState.safetyMonitoringRegion.criticalFault {
            // 엔진 파손 및 급발진을 막기 위한 비가역적(Irreversible) 하드 차단 상태.
            // 물리적 재시동이나 정비가 이루어지기 전까지 이 안전 상태를 강제로 유지합니다.

            do action fatalFailSafe : CF3::UF3_2 {
                assign sensor := currentSensorData;
                bind airIntake = Out_AirCmd;
                bind fuelCmd = Out_FuelCmd;
                bind dashboard = Out_Dashboard;
            }
        }

        // [설계 의도] CriticalFault -> NormalMonitoring 으로 복귀하는 트랜지션은 생성하지 않음.
        // 이는 중대한 하드웨어 에러 발생 후 시스템이 스스로 제어 권한을 회복하는 것을 방지하는 방어적 모델링입니다.
    }

    // ==========================================
    // 4. CalibrationSupportBehavior
    // ==========================================
    state def CalibrationSupportBehavior :> CalibrationHandling {
        doc
        /* 외부 엔지니어링 툴(XCP/CCP)의 접근 세션을 제어하는 오프라인 캘리브레이션 상태 머신.
         * 요청-응답(Request-Response) 패턴을 기반으로 유효성 검사, 무결성 검증, 
         * 그리고 비정상 접근 시의 거절/롤백 절차를 순차적으로 통제합니다.
         */

        // in In_CalReq : CalibrationRequest;
        out Out_CalRes : CalibrationStatus;

        private item currentCalReq : CalibrationRequest;

        first start then cal_Idle;

        // ==========================================
        // 상태 1: 대기 (Cal_Idle)
        // ==========================================
        state
            redefines cal_Idle
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.calibrationHandling.cal_Idle; // 외부 캘리브레이션 툴의 요청을 기다리는 기본 상태

        // Idle -> Authorizing (정상적인 메모리 주소 접근 시도) , 실제 구현에서는 In_CalReq가 활성화된 이벤트 트리거도 함께 평가됨
        transition validRequest
            first cal_Idle
            accept calReq : CalibrationRequest
            if calReq.targetMemoryAddress > 0 do action { assign currentCalReq := calReq; }
            then authorizing {
            dependency self to t_reqAuth;
        }

        // Idle -> RejectingAndRollback (비정상적인 메모리 주소 접근 시도)
        transition invalidRequest
            first cal_Idle
            accept calReq : CalibrationRequest
            if calReq.targetMemoryAddress <= 0 do action { assign currentCalReq := calReq; }
            then rejectingAndRollback {
            dependency self to t_invalidReq;
        }

        // ==========================================
        // 상태 2: 메모리 접근 인가 (Authorizing) - UF4.1
        // ==========================================
        state
            redefines authorizing
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.calibrationHandling
                    .authorizing {
            // 유효한 접근 요청에 대해 세션을 열고 정상 코드를 반환
            do action authAccess : CF4::UF4_1 {
                assign calibration_Req := currentCalReq;
                bind calibration_Res = Out_CalRes;
            }
        }

        // 인가 결과를 평가하여 성공/실패 경로 분기
        transition authSuccess
            first authorizing
            accept status : CalibrationStatus
            if status.responseCode == 200 then verifying {
            dependency self to t_authToVerify;
        }

        transition authFail
            first authorizing
            accept status : CalibrationStatus
            if status.responseCode != 200 then rejectingAndRollback {
            dependency self to t_authFail;
        }

        // ==========================================
        // 상태 3: 데이터 무결성 검증 (Verifying) - UF4.2
        // ==========================================
        state
            redefines verifying
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.calibrationHandling.verifying {
            // 튜닝 파라미터 기록 후, 체크섬 등을 통해 메모리 무결성을 검증
            do action verifyData : CF4::UF4_2 {
                assign calibration_Req := currentCalReq;
                bind calibration_Res = Out_CalRes;
            }
        }

        // Verifying -> Idle (검증 성공: 유효한 체크섬 반환 후 튜닝 확정)
        transition verifySuccess
            first verifying
            accept status : CalibrationStatus
            if status.verifiedChecksum > 0 then cal_Idle {
            dependency self to t_verifySuccess;
        }

        // Verifying -> RejectingAndRollback (검증 실패: 체크섬 오류 시 롤백)
        transition verifyFail
            first verifying
            accept status : CalibrationStatus
            if status.verifiedChecksum <= 0 then rejectingAndRollback {
            dependency self to t_verifyFail;
        }

        // ==========================================
        // 상태 4: 비유효 접근 거절 및 롤백 (RejectingAndRollback) - UF4.3
        // ==========================================
        state
            redefines rejectingAndRollback
            :> rvEgasState.monitoringAndServiceRegion.monitoringActive.calibrationHandling
                    .rejectingAndRollback {
            // 인가 거절 또는 무결성 검증 실패 시, 에러(200 이외의 코드)를 반환하고 메모리를 튜닝 이전의 안전한 상태로 롤백(Rollback)하는 상태
            do action rejectAccess : CF4::UF4_3 {
                assign calibration_Req := currentCalReq;
                bind calibration_Res = Out_CalRes;
            }
        }

        // 롤백/거절 처리 완료 후 다음 세션을 위해 다시 대기 상태로 복귀
        transition rejectToIdle first rejectingAndRollback then cal_Idle {
            dependency self to t_rejectToIdle;
        }
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

        // in In_DiagReq : DiagnosticRequest;
        in In_SensorPort : EngineSensorData;
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
            if diagReq.serviceId == 1 do action { assign currentDiagReq := diagReq; }
            then ReadingDTC {
            dependency self to t_reqDTC;
        }

        transition reqZeroPoint
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if diagReq.serviceId == 2 do action { assign currentDiagReq := diagReq; }
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
            do action readDTC : CF5::UF5_1 {
                assign diag_Req := currentDiagReq;
                assign sensorPort := In_SensorPort;
                bind diag_Res = Out_DiagRes;
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
            do action zeroPointCal : CF5::UF5_2 {
                assign diag_Req := currentDiagReq;
                bind diag_Res = Out_DiagRes;
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
            do action rejectDiag : CF5::UF5_3 {
                assign diag_Req := currentDiagReq;
                bind diag_Res = Out_DiagRes;
            }
        }

        // 거절 처리 완료 후 다음 요청을 위해 대기 상태로 복귀
        transition rejectToIdle first RejectingRequest then Diag_Idle {
            dependency self to t_rejectToIdle;
        }
    }
} // package FE_BehaviorModel
