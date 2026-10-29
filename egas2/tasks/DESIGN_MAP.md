# DESIGN_MAP: 횡단 설계 지도
상세는 표의 Task 열에 적힌 카드에서 확정한다. 패키지 이름은 모두 `EgasArch_` 접두사를 쓴다.

## 1. 공통 package (Common)
수치와 재사용 constraint는 이곳에 한 번만 정의하고 다른 곳은 참조만 한다.

| 패키지(접미) | 담는 것 | 규칙 | 채우는 Task |
|---|---|---|---|
| Common_Units | ms, FIT(1e-9/h), %, N·m, rpm, km/h 등 단위와 Quantity | 단위 정의는 1곳 | T02 |
| Common_Enums | AsilLevel(QM·A·B·C·D), MonitoringLevel(L1·L2·L3), FaultClass(single·dual·double·latent), DefectState(assumed·confirmed), ReactionKind(limpHome·ICO·reset·powerStageShutoff 등), ValueStatus(standard·project·pilotAssumed·tbd·reviewed) | 레거시 enum 28개를 이 기준으로 통합 | T02, 확장 T07·T19 |
| Common_Signals | 경계 신호(페달 PVS1·PVS2, 브레이크, 엔진 속도, 토크 요청 등)와 내부 신호 item | 경계 신호는 T06, 내부 신호는 T14에서 추가. 같은 신호를 두 곳에서 정의하지 않음 | T06, T14 |
| Common_Metadata | 2절의 메타데이터 정의 | T02에서 metadata def와 attribute·constraint 방식을 비교해 확정 | T02, 확장 T07·T19 |
| Catalog_EgasStandard | EGAS 표준 값: Q&A 반복 80 ms 이하, 질문 10개 이상, 검출→반응 벤치마크 500 ms(예시), 셧오프 경로 테스트·ROM 검사 주행 사이클당 1회 | 값마다 SourceRef와 status=standard | T02 시드 |
| Catalog_SafetyTargets | SG별 ASIL과 FTTI, 하드웨어 지표 목표(ASIL B: SPFM 90% 이상, LFM 60% 이상, PMHF 100 FIT 미만, ISO 26262-5 기준값이며 판 확인 필요) | status 필수, FTTI는 tbd로 시작 | T07, T19 |
| Catalog_TimingBudgets | 안전 경로별 FDTI·FRTI·FTTI 1표 | 요구 수준 예산만. 단계별 ms 할당과 WCET 금지 | T19 |
| Catalog_Calibration | EGAS가 project specific 또는 calibratable로 남긴 값(허용 편차, 디바운스, 리셋 횟수, 한계값 등) | 전부 tbd로 시작하고 확정하면 status 변경 | T12, T19 |
| Constraint_Library | 재사용 constraint def: 범위 검사(SRC), 기울기, 두 채널 동기성, 허용값 비교, 디바운스(assumed → confirmed) | 같은 판정식을 다시 쓰지 않음 | T11, T12 |
| Templates | 요구 템플릿(레거시 3종 중 필요한 것) | 새로 만들지 않고 이주 | T12 |

## 2. 메타데이터 모델
SPES는 품질 요구를 해결지향 요구에 주석으로 붙인다. 분류와 출처 태그는 metadata def로, 제약으로 검증해야 하는 수치(FDTI + FRTI ≤ FTTI 등)는 attribute와 constraint def로 두는 방안을 T02에서 비교해 확정한다. FIT와 DC는 표준에 없으므로 pilotAssumed로 시작하고 출처 필드를 비우지 않는다. FDTI·FRTI·FTTI는 ISO 26262:2018 용어 기준이며 D-04에서 판을 확정한다.

