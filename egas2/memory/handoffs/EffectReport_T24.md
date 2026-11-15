# EffectReport_T24: SysML v2 효과성 평가 보고서 (2026-11-15)

상태: 점수와 권고는 AI 제안이며 사용자 승인 전이다. 점수는 EVAL_PLAN 기준(1·3·5점)이다. 안전 타당성을 모델 완결성으로 추정하지 않았다. 질의 도구가 없어(EVALLOG T04·T13~T21b) 근거는 grep·IDE 조회와 `kpi.py`·`lint.py`·`check_namespace.py`·`syside check` 결과다.

## 1. 채점표 (제안)

| 기준             | 점수 | 근거                                                                                                                                                                                                                                   | 5점이 안 되는 이유                                                                                                                                                                           |
| ---------------- | ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 표현력           | 3    | 14개 계층 사슬과 `satisfy`·`allocation`·`#derivation`·`#refinement`·`connect`·`bind`가 Syside를 통과(T14~T22). `LogicalEgasSystem :> EgasSystem` 상속으로 포트 계약이 일치(T17), 추상화 1회전이 같은 양식으로 반복됨(T22)              | 독립성·FFI는 요소가 아니라 doc·연결 주석(AQ5). Concern `subject` 재정의가 Syside 오류라 `frame`으로 우회(D-13). SG→SYSR 일부는 문자열 관계(OI-12). 메타데이터가 길어 줄이 늘어남(T22 +138줄) |
| 추적성           | 3    | AQ 8개 중 5개 가능, 3개 부분(아래 3절). SG→SHR→SYSR→UF→FN→LC 사슬에 끊김 없음(K10, AqResults_T21b). K15 고아 0                                                                                                                         | 질의 실행 도구가 없어 grep으로만 조회. 검증 커버리지는 def 이름으로 읽음. SHR 해상도(AQ7), SYSR 5개 검증 공백(OI-28)                                                                         |
| 일관성 유지      | 3    | `lint.py` 0·0, `check_namespace.py` 0·0, `kpi.py` HARD 0, `syside check` 통과가 Task마다 반복됨. Gate 점검이 grep으로 OI-19(flow·채널 불일치)와 R3(FSR 추적 누락)을 찾아 같은 Task에서 수정                                            | 스캐너가 정규식이라 한 줄 선언·위치를 fixture로 고정해야 함(T03). K4는 부분 문자열 일치(OI-01). 사슬 일관성의 상당 부분은 Gate 수동 점검                                                     |
| 도구 성숙도      | 3    | 텍스트 편집, `syside check`, 표준 view 7종 정의는 안정. 한계가 문서화됨                                                                                                                                                                | 에이전트가 Syside 진단을 못 읽거나(T04) 'shadows previously declared element' 오탐(T15~T22). GridView·Sequence·Browser는 GeneralView로만 표시(T04~T10). SysML 쿼리 도구 없음                 |
| AI 협업 효율     | 3    | 카드 범위 안에서 Task T01~T23이 반복 가능하게 닫혔고 검사 0이 기준이 됨. safety-reviewer가 10건 지적(T21a)해 문구 4건 수정·OI 5건 등록                                                                                                 | 크레딧·소요가 전부 `est`라 "기록된 노력"이 없음. 카드 초과(T22 +138 vs +90), 카드 밖 수정(D-25), 상주 컨텍스트 초과(T13·T20, D-18), 터미널 한글 깨짐(T21c)                                   |
| 문서 대비 노력   | 3    | 재사용(상속·`bind` 양식, Common 카탈로그 1곳 수치)과 자동 검사(K1~K15)가 있음. 줄 수는 새 사슬·검증이 늘어난 결과이므로 문서 분량과 단순 비교하지 않음                                                                                 | 정량 비교 불가: 비용이 `est`이고 문서 기반 작업 기준선이 없음. 정성으로만 "비슷하거나 약간 이득"                                                                                             |
| ISO 26262 적합성 | 3    | 값마다 SourceRef·ValueStatus(standard 14, project 3, pilotAssumed 38, tbd 0, reviewed 2). ASIL B는 EGAS e83 기준, FDTI·FRTI는 ISO 26262-1 정의를 인용(A-05). 근거 없는 값은 pilotAssumed로 격리하고 승인 행(A-01~A-19)을 사용자가 기록 | A-02·A-06 보류(FTTI 내 위험 제거 미입증, A-17). S/E/C·시간 값은 가정. 독립성·FFI·FIT·DC·CCF 완화 미모델(OI-21·27·29). 충족을 선언하지 않음                                                   |

합계 21/35. 안전 값 승인 상태: A-01~A-19 기록, 모델 pilotAssumed 38·reviewed 2. 이 상태가 3점의 상한이다.

## 2. 한계의 원인 분리

