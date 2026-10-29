---
description: "다음 Task 카드 초안을 쓴다. 사용법: /plan-next-task T06"
agent: agent
---
사용자가 입력한 Task ID(없으면 STATE의 "다음 Task")의 카드 초안을 `egas2/tasks/<ID>.md`에 `status: draft`로 쓴다. 실행하지 않는다.

읽을 것: `egas2/tasks/MAP.md`의 해당 행, `egas2/tasks/DESIGN_MAP.md`에서 해당 Task가 나오는 행, 최근 handoff, STATE.md, KPI_SNAPSHOT.md, DECISIONS.md.
카드는 양식(`_CARD_TEMPLATE.md`)을 따르고 120줄을 넘기지 않는다. 규칙:
- **목적은 MAP.md의 해당 행을 그대로 옮긴다.** 바꿔야 하면 카드에 "MAP과 다른 점"을 쓰고 DECISIONS.md에 사유를 적는다.
- **자급자족 카드**: 실행에 필요한 DESIGN_MAP 행(공통 package, 메타데이터, viewpoint·view, Skill)을 카드에 복사해 넣는다. 실행 Task가 DESIGN_MAP 전체를 읽지 않게 한다.
- "읽을 파일"은 5개 이내. 레거시는 legacy_query.py 조회 힌트로 적는다.
- AI가 할 일은 번호 목록이고 파일·요소 이름까지 구체적으로 쓴다. 사용자 판단이 필요한 지점은 GATE로 표시한다.
- 예상 산출 규모(모델 400줄·md 150줄 이내)와 권장 모델 등급(기계적 작업은 저가 모델, T02·T07·T12·T19 같은 설계·안전 판단은 상위 모델)을 적는다. 규모를 넘으면 카드를 둘로 나눈다.
- 이 Task가 KPI에 미칠 영향(어느 계층 줄 수가 늘어나는지)과 DoD, After를 쓴다.
끝나면 "카드를 검토하고 status를 approved로 바꾼 뒤 /start-task를 실행하세요"라고 안내한다.
