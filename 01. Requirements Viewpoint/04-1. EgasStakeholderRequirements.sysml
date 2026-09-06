package EgasStakeholderRequirements {
    doc
    /* [이해관계자 요구사항 뷰포인트]
     * 03번 파일의 Concern을 근거(`frame concern`)로 삼아, "기술 명세가 아닌 이해관계자의 비즈니스/운용 니즈"를
     * SHR-xx(시스템 관련, 2번 섹션) 와 SHR-Pxx(프로젝트/비즈니스 관련, 3번 섹션)로 정의한다.
     * 각 항목은 사용자 관점 인수 조건(acceptanceCriteria)과 검증 방법(validationMethod)을 갖추어야 하며,
     * 06번 파일의 시스템 요구사항(SYSR)이 `traceToParent`로 이 항목들을 상위 추적 대상으로 참조한다.
     */
    private import ModelingMetadata::*;
    private import EgasSystemStakeHolders::*;
    private import ReqCommon::*;
    private import ScalarValues::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 이해관계자 요구사항 전용 특성 및 타입 정의
    // ==========================================

    requirement def StakeholderRequirement {
        doc
        /* 기술적 명세가 아닌, 이해관계자의 비즈니스/운용 니즈와 인수 조건을 대변하는 요구사항 */

        subject egas : EgasSystemContext::EgasSystem;

        attribute priorityLevel : PriorityLevel [1];
        attribute criticalityLevel : CriticalityLevel [1];
        attribute reqValidationStatus : ReqValidationStatus [1];

        require constraint acceptanceCriteria; // 사용자 관점의 인수 조건

        attribute author : ProjectMember;
        attribute owner : ProjectMember;
        attribute traceToSource : String [1..*];

        @MetaInformation {
            version = "v0.2";
        }
    }

    requirement def SystemRelatedSR :> StakeholderRequirement;
    requirement def ProjectRelatedSR :> StakeholderRequirement;

    // ==========================================
    // 2. 이해관계자 요구사항 목록 (기존 OBJ-S, OBJ-P 변환)
    // ==========================================

    requirement <'SHR-01'> reqSafeTorqueArbitration : SystemRelatedSR {
        doc
        /* 다중 토크 요구에 대한 안전 최우선 중재 및 제동 오버라이드(Brake Override) 실행 */
        // 요구사항을 평가할 블랙박스 대상 시스템 지정

        frame concern torqueArbitration : TorqueArbitrationConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "NHTSA 급발진 방지 가이드라인";

        // 인수 조건(Acceptance Criteria)을 EgasSystem의 외부 포트 입출력 기반 제약식으로 정의
        require constraint :>> acceptanceCriteria {
            doc
            /* 운전자의 가속 페달 입력과 브레이크 입력이 동시에 발생할 경우, 시스템은 브레이크 입력을 우선하여 최종 출력인 공기 유입량(IntakeAirFlow)을 강제로 차단/제한해야 한다. */

            // EgasSystem 블랙박스의 Port로 유입/유출되는 Item을 직접 참조하여 논리식 구성
            // (참고: 페이로드 아이템 내부에 active, value 등의 논리/물리 속성이 선언되어 있다고 가정)
            (egas.accelPort.accelIntent.pedalDisplacement [mm] > 0.0 and
                egas.brakePort.brakeInput.pressure > 0.0 [Pa]) implies
            egas.airIntakePort.airFlow.massFlow <= 0.0 [kg / s]
        }

        @Rationale {
            doc
            /* 가속 페달, 크루즈 컨트롤, 외부 제어기의 요구가 상충될 때 주행 안정성을 최우선으로 확보해야 함 */
        }

        @MetaInformation {
            version = "v0.2";
        }
    }

    requirement <'SHR-02'> reqPreciseClosedLoopControl : SystemRelatedSR {
        doc
        /* 하드웨어 오차를 보정하여 중재된 최종 목표 토크를 달성하기 위한 스로틀 밸브 및 연료/점화계의 폐루프 정밀 제어 */

        frame concern preciseControl : PreciseControlConcern;
        frame concern hardwareTolerance : HardwareToleranceHandlingConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "엔진 부품 공급사(Tier 1) 인터뷰";

        require constraint :>> acceptanceCriteria {
            doc
            /* 다양한 환경 조건에서 하드웨어 한계를 시스템이 보정하여, 
             * 실제 연소계 피드백의 정상 상태 오차(Steady-state error)가 2.0% 이하로 유지되어야 하며, 실화(Misfire)가 발생하지 않아야 한다.
             */

            egas.combustionStatusPort.combustionStatus.steadyStateError <= 2.0 and
            egas.combustionStatusPort.combustionStatus.misfireRate <= 0.0 [Hz]
        }

        @Rationale {
            doc
            /* 양산 부품의 물리적 한계를 극복하고 목표 토크를 실제 엔진 동력으로 정확하게 변환해야 함 */
        }

        @MetaInformation {
            version = "v0.2";
        }
    }

    requirement <'SHR-03'> reqFailSafeSensorMonitoring : SystemRelatedSR {
        doc
        /* 이중화 센서(PVS, TPS) 실시간 모니터링을 통한 액추에이터 고장 진단 및 페일세이프(Fail-safe) 구현 */

        frame concern hardwareFailure : HardwareFailureConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "ISO 26262 기능안전 요구사항";

        require constraint :>> acceptanceCriteria {
            doc
            /* 엔진 냉각수 온도가 안전 한계(예: 120도)를 초과하는 등 센서 측정값이 비정상 범위를 기록하면, 급발진 없이 즉각 공기 유입을 제한하고 연료 제어를 차단해야 한다. */

            // 센서 고장(단선/합선 등) 시 발생하는 극단적인 물리적 수치를 결함 기준으로 삼음
            egas.sensorPort.sensorData.coolantTemp > 120.0 ['°'] implies
            (egas.airIntakePort.airFlow.massFlow <= 0.0 [kg / s] and
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth <= 0.0 [s])
        }

        @Rationale {
            doc
            /* 단일 결함이 치명적 사고로 이어지지 않도록 안전 상태를 보장해야 함 */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-04'> reqDynamicResponsiveness : SystemRelatedSR {
        doc
        /* 운전자 조작 및 외부 제어기(ESP/TCU)의 긴급 개입 요구에 대한 지연 없는 즉각적이고 부드러운 토크 응답성 확보 */

        frame concern drivability : DrivabilityAndResponseConcern;
        frame concern interventionResponse : TorqueInterventionResponsivenessConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "섀시 제어 부서(ESP/TCU) 협의 회의록";

        // "이질감이나 딜레이 없이... 즉각 안정화됨"을 정량적인 타이밍 제약(Timing Constraint)으로 재정의
        require constraint :>> acceptanceCriteria {
            doc
            /* ESP/TCU 등 외부 제어기로부터 토크 강제 저감 요청(0 미만)이 인가되면, 
             * 시스템은 15ms 이내에 요구 토크를 즉각 반영해야 한다.
             */

            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s]
        }

        @Rationale {
            doc
            /* 빙판길 미끄럼 방지 등 긴급 제어의 실효성을 높이기 위해 매우 빠른 제어 응답성이 요구됨 */
        }

        @MetaInformation {
            version = "v0.2";
        }
    }

    requirement <'SHR-05'> reqPowertrainCalibrationSupport : SystemRelatedSR {
        doc
        /* 엔진 성능 및 배출가스 최적화를 위한 연료 분사 및 점화 제어 맵(Map)의 정밀 튜닝 환경 제공 */

        frame concern calibration : PowertrainCalibrationConcern;

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "캘리브레이션 엔지니어링 팀 요구사항";

        require constraint :>> acceptanceCriteria {
            doc
            /* 외부 캘리브레이션 툴이 통신 포트를 통해 접근 요청(calReq)을 인가할 때, 시스템은 맵 데이터에 대한 접근 권한(isAccessible)을 부여하고 파라미터 튜닝을 허용해야 한다. */

            // EgasSystem의 calibrationPort로 유입되는 요청과 유출되는 상태 간의 논리적 제약
            egas.calibrationPort.calReq.isActive == true implies
            egas.calibrationPort.calStatus.isAccessible == true
        }

        @Rationale {
            doc
            /* 차량별 특성에 맞춰 엔지니어가 연소 효율을 극대화할 수 있는 인터페이스가 필요함 */
        }

        @MetaInformation {
            version = "v0.2";
        }
    }

    requirement <'SHR-06'> reqDiagnosticAndMaintenanceSupport : SystemRelatedSR {
        doc
        /* 시스템 결함 시 명확한 고장 진단 코드(DTC) 제공 및 부품 교체 후 용이한 영점 조정 프로세스 지원 */

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "A/S 서비스 센터 VOC 리포트";

        require constraint :>> acceptanceCriteria {
            doc
            /* 시스템 내부에 결함(예: 냉각수 온도 허용치 초과 등 물리적 이상)이 존재할 경우 진단기의 요청에 따라 정확한 DTC를 출력해야 하며, 영점 조정 요청이 수신되면 추가 프로그래밍 없이 영점 조정 완료 상태로 전환되어야 한다. */

            // 1. 물리적 이상(고장) 발생 시 DTC 출력 제약
            (egas.sensorPort.sensorData.coolantTemp > 120.0 ['°'] implies
                egas.diagPort.diagStatus.hasValidDtc == true) and
            (// 2. 영점 조정 요청 시 캘리브레이션 완료 상태 제약
                egas.diagPort.diagReq.isZeroPointResetRequested == true implies
                egas.diagPort.diagStatus.isZeroPointCalibrated == true)
        }

        @Rationale {
            doc
            /* 서비스 센터 현장에서의 수리 시간 단축 및 유지보수 편의성이 보장되어야 함 */
        }

        frame concern diagnostics : DiagnosticsAndMaintenanceConcern;

        @MetaInformation {
            version = "v0.3";
        }
    }

    requirement <'SHR-07'> reqModularInterfaceArchitecture : SystemRelatedSR {
        doc
        /* 다양한 파생 차종 및 신규 제어기(자율주행 등)와의 연동을 견고하게 지원하는 표준화된 모듈형 아키텍처 구축 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::InReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "R&D 플랫폼 아키텍처 가이드라인";

        // 시스템 런타임 속성(Boolean) 대신 정성적인 서술형 제약(Textual Constraint) 유지
        require constraint :>> acceptanceCriteria {
            doc
            /* [설계 제약] 신규 제어기(AddEcu)의 추가 연동 시, 기존 EgasSystem의 핵심 제어 로직 소스코드는 변경 없이 인터페이스(Port) 확장만으로 통합이 가능해야 한다. */

            // 런타임 상태가 아니므로 무리하게 implies 수식으로 만들지 않고,
            // 요구사항 본문의 텍스트 명세로만 남겨두어 리뷰 기반 검증을 유도합니다.[cite: 2]
        }

        @Rationale {
            doc
            /* 신규 시스템 추가 시 전체 엔진 코어 로직에 미치는 영향을 최소화하여 재검증 비용을 낮춰야 함 */
        }

        frame concern architectureFlexibility : ArchitectureFlexibilityConcern;

        @MetaInformation {
            version = "v0.2";
        }
    }

    // ==========================================
    // 3. 프로젝트 및 비즈니스 관련 이해관계자 요구사항
    // ==========================================

    requirement <'SHR-P01'> reqIso26262SafetyCompliance : ProjectRelatedSR {
        doc
        /* 글로벌 자동차 기능 안전 표준(ISO 26262) 프로세스 준수 및 최고 안전 등급 인증 획득 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Validated;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "법무 및 규제 대응 팀 전략";

        // 문자열 속성을 제거하고 서술적 설계/프로세스 제약(Textual Constraint)으로 재정의
        require constraint :>> acceptanceCriteria {
            doc
            /* [프로세스/인증 제약] ISO 26262 ASIL-D 요구사항을 충족하는 산출물이 모두 작성되어 공인 외부 인증 기관의 감사를 통과해야 한다. */
            // 물리적 런타임 수식이 아니므로 doc 주석 형태의 텍스트 제약으로 명세함
        }

        @Rationale {
            doc
            /* 시장 진입 리스크 해소 및 대규모 리콜 사태를 원천 차단하기 위한 필수 비즈니스 제약 */
        }

        frame concern functionalSafety : FunctionalSafetyConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-P02'> reqEfficientPlatformDevelopment : ProjectRelatedSR {
        doc
        /* 코어 로직의 재사용성 극대화 및 테스트 자동화를 통한 차기 파생 모델 개발 시 R&D 리드타임 및 비용 절감 */

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "경영진 원가 절감 목표 (2025)";

        require constraint :>> acceptanceCriteria {
            doc
            /* [비즈니스 제약] 차기 파생 차종 소프트웨어 개발 시 코어 로직의 재사용률이 80.0% 이상을 달성하여 전체 개발 리드타임이 단축되어야 한다. */
            // 재사용률이라는 비즈니스 지표를 정량적으로 평가하기 위한 서술적 제약
        }
        @Rationale {
            doc
            /* 재검증 비용을 낮추고 신기술 적용 속도를 높여 비즈니스 경쟁력을 확보해야 함 */
        }

        frame concern architectureFlexibilityBiz : ArchitectureFlexibilityConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }
} // package EgasStakeholderRequirements
