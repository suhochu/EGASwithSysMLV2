package RV_BehavioralModel {
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import RV_InterfaceModel::*;
    private import RV_ContextModel::*;
    private import RV_OperationalModel::*;

    @MetaInformation { version = "v0.7"; }

    state def EgasBehavior {
        dependency
            self
            to
                EgasOperationalRequirements_UC1,
                EgasOperationalRequirements_UC2,
                EgasOperationalRequirements_UC3;

        // ==========================================
        // 1. 주행 토크 제어 영역 (UC1)
        // ==========================================
        state drivingControlRegion {
            first start then Standby;
            state Standby;

            state Active {
                first start then ManualDriving;
                state ManualDriving {
                    do action manageArbitration
                        : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
                }
                state CruiseDriving {
                    do action manageArbitration
                        : EgasOperationalRequirements_UC1::ManageDrivingTorqueArbitration;
                }

                transition t_manualToCruise
                    first ManualDriving accept CruiseControlCommand then CruiseDriving;
                transition t_cruiseToManual
                    first CruiseDriving accept AccelerationIntent then ManualDriving;
            }

            state BrakeOverridden {
                do action overrideBrake
                    : EgasOperationalRequirements_UC1::OverrideBrakeIntervention;
            }
            state WaitForPedalRelease;

            transition t_standbyToActive first Standby accept AccelerationIntent then Active;
            transition t_activeToStandby first Active then Standby;
            transition t_activeToBrake first Active accept BrakePedalPosition then BrakeOverridden;
            transition t_brakeToWait first BrakeOverridden then WaitForPedalRelease;
            transition t_brakeToStandby first BrakeOverridden then Standby;
            transition t_waitToStandby first WaitForPedalRelease then Standby;
        }

        // ==========================================
        // 2. 긴급 개입 제어 영역 (UC2)
        // ==========================================
        state emergencyInterventionRegion {
            first start then EmergencyStandby;
            state EmergencyStandby;

            state InterventionActive {
                first start then InitialCheck;
                state InitialCheck;
                state ParallelReduction {
                    do action manageEmergency
                        : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
                }
                state DelayCompensating {
                    do action manageEmergency
                        : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
                }
                state ActuatorStuckFallback {
                    do action manageEmergency
                        : EgasOperationalRequirements_UC2::ManageEmergencyIntervention;
                }

                transition t_checkToNormal first InitialCheck then ParallelReduction;
                transition t_checkToDelay first InitialCheck then DelayCompensating;
                transition t_normalToDelay first ParallelReduction then DelayCompensating;
                transition t_delayToNormal first DelayCompensating then ParallelReduction;
                transition t_stuckDetect first ParallelReduction then ActuatorStuckFallback;

                transition t_finishNormal first ParallelReduction then EmergencyStandby;
                transition t_finishDelay first DelayCompensating then EmergencyStandby;
            }
            transition t_triggerIntervention
                first EmergencyStandby accept TorqueInterventionRequest then InterventionActive;
        }

        // ==========================================
        // 3. 상시 안전 감시 영역 (UC3)
        // ==========================================
        state safetyMonitoringRegion {
            first start then NormalMonitoring;
            state NormalMonitoring {
                do action executeDelayComp
                    : EgasOperationalRequirements_UC3::ExecuteDelayCompensation;
            }
            state CriticalFault {
                do action executeFailSafe
                    : EgasOperationalRequirements_UC3::ExecuteEmergencyFailSafe;
            }

            transition t_faultDetection
                first NormalMonitoring accept EngineSensorData then CriticalFault;
        }

        // ==========================================
        // 4 & 5. 진단 및 캘리브레이션 영역 (UC4, UC5)
        // ==========================================
        state monitoringAndServiceRegion {
            first start then MonitoringActive;
            state MonitoringActive {
                state calibrationHandling {
                    first start then Cal_Idle;
                    state Cal_Idle;
                    state Authorizing {
                        do action authorize
                            : EgasOperationalRequirements_UC4::AuthorizeMemoryAccess;
                    }
                    state Verifying {
                        do action verifyIntegrity
                            : EgasOperationalRequirements_UC4::VerifyDataIntegrity;
                    }
                    state RejectingAndRollback {
                        do action rejectInvalidAccess
                            : EgasOperationalRequirements_UC4::RejectInvalidAccess;
                    }

                    transition t_reqAuth first Cal_Idle then Authorizing;
                    transition t_invalidReq first Cal_Idle then RejectingAndRollback;
                    transition t_authToVerify first Authorizing then Verifying;
                    transition t_authFail first Authorizing then RejectingAndRollback;
                    transition t_verifySuccess first Verifying then Cal_Idle;
                    transition t_verifyFail first Verifying then RejectingAndRollback;
                    transition t_rejectToIdle first RejectingAndRollback then Cal_Idle;
                }

                state diagnosticsHandling {
                    first start then Diag_Idle;
                    state Diag_Idle;
                    state ReadingDTC {
                        do action readDtc
                            : EgasOperationalRequirements_UC5::ReadDiagnosticTroubleCode;
                    }
                    state CalibratingZeroPoint {
                        do action zeroPointCal
                            : EgasOperationalRequirements_UC5::ExecuteZeroPointCalibration;
                    }
                    state RejectingRequest {
                        do action rejectReq
                            : EgasOperationalRequirements_UC5::RejectInvalidDiagnosticRequest;
                    }

                    transition t_reqDTC first Diag_Idle then ReadingDTC;
                    transition t_reqZero first Diag_Idle then CalibratingZeroPoint;
                    transition t_reqInvalid first Diag_Idle then RejectingRequest;
                    transition t_readToIdle first ReadingDTC then Diag_Idle;
                    transition t_calToIdle first CalibratingZeroPoint then Diag_Idle;
                    transition t_rejectToIdle first RejectingRequest then Diag_Idle;
                }
            }
        }
    }
} // package RV_BehavioralModel
