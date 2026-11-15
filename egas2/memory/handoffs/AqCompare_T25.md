# AqCompare_T25: `trace_query.py` 결과와 AqResults_T21b.md 대조 (2026-11-16)

실행: `python egas2/tools/trace_query.py`(Syside 모델 그래프, 읽기 전용). 기대 답은 T24a가 갱신한 AqResults_T21b.md. 틀린 쪽은 모두 기대 답의 옛 수치였고(SUD 추가·T24a 이전 값), 스크립트 규칙 오류는 없었다.

| AQ  | 스크립트 결과                                                                            | 기대 답(AqResults)                               | 일치 | 차이의 원인                                                                                         |
| --- | ---------------------------------------------------------------------------------------- | ------------------------------------------------ | ---- | --------------------------------------------------------------------------------------------------- |
| AQ1 | SG 1: LC 9/9, UF 9/9, FN 13/13 도달. SYSR 14 중 9가 SG에 이름                            | LC 6개 전부 SG-01에 이름                         | 일치 | LC 6→9는 T22의 SUD 유닛 3개. 이르지 못하는 SYSR 5개는 성능 SYSR(arbitration 등)로 SG 파생이 아님    |
| AQ2 | LC마다 SYSR 1~7, 전부 SG 1. satisfy(LC) 19, derivation 30                                | satisfy 15, derivation 21                        | 일치 | 옛 수치는 T22(SUD)·T24a(SG→FSR 7, TSR 2) 이전. `l3Monitor` → `sysrControllerMonitoring` 경로 동일   |
| AQ3 | UF·LC·FN 빈 결과 없음                                                                    | 정당한 빈 결과                                   | 일치 | 없음                                                                                                |
| AQ4 | SYSR 14, SHR 부모 없음 2(`sudTorqueComparison`·`sudExcessConfirmation`), Beh 부모 없음 5 | 12/12 SHR 부모, Beh 없음 3                       | 일치 | TSR 2개(SUD)는 SYSR에서 파생(L2Monitor 55·59행)이라 SHR 부모가 없는 것이 맞다. Beh 5 = 옛 3 + TSR 2 |
| AQ5 | ASIL 9/9(B), 메커니즘 3, CCF 3, 독립성 2(`demonstrated=false`)                           | ASIL 6/6 B, 메커니즘 3, CCF 3, 독립성 2          | 일치 | LC 6→9(SUD)                                                                                         |
| AQ6 | SYSR 14/14 검증, SHR 6/6 검증                                                            | SYSR 12/12·TSR 2/2, SHR 6                        | 일치 | 없음                                                                                                |
| AQ7 | SC 6: 12개 `#refinement`, SC마다 SYSR 1~4와 LC 집합. SafetyAssessment는 SYSR 0           | SC→SYSR 12건(4·2·1·3·2)                          | 일치 | 스크립트가 SC별 LC 집합까지 계산. SafetyAssessmentScenario는 SYSR가 없다(기대 답에 없던 사실)       |
| AQ8 | 액터 6, 포트 7/8 연결, `torqueMonitor` 액터 없음                                         | 액터 6, 포트 7/8, `torqueMonitor` 내부 감시 포트 | 일치 | 없음                                                                                                |

## 진단 경로

`python egas2/tools/trace_query.py --diag`는 `syside.try_load_model`의 진단을 `심각도 코드 파일:줄:열: 메시지` 텍스트로 출력하고 오류가 있으면 종료 코드 1이다. 현재 errors 0, warnings 0. IDE Problems 창은 같은 진단이지만 에이전트가 읽는 경로는 에이전트 진단 도구(`get_errors`)이고, 이번 Task에서도 0이었다.

## 한계

- 이름 고정: 질의가 `SafetyGoalData`·`AsilAllocatedComponent`·`EgasContext`·`EgasSystem`·`IndependenceConstraint` 같은 이름과 계층 접두어(`kpi_config.json`)에 의존한다. 이름이 바뀌면 질의도 바꿔야 한다.
- AQ1 SG 도달은 SHR이 SG를 `:>`로 특수화하거나 `#derivation`으로 이어진 경우만 센다(lint L9와 같은 관계 의미).
- SafetyAssessmentScenario가 SYSR를 refine하지 않는 것은 모델 정보이며 이상 여부는 판단하지 않았다.
