package RV_BehavioralModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*;
    private import RV_OperationalModel::*;
    private import SI::*;

    @MetaInformation { version = "v0.8"; }

    state def DrivingControlRegion {
        first start then powerOff;

        state powerOff;
        state standby;

        state active {
            first start then manualDriving;
            // 정상 주행 중에만 CF1 기준 명령에 마찰/지연 보정을 직렬 후처리로 적용 (UC3 Normal)
            do action compensate : EgasOperationalRequirements_UC3::ExecuteDelayCompensation;
            state manualDriving {
                do action manageArbitration
                    : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            }
            state cruiseDriving {
                do action manageArbitration
                    : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            }
            // [변경] 가속 페달 입력 → 크루즈 일시 중단(Suspended)하고 수동 주행
            transition t_cruiseToManual
                first cruiseDriving accept AccelerationIntent then manualDriving;

            transition t_manualToStandby first manualDriving accept AccelerationIntent then standby; // 수동 주행에서 페달 해제 시에만 대기. 크루즈 중에는 대기로 가지 않음
            transition t_cruiseCancel first cruiseDriving accept CruiseControlCommand then standby;
        }

        state brakeOverridden {
            do action overrideBrake : EgasOperationalRequirements_UC1::OverrideBrakeIntervention;
        }
        state waitForPedalRelease;

        transition t_standbyToActive first standby accept AccelerationIntent then active;
        transition t_standbyToBrake first standby accept AccelerationIntent then brakeOverridden; // 가드(FE): 제동이 먼저 입력된 상태에서 가속 입력
        transition t_activeToBrake
            first active
            accept brake : BrakePedalPosition
            if brake.pressure > 0.0 [Pa] // active ⇒ 구동 요구 활성 (IsBrakeOverrideTriggered와 동치)
                then brakeOverridden;

        transition t_brakeToWait
            first brakeOverridden accept BrakePedalPosition then waitForPedalRelease;
        transition t_brakeToStandby first brakeOverridden accept BrakePedalPosition then standby;
        transition t_waitToStandby first waitForPedalRelease accept AccelerationIntent then standby;

        transition t_powerOn first powerOff accept IgnitionState then standby;
        transition t_powerOffStandby first standby accept IgnitionState then powerOff;
        transition t_powerOffActive first active accept IgnitionState then powerOff;
        transition t_powerOffOverride first brakeOverridden accept IgnitionState then powerOff;

        transition t_powerOffWait first waitForPedalRelease accept IgnitionState then powerOff; // 래치 대기 중 시동 OFF

        // Set/Resume으로 크루즈 진입 (가드: FE - 요청 종류, 페달/제동 없음, 설정 속도 유효)
        transition t_standbyToCruise
            first standby accept CruiseControlCommand then active.cruiseDriving;
        //  transition t_activeToStandby first active then standb
    }

    state def EmergencyInterventionRegion {
        first start then emergencyStandby;
        state emergencyStandby;

        state InterventionActive {
            first start then initialCheck;
            state initialCheck;
            state parallelReduction {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;

                // 스로틀 추종 감시 (디바운스)
                first start then tracking;
                state tracking; // 스로틀이 목표 개도를 추종 중
                state stuckSuspected; // 편차 초과 관측 중 (확정 전)

                // 가드: tracking→stuckSuspected는 IsThrottleDeviated == true, 복귀는 false (가드식은 FE에서 명세)
                transition t_trackingLost
                    first tracking accept ThrottlePositionFeedback then stuckSuspected;
                transition t_trackingRecovered
                    first stuckSuspected accept ThrottlePositionFeedback then tracking;
                transition t_stuckDetect
                    first stuckSuspected
                    accept after ThrottleStuckLogic::stuckConfirmTime
                    then actuatorStuckFallback;
            }
            state delayCompensating {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            }

            // [래치] 해제 요청으로 나가지 않는다. 점화 OFF(t_ignitionOffReset)로만 해제한다.
            state actuatorStuckFallback {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            }

            transition t_checkToNormal first initialCheck then parallelReduction;
            transition t_checkToDelay first initialCheck then delayCompensating;

            // [변경] 개입 중(delta < 0)일 때만 정상/지연 전환 → 해제 요청과 겹치지 않음
            transition t_normalToDelay
                first parallelReduction
                accept req : TorqueInterventionRequest
                if (
                    req.requestedTorqueDelta < 0.0 [N * m] and
                    req.messageAge > TimingConceptsAndLimits::commDelayThreshold
                ) // Before: req.latency > 15.0 [milli * s]
                    then delayCompensating;
            transition t_delayToNormal
                first delayCompensating
                accept req : TorqueInterventionRequest
                if (
                    req.requestedTorqueDelta < 0.0 [N * m] and
                    req.messageAge <= TimingConceptsAndLimits::commDelayThreshold
                ) // Before: req.latency <= 15.0 [milli * s]
                    then parallelReduction;

            transition t_stuckDetect first parallelReduction then actuatorStuckFallback;

            // [변경] accept/가드 없는 완료 전이 → 해제 요청(delta >= 0)에 의한 전이
            transition t_finishNormal
                first parallelReduction
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m] then emergencyStandby;
            transition t_finishDelay
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta >= 0.0 [N * m] then emergencyStandby;
        }
        // 저감 요청(delta < 0)일 때만 개입 진입
        transition t_triggerIntervention
            first emergencyStandby
            accept req : TorqueInterventionRequest
            if req.requestedTorqueDelta < 0.0 [N * m] then InterventionActive;

        //  점화 OFF → 고착 래치를 포함한 모든 하위 상태 초기화
        transition t_ignitionOffReset
            first InterventionActive
            accept ign : IgnitionState
            if ign.status == IgnitionStatusEnum::Off then emergencyStandby;
    }

    state def SafetyMonitoringRegion {
        first start then normalMonitoring;
        state normalMonitoring;
        // 확정 대기: 원인별로 분리
        state pedalFaultSuspected;
        state throttleFaultSuspected;
        state overheatSuspected;
        // [래치] 점화 OFF(t_safetyIgnitionOffReset)로만 해제
        state criticalFault {
            do action executeFailSafe : EgasOperationalRequirements_UC3::ExecuteEmergencyFailSafe;
        }

        // 관측 (가드: IsChannelDeviated / IsOverheated - FE)
        transition t_pedalObserved
            first normalMonitoring accept AccelerationPedalPosition then pedalFaultSuspected;
        transition t_throttleObserved
            first normalMonitoring accept ThrottlePositionFeedback then throttleFaultSuspected;
        transition t_overheatObserved
            first normalMonitoring accept EngineSensorData then overheatSuspected; // 구 t_faultDetection
        // 회복 (가드: not 편차 / not 과열 - FE)
        transition t_pedalRecovered
            first pedalFaultSuspected accept AccelerationPedalPosition then normalMonitoring;
        transition t_throttleRecovered
            first throttleFaultSuspected accept ThrottlePositionFeedback then normalMonitoring;
        transition t_overheatRecovered
            first overheatSuspected accept EngineSensorData then normalMonitoring;
        // 확정
        transition t_pedalConfirm
            first pedalFaultSuspected
            accept after SafeStateLogic::sensorFaultConfirmTime
            then criticalFault;
        transition t_throttleConfirm
            first throttleFaultSuspected
            accept after SafeStateLogic::sensorFaultConfirmTime
            then criticalFault;
        transition t_overheatConfirm
            first overheatSuspected
            accept after SafeStateLogic::overheatConfirmTime
            then criticalFault;
        // 점화 OFF 초기화
        transition t_safetyIgnitionOffReset
            first criticalFault accept IgnitionState then normalMonitoring;
        transition t_pedalIgnitionOff
            first pedalFaultSuspected accept IgnitionState then normalMonitoring;
        transition t_throttleIgnitionOff
            first throttleFaultSuspected accept IgnitionState then normalMonitoring;
        transition t_overheatIgnitionOff
            first overheatSuspected accept IgnitionState then normalMonitoring;
    }

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

        transition t_reqAuth first cal_Idle then authorizing;
        transition t_invalidReq first cal_Idle then rejectingAndRollback;
        transition t_authToVerify first authorizing then verifying;
        transition t_authFail first authorizing then rejectingAndRollback;
        transition t_verifySuccess first verifying then cal_Idle;
        transition t_verifyFail first verifying then rejectingAndRollback;
        transition t_rejectToIdle first rejectingAndRollback then cal_Idle;
    }

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

        transition t_reqDTC first Diag_Idle then ReadingDTC;
        transition t_reqZero first Diag_Idle then CalibratingZeroPoint;
        transition t_reqInvalid first Diag_Idle then RejectingRequest;
        transition t_readToIdle first ReadingDTC then Diag_Idle;
        transition t_calToIdle first CalibratingZeroPoint then Diag_Idle;
        transition t_rejectToIdle first RejectingRequest then Diag_Idle;
    }

    state def EgasBehavior parallel {
        dependency
            self
            to
                EgasOperationalRequirements_UC1,
                EgasOperationalRequirements_UC2,
                EgasOperationalRequirements_UC3;

        // ==========================================
        // 1. 주행 토크 제어 영역 (UC1)
        // ==========================================
        state drivingControlRegion : DrivingControlRegion;

        // ==========================================
        // 2. 긴급 개입 제어 영역 (UC2)
        // ==========================================
        state emergencyInterventionRegion : EmergencyInterventionRegion;

        // ==========================================
        // 3. 상시 안전 감시 영역 (UC3)
        // ==========================================
        state safetyMonitoringRegion : SafetyMonitoringRegion;

        // ==========================================
        // 4 & 5. 진단 및 캘리브레이션 영역 (UC4, UC5)
        // ==========================================
        state monitoringAndServiceRegion {
            first start then monitoringActive;
            state monitoringActive {
                state calibrationHandling : CalibrationHandling;

                state diagnosticsHandling : DiagnosticsHandling;
            }
        }
    }
} // package RV_BehavioralModel
