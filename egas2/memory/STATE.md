# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T14 Functional BB (UF 7개, SYSR 11개 `satisfy`, K15 고아 0. Gate-R R3~R5 흡수. handoffs/T14.md)
- 다음 Task: T15 Functional WB (tasks/T15.md 초안 draft, 사용자가 approved로 바꾼 뒤 실행)
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T14-functional-bb (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 131 defs, 1554줄 (Common 318 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 75 + Scn 98 + Beh 89 + Sysr 275 + Fbb 96 + Fwb 14 + Lbb 7 + Lwb 11 + Ver 180)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T14 PASS, 경보 없음. Common 318/350, Ver 180/180(상한), Sysr 275/300, 이주율 42%
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07 완료 | T08 완료 | T09 완료 | T10 완료 | T11 완료 | T12 완료 | T13 완료(Gate 판정은 사용자) | T14 완료 | T15~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-19 확정(D-19: UF 모드 의존은 `activeModes`와 `ModeChannel`). 열린 이슈: OI-01·OI-02(도구), OI-07(안전 값 승인. A-01~A-03은 기록됐으나 모델 status는 pilotAssumed 그대로, FTTI와 카탈로그 tbd는 미승인, T19 전). OI-03·06·11~14는 resolved. 안전 값: pilotAssumed 8·tbd 14·reviewed 0. 다음 사람 게이트: T16·T20 Gate, T19 안전 판단, T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T14.md (Gate-R 보고서: memory/handoffs/GateR_T13.md)
