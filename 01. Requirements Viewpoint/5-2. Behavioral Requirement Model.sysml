package RV_BehavioralModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*; // [N * m], [Pa], [mm], [km / h] (S3에서 추가)
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*;
    private import RV_OperationalModel::*;
    private import SafeStateLogic::*;
    private import ThrottleStuckLogic::*;
    private import TimingConceptsAndLimits::*;

    @MetaInformation { version = "v0.8"; }

    // ==========================================
    // 1. 주행 토크 제어 영역 (UC1)
    // ==========================================
    state def DrivingControlRegion {
        in egas : EgasSystem; // [M5] 가드가 읽는 EGAS 경계 값 (FE의 In_* 입력과 동치)

        first start then powerOff;

        state powerOff;
        state standby;

        state active {
            first start then manualDriving;
            do action compensate : EgasOperationalRequirements_UC3::ExecuteDelayCompensation; // S8
            state manualDriving {
                do action manageArbitration
                    : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            }
            state cruiseDriving {
                do action manageArbitration
                    : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            }

            // 가속 페달 → 크루즈 일시 중단하고 수동 주행 (SYSR-23: 가속 페달 > 크루즈)
            transition t_cruiseToManual
                first cruiseDriving
                accept AccelerationIntent
                if egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm] then manualDriving;
            // 수동 주행에서 페달 해제 시에만 대기
            transition t_manualToStandby
                first manualDriving
                accept AccelerationIntent
                if egas.accelPort.accelIntent.pedalDisplacement == 0.0 [mm] then standby;
            // 레버 요청: Set(재설정) / Cancel / Off (서로 다른 request 값으로 배타)
            transition t_cruiseReSet
                first cruiseDriving
                accept CruiseControlCommand
                if (
                    egas.ccPort.ccCmd.request == CruiseControlRequestEnum::Set and
                    egas.ccPort.ccCmd.setSpeed > 0.0 [km / h]
                )
                    then cruiseDriving;
            transition t_cruiseCancel
                first cruiseDriving
                accept CruiseControlCommand
                if egas.ccPort.ccCmd.request == CruiseControlRequestEnum::Cancel then standby;
            transition t_cruiseOff
                first cruiseDriving
                accept CruiseControlCommand
                if egas.ccPort.ccCmd.request == CruiseControlRequestEnum::Off then standby;
        }

        state brakeOverridden {
            do action overrideBrake : EgasOperationalRequirements_UC1::OverrideBrakeIntervention;
        }
        state waitForPedalRelease;

        // ----- 대기에서 진입 -----
        // 가속 이벤트: 페달 > 0 에서 제동 오버라이드 트리거 여부로 배타 (S6)
        transition t_standbyToActive
            first standby
            accept AccelerationIntent
            if (
                egas.ignitionPort.ignitionStatus.status == IgnitionStatusEnum::On and
                egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm] and
                not IsBrakeOverrideTriggered(
                    egas.accelPort.accelIntent.pedalDisplacement,
                    egas.ecu.ccState,
                    egas.brakePort.brakeInput.pressure
                )
            )
                then active;
        transition t_standbyToBrake
            first standby
            accept AccelerationIntent
            if (
                egas.ignitionPort.ignitionStatus.status == IgnitionStatusEnum::On and
                egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm] and
                IsBrakeOverrideTriggered(
                    egas.accelPort.accelIntent.pedalDisplacement,
                    egas.ecu.ccState,
                    egas.brakePort.brakeInput.pressure
                )
            )
                then brakeOverridden;
        // 크루즈 요청 이벤트: Set / Resume (S9, 페달과 제동이 없을 때만)
        transition t_standbyToCruiseSet
            first standby
            accept CruiseControlCommand
            if (
                egas.ignitionPort.ignitionStatus.status == IgnitionStatusEnum::On and
                egas.ccPort.ccCmd.request == CruiseControlRequestEnum::Set and
                egas.ccPort.ccCmd.setSpeed > 0.0 [km / h] and
                egas.accelPort.accelIntent.pedalDisplacement == 0.0 [mm] and
                egas.brakePort.brakeInput.pressure == 0.0 [Pa]
            )
                then active.cruiseDriving;
        transition t_standbyToCruiseResume
            first standby
            accept CruiseControlCommand
            if (
                egas.ignitionPort.ignitionStatus.status == IgnitionStatusEnum::On and
                egas.ccPort.ccCmd.request == CruiseControlRequestEnum::Resume and
                egas.ecu.ccSetSpeed > 0.0 [km / h] and
                egas.accelPort.accelIntent.pedalDisplacement == 0.0 [mm] and
                egas.brakePort.brakeInput.pressure == 0.0 [Pa]
            )
                then active.cruiseDriving;

        // ----- 오버라이드 진입과 해제 (S5, S6) -----
        transition t_activeToBrake
            first active
            accept BrakePedalPosition
            if (
                egas.ignitionPort.ignitionStatus.status == IgnitionStatusEnum::On and
                IsBrakeOverrideTriggered(
                    egas.accelPort.accelIntent.pedalDisplacement,
                    egas.ecu.ccState,
                    egas.brakePort.brakeInput.pressure
                )
            )
                then brakeOverridden;
        // 제동 해제 시 가속 페달의 현재 상태로 분기 (배타: 페달 > 0 / == 0)
        transition t_brakeToWait
            first brakeOverridden
            accept BrakePedalPosition
            if (
                egas.brakePort.brakeInput.pressure == 0.0 [Pa] and
                egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm]
            )
                then waitForPedalRelease;
        transition t_brakeToStandby
            first brakeOverridden
            accept BrakePedalPosition
            if (
                egas.brakePort.brakeInput.pressure == 0.0 [Pa] and
                egas.accelPort.accelIntent.pedalDisplacement == 0.0 [mm]
            )
                then standby;
        transition t_waitToStandby
            first waitForPedalRelease
            accept AccelerationIntent
            if egas.accelPort.accelIntent.pedalDisplacement == 0.0 [mm] then standby;

        // ----- 점화 (값 조건 추가) -----
        transition t_powerOn
            first powerOff
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::On then standby;
        transition t_powerOffStandby
            first standby
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff;
        transition t_powerOffActive
            first active
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff;
        transition t_powerOffOverride
            first brakeOverridden
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff;
        transition t_powerOffWait
            first waitForPedalRelease
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then powerOff;
    }

    // ==========================================
    // 2. 긴급 개입 제어 영역 (UC2)
    // ==========================================
    state def EmergencyInterventionRegion {
        in egas : EgasSystem; // [M5]

        first start then emergencyStandby;
        state emergencyStandby;

        state InterventionActive {
            first start then initialCheck;
            state initialCheck;

            state parallelReduction {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;

                // S4: 스로틀 추종 감시 (디바운스)
                first start then tracking;
                state tracking;
                state stuckSuspected;

                transition t_trackingLost
                    first tracking
                    accept ThrottlePositionFeedback
                    if (
                        egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] and
                        IsThrottleDeviated(
                            egas.throttle.positionCommand.openingPercentage,
                            egas.throttle.positionFeedback.openingPercentage,
                            stuckDeviationLimit
                        )
                    )
                        then stuckSuspected;
                transition t_trackingRecovered
                    first stuckSuspected
                    accept ThrottlePositionFeedback
                    if (
                        not IsThrottleDeviated(
                            egas.throttle.positionCommand.openingPercentage,
                            egas.throttle.positionFeedback.openingPercentage,
                            stuckDeviationLimit
                        )
                    )
                        then tracking;
                transition t_stuckDetect
                    first stuckSuspected accept after stuckConfirmTime then actuatorStuckFallback;
            }
            state delayCompensating {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            }
            // [래치] 해제 요청으로 나가지 않는다. 점화 OFF(t_ignitionOffReset)로만 해제 (S3)
            state actuatorStuckFallback {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            }

            // 진입 분기 (배타: messageAge <= / > commDelayThreshold, M2)
            transition t_checkToNormal
                first initialCheck
                if egas.torqueInterventionPort.torqueReq.messageAge <= commDelayThreshold
                then parallelReduction;
            transition t_checkToDelay
                first initialCheck
                if egas.torqueInterventionPort.torqueReq.messageAge > commDelayThreshold
                then delayCompensating;

            // 요청 이벤트: 개입 중(delta < 0)이면 정상/지연 전환, 해제(delta >= 0)이면 대기 (S3, 배타)
            transition t_normalToDelay
                first parallelReduction
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0.0 [N * m] and req.messageAge > commDelayThreshold
                    then delayCompensating;
            transition t_delayToNormal
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0.0 [N * m] and req.messageAge <= commDelayThreshold
                    then parallelReduction;
            transition t_finishNormal
                first parallelReduction
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m] then emergencyStandby;
            transition t_finishDelay
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m] then emergencyStandby;
        }

        transition t_triggerIntervention
            first emergencyStandby
            accept req : TorqueInterventionRequest
            if req.requestedTorqueDelta < 0.0 [N * m] then InterventionActive;
        transition t_ignitionOffReset
            first InterventionActive
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then emergencyStandby;
    }

    // ==========================================
    // 3. 상시 안전 감시 영역 (UC3) - S7, S8 반영
    // ==========================================
    state def SafetyMonitoringRegion {
        first start then normalMonitoring;
        state normalMonitoring; // [S8] 감시만 (보정은 주행 경로의 후처리로 이동)
        state pedalFaultSuspected;
        state throttleFaultSuspected;
        state overheatSuspected;
        // [래치] 점화 OFF(t_safetyIgnitionOffReset)로만 해제
        state criticalFault {
            do action executeFailSafe : EgasOperationalRequirements_UC3::ExecuteEmergencyFailSafe;
        }

        // 관측: 이벤트 종류가 서로 달라 배타. 값 조건은 SYSR-02/06, SHR-09의 판정식과 같다
        transition t_pedalObserved
            first normalMonitoring
            accept pos : AccelerationPedalPosition
            if IsChannelDeviated(pos.pvs1Percentage, pos.pvs2Percentage, redundancyDeviationLimit)
                then pedalFaultSuspected;
        transition t_throttleObserved
            first normalMonitoring
            accept fb : ThrottlePositionFeedback
            if IsChannelDeviated(fb.tps1Percentage, fb.tps2Percentage, redundancyDeviationLimit)
                then throttleFaultSuspected;
        transition t_overheatObserved
            first // 구 t_faultDetection (값 조건 없이 전이하던 것)
                normalMonitoring
            accept sensor : EngineSensorData
            if IsOverheated(sensor.coolantTemp, coolantOverheatLimit) then overheatSuspected;

        // 회복
        transition t_pedalRecovered
            first pedalFaultSuspected
            accept pos : AccelerationPedalPosition
            if (
                not IsChannelDeviated(
                    pos.pvs1Percentage,
                    pos.pvs2Percentage,
                    redundancyDeviationLimit
                )
            )
                then normalMonitoring;
        transition t_throttleRecovered
            first throttleFaultSuspected
            accept fb : ThrottlePositionFeedback
            if not IsChannelDeviated(fb.tps1Percentage, fb.tps2Percentage, redundancyDeviationLimit)
                then normalMonitoring;
        transition t_overheatRecovered
            first overheatSuspected
            accept sensor : EngineSensorData
            if not IsOverheated(sensor.coolantTemp, coolantOverheatLimit) then normalMonitoring;

        // 확정 (타이머)
        transition t_pedalConfirm
            first pedalFaultSuspected accept after sensorFaultConfirmTime then criticalFault;
        transition t_throttleConfirm
            first throttleFaultSuspected accept after sensorFaultConfirmTime then criticalFault;
        transition t_overheatConfirm
            first overheatSuspected accept after overheatConfirmTime then criticalFault;

        // 점화 OFF 초기화
        transition t_safetyIgnitionOffReset
            first criticalFault
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring;
        transition t_pedalIgnitionOff
            first pedalFaultSuspected
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring;
        transition t_throttleIgnitionOff
            first throttleFaultSuspected
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring;
        transition t_overheatIgnitionOff
            first overheatSuspected
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then normalMonitoring;
    }

    // ==========================================
    // 4. 캘리브레이션 영역 (UC4)
    // ==========================================
    state def CalibrationHandling {
        first start then cal_Idle;
        state cal_Idle;
        state authorizing {
            do action authorize : EgasOperationalRequirements_UC4::AuthorizeMemoryAccess;
        }
        state verifying {
            do action verifyIntegrity : EgasOperationalRequirements_UC4::VerifyDataIntegrity;
        }
        state rejectingAndRollback {
            do action rejectInvalidAccess : EgasOperationalRequirements_UC4::RejectInvalidAccess;
        }

        // 요청 주소로 배타 (> 0 / <= 0)
        transition t_reqAuth
            first cal_Idle
            accept calReq : CalibrationRequest
            if calReq.targetMemoryAddress > 0 then authorizing;
        transition t_invalidReq
            first cal_Idle
            accept calReq : CalibrationRequest
            if calReq.targetMemoryAddress <= 0 then rejectingAndRollback;
        // 인가 결과로 배타 (== 200 / != 200). 자기 출력을 받는 구조는 F4에서 정리
        transition t_authToVerify
            first authorizing
            accept status : CalibrationStatus
            if status.responseCode == 200 then verifying;
        transition t_authFail
            first authorizing
            accept status : CalibrationStatus
            if status.responseCode != 200 then rejectingAndRollback;
        // 검증 결과로 배타 (체크섬 > 0 / <= 0)
        transition t_verifySuccess
            first verifying
            accept status : CalibrationStatus
            if status.verifiedChecksum > 0 then cal_Idle;
        transition t_verifyFail
            first verifying
            accept status : CalibrationStatus
            if status.verifiedChecksum <= 0 then rejectingAndRollback;
        transition t_rejectToIdle first rejectingAndRollback then cal_Idle; // 단일 출구라 완료 전이 유지
    }

    // ==========================================
    // 5. 진단 영역 (UC5)
    // ==========================================
    state def DiagnosticsHandling {
        first start then Diag_Idle;
        state Diag_Idle;
        state ReadingDTC {
            do action readDtc : EgasOperationalRequirements_UC5::ReadDiagnosticTroubleCode;
        }
        state CalibratingZeroPoint {
            do action zeroPointCal : EgasOperationalRequirements_UC5::ExecuteZeroPointCalibration;
        }
        state RejectingRequest {
            do action rejectReq : EgasOperationalRequirements_UC5::RejectInvalidDiagnosticRequest;
        }

        // 서비스 ID로 배타 (1 / 2 / 그 외)
        transition t_reqDTC
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if diagReq.serviceId == 1 then ReadingDTC;
        transition t_reqZero
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if diagReq.serviceId == 2 then CalibratingZeroPoint;
        transition t_reqInvalid
            first Diag_Idle
            accept diagReq : DiagnosticRequest
            if diagReq.serviceId != 1 and diagReq.serviceId != 2 then RejectingRequest;
        transition t_readToIdle first ReadingDTC then Diag_Idle;
        transition t_calToIdle first CalibratingZeroPoint then Diag_Idle;
        transition t_rejectToIdle first RejectingRequest then Diag_Idle;
    }

    // ==========================================
    // 통합: EGAS 병렬 동작
    // ==========================================
    state def EgasBehavior parallel {
        in egas : EgasSystem; // [M5] 가드 입력용 EGAS 경계 값. 영역에 바인딩된다.

        dependency
            self
            to
                EgasOperationalRequirements_UC1,
                EgasOperationalRequirements_UC2,
                EgasOperationalRequirements_UC3;

        state drivingControlRegion : DrivingControlRegion;
        state emergencyInterventionRegion : EmergencyInterventionRegion;
        state safetyMonitoringRegion : SafetyMonitoringRegion;

        state monitoringAndServiceRegion {
            first start then monitoringActive;
            state monitoringActive {
                state calibrationHandling : CalibrationHandling;
                state diagnosticsHandling : DiagnosticsHandling;
            }
        }

        bind drivingControlRegion.egas = egas; // [M5]
        bind emergencyInterventionRegion.egas = egas; // [M5]
    }
} // package RV_BehavioralModel
