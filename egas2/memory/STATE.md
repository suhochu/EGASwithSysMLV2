# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T17 Logical BB (handoffs/T17.md. D-22: `LogicalEgasSystem :> EgasSystem`, UF 사이 `flow` 13개, Ver 예산 210, `logicalBbView` 추가. OI-15·OI-16 resolved). T16 Gate-F 판정은 사용자
- 다음 Task: T18 Logical WB와 할당 (tasks/T18.md 초안 draft, 사용자가 approved로 바꾼 뒤 실행). OI-17을 처리
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T17-logical-bb (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 142 defs, 1731줄 (Common 336 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 275 + Fbb 109 + Fwb 136 + Lbb 6 + Lwb 12 + Ver 199)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T17 PASS, 경보 없음. Common 336/350, Val 80/80, Ver 199/210, Sysr 275/300, 이주율 57%
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md)으로 둔다(D-18). T16 보고서는 GateF_T16.md
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07 완료 | T08 완료 | T09 완료 | T10 완료 | T11 완료 | T12 완료 | T13 완료(Gate 판정은 사용자) | T14 완료 | T15 완료 | T16 완료(Gate-F 판정은 사용자) | T17 완료 | T18~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-22 확정(D-22: OI-15 방식 flow 13개, Ver 예산 210). 열린 이슈: OI-01·OI-02(도구), OI-07(안전 값 승인. A-01~A-03은 기록됐으나 모델 status는 pilotAssumed 그대로, 나머지 값은 AI가 정한 pilotAssumed로 미승인, T19 전), OI-17(T18), OI-18(T18~T20·T23). OI-03·06·11~16은 resolved. 안전 값: pilotAssumed 22·tbd 0·reviewed 0(FN doc의 tbd와 `activeModes`는 값 없음). 다음 사람 게이트: T16 통과 판단, T18 LC 구성 확인, T19 안전 판단, T20 Gate, T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T17.md (Gate 보고서: memory/handoffs/GateR_T13.md, GateF_T16.md)
