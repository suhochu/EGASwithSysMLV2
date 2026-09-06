package EgasSystemStakeHolders {
    doc
    /* [이해관계자 및 우려사항 뷰포인트]
     * "누가" EGAS 시스템에 관심을 갖는지(이해관계자, 2번 섹션)와, 그들이 "무엇을" 우려하는지(우려사항/Concern, 3번 섹션)를 정의한다.
     * 각 Concern은 01번 파일의 'OBJ-IDEA' 목표를 `:>` 특화(specialization)하여, "목표 → 우려사항" 상향 추적성을 이루며,
     * 04번 파일의 이해관계자 요구사항(SHR)이 `frame concern`으로 이 Concern들을 근거로 삼는다.
     */
    // ModelingMetadata 패키지의 요소(Rationale 등)를 사용하기 위해 import
    private import ModelingMetadata::*;
    private import ScalarValues::*;
    private import EgasSystemContext::EgasSystem;
    private import SystemObjectives::*;
    private import ReqCommon::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 이해관계자 관련 기본 요소 정의
    // ==========================================

    part def EgasStakeholder {
        attribute priority : StakeholderPriorityKind; // 이해관계자의 요구사항 누락 시 시스템 실패에 미치는 영향력(Criticality) 기준
        attribute effort : ElicitationEffortKind; // 요구사항을 도출하고 시스템 설계에 반영하기 위해 필요한 노력(시간, 자원, 복잡도) 기준
        attribute category : StakeholderCategoryKind; // 이해관계자가 시스템 수명주기(Lifecycle) 및 비즈니스 생태계에서 담당하는 역할 기준
    }

    enum def StakeholderPriorityKind {
        Critical; // 요구사항 누락 시 프로젝트가 즉각 실패하거나 법적/안전상 치명적 제재를 받는 핵심 주체 (예: 규제 기관, 투자자, 핵심 의사결정권자).
        High; // 시스템 수용성과 비즈니스 가치에 직접적인 영향을 미치는 주요 주체 (예: 주 사용층, 도메인 전문가).
        Medium; // 시스템과 상호작용하지만 프로젝트 방향성을 일방적으로 변경할 권한은 없는 주체 (예: 2차 사용자, 간접 연계 시스템 담당자).
        Low; // 시스템 결과에 관심은 있으나 요구사항 반영 우선순위가 가장 낮은 주체.
    }

    enum def ElicitationEffortKind {
        High; // 요구사항이 매우 모호하거나, 상충되는 의견을 조율하기 위해 다수의 워크샵과 프로토타이핑이 필요한 경우.
        Medium; // 표준적인 인터뷰, 설문, 기존 문서 분석을 통해 요구사항을 도출하고 설계에 반영할 수 있는 일반적인 수준.
        Low; // 이미 명확한 국제 표준(예: ISO 26262), 법규, 또는 기존 레거시 시스템의 사양서가 존재하여 요구사항을 단순히 추출 및 차용하면 되는 경우.
    }

    enum def StakeholderCategoryKind {
        EndUser; // 시스템을 직접 조작하고 경험하는 주체 (예: 운전자, 승객).
        RegulatoryAuthority; // 법적 제재, 표준 준수(ISO 26262), 형식 승인을 담당하는 주체 (예: 국토교통부, TÜV 등 외부 평가 기관).
        DeveloperEngineering; // 시스템을 직접 설계, 구현, 테스트하는 내부 주체 (예: 플랫폼 엔지니어, 시스템 아키텍트, SW/HW 개발자).
        AcquirerCustomer; // 시스템 개발을 의뢰하거나 비즈니스적 가치를 평가하는 주체 (예: 완성차 OEM, 제품 관리자(PM)).
        SupplierPartner; // 시스템에 연동되는 외부 부품이나 하위 모듈을 제공하는 주체 (예: Tier 1/2 센서 공급사, 변속기(TCU) 제조사).
        MaintenanceSupport; // 시스템 출시 후 수리, 정비, 업데이트를 담당하는 주체 (예: 정비소 미캐닉, 서비스 센터).
    }

    // ==========================================
    // 2. 이해관계자 정의
    // ==========================================

    part def Driver :> EgasStakeholder {
        doc
        /* 운전자 (Brake, CC-Control Lever, Acceleration Pedal 직접 조작)
         * 주행 중 가속, 제동, 크루즈 컨트롤 조작 시 이질감 없는 즉각적이고 예측 가능한 차량 반응 확보 우려
         */
        :>> category = StakeholderCategoryKind::EndUser;
        :>> priority = StakeholderPriorityKind::Critical;
        :>> effort = ElicitationEffortKind::High;

        @MetaInformation {
            version = "v0.1";
        }
    }
    part def SafetyRegulator :> EgasStakeholder {
        doc
        /* 안전 규제 기관 (전체 시스템의 페일세이프 및 신뢰성)
         * ISO 26262 기능 안전 규격 준수 및 하드웨어 센서 고장(단선/단락) 시 페일세이프(Fail-safe) 전환 신뢰성 우려
         */
        :>> category = StakeholderCategoryKind::RegulatoryAuthority;
        :>> priority = StakeholderPriorityKind::Critical;
        :>> effort = ElicitationEffortKind::Low;

        @MetaInformation {
            version = "v0.1";
        }
    }

    part def PlatformEngineer :> EgasStakeholder {
        doc
        /* 플랫폼 엔지니어 / 시스템 아키텍트 (ECU 중심의 전체 아키텍처)
         * 외부 제어기(TCU, ESP)와의 모듈화된 인터페이스 구축 및 다중 제어 개입 시 안정적인 토크 중재 아키텍처 확보 우려
         */
        :>> category = StakeholderCategoryKind::DeveloperEngineering;
        :>> priority = StakeholderPriorityKind::High;
        :>> effort = ElicitationEffortKind::Medium;

        @MetaInformation {
            version = "v0.1";
        }
    }

    part def CalibrationEngineer :> EgasStakeholder {
        doc
        /* 파워트레인 캘리브레이션 엔지니어 (Fuel Injection Ignition System, Throttle Valve 연동)
         * 차량 성능 및 배출가스 최적화를 위해 목표 토크를 실제 연료 분사량 및 점화 시기로 변환하는 ECU 맵(Map)의 정밀 튜닝 가능성 우려
         */
        :>> category = StakeholderCategoryKind::DeveloperEngineering;
        :>> priority = StakeholderPriorityKind::High;
        :>> effort = ElicitationEffortKind::High;

        @MetaInformation {
            version = "v0.1";
        }
    }

    part def AddEcuDeveloper :> EgasStakeholder {
        doc
        /* 능동 안전 및 섀시 제어기 개발자 (Add. ECU with Torque Request)
         * 주행 안정성 제어(ESP) 또는 변속 충격 완화(TCU)를 위해 EGAS 시스템에 토크 개입(Torque Intervention) 요청 시, 요구 토크의 즉각적이고 정확한 반영 여부 우려
         */
        :>> category = StakeholderCategoryKind::SupplierPartner;
        :>> priority = StakeholderPriorityKind::High;
        :>> effort = ElicitationEffortKind::Medium;

        @MetaInformation {
            version = "v0.1";
        }
    }

    part def HardwareSupplier :> EgasStakeholder {
        doc
        /* 센서 및 구동계 부품 공급사 (Add. Sensors, Throttle Valve 하드웨어)
         * 제공된 센서 및 스로틀 모터 하드웨어의 물리적 한계(응답 지연, 허용 오차)가 ECU 제어 주기 내에서 정상적으로 수용 및 보정되는지에 대한 우려
         */
        :>> category = StakeholderCategoryKind::SupplierPartner;
        :>> priority = StakeholderPriorityKind::Medium;
        :>> effort = ElicitationEffortKind::Medium;

        @MetaInformation {
            version = "v0.1";
        }
    }

    part def ServiceMechanic :> EgasStakeholder {
        doc
        /* 정비 및 서비스 기술자 (전체 EGAS-System 유지보수 및 진단)
         * 가속 페달 센서(PVS)나 스로틀 밸브(TPS) 고장 발생 시 명확한 고장 진단 코드(DTC) 출력 및 부품 교체 후 영점 조정(Calibration)의 용이성 확보 우려
         */
        :>> category = StakeholderCategoryKind::MaintenanceSupport;
        :>> priority = StakeholderPriorityKind::Medium;
        :>> effort = ElicitationEffortKind::Low;

        @MetaInformation {
            version = "v0.1";
        }
    }

    // ==========================================
    // 3. 이해관계자의 우려사항(Concern) 정의
    // ==========================================

    concern def TorqueArbitrationConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder driver : Driver;
        require constraint {
            doc
            /* 다중 토크 요구 상충 및 가속/제동 동시 조작 상황에서도 차량의 주행 통제권을 상실하지 않아야 한다. */
        }
        @Rationale {
            doc
            /* [사용자 입력 우선순위 및 중재]
             * 운전자, 크루즈 컨트롤, 외부 제어기 등 다양한 소스의 토크 요구가 충돌할 때 안전한 주행 상태를 보장할 수 있는 중재 메커니즘이 부재함
             */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def PreciseControlConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder driver : Driver;
        require constraint {
            doc
            /* 요구 토크와 실제 물리적 엔진 동력 간의 오차를 최소화하여 정확하고 지연 없이 제어해야 한다. */
        }
        @Rationale {
            doc
            /* [제어 정확성] 
             * 다양한 환경 변수 속에서도 시스템이 산출한 목표 토크를 실제 엔진에서 정확하고 지연 없이 구현해야 함
             */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def DrivabilityAndResponseConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder driver : Driver;
        require constraint {
            doc
            /* 운전자의 페달 조작에 대해 이질감 없이 즉각적이고 예측 가능한 차량 반응을 제공해야 한다 */
        }
        @Rationale {
            doc
            /* [주행 감성 및 반응성 : 제어 오차와 구별되는 인지적 관점]
             * 운전자의 물리적 페달 조작이 전자 신호로 변환되어 실제 엔진 동력으로 이어지는 과정에서 지연이나 비선형적인 반응이 발생하면 운전자가 불안감이나 피로를 느낄 수 있음
             */
        }
        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def HardwareFailureConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder safetyRegulator : SafetyRegulator;
        require constraint {
            doc
            /* 센서 및 액추에이터의 기계적/전기적 결함 발생 시 급발진 등 치명적인 사고로 이어지지 않도록 안전 상태(Safe State)를 보장해야 한다. */
        }
        @Rationale {
            doc
            /* [결함 방지]
             * 단일 센서나 구동계 고장이 차량의 급발진이나 시동 꺼짐 등 대형 사고로 직결될 수 있는 위험이 존재함
             */
        }
        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def FunctionalSafetyConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder safetyRegulator : SafetyRegulator;
        require constraint {
            doc
            /* 시스템의 결함이 인명 사고로 이어지지 않도록 자동차 기능 안전 규격(ISO 26262 등)을 준수하고 입증해야 한다. */
        }
        @Rationale {
            doc
            /* [표준 준수] 
             * 엔진 제어 시스템의 치명적인 오류는 제조사에 막대한 법적, 경제적 타격을 입힐 수 있으므로 글로벌 안전 표준 입증이 필수적임
             */
        }
        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def ArchitectureFlexibilityConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder systemArchitect : PlatformEngineer;
        require constraint {
            doc
            /* 파생 차종 및 신기술(자율주행 등) 도입 시 코어 로직의 재검증과 R&D 비용을 최소화할 수 있도록 아키텍처의 확장성과 유연성을 확보해야 한다. */
        }
        @Rationale {
            doc
            /* [아키텍처 유연성]
             * 기능이 강하게 결합되어 있을 경우, 새로운 제어기의 인터페이스를 추가할 때마다 코어 로직 전체를 재검증해야 하는 비효율이 발생함
             */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def PowertrainCalibrationConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder calibrationEngieer : CalibrationEngineer;
        require constraint {
            doc
            /* 차량 성능 및 배출가스 최적화를 위해 연료 분사량 및 점화 시기 제어 맵(Map)을 정밀하게 튜닝할 수 있어야 한다. */
        }
        @Rationale {
            doc
            /* [튜닝 정밀도] 
             * 산출된 목표 토크를 실제 연료 분사량 및 점화 시기로 변환하는 과정에서, 온도 및 기압 등 다양한 환경 변수를 반영하여 엔지니어가 미세 조정할 수 있는 제어 변수가 확보되어야 함
             */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def TorqueInterventionResponsivenessConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder addEcuDeveloper : AddEcuDeveloper;
        require constraint {
            doc
            /* 주행 안정성(ESP) 및 변속 제어(TCU)를 위한 외부의 긴급 토크 개입 요청을 지연 없이 즉각적으로 엔진 출력에 반영해야 한다. */
        }
        @Rationale {
            doc
            /* [시스템 간 통신 응답성]
             * 빙판길 미끄럼 방지나 변속 충격 완화를 위한 토크 저감/제한 요청은 밀리초(ms) 단위의 빠른 응답성을 요구하므로, EGAS 시스템의 수신 및 처리 지연이 없어야 함
             */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def HardwareToleranceHandlingConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder hardwareSuppler : HardwareSupplier;
        require constraint {
            doc
            /* 양산 센서 및 액추에이터 하드웨어의 물리적 한계 및 허용 오차를 폐루프 제어를 통해 안정적으로 수용하고 보정해야 한다. */
        }
        @Rationale {
            doc
            /* [ 물리적 한계 보정]
             * 양산 부품 특성상 불가피하게 발생하는 기계적 마찰, 센서 노이즈, 모터 응답 지연 등을 ECU의 폐루프 제어(Closed-loop control) 로직이 흡수하고 보정할 수 있어야 함
             */
        }

        @MetaInformation {
            version = "v0.1";
        }
    }

    concern def DiagnosticsAndMaintenanceConcern :> EgasSystemIdea {
        subject egasSystem : EgasSystem;
        stakeholder serviceMechanic : ServiceMechanic;
        require constraint {
            doc
            /* 시스템 고장 발생 시 명확한 진단 코드(DTC)를 출력하고, 하드웨어 부품 교체 후 영점 조정(Calibration) 프로세스가 용이해야 한다. */
        }
        @Rationale {
            doc
            /* [유지보수 및 진단 용이성]
             * 정비 현장에서 가속 페달 센서나 스로틀 밸브의 결함을 OBD 단자를 통해 빠르고 정확하게 진단해야 하며, 하드웨어 교체 시 ECU가 새로운 부품 특성을 쉽게 학습할 수 있어야 수리 시간이 단축됨
             */
        }
        @MetaInformation {
            version = "v0.1";
        }
    }
} // package EgasSystemStakeHolders
