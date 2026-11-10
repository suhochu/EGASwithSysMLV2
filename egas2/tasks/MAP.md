# MAP: 전체 Task 지도 (25개)

게이트는 T13, T16, T20. 요구사항 순서는 사용자 순서가 기본값이고 D-01에서 확정한다.
카드는 한 번에 하나씩, 앞 Task가 끝날 때 /close-task가 다음 카드 초안을 쓰고 사용자가 approved로 바꾼 뒤에만 실행한다.

T01 scope decision (D-05): gasoline manifold injection, torque-comparison monitoring, and L3 Q&A; other variants are out of scope. Keep brake override as a thin scenario.

| Task                            | 목적                                                                       | AI가 하는 일                                                                                                                                                                     |
| ------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Phase 0 — 기반**              |                                                                            |                                                                                                                                                                                  |
| T00                             | 스캐폴드를 설치하고 검증한다                                               | 완료(스캐폴드). 사용자: 설치, 검사 실행, 레거시 컴파일 기준선 기록                                                                                                               |
| T01                             | 범위, 평가 기준, 열린 결정을 확정한다                                      | LEGACY_INVENTORY와 REF_DIGEST를 읽고 CHARTER.md, 결정안 비교, 채점표, 수용 질의(AQ) 작성                                                                                         |
| T02                             | 모든 Task가 import할 공통 기반을 설계한다                                  | Common 패키지 골격, 메타데이터 모델, 카탈로그 시드 작성. IDE 진단 0으로 마무리                                                                                                   |
| T03                             | 중복과 순서 위반을 기계가 잡게 한다                                        | 모델링 규칙(SPES Hint 포함), 관계 구문(refine·derive·satisfy·allocate)과 추적 검사 규칙 결정, Registry 시드, lint.py 작성, `kpi_config.json`의 `registry_enforced`를 true로 전환 |
| T04                             | 얇은 사슬로 규칙·도구·뷰를 먼저 검증한다 (끝나면 Pilot Gate 0: KPI.md 5번) | 계층마다 요소 1개와 viewpoint·view 1개씩 작성, 도구 지원 현황과 Syside 진단을 에이전트가 읽을 수 있는지 확인                                                                     |
| **Phase 1 — 요구사항 뷰포인트** |                                                                            |                                                                                                                                                                                  |
| T05                             | 목적, 이해관계자, Concern(Needs)을 정리한다                                | 레거시를 고도 규칙으로 걸러 이주, Goal 구조(hard/soft, AND/OR) 작성                                                                                                              |
| T06                             | 시스템 컨텍스트: 블랙박스 경계, 외부 액터, 인터페이스                      | EgasSystem을 포트만 남기고 정리, 액터·인터페이스 이주, 내부 신호를 기능 계층 후보로 분류, Item definition 요약                                                                   |
| T07                             | 안전 컨셉 1: HARA-lite와 Safety Goal                                       | EGAS SZ-01~04에서 시작해 HARA 표와 SG 모델 작성, 근거 없는 값은 pilotAssumed 표시                                                                                                |
| T08                             | 이해관계자 요구(SHR)                                                       | 레거시 SHR 20개를 hard goal 12개 이하로 통합, 경계 값만 참조                                                                                                                     |
| T09                             | Stakeholder Validation 계획                                                | SHR마다 검증 방법과 수용 기준만 모델링                                                                                                                                           |
| T10                             | 운용 시나리오                                                              | 5개 내외의 main·alternative·exception 시나리오, 목표 충족 관계와 선·후조건                                                                                                       |
| T11                             | System Behavior(구조·연산·거동)                                            | 상태머신 1개로 통합, 모드 개념 1종, 연산·정보구조 모델 정리                                                                                                                      |
| T12                             | System Requirements와 FSR                                                  | SYSR 20개 이하, 상위·시나리오·거동 추적, FSR에 ASIL 상속                                                                                                                         |
| T13                             | Gate-R                                                                     | 요구 계층 점검 보고(/gate-review)                                                                                                                                                |
| **Phase 2 — 기능 뷰포인트**     |                                                                            |                                                                                                                                                                                  |
| T14                             | Functional BB: UF 계층, 인터페이스, 모드                                   | UF 도출, 인터페이스는 컨텍스트의 부분집합, mode channel, SYSR satisfy                                                                                                            |
| T15                             | Functional WB                                                              | Golden Path 대상 UF만 FN으로 분해, BB와 WB의 입출력 매핑표                                                                                                                       |
| T16                             | Gate-F                                                                     | 기능 계층 점검 보고                                                                                                                                                              |
| **Phase 3 — 논리 뷰포인트**     |                                                                            |                                                                                                                                                                                  |
| T17                             | Logical BB                                                                 | 루트 컴포넌트는 기능 BB 경계를 그대로 채택, 포트 계약                                                                                                                            |
| T18                             | Logical WB와 할당                                                          | L1·L2·L3 구조 기준 분해, 채널, FN 할당 100%, UF와 LC의 n:m 매핑                                                                                                                  |
| T19                             | 안전 아키텍처                                                              | ASIL 할당·분해, 독립성(FFI), 안전 메커니즘, C²FT-lite, FDTI·FRTI·FTTI 표, FIT·DC 집계 시연                                                                                       |
| T20                             | Gate-L                                                                     | 논리 계층 점검 보고                                                                                                                                                              |
| **Phase 4 — 마무리**            |                                                                            |                                                                                                                                                                                  |
| T21a                            | L3 셧오프 경로와 CCF (OI-20)                                               | L2 반응 경로의 L1 모드 의존 제거, L3 독립 모니터링·셧오프 LC, 공유 입력 공통원인(CCF) 모델링, A-02 근거 정리                                                                     |
| T21c                            | L3 Q&A 상대 연결 (OI-22)                                                   | UF-09와 `l1Control`의 Q&A 연결, 독립성 문구 정리. D-30: T21b 앞에 실행 권장                                                                                                      |
| T21b                            | 뷰 통합, 추적 매트릭스, 검증 데모                                          | FSR 검증 케이스 5개, 추적 view, 수용 질의(AQ)에 실제로 답하고 결과표 작성. D-30: L3 FDTI·FRTI tbd(OI-23)와 셧오프 의미(OI-24) 포함                                               |
| T22 (선택)                      | 추상화 계층 시연                                                           | L2 감시 컴포넌트를 새 SUD로 보고 요구 → 기능 → 논리를 얇게 한 번 더                                                                                                              |
| T23                             | 레거시 삭제 게이트와 아카이브                                              | MIGRATION_MAP 100% 처분 확인, 강등 상세를 archive/로, egas2 단독 컴파일·참조 0 확인 보고                                                                                         |
| **Phase 5 — 평가**              |                                                                            |                                                                                                                                                                                  |
| T24                             | SysML v2 효과성 평가 보고서                                                | 채점표, 원인 분리(언어·도구·AI 협업·방법론), 권고                                                                                                                                |

## 매 Task 공통

/close-task가 `kpi.py`를 실행한다(KPI.md). HARD가 있으면 닫지 못하고, 카드의 목적은 이 표의 행을 그대로 옮긴다.

## 사람 게이트

T01 결정(D-01~D-10), 안전 값을 다루는 T07·T12·T19, Gate 세 번, T23의 레거시 삭제 승인.
