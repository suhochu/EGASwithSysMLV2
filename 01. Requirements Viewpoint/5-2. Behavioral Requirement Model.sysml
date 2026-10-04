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
            state manualDriving {
                do action manageArbitration
                    : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            }
            state cruiseDriving {
                do action manageArbitration
                    : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
            }

            transition t_manualToCruise
                first manualDriving accept CruiseControlCommand then cruiseDriving;
            transition t_cruiseToManual
                first cruiseDriving accept AccelerationIntent then manualDriving;
        }

        state brakeOverridden {
            do action overrideBrake : EgasOperationalRequirements_UC1::OverrideBrakeIntervention;
        }
        state waitForPedalRelease;

        transition t_standbyToActive first standby accept AccelerationIntent then active;
        transition t_standbyToBrake first standby accept AccelerationIntent then brakeOverridden; // 가드(FE): 제동이 먼저 입력된 상태에서 가속 입력
        transition t_activeToStandby first active then standby;
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
                if req.requestedTorqueDelta < 0.0 [N * m] and req.latency > 15.0 [milli * s]
                    then delayCompensating;
            transition t_delayToNormal
                first delayCompensating
                accept req : TorqueInterventionRequest
                if req.requestedTorqueDelta < 0.0 [N * m] and req.latency <= 15.0 [milli * s]
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
        state normalMonitoring {
            do action executeDelayComp : EgasOperationalRequirements_UC3::ExecuteDelayCompensation;
        }
        state criticalFault {
            do action executeFailSafe : EgasOperationalRequirements_UC3::ExecuteEmergencyFailSafe;
        }

        transition t_faultDetection
            first normalMonitoring accept EngineSensorData then criticalFault;
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
