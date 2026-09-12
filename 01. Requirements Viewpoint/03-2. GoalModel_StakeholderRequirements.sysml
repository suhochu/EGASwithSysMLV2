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

        @HardGoal;
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

        @Rationale {
            doc
            /* 양산 부품의 물리적 한계를 극복하고 목표 토크를 실제 엔진 동력으로 정확하게 변환해야 함 */
        }

        @MetaInformation {
            version = "v0.3";
        }

        @SoftGoal;
    }

    requirement <'SHR-02-1'> reqSteadyStatePrecision :> 'SHR-02' {
        doc
        /* 중재된 최종 목표 토크를 달성하기 위한 폐루프 정밀 제어 및 오버슈트 한계 준수 해야 한다. */

        require constraint :>> acceptanceCriteria {
            doc
            /* 실제 연소계 피드백의 정상 상태 오차(Steady-state error)가 2.0% 이하로 유지되어야 하며,
             * 목표 토크 도달 시 오버슈트(Overshoot)를 5.0% 이내로 제어해야 한다.
             */
            egas.combustionStatusPort.combustionStatus.steadyStateError <= 2.0 and
            egas.combustionStatusPort.combustionStatus.torqueOvershoot <= 5.0
        }

        @Rationale {
            doc
            /* 목표 토크를 실제 엔진 동력으로 정확하게 변환하기 위한 필수 정밀도 */
        }

        @MetaInformation {
            version = "v0.1";
        }

        @HardGoal;
    }

    requirement <'SHR-02-2'> reqMisfirePrevention :> 'SHR-02' {
        doc
        /* 하드웨어 마찰 및 지연 오차를 보정하여 엔진 실화(Misfire) 발생을 원천 차단 해야 한다. */

        require constraint :>> acceptanceCriteria {
            doc
            /* 액추에이터의 물리적 한계를 시스템이 보정하여 실화(Misfire)가 발생하지 않아야(0Hz) 하며,
             * 제어 명령 산출 후 액추에이터 최종 응답 지연이 10ms 이내여야 한다.
             */
            egas.combustionStatusPort.combustionStatus.misfireRate <= 0.0 [Hz] and
            egas.fuelCmdPort.fuelCmd.actuatorLatency <= 10.0 [milli * s]
        }

        @Rationale {
            doc
            /* 양산 부품의 물리적 한계를 극복하고 치명적인 연소 실패를 방지해야 함 */
        }

        @MetaInformation {
            version = "v0.1";
        }

        @HardGoal;
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
        @HardGoal;
    }

    requirement <'SHR-04'> reqDynamicResponsiveness : SystemRelatedSR {
        doc
        /* 운전자 조작 및 외부 제어기(ESP/TCU)의 긴급 개입 요구에 대한 지연 없는 즉각적이고 부드러운 토크 응답성 확보 */

        frame concern interventionResponse : TorqueInterventionResponsivenessConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "섀시 제어 부서(ESP/TCU) 협의 회의록";

        @Rationale {
            doc
            /* 빙판길 미끄럼 방지 등 긴급 제어의 실효성을 높이기 위해 매우 빠른 제어 응답성이 요구됨 */
        }

        @MetaInformation {
            version = "v0.3";
        }

        @SoftGoal;
    }

    requirement <'SHR-04-1'> reqTorqueInterventionByAirflow :> 'SHR-04' {
        doc
        /* 외부 제어기(ESP/TCU)의 긴급 개입 요구 시, 스로틀 공기량 저감을 통한 즉각적인 토크 응답성을 확보 해야 한다. */

        require constraint :>> acceptanceCriteria {
            doc
            /* ESP/TCU 토크 강제 저감 요청 시, 15ms 이내에 목표 공기량(massFlow)을 기존 상태보다 줄여 토크를 저감해야 한다. */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            (egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s] and
                egas.airIntakePort.airFlow.massFlow < egas.airIntakePort.airFlow.previousMassFlow)
        }

        @Rationale {
            doc
            /* [공기계 제어의 목적] 
             * 스로틀 밸브를 통한 공기량 제어는 연소 불안정(실화)이나 배출가스 급증 부작용 없이 
             * 가장 안정적이고 근본적으로 토크를 저감할 수 있는 1차적인 개입 수단이기 때문임.
             */
        }

        @HardGoal;
    }

    requirement <'SHR-04-2'> reqTorqueInterventionByFuelIgnition :> 'SHR-04' {
        doc
        /* 외부 제어기(ESP/TCU)의 긴급 개입 요구 시, 연료 분사 저감 및 점화 지각 제어를 통한 즉각적인 토크 응답성을 확보 해야 한다. */

        require constraint :>> acceptanceCriteria {
            doc
            /* ESP/TCU 토크 강제 저감 요청 시, 15ms 이내에 연료 분사 시간(Pulse Width)을 기존 상태보다 줄여 토크를 저감해야 한다. */
            egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m] implies
            (egas.torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s] and
                egas.fuelCmdPort.fuelCmd.injectionPulseWidth <
                egas.fuelCmdPort.fuelCmd.previousPulseWidth)
        }

        @Rationale {
            doc
            /* [연소계 제어의 목적]
             * 흡기 매니폴드의 구조적 체적으로 인해 공기량 제어만으로는 15ms 이내의 물리적 응답을 보장하기 어려우므로, 
             * 빙판길 미끄럼 방지나 변속 충격 완화와 같은 초단기 긴급 상황에서는 
             * 연소 사이클에 즉각 개입하는 연료 차단 및 점화 지각 제어가 필수적임.
             */
        }

        @HardGoal;
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

        @Rationale {
            doc
            /* 차량별 특성에 맞춰 엔지니어가 연소 효율을 극대화할 수 있는 인터페이스가 필요함 */
        }

        @MetaInformation {
            version = "v0.3";
        }

        @SoftGoal;
    }

    requirement <'SHR-05-1'> reqCalibrationMemoryAccess :> 'SHR-05' {
        doc
        /* 외부 캘리브레이션 툴의 유효한 메모리 접근 요청에 대한 통신 응답 및 접근 권한 통제 */

        require constraint :>> acceptanceCriteria {
            doc
            /* 외부 툴이 유효한 메모리 주소(targetMemoryAddress > 0)로 접근 시, 
             * 제어기는 정상 통신 상태 코드(200)를 반환하여 접근을 허용해야 한다.
             */
            egas.calibrationPort.calReq.targetMemoryAddress > 0 implies
            egas.calibrationPort.calStatus.responseCode == 200
        }

        @Rationale {
            doc
            /* 인가된 외부 장비가 제어기의 내부 변수 및 맵 데이터 영역에 원활하게 접속할 수 있도록 통신 상태를 보장해야 함 */
        }
        @HardGoal;
    }

    requirement <'SHR-05-2'> reqCalibrationDataIntegrity :> 'SHR-05' {
        doc
        /* 연료 분사 및 점화 제어 맵(Map) 데이터 업데이트 시 메모리 무결성(Integrity) 확보 */

        require constraint :>> acceptanceCriteria {
            doc
            /* 파라미터 튜닝 데이터가 기록된 후, 제어기는 자체적인 검증을 거쳐 
             * 유효한 메모리 체크섬(verifiedChecksum > 0)을 반환해야 한다.
             */
            egas.calibrationPort.calReq.targetMemoryAddress > 0 implies
            egas.calibrationPort.calStatus.verifiedChecksum > 0
        }

        @Rationale {
            doc
            /* 통신 노이즈나 패킷 손실로 인해 오염된 제어 맵 데이터가 덮어씌워져 엔진이 오작동 및 파손되는 것을 원천 방지해야 함 */
        }
        @HardGoal;
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
            /* 물리적 결함(냉각수 온도 초과 등)이 존재할 때 ReadDTC(serviceId == 1) 요청이 들어오면 정상 응답(200)과 함께 유효한 DTC 코드(0 초과)를 반환해야 하며, 
             * 영점 조정(serviceId == 2) 요청 시 추가 프로그래밍 없이 정상 응답(200)을 반환해야 한다.
             */

            // 1. 물리적 이상 시 DTC 읽기 요청(serviceId == 1)에 대한 응답 제약
            (egas.sensorPort.sensorData.coolantTemp > 120.0 ['°'] and
                egas.diagPort.diagReq.serviceId == 1) implies
            (egas.diagPort.diagStatus.responseCode == 200 and
                egas.diagPort.diagStatus.dtcCode > 0 and
                (// 2. 영점 조정 요청(serviceId == 2)에 대한 완료 응답 제약
                    egas.diagPort.diagReq.serviceId == 2 implies
                    egas.diagPort.diagStatus.responseCode == 200))
        }

        @Rationale {
            doc
            /* 서비스 센터 현장에서의 수리 시간 단축 및 유지보수 편의성이 보장되어야 함 */
        }

        frame concern diagnostics : DiagnosticsAndMaintenanceConcern;

        @MetaInformation {
            version = "v0.3";
        }

        @HardGoal;
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

        @SoftGoal;
    }

    requirement <'SHR-08'> reqDriverPedalResponsiveness : SystemRelatedSR {
        doc
        /* 운전자의 가속 페달 조작 시 지연 없는 즉각적이고 이질감 없는 차량 가속 반응 확보 */

        // 정성적 소프트 골이었던 DrivabilityAndResponseConcern을 근거로 삼음
        frame concern drivability : DrivabilityAndResponseConcern;

        :>> priorityLevel = PriorityLevel::High;
        :>> criticalityLevel = CriticalityLevel::Major;
        :>> reqValidationStatus = ReqValidationStatus::Draft;
        :>> author = ProjectMember::suhoChu;
        :>> owner = ProjectMember::suhoChu;
        :>> traceToSource = "차량 동역학 및 인간공학 평가 기준서";

        require constraint :>> acceptanceCriteria {
            doc
            /* 1. 가속 페달 입력이 0을 초과하여 발생할 경우, 시스템은 50ms 이내에 입력을 처리해야 한다.
             * 2. 가속 시 탑승자가 이질감을 느끼지 않도록 종방향 가속도 변화율(Jerk)은 10.0 m/s³ 이하로 제한되어야 한다.
             */

            // 조건 1: Latency 제약 (50ms 이하)
            egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm] implies
            (egas.accelPort.accelIntent.latency <= 50.0 [milli * s] and
                // 조건 2: 승차감 확보를 위한 Jerk 제약 (10.0 이하)
                // (EgasSystem에 dynamicsFeedbackPort가 추가되었다고 가정)
                egas.dynamicsFeedbackPort.dynamicsStatus.longitudinalJerk <= 10.0)
        }

        @Rationale {
            doc
            /* 인간의 인지 한계(약 50ms~100ms)보다 빠른 시스템 응답성을 확보하고,
             * 급격한 스로틀 밸브 개방으로 인한 차량의 울컥거림(Jerk)을 물리적으로 억제해야 함
             */
        }

        @HardGoal;
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

        @SoftGoal;
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

        @SoftGoal;
    }
} // package EgasStakeholderRequirements
