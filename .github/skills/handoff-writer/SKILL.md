---
name: handoff-writer
description: "Task 종료 시 handoff 파일, STATE.md, EVALLOG 한 줄, Registry·MIGRATION_MAP 갱신을 정해진 양식으로 작성한다. /close-task 중이거나 handoff를 쓸 때 사용한다."
---
# handoff-writer

1. `egas2/memory/handoffs/_TEMPLATE.md`를 복사해 `<ID>.md`로 저장하고 모든 항목을 채운다. 비어 있는 항목은 "없음"이라고 쓴다.
2. 사실만 쓴다: 만든 파일(줄 수), 결정과 이유, Registry 변경, 요소 수와 ID 범위, archive로 내린 것, status가 pilotAssumed·tbd인 값, 다음 Task가 알아야 할 것, 검사 결과.
3. STATE.md는 "현재 상태"만 남기고 이력은 handoff에 둔다. 100줄을 넘기지 않는다.
4. EVALLOG는 한 줄: `Txx | 소요(분) | AI 반복 | 크레딧 | 막힌 점 | 쉬웠던 점 | 문서 대비 이득(○△✕)`.
5. MIGRATION_MAP.csv: 이주(keep·merge)한 요소만 요소 행(`legacy_file, legacy_element, kind, disposition, target, task, note`)으로 추가한다. 강등·폐기는 파일 또는 그룹 행 하나로 기록한다(토큰 절약). 파일 단위 `*` 행의 disposition이 unmapped가 아니면 그 파일은 처리된 것이다. 이번 Task에서 파일 하나를 끝까지 처리했을 때만 그 행의 disposition(keep·merge·demote·delete·rebuild)을 바꾼다.
