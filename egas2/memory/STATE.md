# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T06 (외부 액터 6개, 경계 포트·신호 7쌍, Common_Signals, ContextViewpoint와 뷰 2종, OI-05 해소, D-13)
- 다음 Task: T07 (tasks/T07.md 초안 draft, 사용자 approved 후 실행. 안전 판단 Task)
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T06-system-context (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 75 defs, 614줄 (Common 208 + Obj 19 + Needs 75 + Ctx 78 + 나머지 사슬 + Ver 80)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-13 확정. 열린 이슈: OI-01·OI-02(도구), OI-03(UF/FN 재분류, T14), OI-06(내부 신호 추가, T14). 다음 사람 게이트: T07·T12·T19 안전 판단, T13·T16·T20 Gate, T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T06.md
