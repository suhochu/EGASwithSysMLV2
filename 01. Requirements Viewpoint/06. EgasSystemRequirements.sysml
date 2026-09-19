package EgasSystem_Requirements {
    doc
    /* [시스템 요구사항 뷰포인트]
     * SHR-xx(04번 파일)를 `traceToParent`로 상위 추적하고, `satisfy requirement ... by ...`로
     * 05번 파일의 유스케이스/액티비티에서 하향 실현되는 SYSR-xx를 정의한다.
     * 각 SYSR은 99번 파일의 공식 제약 템플릿(OverrideRequirement/RedundancyDeviationRequirement/
     * PerformanceTimingRequirement)를 재사용하여 `assume`/`require` 제약을 정량적으로 명시하므로,
     * 검증(V&V) 가능한 형태로 작성되어 있다.
     */
    private import ScalarValues::*;
    private import RV_Objectives::*;
    private import ModelingMetadata::Rationale;
    private import Requirements::*;
    private import ReqCommon::*;
    private import SensmetryRequirementTemplates::*;
    private import RV_ContextModel::*;
    private import RV_StakeholderRequirementModel::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. SYSMOD 요구사항 메타데이터 구조 정의부
    // ==========================================
    requirement def SystemRequirement {
        attribute priorityLevel : PriorityLevel [1]; // Priority (우선순위) 비즈니스적 가치나 구현의 시급성을 나타냅니다.
        attribute criticalityLevel : CriticalityLevel [1]; // Criticality (치명도/필수성) 요구사항 미충족 시 시스템 안전 및 기능에 미치는 영향을 나타냅니다.
        attribute risks : RiskMetadata::RiskLevelEnum [1]; // Risk of Implementation (구현 리스크), 기술적 난이도 및 일정 지연 위험도를 나타냅니다.
        attribute reqVerificationStatus : ReqVerificationStatus [1]; // Need/Requirement Verification Status (작성 검증 상태) 요구사항 문장 자체가 표준 구문(Syntax)에 맞게 잘 작성되었는지 품질 상태를 나타냅니다.
        attribute reqValidationStatus : ReqValidationStatus [1]; // Need/Requirement Validation Status (유효성 확인 상태) 요구사항이 이해관계자의 실제 니즈를 올바르게 대변하고 있는지 상태를 나타냅니다.
        ref occurrence allocationBudget [*]; // Allocation/Budgeting (할당 및 성능 예산) 어떤 하위 시스템이나 컴포넌트에 배분되었는지 명시합니다.
        attribute successCriteria : String [1]; // V&V Success Criteria (성공 기준) 객관적으로 판별할 수 있는 구체적이고 정량적인 합격/실패 조건을 기술합니다.
        case vvStrategy [1]; // V&V Strategy (검증 전략)  해당 요구사항 실현을 검증하기 위한 전반적인 테스트 시나리오 및 전략을 기재합니다.
        attribute vvMethod : VVMethod [1]; // V&V Method (검증 방법) 위에서 정의한 4가지 Enum 값 중 하나를 선택하도록 강제합니다.
        attribute vvResponsibleOrganization : String [1]; // V&V Responsible Organization (담당 조직) 검증을 수행하고 승인할 부서 또는 담당자 이름을 명시합니다.
        attribute author : ProjectMember;
        attribute owner : ProjectMember;
        ref requirement traceToParent [0..*]; // Trace to Parent (상위 추적성)  이 요구사항이 파생된 상위 요구사항을 직접 참조(Reference)합니다.최상위 요구사항일 가능성을 고려하여 [0..*]로 하거나, 무조건 파생되게 하려면 [1..*]로 설정합니다.
        attribute traceToSource : String [1..*]; // Trace to Source (출처 추적성) 요구사항이 도출된 원천(문서 번호, 규제 링크, 고객 인터뷰 날짜 등)을 문자열로 기입합니다. 최소 1개 이상의 출처를 반드시 명시하도록 [1..*]로 강제합니다.
    }

    // 시스템 기능 요구 사항
    requirement def FunctionSR :> SystemRequirement;
    requirement def ControlAndAlgorithm :> FunctionSR;
    requirement def ModeAndState :> FunctionSR;
    requirement def Diagnostics :> FunctionSR;
    requirement def FunctionalSafety :> FunctionSR;
    requirement def Interface :> FunctionSR;
    requirement def DataMgt :> FunctionSR;

    // 시스템 비기능 요구 사항
    requirement def NonFunctionSR :> SystemRequirement;
    requirement def PerformanceNSR :> NonFunctionSR; // 응답 속도, 처리량 관련
    requirement def ReliabilityNSR :> NonFunctionSR; // 가용성, 고장률 관련
    requirement def SafetyNSR :> NonFunctionSR; // 물리적 안전 및 페일세이프 관련
    requirement def SecurityNSR :> NonFunctionSR; // 데이터 보호 및 인증 관련
    requirement def MaintainabilityNSR :> NonFunctionSR; // 유지보수, 확장, OTA 관련
    requirement def UsabilityNSR :> NonFunctionSR; // 사용자 경험(UX) 및 조작 관련
    requirement def EnvironmentalNSR :> NonFunctionSR; // 전력, 온도, 물리적 크기 제약

    package Functional_Safety_Requirements {
        // ==========================================
        // SYSR-01a: 브레이크 오버라이드 제어 로직 (기능/안전 요구사항)
        // ==========================================
        requirement <'SYSR-01a'> reqBrakeOverrideLogic : FunctionalSafety, OverrideRequirement {
            doc
            /* When both {primaryInputActive} and {overrideInputActive} are true, the {outputValue} must be limited to {safeLimit}. */

            subject ecu : EngineControlUnit;
            stakeholder driver : RV_StakeHolderModel::Driver;
            stakeholder regulator : RV_StakeHolderModel::SafetyRegulator;

            // [Template: OverrideRequirement 속성]
            attribute :>> primaryInputActive; // 가속 페달 입력 상태
            attribute :>> overrideInputActive; // 브레이크 페달 입력 상태
            attribute :>> outputValue; // 산출된 최종 목표 토크
            attribute :>> safeLimit = 0.0; // 강제 제한 토크량

            assume constraint {
                doc
                /* 제어기는 정상 동작 상태이며, 페달 센서로부터 유효한 신호가 인가된다고 가정한다. */
                safeLimit == 0.0
            }

            require constraint {
                doc
                /* 가속과 제동이 동시에 입력될 경우, 최종 산출 토크를 안전 한계 이하로 강제 제한해야 한다. */
                (primaryInputActive and overrideInputActive) implies outputValue <= safeLimit
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Critical;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = ecu;
            :>> successCriteria = "동시 입력 시 산출 토크가 0.0으로 제한됨을 확인";

            case :>> vvStrategy {
                doc
                /* 물리적 브레이크 압력과 PVS 신호 동시 주입을 통한 로직 검증 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Verification Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqSafeTorqueArbitration;  
            :>> traceToSource = "NHTSA 급발진 방지 가이드라인";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-04: 스로틀 폐루프 제어 정밀도 (기능/안전 요구사항)
        // ==========================================
        requirement <'SYSR-04'> reqThrottleClosedLoopAccuracy
            : ControlAndAlgorithm, RedundancyDeviationRequirement {
            doc
            /* If the absolute difference between {channel1} and {channel2} exceeds {maxDeviation}, {faultFlag} must be asserted true. */

            subject ecu : EngineControlUnit;
            ref part throttle : ThrottleValve;

            stakeholder hardwareSupplier : RV_StakeHolderModel::HardwareSupplier;
            stakeholder calibrationEng : RV_StakeHolderModel::CalibrationEngineer;

            // [Template: RedundancyDeviationRequirement 속성]
            attribute :>> channel1; // ThrottlePositionCommand (목표값)
            attribute :>> channel2; // ThrottlePositionFeedback (실제값)
            attribute :>> maxDeviation = 2.0; // 폐루프 제어 허용 오차 2.0%
            attribute :>> faultFlag; // 제어 오차 한계 초과 플래그

            assume constraint {
                doc
                /* 목표 개도각과 실제 개도각 간의 최대 허용 편차는 2.0%로 고정된다. */
                maxDeviation == 2.0
            }

            require constraint {
                doc
                /* 부하 변동 시 목표값과 실제값의 오차가 ±2.0%를 초과할 경우 고장 플래그 활성화 */
                (channel1 - channel2 > maxDeviation or channel2 - channel1 > maxDeviation) implies
                faultFlag == true
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::InReview;

            :>> allocationBudget = (ecu, throttle);
            :>> successCriteria = "부하 변동 시 정상 상태(Steady-state) 오차가 ±2.0% 이내로 수렴함";

            case :>> vvStrategy {
                doc
                /* 동력계(Dynamometer) 환경에서 스텝 입력 인가 및 제어 정밀도 분석 */
            }
            :>> vvMethod = VVMethod::Analysis;
            :>> vvResponsibleOrganization = "Powertrain Calibration Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = (
                stakeholderRequirementSet.reqPreciseClosedLoopControl, stakeholderRequirementSet.reqSteadyStatePrecision
            );
            :>> traceToSource = "엔진 부품 공급사(Tier 1) 인터뷰";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-07: 복합 고장 발생 시 강제 전환 (기능/안전 요구사항)
        // ==========================================
        requirement <'SYSR-07'> reqSafeStateEnforcementOnFault
            : FunctionalSafety, OverrideRequirement {
            doc
            /* When both {primaryInputActive} and {overrideInputActive} are true, the {outputValue} must be limited to {safeLimit}. */

            subject ecu : EngineControlUnit;
            stakeholder regulator : RV_StakeHolderModel::SafetyRegulator;

            // [Template: OverrideRequirement 속성]
            attribute :>> primaryInputActive; // 목표 토크 생성(요구) 상태
            attribute :>> overrideInputActive; // 스로틀 또는 연소 구동계 고장 플래그 활성화 상태
            attribute :>> outputValue; // 최종 출력 토크 (limitedTorque)
            attribute :>> safeLimit = 0.0; // 강제 차단 한계 (0.0 토크)

            assume constraint {
                doc
                /* 안전 상태(Safe State) 진입 시 강제되는 토크 한계치는 0.0으로 고정된다. */
                safeLimit == 0.0
            }

            require constraint {
                doc
                /* 스로틀 또는 연소 구동계에 고장이 감지되면, 요구 토크의 크기와 무관하게 출력을 0.0으로 즉시 차단해야 한다. */
                (primaryInputActive and overrideInputActive) implies outputValue <= safeLimit
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Critical;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "스로틀/연료계 고장 플래그 발동 시 최종 토크 출력이 0.0으로 차단됨을 1,000회 검증";

            case :>> vvStrategy {
                doc
                /* HILS 환경에서 구동계 고장 플래그 강제 활성화 시 토크 출력 모니터링 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Verification Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqFailSafeSensorMonitoring;
            :>> traceToSource = "ISO 26262 기능안전 요구사항";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-10: 크루즈 컨트롤 제동 취소 오버라이드 (기능/안전 요구사항)
        // ==========================================
        requirement <'SYSR-10'> reqCruiseControlBrakeCancel : ModeAndState, OverrideRequirement {
            doc
            /* When both {primaryInputActive} and {overrideInputActive} are true, the {outputValue} must be limited to {safeLimit}. */

            subject ecu : EngineControlUnit;
            stakeholder driver : RV_StakeHolderModel::Driver;

            // [Template: OverrideRequirement 속성]
            attribute :>> primaryInputActive; // 크루즈 컨트롤 활성화 상태 (ccState == Active)
            attribute :>> overrideInputActive; // 브레이크 페달 조작 상태 (isBraking == true)
            attribute :>> outputValue; // 크루즈 컨트롤 요구 토크 (ccTorqueRequest)
            attribute :>> safeLimit = 0.0; // CC 요구 토크 무효화 한계

            assume constraint {
                doc
                /* 브레이크 개입 시 크루즈 컨트롤의 목표 토크 한계는 0.0으로 고정된다. */
                safeLimit == 0.0
            }

            require constraint {
                doc
                /* 크루즈 컨트롤 활성화 상태에서 제동 입력 감지 시 요구 토크를 0.0으로 무효화해야 한다. */
                (primaryInputActive and overrideInputActive) implies outputValue <= safeLimit
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "크루즈 컨트롤 주행 중 브레이크 조작 시 즉각적으로 CC 요구 토크가 0으로 차단됨을 확인";

            case :>> vvStrategy {
                doc
                /* HILS 환경에서 크루즈 컨트롤 상태 중 브레이크 신호 트리거 테스트 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Verification Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqSafeTorqueArbitration;
            :>> traceToSource = "NHTSA 급발진 방지 가이드라인";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-14: 액추에이터 고착 시 연료 차단 (기능/안전 요구사항)
        // ==========================================
        requirement <'SYSR-14'> reqActuatorStuckFuelCut : FunctionalSafety, OverrideRequirement {
            doc
            /* 긴급 개입 시 스로틀 공기량이 축소되지 않는 고착(Stuck) 상황 감지 시, 10ms 이내 연료 분사를 0.0으로 강제 차단해야 한다. */

            subject ecu : EngineControlUnit;
            stakeholder regulator : RV_StakeHolderModel::SafetyRegulator;
            stakeholder addEcuDeveloper : RV_StakeHolderModel::AddEcuDeveloper;

            // [Template: OverrideRequirement 속성]
            attribute :>> primaryInputActive; // 외부(ESP/TCU) 토크 저감 개입 요청 상태
            attribute :>> overrideInputActive; // 스로틀 고착(Stuck) 감지 상태 (공기량 미감소)
            attribute :>> outputValue; // 연료 분사 제어 시간 (Injection Pulse Width)
            attribute :>> safeLimit = 0.0; // 연료 전면 차단 (0.0s)

            assume constraint {
                doc
                /* 스로틀 고착 시 안전 확보를 위한 연료 분사 시간 한계는 0.0으로 고정된다. */
                safeLimit == 0.0
            }

            require constraint {
                doc
                /* 긴급 토크 저감 요청 중 스로틀 고착(공기량 축소 실패)이 감지되면 연료 분사를 0.0으로 강제 차단해야 한다. */
                (primaryInputActive and overrideInputActive) implies outputValue <= safeLimit
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Critical;
            :>> risks = RiskMetadata::RiskLevelEnum::high;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Draft;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "토크 개입 중 공기량 고착 주입 시 10ms 이내에 연료 분사 폭(Pulse Width)이 0.0으로 제한됨을 확인";

            case :>> vvStrategy {
                doc
                /* HILS 환경에서 ESP 개입 요청 시그널과 스로틀 포지션 센서 고착(Stuck) 시그널 동시 주입 테스트 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Verification Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqTorqueInterventionFallbackFuelOnly; // SHR-04-3 대체 경로 추적
            :>> traceToSource = (
                "ISO 26262 기능안전 요구사항", "섀시 제어 부서(ESP/TCU) 예외 처리 합의서"
            );

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-15: 통신 지연 시 제어값 동결 (기능/제어 요구사항)
        // ==========================================
        requirement <'SYSR-15'> reqCommDelayControlValueFreeze : ControlAndAlgorithm {
            doc
            /* 외부 토크 개입 통신 지연이 15ms를 초과할 경우, 타임아웃 전까지 직전 주기의 공기량 및 연료 제어값을 동일하게 유지(보상)해야 한다. */

            subject ecu : EngineControlUnit;
            stakeholder addEcuDeveloper : RV_StakeHolderModel::AddEcuDeveloper;

            attribute currentLatency : Real; // 현재 토크 개입 메시지 수신 지연 시간
            attribute maxLatency : Real = 15.0; // 정상 통신 지연 허용 한계치 (15ms)

            attribute currentAirFlow : Real; // 산출될 현재 공기량 제어값
            attribute previousAirFlow : Real; // 직전 주기의 공기량 제어값
            attribute currentFuelPulseWidth : Real; // 산출될 현재 연료 분사 제어값
            attribute previousFuelPulseWidth : Real; // 직전 주기의 연료 분사 제어값

            assume constraint {
                doc
                /* 최대 허용 정상 통신 지연 시간은 15ms로 설정된다. */
                maxLatency == 15.0
            }

            require constraint {
                doc
                /* 통신 지연이 15ms를 초과하는 경우 급격한 거동 변화를 막기 위해 현재의 공기량과 연료 분사량은 직전 주기의 값과 동일하게 동결되어야 한다. */
                currentLatency > maxLatency implies
                (currentAirFlow == previousAirFlow and
                    currentFuelPulseWidth == previousFuelPulseWidth)
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Draft;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "CAN 메시지 지연 15ms 초과 주입 시 스로틀 개도각 및 인젝터 PWM 듀티비가 직전 제어 주기 값으로 유지됨을 확인";

            case :>> vvStrategy {
                doc
                /* 네트워크 부하 테스트 및 통신 지연/드롭(Delay/Drop) 결함 주입을 통한 제어값 유지 분석 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Vehicle Network Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqDynamicResponsiveness; // SHR-04 대안 경로 추적
            :>> traceToSource = "섀시 제어 부서(ESP/TCU) 협의 회의록";

            @MetaInformation { version = "v0.1"; }
        }
    } // package Functional_Safety_Requirements

    package Performance_Requirements {
        // ==========================================
        // SYSR-01b: 브레이크 오버라이드 응답 속도 (성능 요구사항)
        // ==========================================
        requirement <'SYSR-01b'> reqBrakeOverrideTiming
            : PerformanceNSR, PerformanceTimingRequirement {
            doc
            /* The {brake override process} shall complete within {maxResponseTime}. */

            subject ecu : EngineControlUnit;
            stakeholder driver : RV_StakeHolderModel::Driver;
            stakeholder regulator : RV_StakeHolderModel::SafetyRegulator;

            // [Template: PerformanceTimingRequirement 속성]
            attribute :>> executionTime; // 오버라이드 처리 소요 시간
            attribute :>> maxResponseTime = 10.0; // 10ms 이내 완료 제약

            assume constraint {
                doc
                /* 최대 허용 지연 시간은 10ms 단위로 고정된다. */
                maxResponseTime == 10.0
            }

            require constraint {
                doc
                /* 브레이크 오버라이드 제어 프로세스는 10ms 이내에 반드시 완료되어야 한다. */
                executionTime <= maxResponseTime
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "오버라이드 조건 발생부터 스로틀 명령 출력까지 10ms 이내 완료를 1,000회 검증";

            case :>> vvStrategy {
                doc
                /* 최대 부하(Worst Case Execution Time) 상태에서 오버라이드 지연 시간 실측 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Verification Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = (
                stakeholderRequirementSet.reqSafeTorqueArbitration, stakeholderRequirementSet.reqDynamicResponsiveness
            );
            :>> traceToSource = (
                "NHTSA 급발진 방지 가이드라인", "섀시 제어 부서(ESP/TCU) 협의 회의록"
            );

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-03: 외부 개입 제어 지연 시간 (성능 요구사항)
        // ==========================================
        requirement <'SYSR-03'> reqExternalInterventionLatency
            : PerformanceNSR, PerformanceTimingRequirement {
            doc
            /* The {external intervention process} shall complete within {maxResponseTime}. */

            subject ecu : EngineControlUnit;
            stakeholder addEcuDeveloper : RV_StakeHolderModel::AddEcuDeveloper;

            // [Template: PerformanceTimingRequirement 속성]
            attribute :>> executionTime; // 종단 간(End-to-End) 제어 지연 시간
            attribute :>> maxResponseTime = 15.0; // 15ms 이내 응답 제약

            assume constraint {
                doc
                /* 최대 허용 지연 시간은 15ms로 고정되며, 통신 버스는 정상 상태라고 가정한다. */
                maxResponseTime == 15.0
            }

            require constraint {
                doc
                /* 토크 개입 요청 메시지 수신부터 제어 명령 출력까지의 처리 시간은 15ms 이하이어야 한다. */
                executionTime <= maxResponseTime
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::high;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::InReview;

            :>> allocationBudget = ecu; // (CAN Rx/Tx)
            :>> successCriteria =
                "메시지 수신부터 액추에이터 PWM 신호 변경까지 최대 15ms 이내 실측";

            case :>> vvStrategy {
                doc
                /* 네트워크 부하 80% 이상의 Worst Case에서 종단 간 지연 시간 측정 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Vehicle Network Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = (
                stakeholderRequirementSet.reqDynamicResponsiveness,
                stakeholderRequirementSet.reqTorqueInterventionByAirflow,
                stakeholderRequirementSet.reqTorqueInterventionByFuelIgnition
            );
            :>> traceToSource = "섀시 제어 부서(ESP/TCU) 협의 회의록";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-08: 연소 제어 연산 응답성 (성능 요구사항)
        // ==========================================
        requirement <'SYSR-08'> reqCombustionControlExecutionTiming
            : PerformanceNSR, PerformanceTimingRequirement {
            doc
            /* The {Command Fuel and Ignition process} shall complete within {maxResponseTime}. */

            subject ecu : EngineControlUnit;
            stakeholder calibrationEng : RV_StakeHolderModel::CalibrationEngineer;
            stakeholder hardwareSupplier : RV_StakeHolderModel::HardwareSupplier;

            // [Template: PerformanceTimingRequirement 속성]
            attribute :>> executionTime; // 연료/점화 제어값 산출 연산 시간
            attribute :>> maxResponseTime = 5.0; // 5ms 이내 완료 제약

            assume constraint {
                doc
                /* 연료 분사 및 점화 시기 연산의 최대 허용 지연 시간은 5ms로 고정된다. */
                maxResponseTime == 5.0
            }

            require constraint {
                doc
                /* 센서 데이터 수집부터 연료/점화 제어값 산출 연산까지 5ms 이내에 처리되어야 한다. */
                executionTime <= maxResponseTime
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::high;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::InReview;

            :>> allocationBudget = ecu; // Fuel/Ignition Path
            :>> successCriteria =
                "고 RPM(최대 부하) 조건에서 연소 제어 알고리즘의 실행 시간이 5ms를 초과하지 않음";

            case :>> vvStrategy {
                doc
                /* 마이크로컨트롤러 최악 실행 시간(WCET) 프로파일링 분석 */
            }
            :>> vvMethod = VVMethod::Analysis;
            :>> vvResponsibleOrganization = "Powertrain Software Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = (
                stakeholderRequirementSet.reqPreciseClosedLoopControl, stakeholderRequirementSet.reqMisfirePrevention
            );
            :>> traceToSource = "엔진 부품 공급사(Tier 1) 인터뷰";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-09: 고장 진단 코드(DTC) 기록 응답성 (성능 요구사항)
        // ==========================================
        requirement <'SYSR-09'> reqDtcGenerationLatency
            : PerformanceNSR, PerformanceTimingRequirement {
            doc
            /* The {DTC generation process} shall complete within {maxResponseTime}. */

            subject ecu : EngineControlUnit;
            stakeholder mechanic : RV_StakeHolderModel::ServiceMechanic;

            // [Template: PerformanceTimingRequirement 속성]
            attribute :>> executionTime; // 고장 발생부터 비휘발성 메모리 기록까지의 시간
            attribute :>> maxResponseTime = 50.0; // 50ms 이내 기록 제약

            assume constraint {
                doc
                /* DTC 기록의 최대 허용 지연 시간은 50ms로 고정된다. */
                maxResponseTime == 50.0
            }

            require constraint {
                doc
                /* 고장 진단 확정 후 50ms 이내에 비휘발성 메모리(NVM)에 DTC 저장을 완료해야 한다. */
                executionTime <= maxResponseTime
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::Medium;
            :>> criticalityLevel = CriticalityLevel::Minor;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::InReview;

            :>> allocationBudget = ecu; // Diagnostic Module
            :>> successCriteria =
                "하드웨어 결함 주입 시점부터 50ms 이내에 NVM에 DTC가 저장됨을 오실로스코프로 실측";

            case :>> vvStrategy {
                doc
                /* 결함 주입 후 EEPROM 쓰기 사이클 실행 시간 측정 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Diagnostics & Maintenance Support Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqDiagnosticAndMaintenanceSupport;
            :>> traceToSource = "A/S 서비스 센터 VOC 리포트";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-11: 캘리브레이션 맵 업데이트 응답성 (성능 요구사항)
        // ==========================================
        requirement <'SYSR-11'> reqCalibrationMapUpdateLatency
            : PerformanceNSR, PerformanceTimingRequirement {
            doc
            /* The {Calibration parameter update process} shall complete within {maxResponseTime}. */

            subject ecu : EngineControlUnit;
            stakeholder calibrationEng : RV_StakeHolderModel::CalibrationEngineer;

            // [Template: PerformanceTimingRequirement 속성]
            attribute :>> executionTime; // 파라미터 업데이트 반영 시간
            attribute :>> maxResponseTime = 100.0; // 100ms 이내 완료 제약

            assume constraint {
                doc
                /* XCP 캘리브레이션 파라미터 적용의 최대 허용 지연 시간은 100ms로 고정된다. */
                maxResponseTime == 100.0
            }

            require constraint {
                doc
                /* 툴로부터 제어 맵 파라미터 업데이트 수신 후 100ms 이내에 RAM 데이터 반영 및 제어 로직에 적용되어야 한다. */
                executionTime <= maxResponseTime
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::Medium;
            :>> criticalityLevel = CriticalityLevel::Minor;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Draft;

            :>> allocationBudget = ecu; // Calibration Interface
            :>> successCriteria =
                "XCP 프로토콜을 통한 맵 파라미터 수정 시 100ms 이내에 제어 로직에 적용됨을 확인";

            case :>> vvStrategy {
                doc
                /* 표준 캘리브레이션 툴을 연동하여 파라미터 쓰기 요청 후 로직 반영 지연 시간 실측 */
            }
            :>> vvMethod = VVMethod::Demonstration;
            :>> vvResponsibleOrganization = "Powertrain Calibration Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = (
                stakeholderRequirementSet.reqPowertrainCalibrationSupport,
                stakeholderRequirementSet.reqCalibrationDataIntegrity
            );
            :>> traceToSource = "캘리브레이션 엔지니어링 팀 요구사항";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-13: 가속 페달 응답성 및 승차감 (성능 요구사항)
        // ==========================================
        requirement <'SYSR-13'> reqPedalResponseAndRideComfort
            : PerformanceNSR, PerformanceTimingRequirement {
            doc
            /* The {pedal input processing} shall complete within {maxResponseTime}, and the resulting longitudinal jerk shall not exceed {maxLongitudinalJerk}. */

            subject ecu : EngineControlUnit;
            ref part pedal : AccelerationPedal;
            stakeholder driver : RV_StakeHolderModel::Driver;

            // [Template: PerformanceTimingRequirement 속성]
            attribute :>> executionTime; // 가속 페달 입력 처리 소요 시간
            attribute :>> maxResponseTime = 50.0; // 50ms 이내 처리 제약

            // 승차감 확보를 위한 커스텀 속성
            attribute measuredJerk : Real; // 실측된 종방향 가속도 변화율(Jerk)
            attribute maxLongitudinalJerk : Real = 10.0; // Jerk 허용 한계

            assume constraint {
                doc
                /* 가속 페달 입력 처리의 최대 허용 지연 시간은 50ms, Jerk 한계는 10.0으로 고정된다. */
                maxResponseTime == 50.0 and maxLongitudinalJerk == 10.0
            }

            require constraint {
                doc
                /* 가속 페달 입력은 50ms 이내에 처리되어야 하며, 승차감 확보를 위해 종방향 가속도 변화율(Jerk)은 10.0 이하로 유지되어야 한다. */
                executionTime <= maxResponseTime and measuredJerk <= maxLongitudinalJerk
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::InReview;

            :>> allocationBudget = (ecu, pedal);
            :>> successCriteria =
                "가속 페달 입력 후 50ms 이내 처리 및 종방향 Jerk 10.0 이하 유지를 실차 계측으로 확인";

            case :>> vvStrategy {
                doc
                /* 실차 주행 시험에서 페달 입력-응답 지연 및 가속도 변화율 동시 계측 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Vehicle Dynamics & Human Factors Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqDriverPedalResponsiveness;
            :>> traceToSource = "차량 동역학 및 인간공학 평가 기준서";

            @MetaInformation { version = "v0.1"; }
        }
    } // package Performance_Requirements

    package Diagnostics_Maintainability_Security_Architecture_Requirements {
        // ==========================================
        // SYSR-02: 가속 페달 센서 편차 감지 (진단/안전 요구사항)
        // ==========================================
        requirement <'SYSR-02'> reqPvsRedundancyFaultDetection
            : Diagnostics, RedundancyDeviationRequirement {
            doc
            /* If the absolute difference between {channel1} and {channel2} exceeds {maxDeviation}, {faultFlag} must be asserted true. */

            subject ecu : EngineControlUnit;
            ref part pedal : AccelerationPedal;

            stakeholder regulator : RV_StakeHolderModel::SafetyRegulator;
            stakeholder mechanic : RV_StakeHolderModel::ServiceMechanic;

            // [Template: RedundancyDeviationRequirement 속성]
            attribute :>> channel1; // PVS1 센서 전압
            attribute :>> channel2; // PVS2 센서 전압
            attribute :>> maxDeviation = 5.0; // 허용 오차 5.0%
            attribute :>> faultFlag; // 편차 초과 시 발동할 고장 플래그

            assume constraint {
                doc
                /* 두 센서 간 정상 범주의 최대 허용 전압 편차는 5.0%로 고정된다. */
                maxDeviation == 5.0
            }

            require constraint {
                doc
                /* PVS1과 PVS2 간의 절대 편차가 5.0%를 초과하면 시스템 고장 플래그가 참(true)으로 활성화되어야 한다. */
                (channel1 - channel2 > maxDeviation or channel2 - channel1 > maxDeviation) implies
                faultFlag == true
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Critical;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = (ecu, pedal);
            :>> successCriteria =
                "5.0% 이상의 편차 주입 시 즉각적인 DTC 기록 및 페일세이프 전환 확인";

            case :>> vvStrategy {
                doc
                /* 결함 주입(Fault Injection) 장비 기반 센서 편차 시뮬레이션 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Sensor Diagnostics Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqFailSafeSensorMonitoring;
            :>> traceToSource = "ISO 26262 기능안전 요구사항";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-06: 스로틀 밸브 센서 편차 감지 (진단/안전 요구사항)
        // ==========================================
        requirement <'SYSR-06'> reqTpsRedundancyFaultDetection
            : Diagnostics, RedundancyDeviationRequirement {
            doc
            /* If the absolute difference between {channel1} and {channel2} exceeds {maxDeviation}, {faultFlag} must be asserted true. */

            subject ecu : EngineControlUnit;
            ref part throttle : ThrottleValve;
            stakeholder regulator : RV_StakeHolderModel::SafetyRegulator;

            // [Template: RedundancyDeviationRequirement 속성]
            attribute :>> channel1; // TPS1 센서 전압
            attribute :>> channel2; // TPS2 센서 전압
            attribute :>> maxDeviation = 5.0; // 허용 오차 5.0%
            attribute :>> faultFlag; // 스로틀 피드백 이상 감지 플래그

            assume constraint {
                doc
                /* TPS1과 TPS2 센서 간의 정상 허용 전압 편차는 5.0%로 고정된다. */
                maxDeviation == 5.0
            }

            require constraint {
                doc
                /* TPS1과 TPS2 간의 절대 편차가 5.0%를 초과하면 스로틀 고장 플래그가 참(true)으로 활성화되어야 한다. */
                (channel1 - channel2 > maxDeviation or channel2 - channel1 > maxDeviation) implies
                faultFlag == true
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Critical;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = (ecu, throttle);
            :>> successCriteria =
                "TPS 5.0% 편차 발생 시 즉시 고장 감지 플래그(faultDetected)가 활성화됨을 확인";

            case :>> vvStrategy {
                doc
                /* TPS 신호 단선/단락 및 임의 편차 주입 테스트 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Sensor Diagnostics Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqFailSafeSensorMonitoring;
            :>> traceToSource = "ISO 26262 기능안전 요구사항";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-16: 메모리 인가 및 롤백 제어 (보안 요구사항)
        // ==========================================
        requirement <'SYSR-16'> reqMemoryAccessAuthorizationAndRollback
            : SecurityNSR, PerformanceTimingRequirement {
            doc
            /* 유효하지 않은 메모리 주소(0 이하)로 접근 시, 10ms 이내에 에러 코드를 반환하고 데이터 기록을 거부(롤백)해야 한다. */

            subject ecu : EngineControlUnit;
            stakeholder calibrationEng : RV_StakeHolderModel::CalibrationEngineer;

            // [Template: PerformanceTimingRequirement 속성 확장]
            attribute targetMemoryAddress : Integer; // 캘리브레이션 툴이 접근하려는 메모리 주소
            attribute responseCode : Integer; // 반환할 상태 코드
            attribute :>> executionTime; // 에러 반환 및 롤백 소요 시간
            attribute :>> maxResponseTime = 10.0; // 10ms 이내 제약

            assume constraint {
                doc
                /* 보안 예외 처리 최대 허용 지연 시간은 10ms로 고정된다. */
                maxResponseTime == 10.0
            }

            require constraint {
                doc
                /* 비유효 주소(0 이하) 접근 시 10ms 이내에 에러 코드(non-200)를 반환해야 한다. */
                targetMemoryAddress <= 0 implies
                (responseCode != 200 and executionTime <= maxResponseTime)
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::High;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Draft;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "비정상 메모리 주소(-1, 0 등) 쓰기 요청 시 10ms 이내에 에러 코드 반환 및 RAM 변경 없음 확인";

            case :>> vvStrategy {
                doc
                /* 캘리브레이션 툴 스크립트를 통한 비유효 주소 접근 및 메모리 덤프 무결성 검증 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Security Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqCalibrationMemoryAccess; // SHR-05-1 추적
            :>> traceToSource = "캘리브레이션 통신 보안 가이드라인";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-17: 센서 영점 조정 자동화 (유지보수 요구사항)
        // ==========================================
        requirement <'SYSR-17'> reqZeroPointCalibrationAutomation
            : MaintainabilityNSR, PerformanceTimingRequirement {
            doc
            /* 진단기로부터 영점 조정(serviceId == 2) 요청 시, 100ms 이내에 정상 응답(200)을 반환해야 한다. */

            subject ecu : EngineControlUnit;
            stakeholder mechanic : RV_StakeHolderModel::ServiceMechanic;

            // [Template: PerformanceTimingRequirement 속성 확장]
            attribute serviceId : Integer; // 진단기가 전송한 서비스 ID
            attribute responseCode : Integer; // 반환할 상태 코드
            attribute :>> executionTime; // 영점 조정 프로세스 완료 시간
            attribute :>> maxResponseTime = 100.0; // 100ms 이내 제약

            assume constraint {
                doc
                /* 영점 조정 처리 최대 허용 지연 시간은 100ms로 고정된다. */
                maxResponseTime == 100.0
            }

            require constraint {
                doc
                /* 영점 조정 서비스(ID 2) 요청 시 100ms 이내에 정상 완료 응답(200)을 반환해야 한다. */
                serviceId == 2 implies (responseCode == 200 and executionTime <= maxResponseTime)
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::Medium;
            :>> criticalityLevel = CriticalityLevel::Minor;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Draft;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "serviceId=2 진단 요청 시 추가 프로그래밍 개입 없이 100ms 이내에 완료 응답 수신 확인";

            case :>> vvStrategy {
                doc
                /* 정비용 OBD 시뮬레이터를 통한 영점 조정 서비스 코드 호출 및 응답 지연 실측 */
            }
            :>> vvMethod = VVMethod::Demonstration;
            :>> vvResponsibleOrganization = "Diagnostics & Maintenance Support Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqDiagnosticAndMaintenanceSupport; // SHR-06 추적
            :>> traceToSource = "A/S 서비스 센터 VOC 리포트";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-05: 외부 통신 프로토콜 무결성 검증 (인터페이스/아키텍처 요구사항)
        // ==========================================
        requirement <'SYSR-05'> reqProtocolIntegrityCheck : Interface, OverrideRequirement {
            doc
            /* When both {primaryInputActive} and {overrideInputActive} are true, the {outputValue} must be limited to {safeLimit}. */

            subject ecu : EngineControlUnit;
            stakeholder platformEng : RV_StakeHolderModel::PlatformEngineer;

            // [Template: OverrideRequirement 속성]
            attribute :>> primaryInputActive; // 외부 개입 요구(Intervention) 수신 여부
            attribute :>> overrideInputActive; // 무결성 오류(Checksum/Timeout 등) 감지 여부
            attribute :>> outputValue; // 반영되는 외부 개입 토크량
            attribute :>> safeLimit = 0.0; // 오류 시 외부 개입 토크를 0.0으로 강제 차단

            assume constraint {
                doc
                /* 무결성 오류 발생 시 외부 개입 토크의 안전 한계는 0.0으로 고정된다. */
                safeLimit == 0.0
            }

            require constraint {
                doc
                /* 외부 개입 요구가 존재하더라도 무결성 오류가 감지되면, 해당 개입 토크 출력을 안전 한계 이하로 제한(차단)해야 한다. */
                (primaryInputActive and overrideInputActive) implies outputValue <= safeLimit
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::Medium;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::low;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::Validated;

            :>> allocationBudget = ecu;
            :>> successCriteria = "결함 메시지 주입 시 개입 토크를 100% 차단하고 0.0으로 무효화함";

            case :>> vvStrategy {
                doc
                /* CAN 결함 주입 테스트를 통한 무결성 훼손 메시지 차단 확인 */
            }
            :>> vvMethod = VVMethod::Test;
            :>> vvResponsibleOrganization = "Powertrain Software Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqSafeTorqueArbitration;
            :>> traceToSource = "NHTSA 급발진 방지 가이드라인";

            @MetaInformation { version = "v0.1"; }
        }

        // ==========================================
        // SYSR-12: 신규 외부 제어기 인터페이스 확장성 (유지보수/아키텍처 요구사항)
        // ==========================================
        requirement <'SYSR-12'> reqModularInterfaceExtensibility : MaintainabilityNSR {
            doc
            /* 신규 외부 제어기(자율주행 ECU 등)의 토크 개입 인터페이스를 추가할 때, 기존 토크 중재 핵심 로직의 소스 코드 변경 없이 표준 포트 정의만으로 연동할 수 있어야 한다. */

            subject ecu : EngineControlUnit;
            stakeholder platformEng : RV_StakeHolderModel::PlatformEngineer;

            attribute coreLogicModified : Boolean; // 신규 연동을 위해 토크 중재 핵심 로직 소스코드가 수정되었는지 여부
            attribute newInterfaceAdded : Boolean; // 신규 외부 제어기 인터페이스가 추가되었는지 여부

            assume constraint {
                doc
                /* 신규 제어기는 기존 TorqueInterventionPort와 동일한 포트 타입 규격을 준수하여 연동을 시도한다고 가정한다. */
                newInterfaceAdded == true
            }

            require constraint {
                doc
                /* 신규 외부 제어기 인터페이스가 추가되어도 기존 토크 중재 핵심 로직의 소스코드는 변경되지 않아야 한다. */
                newInterfaceAdded implies coreLogicModified == false
            }

            // [SYSMOD 관리 속성]
            :>> priorityLevel = PriorityLevel::Medium;
            :>> criticalityLevel = CriticalityLevel::Major;
            :>> risks = RiskMetadata::RiskLevelEnum::medium;
            :>> reqVerificationStatus = ReqVerificationStatus::Verified;
            :>> reqValidationStatus = ReqValidationStatus::InReview;

            :>> allocationBudget = ecu;
            :>> successCriteria =
                "신규 외부 제어기 인터페이스 추가 시 'Arbitrate Torque Requests Activity'의 소스코드 diff가 0임을 코드 리뷰로 확인";

            case :>> vvStrategy {
                doc
                /* 신규 제어기 인터페이스 추가 시나리오를 가정한 아키텍처/코드 리뷰 및 정적 분석 */
            }
            :>> vvMethod = VVMethod::Inspection;
            :>> vvResponsibleOrganization = "Platform Architecture Team";
            :>> author = ProjectMember::suhoChu;
            :>> owner = ProjectMember::suhoChu;
            :>> traceToParent = stakeholderRequirementSet.reqModularInterfaceArchitecture;
            :>> traceToSource = "R&D 플랫폼 아키텍처 가이드라인";

            @MetaInformation { version = "v0.1"; }
        }
    } // package Diagnostics_Maintainability_Security_Architecture_Requirements
} // package EgasSystem_Requirements
