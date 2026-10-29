---
description: "현재 Task를 마무리한다: 검사, KPI, handoff, STATE 갱신, 커밋, 다음 카드 초안"
agent: agent
---
현재 브랜치(`egas2/<ID>-...`)의 Task를 마무리한다. 토큰 절약 규칙을 지킨다.

1. 카드의 완료 기준(DoD)을 점검하고 미충족 항목을 나열한다. 미충족이 있으면 멈추고 묻는다.
2. IDE 진단 오류 수 N을 확인한다(STATE.md의 "IDE 진단 방식"에 따라 진단 도구 또는 사용자에게 질문). 그다음 `python egas2/tools/check_namespace.py`와 `python egas2/tools/kpi.py --task <ID> --ide-errors <N>`를 실행한다. HARD가 있으면 Task를 닫지 않는다. KPI_SNAPSHOT.md와 KPI_LOG.csv는 스크립트가 쓴다. 직접 고치지 않는다.
3. 직전 KPI_LOG 행과 비교해 이탈 신호(TREND 경보, 상한 근접 계층, 처음 계획에 없던 산출)를 3줄 이내로 정리한다. 목적이 MAP.md의 해당 행과 다르게 흘러갔다면 DECISIONS.md에 사유를 적고 사용자에게 알린다.
4. `egas2/memory/handoffs/<ID>.md`를 `_TEMPLATE.md` 양식으로 쓴다(80줄 이내, KPI 한 줄 포함).
5. `egas2/memory/STATE.md`를 다시 쓴다(100줄 이내): 마지막 완료 Task, 다음 Task, 요소 수, 진행표, 열린 결정.
6. 아래를 갱신한다: `DECISIONS.md`(새 결정), `REGISTRY.md`(추가·병합·폐기), `OPEN_ISSUES.md`, `EVALLOG.md` 한 줄(모르는 값은 est, 크레딧은 사용자가 채운다), `MIGRATION_MAP.csv`(이주한 요소는 요소 행, 강등·폐기는 파일·그룹 행 하나로. 이번 Task에서 처리를 끝낸 레거시 파일은 `*` 행의 disposition을 keep, merge, demote, delete, rebuild 중 하나로 바꾼다. 일부만 처리했으면 바꾸지 않는다).
7. 커밋한다: `git add egas2 .github` 후 `git commit -m "egas2: <ID> <제목>"`. push와 통합 브랜치로의 머지는 하지 않는다(사용자가 한다).
8. `/plan-next-task`와 같은 절차로 다음 카드 초안 `egas2/tasks/<다음ID>.md`를 `status: draft`로 쓴다. 실행하지 않는다.
9. 최종 메시지: 변경 요약 10줄 이내, 이탈 신호, 사용자가 검토할 항목(안전 값, 결정), 다음 단계 안내.
