package FW_CalibrationDiagnosticsWhiteBoxModel {
    doc
    /* [CF3 하드웨어 안전 모니터링 - 화이트박스 모델 파트 ]
     * 엔진 마찰/지연 실시간 보정(UF3_1)과 치명적 결함 페일세이프(UF3_2)의 
     * 상세 내부 구조, 내부 트리거 논리, 그리고 처리 시간 할당을 명세합니다.
     */

    private import FB_FunctionalBlackBoxModel::*;
    private import FW_UF1_WhiteBoxModel::*;
    private import RV_InterfaceModel::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;
    private import SafeStateLogic::*;

    @MetaInformation {
        version = "v0.1";
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
} // package FW_CalibrationDiagnosticsWhiteBoxModel