| 메타데이터 | 붙는 대상 | 주요 필드 | 근거 |
|---|---|---|---|
| SourceRef | 목표, 요구, 값 | document, itemId(예: EGAS_e369), page | EGAS 문단 ID |
| ValueStatus | 모든 요소와 값 | status(standard·project·pilotAssumed·tbd·reviewed), reviewer, rationale | AI 초안 관리 |
| GoalData | 목표 | kind(hard·soft), refinement(AND·OR), conflictsWith, contributesTo | SPES 4.2.2 |
| ScenarioData | 시나리오 | kind(main·alternative·exception), fulfills(Goal), preCondition, postCondition | SPES 4.2.3 |
| AbstractionLayer | 계층 요소 | layer(0, 1, …) | SPES 3.4.1 |
| SafetyGoalData | Safety Goal | asil, severity, exposure, controllability, hazardousEvent, ftti, safeState | ISO 26262-3, EGAS e83~e90 |
| SafetyRequirementData | FSR, TSR | level(FSR·TSR), asil, asilOrigin(inherited·decomposed), isSafetyMechanism, derivedFrom(SG) | ISO 26262-3·4 |
| AsilDecomposition | 요구 | parentAsil, partAsil1, partAsil2, independenceRationale | ISO 26262-9 |
| FreedomFromInterference | 컴포넌트 쌍 | interferenceKind(timing·memory·communication), mitigation | EGAS e664 |
| SafetyMechanism | 기능, 컴포넌트 | kind(plausibility·redundancy·monitor·watchdog·memoryTest), monitoringLevel(L1·L2·L3), detects(FailureMode), diagnosticCoverage, faultClassCovered | EGAS 10.1 |
| FailureMode | 포트, 컴포넌트 | mode, effect, propagatesTo(port), detectedBy | SPES 8.3 (C²FT-lite) |
| FaultReaction | 기능, 상태 전이 | reactionKind, reversible, triggerState(assumed·confirmed), detectionToReactionMax | EGAS e47, e48, e431~e437 |
| TimingBudget | 요구, 안전 경로 | kind(FDTI·FRTI·FTTI·response), value(ms), derivedFrom | ISO 26262-1 (FDTI + FRTI ≤ FTTI) |
| HwFailureRate | 하드웨어 컴포넌트 | fit(1e-9/h), fitSource, failureModeShare, diagnosticCoverage | ISO 26262-5 (SPFM·LFM·PMHF 집계) |

## 3. Viewpoint, View, 다이어그램
viewpoint def는 SPES의 concern과 점검 규칙(Hint)을 담고(frame concern, require constraint), view def는 satisfy로 viewpoint에 연결하며 expose·filter·render로 구성한다. 표준 뷰 정의(GeneralView, InterconnectionView, ActionFlowView, StateTransitionView, SequenceView, GridView, BrowserView)의 지원 범위는 T04에서 확인하고, 미지원 뷰는 표나 텍스트로 대체해 EVALLOG에 기록한다.

