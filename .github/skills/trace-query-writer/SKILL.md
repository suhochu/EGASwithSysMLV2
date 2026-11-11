---
name: trace-query-writer
description: 수용 질의(AQ)를 egas2 모델의 요소 이름·관계·view 조회로 바꾸고 결과표를 쓴다. AQ 표(EVAL_PLAN.md)에 답하거나 추적 view를 점검할 때 사용한다.
---

# trace-query-writer

도구가 실행하는 SysML 쿼리가 없으므로(OI-01·02) 질의는 `grep_search`와 IDE 요소 조회로 한다. 결과표에 이 사실을 적는다.

## 절차

1. AQ 문장을 관계 종류로 번역한다: satisfy(`satisfy X by Y`), allocation(`allocation .. allocate A to B`), derivation(`#derivation connection`), refinement(`#refinement dependency`), specialization(`:>`), verify(`objective { verify .. }`), connect(`connect a to b`).
2. 관계 종류마다 정규식을 하나 정한다. 예: `^\s*satisfy sysr\w+ by`, `^\s*allocation \w+ : Allocation allocate`, `#derivation connection`, `verify verified`.
3. 결과 집합과 전체 집합(요소 def 또는 usage 목록)을 비교한다. 차집합이 빈 결과면 "정당한 빈 결과"인지 이유를 적는다.
4. 사슬 AQ는 SG → SHR(`:> UnintendedAccelerationGoal`) → SYSR(`#derivation`) → UF(`satisfy` Fbb) → FN(`dependency ...Decomposition`) → LC(`allocation`, `satisfy` Lwb) 순서로 한 단계씩 확인한다.
5. 결과를 가능·부분·불가로 판정한다. 부분이면 빠진 해상도나 관계를 한 줄로 적는다.

## 결과표 열

AQ | 질의 방법(요소·관계·view) | 결과(가능·부분·불가) | 근거 요소 이름 | 빈 결과가 정당한가

## 규칙

- 근거는 요소 이름으로 쓴다. 줄 번호는 바뀌므로 쓰지 않는다.
- 개수는 grep으로 센 값만 쓴다(추정 금지).
- view로 답하면 view 이름(`sgToLcTraceView`, `verificationCoverageView`, `sysrTraceView`, `allocationView`, `chainBrowser`)을 적는다. GridView는 Syside가 GeneralView로 보여 주므로 표 렌더를 약속하지 않는다.
- 안전 값은 이 스킬이 승인하지 않는다. 상태(pilotAssumed 등)는 그대로 인용한다.
