package EgasStakeholderReqValidation {
    private import EgasStakeholderRequirements::*;
    private import VerificationCases::VerdictKind;
    private import VerificationCases::PassIf;
    private import SI::*;
    private import ScalarValues::*;
    private import ReqCommon::*;

    verification def ValidationOfStakeholderReq {
        subject context : EgasSystemContext::EgasContext; // 검증 대상을 EgasSystem 단일 요소가 아닌, 외부 액터가 포함된 전체 EgasContext로 지정
        attribute validationMethod : VVMethod;
    }

    verification def TestBrakeOverrideArbitration :> ValidationOfStakeholderReq {
        doc
        /* EgasContext 환경에서 운전자(Driver)가 가속 페달과 브레이크(Brake)를 동시에 조작하는 상충 상황을 모사하여, 
         * 시스템이 제동 의도를 최우선으로 판단하고 토크(공기 유입량)를 강제 차단하는지 확인하는 실차 기반 인수 테스트
         */

        :>> validationMethod = VVMethod::Test;

        objective {
            verify reqSafeTorqueArbitration;
            assume constraint {
                // 가속 페달이 50mm 밟힌 물리적 상황 주입 (기존 value == 50.0 대체)
                context.egas.accelPort.accelIntent.pedalDisplacement == 50.0 [mm] and
                context.egas.brakePort.brakeInput.pressure == 1000.0 [Pa]
            }
        }

        // 테스트 사전 조건(Pre-condition) 모사: 두 페달이 동시에 밟힌 물리적 상황을 강제함

        return verdict : VerificationCases::VerdictKind = PassIf(
            context.egas.airIntakePort.airFlow.massFlow <= 0.0 [kg / s]
        );

        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def DemonstrateClosedLoopPrecision :> ValidationOfStakeholderReq {
        doc
        /* 동력계(Dynamometer) 및 실차 운용 환경에서 하드웨어 오차 보정 및 정밀 제어 성능을 시연하는 검증 케이스 */

        :>> validationMethod = VVMethod::Demonstration;

        objective {
            verify reqPreciseClosedLoopControl;
        }

        // 폐루프 제어의 정상 상태 오차(Steady-state error)가 허용 범위(예: 2.0%) 이내일 경우 합격(Pass) 판정
        return verdict : VerdictKind = PassIf(
            context.egas.combustionStatusPort.combustionStatus.steadyStateError <= 2.0 and
            context.egas.combustionStatusPort.combustionStatus.misfireRate <= 0.0 [Hz]
        );
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def TestSensorFaultFailSafe :> ValidationOfStakeholderReq {
        doc
        /* 도메인 전문가 및 규제 기관이 참여하여 결함 발생 시 엔진 구동 차단(안전 상태 진입)을 시연 및 검토하는 검증 케이스 */

        :>> validationMethod = VVMethod::Inspection;

        objective {
            verify reqFailSafeSensorMonitoring;

            // 물리적 결함 사전 조건 모사: 냉각수 온도가 130도로 치솟은 오버히팅 센서 데이터 주입
            assume constraint {
                context.egas.sensorPort.sensorData.coolantTemp == 130.0 ['°']
            }
        }

        // 전문가 시연 중 결함 발현 시 흡기량 및 연료 차단 상태를 확인하여 최종 합격(Pass) 판정
        // 조건 발현 시 흡기량 및 연료 차단 상태를 확인하여 최종 합격(Pass) 판정
        return verdict : VerificationCases::VerdictKind = PassIf(
            context.egas.airIntakePort.airFlow.massFlow <= 0.0 [kg / s] and
            context.egas.fuelCmdPort.fuelCmd.injectionPulseWidth <= 0.0 [s]
        );
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def TestInterventionLatency :> ValidationOfStakeholderReq {
        doc
        /* 빙판길 주행 등 가혹한 트랙 테스트 환경에서 ESP/TCU(AddEcu)의 긴급 토크 개입(Intervention) 신호가 발생했을 때, 
         * 차량 거동이 딜레이 없이 즉각적으로 안정화되는지 측정하는 검증 케이스
         */

        :>> validationMethod = VVMethod::Test;

        objective {
            verify reqDynamicResponsiveness;
            // 물리적 사전 조건 모사: ESP가 미끄럼 방지를 위해 엔진 토크를 100 N·m 강제 저감 요청
            assume constraint {
                context.egas.torqueInterventionPort.torqueReq.requestedTorqueDelta == -100.0 [N * m]
            }
        }

        // 긴급 토크 개입 요청 수신 후 실제 제어 출력까지의 지연 시간이 15ms 이하인지 판정
        return verdict : VerificationCases::VerdictKind = PassIf(
            context.egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s]
        );
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def DemonstrateCalibrationAccessibility :> ValidationOfStakeholderReq {
        doc
        /* 엔진 벤치 테스트 환경에서 캘리브레이션 엔지니어가 표준 툴(예: XCP/CCP)을 연결하여 제어 맵(Map) 파라미터의 읽기/쓰기 접근 권한을 확인하고 튜닝이 실시간 반영되는지 시연하는 검증 케이스 */
        :>> validationMethod = VVMethod::Demonstration;

        // 검증 목표(objective)에 대상 요구사항을 명시하여 단방향 추적성 확보
        objective {
            verify reqPowertrainCalibrationSupport;
        }

        // 제어 맵 파라미터 업데이트 요청 시 시스템 접근이 정상적으로 허용되고(isAccessible),
        // 튜닝된 값이 적용(isUpdated)되었을 경우 합격(Pass) 판정 반환
        return verdict : VerificationCases::VerdictKind = PassIf(
            context.egas.calibrationPort.calStatus.isAccessible == true and
            context.egas.calibrationPort.calStatus.isUpdated == true
        );
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def DemonstrateDiagnosticAndZeroReset :> ValidationOfStakeholderReq {
        doc
        /* 서비스 센터(A/S) 환경을 모사하여, 진단기를 연결했을 때 고장 코드(DTC)가 정상 출력되고 부품 교체 후 영점 조정이 원활히 수행되는지 시연하는 검증 케이스 */

        :>> validationMethod = VVMethod::Demonstration;

        // 대상 요구사항을 명시하여 요구사항을 상향식으로 참조
        objective {
            verify reqDiagnosticAndMaintenanceSupport;

            assume constraint {
                context.egas.sensorPort.sensorData.coolantTemp == 130.0 ['°'] and
                context.egas.diagPort.diagReq.isZeroPointResetRequested == true
            }
        }

        // DTC가 유효하게 출력되고 영점 조정이 완료된 상태인지 판정
        return verdict : VerificationCases::VerdictKind = PassIf(
            context.egas.diagPort.diagStatus.hasValidDtc == true and
            context.egas.diagPort.diagStatus.isZeroPointCalibrated == true
        );
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def InspectModularArchitecture :> ValidationOfStakeholderReq {
        doc
        /* 도메인 전문가 및 소프트웨어 아키텍트가 참여하여 신규 외부 제어기(자율주행 ECU 등) 통합 시 코어 로직의 소스코드 변경 여부를 정적 분석 및 리뷰하는 검증 케이스 */

        // 검증 목표(objective)에 대상 요구사항을 명시하여 단방향 추적성 확보
        objective {
            verify reqModularInterfaceArchitecture;
        }

        :>> validationMethod = VVMethod::Inspection;

        // [개선 포인트] 리뷰어의 정성적 평가 결과를 검증 케이스 실행 시점의 입력(in)으로 받음
        attribute isCoreLogicModifiedByReview : Boolean;

        // 전문가가 코어 로직 수정이 없다고(false) 평가한 값을 입력하면 합격(Pass) 반환
        return verdict : VerificationCases::VerdictKind = PassIf(
            isCoreLogicModifiedByReview == false
        );
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def AuditIso26262AsilDCompliance :> ValidationOfStakeholderReq {
        doc
        /* 외부 공인 인증 기관의 감사를 통해 ISO 26262 ASIL-D 산출물 및 프로세스 준수 여부를 평가하는 검증 케이스 */

        // 프로젝트 요구사항이므로 특정 물리적 컨텍스트 대신 외부 감사 결과를 파라미터로 입력받음
        attribute isAsilDCertified : Boolean;

        :>> validationMethod = VVMethod::Inspection;

        // 검증 목표에 대상 요구사항 명시 (상향식 추적성)
        objective {
            verify reqIso26262SafetyCompliance;
        }

        // 감사 기관의 최종 통과 결과가 참(true)일 경우 합격(Pass) 반환
        return verdict : VerificationCases::VerdictKind = PassIf(isAsilDCertified == true);
        @MetaInformation {
            version = "v0.1";
        }
    }

    verification def AnalyzeCoreLogicReuseRate :> ValidationOfStakeholderReq {
        doc
        /* 소프트웨어 정적 분석 및 모델 리뷰를 통해 차기 파생 차종 개발 시 코어 로직의 재사용률(%)을 측정하는 검증 케이스 */

        // 실제 측정된 코드/모델 재사용률(%)을 파라미터로 입력받음
        attribute coreLogicReuseRate : Real;

        :>> validationMethod = VVMethod::Inspection;

        objective {
            verify reqEfficientPlatformDevelopment;
        }

        // 측정된 재사용률이 80.0% 이상일 경우에만 합격(Pass) 판정 반환
        return verdict : VerificationCases::VerdictKind = PassIf(coreLogicReuseRate >= 80.0);
        @MetaInformation {
            version = "v0.1";
        }
    }
} // package EgasStakeholderReqValidation
