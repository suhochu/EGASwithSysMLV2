# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T20 Gate-L (handoffs/T20.md, 보고서 GateL_T20.md. 경계·할당·포트 계약·GP-A/B 사슬 끊김 0. 사용자 지시로 Fbb·Lwb 수정: D-25 OI-19 resolved, `sysrSafeStateEnforcement`를 `l2Output`·UF-07이 satisfy. D-26: Ver 예산 265, DESIGN_MAP 정정, CHARTER L3 Q&A 제외). Gate-L 통과·A-02·A-06 판정은 사용자
- 다음 Task: T21a L3 셧오프 경로와 CCF (tasks/T21a.md 초안 draft), 그다음 T21b 검증·추적·AQ (tasks/T21b.md 초안 draft). D-27로 T21을 둘로 나눴다. 사용자가 approved로 바꾼 뒤 실행. T21a는 안전 값을 다루므로 상위 모델과 safety-reviewer 사용
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T20-gate-l (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 154 defs, 1942줄 (Common 374 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 275 + Fbb 112 + Fwb 136 + Lbb 6 + Lwb 159 + Ver 222)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T20 HARD 0, WARN K7(이주율 63% < 곡선 80%, 처분은 T23). Common 374/380, Val 80/80, Ver 222/265, Sysr 275/300, Lwb 159/200, 상주 컨텍스트 17.4KB
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md)으로 둔다(D-18). T16 보고서는 GateF_T16.md, T20 보고서는 GateL_T20.md로 둔다
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07 완료 | T08 완료 | T09 완료 | T10 완료 | T11 완료 | T12 완료 | T13 완료(Gate 판정은 사용자) | T14 완료 | T15 완료 | T16 완료(Gate-F 판정은 사용자) | T17 완료 | T18 완료 | T19 완료 | T20 완료(Gate-L 판정은 사용자) | T21a·T21b·T22~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-27 확정(D-25: Gate-L R1~R3 반영, D-26: R4~R8, D-27: Ver 예산 300·L3와 CCF 모델링·K11 8개 인정). 안전 값 승인 A-01~A-06 기록. 열린 이슈: OI-01·OI-02(도구), OI-07(안전 값 승인: 모델 status는 pilotAssumed 27·tbd 0·reviewed 0 그대로), OI-18(레거시 `1-2 FE Behavior`·`2-1`·`4-1`·`4-2`·`03 1-4` 처분 남음, T21~T23), OI-20(A-02 잔여 한계: ①`modeChannel` 입력 제거, ②L3 셧오프 경로, ③공유 입력 CCF 모델링을 모두 T21a에서 처리). OI-19는 T20에서 resolved. OI-03·06·11~17도 resolved. 다음 사람 게이트: T20 Gate-L 통과 판정과 안전 값 승인(A-02·A-06), T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T20.md (Gate 보고서: memory/handoffs/GateR_T13.md, GateF_T16.md, GateL_T20.md)