| 한계                                       | 언어 | 도구 | AI 협업 | 방법론                          | 근거                    |
| ------------------------------------------ | ---- | ---- | ------- | ------------------------------- | ----------------------- |
| 질의를 실행할 수 없어 grep으로 답함        |      | 주   |         |                                 | OI-01, EVALLOG T13~T21b |
| IDE 진단을 에이전트가 못 읽음, shadow 오탐 |      | 주   | 부      |                                 | EVALLOG T04·T15~T22     |
| GridView 표 렌더 없음(GeneralView)         |      | 주   |         |                                 | EVALLOG T04~T10         |
| Concern `subject` 재정의 불가              | 주   | 부   |         | 부(하위 import 규칙)            | D-13, EVALLOG T06       |
| 메타데이터 블록이 길어 줄 증가             | 주   |      |         |                                 | EVALLOG T22             |
| 독립성·FFI·CCF를 값·관계로 못 잡음         | 부   |      |         | 주(범위·D-05·D-30)              | AQ5, OI-21·27           |
| SHR 해상도로 SC→LC가 넓음                  |      |      |         | 주(`parentShr` 하나가 SYSR 6개) | AQ7, D-26               |
| SYSR 5개·TSR 2개 검증 공백                 |      |      |         | 주(카드 범위 FSR 7)             | OI-28·29                |
| 새 Fbb·Fwb를 못 만듦(상위 WB 재사용)       |      |      |         | 주(계층 토큰 고정)              | T22 handoff             |
| Common 416/410, Sysr·Lwb 예산 상향         |      |      |         | 주(예산 정책, D-34)             | KPI, D-34               |
| 카드 초과·카드 밖 수정                     |      |      | 주      | 부                              | EVALLOG T20·T22, D-25   |
| 상주 컨텍스트 20KB 초과                    |      |      | 부      | 주                              | D-18, EVALLOG T13·T20   |
| 터미널 한글 깨짐                           |      | 부   | 주      |                                 | EVALLOG T21c            |
| L3 FDTI·FRTI·확인 시간이 가정값            |      |      |         | 주(표준에 값 없음, 승인 대기)   | OI-23, A-17·A-19        |
| SHR에 SReq-07 문장 없음, UF-09 파일럿 매핑 |      |      |         | 주(Shr 변경은 사용자 결정)      | OI-25·26                |
| `.env` 이력                                |      |      |         | 주(운영)                        | OI-30                   |

## 3. AQ 최종 판정

`trace-query-writer` 절차로 재확인했다. SYSR 12(FSR 7), Fbb `satisfy` 15건, Lwb `satisfy` 15건, 검증 케이스 7개(`TorqueComparison`·`ExcessConfirmation`·`SafeStateEnforcement`·`PedalSensorFaultDetection`·`LimpHomeTorqueLimit`·`BrakeOverrideTorque`·`ControllerMonitoring`)가 AqResults_T21b와 일치한다. 전체 표: AqResults_T21b.md.

| AQ                      | 판정       | 이유와 보완 비용                                                                                                                                                                                                                                      |
| ----------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AQ1, AQ2, AQ3, AQ4, AQ8 | 가능       | AQ3·AQ4·AQ8은 정당한 빈 결과를 포함                                                                                                                                                                                                                   |
| AQ5                     | 부분       | ASIL은 LC 6개 B inherited로 나오나 독립성·FFI는 요소가 아니라 doc·주석. 보완: 독립성 요구·FFI 제약 요소를 Common 메타데이터와 Lwb 제약으로 추가. Common이 416/410이므로 예산 결정이 선행(est, 모델 변경 수십 줄 규모)                                 |
| AQ6                     | 부분       | SYSR 5개(`sysrArbitrationPriority`·`sysrInterventionReduction`·`sysrInterventionRelease`·`sysrPedalOutputResponse`·`sysrSteadyStateTracking`)와 TSR 2개가 검증 없음. 보완: 기존 `verification def` 양식 7건 반복. Ver 290/300이라 예산 초과 가능(est) |
| AQ7                     | 부분(D-27) | 경로는 있으나 `parentShr` 하나가 SYSR 6개로 퍼져 SC가 GP-A의 LC 전체를 포함. 보완: 시나리오→SYSR 직접 `#refinement`(D-26 R5), Beh→SYSR 세분화. Scn·Beh·Sysr 계층 변경이라 사용자 결정(est)                                                            |

## 4. 비용

실제 크레딧·소요 시간·AI 반복은 EVALLOG에 입력되지 않아 전부 `est`다(사용자가 est 유지 선택). 계획 기준은 월 약 2,000 AI Credits, Task당 약 64 Credits다. 실측 증거는 줄 수뿐이다: 모델 2342줄/177 defs, T22 추상화 1회전 +138줄·새 파일 2개·Registry 6행. 문서 기반 작업과는 정성으로만 비교한다(1절 노력 행).

## 5. 권고 (제안, 승인 필요)

1. 조건부 계속: 같은 범위(SG-01, D-05)에서 파일럿 이후 Task를 잇되, 안전 값은 승인 절차 없이 reviewed로 바꾸지 않는다. pilotAssumed 38이 더 늘기 전에 A-17 재판정(l3Fdti·l3Frti 후보값 존재, A-19)과 A-02·A-06 판단을 사용자가 정한다.
2. 도구 선행: 범위를 넓히기 전에 SysML 요소·관계를 읽는 질의·보고 스크립트(Syside Python API는 OI-04에서 owner 확인에 쓰임)와 에이전트가 읽을 수 있는 진단 경로를 먼저 만든다. 없으면 확대하지 않는다(AQ 자동화, K4 부분 문자열 정정 OI-01).
3. 범위 확대 조건: 다른 SG·컴포넌트로 넓히기 전에 OI-28·29(검증 7건)와 AQ7 해상도를 닫고, 계층 토큰으로 새 Fbb·Fwb를 못 만드는 제약과 Common 예산(416/410)을 새 D-xx로 정한다.
4. 비용 측정: 다음 Task부터 EVALLOG에 실제 크레딧·소요를 기록하고 문서 기반 기준선(같은 범위의 문서 작업 시간)을 한 번 잡는다. 이 전에는 "문서 대비 이득"을 확정하지 않는다.
5. 중단 조건: 권고 2가 충족되지 않은 채 요소가 늘어 수동 Gate 점검이 병목이 되거나, 승인되지 않은 pilotAssumed 값이 계속 늘면 확대를 멈추고 승인·정리부터 한다. OI-30(`.env` 이력)은 사용자가 확인한다.
