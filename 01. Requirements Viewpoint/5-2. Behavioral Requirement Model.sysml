package RV_BehavioralModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*;
    private import RV_OperationalModel::*;

    @MetaInformation { version = "v0.7"; }

    state def DrivingControlRegion {
        first start then standby;
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
                first manualDriving accept CruiseControlCommand then cruiseDriving; //
            transition t_cruiseToManual
                first cruiseDriving accept AccelerationIntent then manualDriving; //
        }

        state brakeOverridden {
            do action overrideBrake : EgasOperationalRequirements_UC1::OverrideBrakeIntervention;
        }
        state waitForPedalRelease;

        transition t_standbyToActive first standby accept AccelerationIntent then active; //
        transition t_activeToStandby first active then standby; //
        transition t_activeToBrake first active accept BrakePedalPosition then brakeOverridden; //
        transition t_brakeToWait first brakeOverridden then waitForPedalRelease; //
        transition t_brakeToStandby first brakeOverridden then standby; //
        transition t_waitToStandby first waitForPedalRelease then standby; //
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
            }
            state delayCompensating {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            }
            state actuatorStuckFallback {
                do action manageEmergency
                    : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
            }

            transition t_checkToNormal first initialCheck then parallelReduction; //
            transition t_checkToDelay first initialCheck then delayCompensating; //
            transition t_normalToDelay first parallelReduction then delayCompensating; //
            transition t_delayToNormal first delayCompensating then parallelReduction; //
            transition t_stuckDetect first parallelReduction then actuatorStuckFallback; //

            transition t_finishNormal first parallelReduction then emergencyStandby; //
            transition t_finishDelay first delayCompensating then emergencyStandby; //
        }
        transition t_triggerIntervention
            first emergencyStandby accept TorqueInterventionRequest then InterventionActive; //
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

        transition t_reqAuth first cal_Idle then authorizing; //
        transition t_invalidReq first cal_Idle then rejectingAndRollback; //
        transition t_authToVerify first authorizing then verifying; //
        transition t_authFail first authorizing then rejectingAndRollback; //
        transition t_verifySuccess first verifying then cal_Idle; //
        transition t_verifyFail first verifying then rejectingAndRollback; //
        transition t_rejectToIdle first rejectingAndRollback then cal_Idle; //
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

        transition t_reqDTC first Diag_Idle then ReadingDTC; //
        transition t_reqZero first Diag_Idle then CalibratingZeroPoint; //
        transition t_reqInvalid first Diag_Idle then RejectingRequest; //
        transition t_readToIdle first ReadingDTC then Diag_Idle; //
        transition t_calToIdle first CalibratingZeroPoint then Diag_Idle; //
        transition t_rejectToIdle first RejectingRequest then Diag_Idle; // ß
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
