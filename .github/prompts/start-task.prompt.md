---
description: "Task 카드를 읽고 해당 Task를 실행한다. 사용법: /start-task T05"
agent: agent
---
사용자가 입력한 Task ID(예: T05)의 카드 `egas2/tasks/<ID>.md`를 실행한다. ID가 없으면 STATE.md의 "다음 Task"를 알려 주고 확인을 구한다. 토큰 절약 규칙(egas2.instructions.md 마지막 절)을 지킨다.

1. 읽기: `egas2/memory/STATE.md`, `egas2/memory/KPI_SNAPSHOT.md`, 가장 최근 handoff 1개, 카드. 이 넷과 `.github/instructions/egas2.instructions.md` 외에는 카드가 지시한 것만 읽는다.
2. 시작 조건: 카드 status가 `approved`이고 STATE의 "다음 Task"와 일치해야 한다. KPI_SNAPSHOT에 HARD 항목이 남아 있으면 멈추고 알린다.
3. 브랜치: 현재 브랜치가 STATE.md의 "통합 브랜치"여야 한다. 아니면 멈추고 알린다. 맞으면 `git switch -c egas2/<ID>-<slug>`로 Task 브랜치를 만든다(이미 그 브랜치면 생략). 관련 없는 변경이 작업 트리에 있으면 멈추고 묻는다.
4. 계획: 카드의 "AI가 할 일"을 10줄 이내로 요약하고 예상 산출 줄 수를 말한다. 카드에 `GATE`로 표시된 항목은 사용자의 답을 기다린다. GATE가 없으면 바로 진행한다.
5. 실행: 카드의 범위 안에서만 파일을 만들고 고친다. 레거시는 `legacy_query.py`로 조회한다. 새 개념은 Registry에 먼저 등록한다.
6. 검사: 파일을 추가할 때마다 `python egas2/tools/check_namespace.py`를 실행한다. SysML 파일을 만들거나 고친 뒤에는 IDE 진단(STATE.md의 "IDE 진단 방식"이 agent면 진단 도구로 `egas2/model` 파일의 오류를 읽고, user-report면 사용자에게 Problems 패널의 egas2 오류 수를 묻는다)을 확인해 0이 되도록 고친다. 끝에 한 번 `python egas2/tools/kpi.py --task <ID> --ide-errors <N> --no-write`를 실행해 HARD를 모두 고친다.
7. 멈춤: 카드의 완료 기준(DoD) 점검 표와 KPI 요약을 보여 주고 "/close-task를 실행하세요"라고 안내한다. 직접 close하지 않는다.
