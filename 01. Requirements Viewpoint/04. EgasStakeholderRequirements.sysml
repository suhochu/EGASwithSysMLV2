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

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 이해관계자 요구사항 전용 특성 및 타입 정의
    // ==========================================

    requirement def StakeholderRequirement {
        doc
        /* 기술적 명세가 아닌, 이해관계자의 비즈니스/운용 니즈와 인수 조건을 대변하는 요구사항 */

        attribute priorityLevel : PriorityLevel [1];
        attribute criticalityLevel : CriticalityLevel [1];
        attribute reqValidationStatus : ReqValidationStatus [1];

        attribute acceptanceCriteria : String [1]; // 사용자 관점의 인수 조건
        attribute validationMethod : ValidationMethod [1];

        attribute author : ProjectMember;
        attribute owner : ProjectMember;
        attribute traceToSource : String [1..*];
    }

    requirement def SystemRelatedSR :> StakeholderRequirement;
    requirement def ProjectRelatedSR :> StakeholderRequirement;

    // ==========================================
    // 2. 이해관계자 요구사항 목록 (기존 OBJ-S, OBJ-P 변환)
    // ==========================================

    requirement <'SHR-01'> reqSafeTorqueArbitration : SystemRelatedSR {
        doc
        /* 다중 토크 요구에 대한 안전 최우선 중재 및 제동 오버라이드(Brake Override) 실행 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::InReview;

        :>> acceptanceCriteria =
            "가속/제동 동시 조작 시, 차량이 브레이크 의도를 최우선으로 하여 즉각적으로 감속함을 체감할 수 있어야 함";
        :>> validationMethod = ValidationMethod::UserAcceptanceTest;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "NHTSA 급발진 방지 가이드라인";

        @Rationale {
            doc
            /* 가속 페달, 크루즈 컨트롤, 외부 제어기의 요구가 상충될 때 주행 안정성을 최우선으로 확보해야 함 */
        }

        frame concern torqueArbitration : TorqueArbitrationConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-02'> reqPreciseClosedLoopControl : SystemRelatedSR {
        doc
        /* 하드웨어 오차를 보정하여 중재된 최종 목표 토크를 달성하기 위한 스로틀 밸브 및 연료/점화계의 폐루프 정밀 제어 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;

        :>> acceptanceCriteria =
            "다양한 환경 조건에서 하드웨어 한계를 시스템이 보정하여 운전자가 요구한 동력을 오차 없이 제공함을 확인";
        :>> validationMethod = ValidationMethod::OperationalDemonstration;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "엔진 부품 공급사(Tier 1) 인터뷰";

        @Rationale {
            doc
            /* 양산 부품의 물리적 한계를 극복하고 목표 토크를 실제 엔진 동력으로 정확하게 변환해야 함 */
        }

        frame concern preciseControl : PreciseControlConcern;
        frame concern hardwareTolerance : HardwareToleranceHandlingConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-03'> reqFailSafeSensorMonitoring : SystemRelatedSR {
        doc
        /* 이중화 센서(PVS, TPS) 실시간 모니터링을 통한 액추에이터 고장 진단 및 페일세이프(Fail-safe) 구현 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Critical;
        :>> reqValidationStatus = ReqValidationStatus::Validated;

        :>> acceptanceCriteria =
            "센서 또는 액추에이터 결함 발생 시 급발진 없이 즉각 엔진 구동을 차단하고 안전 상태로 전환됨을 시연";
        :>> validationMethod = ValidationMethod::ExpertReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "ISO 26262 기능안전 요구사항";

        @Rationale {
            doc
            /* 단일 결함이 치명적 사고로 이어지지 않도록 안전 상태를 보장해야 함 */
        }

        frame concern hardwareFailure : HardwareFailureConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-04'> reqDynamicResponsiveness : SystemRelatedSR {
        doc
        /* 운전자 조작 및 외부 제어기(ESP/TCU)의 긴급 개입 요구에 대한 지연 없는 즉각적이고 부드러운 토크 응답성 확보 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;

        :>> acceptanceCriteria =
            "ESP/TCU 등 외부 제어기의 토크 개입 시 이질감이나 딜레이 없이 차량 거동이 즉각 안정화됨을 트랙 테스트로 확인";
        :>> validationMethod = ValidationMethod::UserAcceptanceTest;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "섀시 제어 부서(ESP/TCU) 협의 회의록";

        @Rationale {
            doc
            /* 빙판길 미끄럼 방지 등 긴급 제어의 실효성을 높이기 위해 매우 빠른 제어 응답성이 요구됨 */
        }

        frame concern drivability : DrivabilityAndResponseConcern;
        frame concern interventionResponse : TorqueInterventionResponsivenessConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-05'> reqPowertrainCalibrationSupport : SystemRelatedSR {
        doc
        /* 엔진 성능 및 배출가스 최적화를 위한 연료 분사 및 점화 제어 맵(Map)의 정밀 튜닝 환경 제공 */

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;

        :>> acceptanceCriteria =
            "표준 툴을 통해 제어 맵에 접근하여 목표 토크 변환 과정을 정밀하게 튜닝할 수 있음을 벤치 테스트로 검증";
        :>> validationMethod = ValidationMethod::OperationalDemonstration;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "캘리브레이션 엔지니어링 팀 요구사항";

        @Rationale {
            doc
            /* 차량별 특성에 맞춰 엔지니어가 연소 효율을 극대화할 수 있는 인터페이스가 필요함 */
        }

        frame concern calibration : PowertrainCalibrationConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-06'> reqDiagnosticAndMaintenanceSupport : SystemRelatedSR {
        doc
        /* 시스템 결함 시 명확한 고장 진단 코드(DTC) 제공 및 부품 교체 후 용이한 영점 조정 프로세스 지원 */

        :>> priorityLevel = PriorityLevel::Medium;
        :>> criticalityLevel = CriticalityLevel::Minor;
        :>> reqValidationStatus = ReqValidationStatus::Draft;

        :>> acceptanceCriteria =
            "고장 발생 시 정확한 DTC가 출력되며, 부품 교체 후 진단기를 통한 영점 조정이 추가 프로그래밍 없이 원활히 수행됨을 시연";
        :>> validationMethod = ValidationMethod::OperationalDemonstration;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "A/S 서비스 센터 VOC 리포트";

        @Rationale {
            doc
            /* 서비스 센터 현장에서의 수리 시간 단축 및 유지보수 편의성이 보장되어야 함 */
        }

        frame concern diagnostics : DiagnosticsAndMaintenanceConcern;

        @MetaInformation {
            version = "v0.1";
        }
    }

    requirement <'SHR-07'> reqModularInterfaceArchitecture : SystemRelatedSR {
        doc
        /* 다양한 파생 차종 및 신규 제어기(자율주행 등)와의 연동을 견고하게 지원하는 표준화된 모듈형 아키텍처 구축 */

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::InReview;

        :>> acceptanceCriteria =
            "신규 제어기 추가 시 코어 엔진 로직의 소스코드 변경 없이 표준 인터페이스만으로 연동 통합이 가능함을 아키텍처 리뷰로 확인";
        :>> validationMethod = ValidationMethod::ExpertReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "R&D 플랫폼 아키텍처 가이드라인";

        @Rationale {
            doc
            /* 신규 시스템 추가 시 전체 엔진 코어 로직에 미치는 영향을 최소화하여 재검증 비용을 낮춰야 함 */
        }

        frame concern architectureFlexibility : ArchitectureFlexibilityConcern;

        @MetaInformation {
            version = "v0.1";
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

        :>> acceptanceCriteria =
            "ISO 26262 ASIL-D 요구사항을 충족하는 산출물이 모두 작성되어 공인 외부 인증 기관의 감사를 통과함";
        :>> validationMethod = ValidationMethod::ExpertReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "법무 및 규제 대응 팀 전략";

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

        :>> acceptanceCriteria =
            "차기 파생 차종 소프트웨어 개발 시 코어 로직의 재사용률이 80% 이상을 달성하여 전체 개발 리드타임이 단축됨을 확인";
        :>> validationMethod = ValidationMethod::ExpertReview;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "경영진 원가 절감 목표 (2025)";

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