| 모델 영역 (Task) | SPES 산출물 | viewpoint (점검 규칙) | 만들 view | 권장 다이어그램 |
|---|---|---|---|---|
| Objective·Needs (T05) | Goal model | GoalViewpoint: 목표 완전성(Hint 4-2) | GoalTreeView, StakeholderConcernMatrix | 목표 트리(AND/OR, 충돌·기여), 이해관계자×Concern 표 |
| Context (T06) | Context model | ContextViewpoint: 입출력·액터 완전성(Hint 4-1) | ContextView, ActorInterfaceTable | 인터커넥션(경계와 외부 액터), 인터페이스 표 |
| Safety (T07) | HARA, Safety Goal | SafetyConceptViewpoint: 위험 → ASIL → SG 추적 | HaraTable, SafetyGoalView | HARA 표, SG → 안전 상태 트리 |
| SHR·Validation (T08·T09) | Goal의 잎, 검증 계획 | RequirementViewpoint | ShrTable, ValidationCoverageMatrix | 표, SHR×검증 매트릭스 |
| Scenario (T10) | Scenario model | ScenarioViewpoint(Hint 4-3, 4-7) | ScenarioView(UC별), GoalScenarioMatrix | 시퀀스(UC별), 목표×시나리오 매트릭스 |
| Behavior (T11) | 거동·연산·구조 요구 | BehaviorViewpoint(Hint 4-4~4-6) | StateView, OperationalFlowView, InfoStructureView | 상태 전이, 액션 흐름, 정보 구조 |
| SYSR (T12) | 해결지향 요구 | SystemRequirementViewpoint | SysrTable, TraceView(SYSR → SHR·시나리오·거동), FsrView | 표, 추적 매트릭스 |
| Functional BB (T14) | UF 계층, 모드 | FunctionalViewpoint: 일관화·기능 간섭·계층 단순화·상호관계(SPES 5.2) | UfHierarchyView, ModeDependencyView, UfInterfaceTable | UF 트리, 모드 의존(mode channel) 다이어그램 |
| Functional WB (T15) | FN 분해 | FunctionalViewpoint | FnDataflowView(UF별), BbWbMappingTable | 액션 흐름, 입출력 매핑 표 |
| Logical (T17·T18) | 논리 컴포넌트 아키텍처 | LogicalViewpoint(SPES 6.2) | LogicalBBView, LogicalDecompositionView, ChannelView, FnAllocationMatrix, UfLcMatrix | 인터커넥션(루트·분해), 할당·UF×LC 그리드 |
| Safety architecture (T19) | C²FT-lite, ASIL | SafetyArchitectureViewpoint | MonitoringLevelView(EGAS Fig 3 구조), AsilAllocationView, FailurePropagationView, TimingBudgetTable | 3-Level 인터커넥션, 실패 모드 전파 표·트리, FDTI·FRTI·FTTI 표 |
| Cross (T21) | 추적 | TraceabilityViewpoint | SgToLcTraceView, VerificationCoverageView | SG → FSR → UF → FN → LC → 검증 그리드 |

## 4. Skill 후보 (위치: .github/skills/<name>/SKILL.md)
스캐폴드에 포함: handoff-writer, egas-ref-lookup, concept-registry-guard, lint-triage. 나머지는 해당 Task 말미에 AI가 SKILL.md를 쓴다.

| Skill | 하는 일 | 만드는 Task | 쓰는 Task |
|---|---|---|---|
| handoff-writer | Handoff, EvalLog, Registry diff를 정해진 양식으로 출력 | 스캐폴드 | 전 Task |
| egas-ref-lookup | EGAS 문단 ID → 요약 조회, SourceRef 생성 | 스캐폴드 | T05~T19 |
| concept-registry-guard | 새 정의 전에 Registry 조회, 병합 판단 | 스캐폴드 | 전 Task |
| lint-triage | lint 결과를 수정 지시로 변환 | 스캐폴드 | 전 Task |
| sysml-v2-modeling-style | 프로젝트 SysML v2 패턴: BB 규칙, 관계 구문, import 방향, 메타데이터 부착법 | T02, T04 | 전 Task |
| spes-viewpoint-guard | 뷰포인트별 허용·금지 요소와 Hint 점검표 | T03 | T05~T20 |
| legacy-distiller | Keep·Merge·Demote·Delete 판정 기준표와 이주 로그 | T04 | T05~T18 |
| sysml-view-builder | viewpoint·view·다이어그램 작성 템플릿과 도구 지원 현황 | T04 | 각 모델 Task |
| iso26262-concept-assistant | HARA-lite, ASIL 결정, FSR 파생, ASIL 분해 검토 틀. AI 초안 표시와 근거 인용 강제 | T07 | T07, T12, T19 |
| safety-metadata-modeler | FTTI·FDTI·FRTI·FIT·DC 메타데이터와 제약 작성 패턴 | T02 초안, T19 완성 | T07, T12, T19 |
| trace-query-writer | 수용 질의(AQ)를 SysML v2 질의·뷰·매트릭스로 변환 | T21 | T21, T24 |
