package FW_CalibrationDiagnosticsWhiteBoxModel {
    doc
    /* 캘리브레이션 및 진단 기능의 상세 화이트박스 동작을 명세합니다.
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import FW_UF1_WhiteBoxModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;
    private import SafeStateLogic::*;
    private import DtcStroage::*;

    @MetaInformation {
        version = "v0.1";
    }

    action def <UF4_1_WB> MemoryAccessAuthorization_WhiteBox :> CF4::CF4_1 {
        in calibration_Req : CalibrationRequest :>> CF4::CF4_1::calibration_Req;
        in expectedCredential : Integer :>> CF4::CF4_1::expectedCredential;
        in ignition : IgnitionState :>> CF4::CF4_1::ignition;
        in vehicleSpeed : ISQ::SpeedValue :>> CF4::CF4_1::vehicleSpeed;
        out isAuthorized : Boolean :>> CF4::CF4_1::isAuthorized;
        out authStatus : CalibrationStatus :>> CF4::CF4_1::authStatus;

        action evaluateAuthorization {
            in req : CalibrationRequest;
            in credential : Integer;
            in currentIgnition : IgnitionState;
            in currentSpeed : ISQ::SpeedValue;
            out authorized : Boolean;
            constraint Local_Authorization {
                authorized ==
                IsCalibrationAuthorized(
                    req.targetMemoryAddress,
                    req.accessCredential,
                    credential,
                    req.operation,
                    currentIgnition.status,
                    currentSpeed
                )
            }
        }

        assert constraint redefines AuthDefinition {
            out redefines result =
                isAuthorized ==
                IsCalibrationAuthorized(
                    calibration_Req.targetMemoryAddress,
                    calibration_Req.accessCredential,
                    expectedCredential,
                    calibration_Req.operation,
                    ignition.status,
                    vehicleSpeed
                );
        }

        bind calibration_Req = evaluateAuthorization.req;
        bind expectedCredential = evaluateAuthorization.credential;
        bind ignition = evaluateAuthorization.currentIgnition;
        bind vehicleSpeed = evaluateAuthorization.currentSpeed;
        bind evaluateAuthorization.authorized = isAuthorized;
    }

    action def <UF4_2_WB> DataIntegrityVerification_WhiteBox :> CF4::CF4_2 {
        in calibration_Req : CalibrationRequest :>> CF4::CF4_2::calibration_Req;
        in isAuthorized : Boolean :>> CF4::CF4_2::isAuthorized;
        out isIntegrityOk : Boolean :>> CF4::CF4_2::isIntegrityOk;
        out verifyStatus : CalibrationStatus :>> CF4::CF4_2::verifyStatus;

        action computeChecksum {
            in req : CalibrationRequest;
            out computed : Integer;
            attribute executionTime : TimeValue;
            constraint Local_ComputeLatency { executionTime <= 60.0 [milli * s] }
        }
        action compareAndCommit {
            in req : CalibrationRequest;
            in computed : Integer;
            out ok : Boolean;
            out status : CalibrationStatus;
            attribute executionTime : TimeValue;
            constraint Local_Compare { ok == (computed == req.payloadChecksum) }
            constraint Local_Response {
                ok implies (status.responseCode == 200 and status.rolledBack == false)
            }
            constraint Local_CommitLatency { executionTime <= 20.0 [milli * s] }
        }

        assert constraint redefines IntegrityCheck {
            out redefines result =
                (isAuthorized and
                    calibration_Req.operation == CalibrationOperationEnum::Write) implies
                (isIntegrityOk ==
                    (verifyStatus.verifiedChecksum == calibration_Req.payloadChecksum) and
                    (isIntegrityOk implies
                        (verifyStatus.responseCode == 200 and
                            verifyStatus.rolledBack == false and
                            computeChecksum.executionTime + compareAndCommit.executionTime <=
                            TimingConceptsAndLimits::mapUpdateBudget)));
        }

        bind calibration_Req = computeChecksum.req;
        bind calibration_Req = compareAndCommit.req;
        flow computeChecksum.computed to compareAndCommit.computed;
        bind compareAndCommit.ok = isIntegrityOk;
        bind compareAndCommit.status = verifyStatus;
    }

    action def <UF4_3_WB> InvalidAccessRejectionAndRollback_WhiteBox :> CF4::CF4_3 {
        in calibration_Req : CalibrationRequest :>> CF4::CF4_3::calibration_Req;
        in isAuthorized : Boolean :>> CF4::CF4_3::isAuthorized;
        in integrityFailed : Boolean :>> CF4::CF4_3::integrityFailed;
        out errorStatus : CalibrationStatus :>> CF4::CF4_3::errorStatus;

        action rejectOrRollback {
            in req : CalibrationRequest;
            in authorized : Boolean;
            in failedIntegrity : Boolean;
            out status : CalibrationStatus;
            constraint Local_UnauthorizedRejection {
                not authorized implies
                (status.responseCode != 200 and
                    status.rolledBack == false and
                    status.responseTime <= TimingConceptsAndLimits::addressRejectBudget)
            }
            constraint Local_IntegrityRollback {
                failedIntegrity implies
                (status.responseCode != 200 and
                    status.rolledBack == true and
                    status.responseTime <= TimingConceptsAndLimits::mapUpdateBudget)
            }
        }

        assert constraint redefines UnauthorizedRejection {
            out redefines result =
                not isAuthorized implies
                (errorStatus.responseCode != 200 and
                    errorStatus.rolledBack == false and
                    errorStatus.responseTime <= TimingConceptsAndLimits::addressRejectBudget);
        }

        assert constraint redefines IntegrityRollback {
            out redefines result =
                integrityFailed implies
                (errorStatus.responseCode != 200 and
                    errorStatus.rolledBack == true and
                    errorStatus.responseTime <= TimingConceptsAndLimits::mapUpdateBudget);
        }

        bind calibration_Req = rejectOrRollback.req;
        bind isAuthorized = rejectOrRollback.authorized;
        bind integrityFailed = rejectOrRollback.failedIntegrity;
        bind rejectOrRollback.status = errorStatus;
    }

    action def <UF5_1_WB> DiagnosticTroubleCodeRead_WhiteBox :> CF5::CF5_1 {
        in diag_Req : DiagnosticRequest :>> CF5::CF5_1::diag_Req;
        in faultMemory : FaultMemoryRecord :>> CF5::CF5_1::faultMemory;
        out dtcStatus : DiagnosticStatus :>> CF5::CF5_1::dtcStatus;

        action lookupFaultMemory {
            in memory : FaultMemoryRecord;
            out foundCode : Integer;
            attribute executionTime : TimeValue;
            constraint Local_LookupLatency { executionTime <= 20.0 [milli * s] }
            constraint Local_Lookup { foundCode == memory.dtcCode }
        }
        action buildDtcResponse {
            in code : Integer;
            out status : DiagnosticStatus;
            attribute executionTime : TimeValue;
            constraint Local_Response { status.responseCode == 200 and status.dtcCode == code }
            constraint Local_BuildLatency { executionTime <= 20.0 [milli * s] }
        }

        assert constraint redefines DtcResponse {
            out redefines result =
                diag_Req.serviceId == DtcStroage::diagServiceReadDtc implies
                (dtcStatus.responseCode == 200 and
                    dtcStatus.dtcCode == faultMemory.dtcCode and
                    lookupFaultMemory.executionTime + buildDtcResponse.executionTime <=
                    TimingConceptsAndLimits::dtcResponseBudget);
        }

        bind faultMemory = lookupFaultMemory.memory;
        flow lookupFaultMemory.foundCode to buildDtcResponse.code;
        bind buildDtcResponse.status = dtcStatus;
    }

    action def <UF5_2_WB> ZeroPointCalibrationRoutine_WhiteBox :> CF5::CF5_2 {
        in diag_Req : DiagnosticRequest :>> CF5::CF5_2::diag_Req;
        in ignition : IgnitionState :>> CF5::CF5_2::ignition;
        in vehicleSpeed : ISQ::SpeedValue :>> CF5::CF5_2::vehicleSpeed;
        out zeroStatus : DiagnosticStatus :>> CF5::CF5_2::zeroStatus;

        action checkServiceMode {
            in currentIgnition : IgnitionState;
            in currentSpeed : ISQ::SpeedValue;
            out allowed : Boolean;
            constraint Local_ServiceMode {
                allowed == IsServiceModeAllowed(currentIgnition.status, currentSpeed)
            }
        }
        action executeZeroPointRoutine {
            in req : DiagnosticRequest;
            in serviceModeAllowed : Boolean;
            out status : DiagnosticStatus;
            constraint Local_Completion {
                (req.serviceId == diagServiceRoutineControl and serviceModeAllowed) implies
                (status.responseCode == 200 and
                    status.responseTime <= TimingConceptsAndLimits::zeroPointBudget)
            }
        }

        assert constraint redefines ZeroPointCal {
            out redefines result =
                (diag_Req.serviceId == diagServiceRoutineControl and
                    IsServiceModeAllowed(ignition.status, vehicleSpeed)) implies
                (zeroStatus.responseCode == 200 and
                    zeroStatus.responseTime <= TimingConceptsAndLimits::zeroPointBudget);
        }

        bind ignition = checkServiceMode.currentIgnition;
        bind vehicleSpeed = checkServiceMode.currentSpeed;
        bind diag_Req = executeZeroPointRoutine.req;
        flow checkServiceMode.allowed to executeZeroPointRoutine.serviceModeAllowed;
        bind executeZeroPointRoutine.status = zeroStatus;
    }

    action def <UF5_4_WB> FaultMemoryStorage_WhiteBox :> CF5::CF5_4 {
        in confirmedFaultCause : FaultCause :>> CF5::CF5_4::confirmedFaultCause;
        out dtcRecord : FaultMemoryRecord :>> CF5::CF5_4::dtcRecord;

        action encodeFaultCause {
            in cause : FaultCause;
            out code : Integer;
            constraint Local_Encode {
                cause != FaultCause::NoFault implies code > 0
            }
        }
        action persistFaultRecord {
            in cause : FaultCause;
            in code : Integer;
            out record : FaultMemoryRecord;
            constraint Local_Persist {
                record.dtcCode == code and
                (cause != FaultCause::NoFault implies
                    record.storageTime <= DtcStroage::dtcStorageBudget)
            }
        }

        assert constraint redefines StorageConstraint {
            out redefines result =
                confirmedFaultCause != FaultCause::NoFault implies
                (dtcRecord.dtcCode > 0 and
                    dtcRecord.storageTime <= DtcStroage::dtcStorageBudget);
        }

        bind confirmedFaultCause = encodeFaultCause.cause;
        bind confirmedFaultCause = persistFaultRecord.cause;
        flow encodeFaultCause.code to persistFaultRecord.code;
        bind persistFaultRecord.record = dtcRecord;
    }
} // package FW_CalibrationDiagnosticsWhiteBoxModel
