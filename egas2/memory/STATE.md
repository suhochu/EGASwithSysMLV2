# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T21b 검증·추적·AQ·OI-23·24 (handoffs/T21b.md, AqResults_T21b.md). FSR 7/7 검증 케이스, `TraceabilityViewpoint`·view 2개, 셧오프 래치(OI-24 resolved), `l3Fdti`·`l3Frti` tbd(OI-23), AQ 8개 답함(부분 AQ5·6·7). 직전: T21c, T21a
- 다음 Task: T23 레거시 삭제 게이트(tasks/T23.md draft). T22(선택)는 건너뜀. 사용자가 approved로 바꾼 뒤 실행. 삭제 승인은 사용자
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T21b-trace-views (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 172 defs, 2195줄 (Common 407 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 306 + Fbb 147 + Fwb 156 + Lbb 6 + Lwb 231 + Ver 284). SYSR 12(FSR 7), UF 9, FN 13, LC 6, 검증 케이스 7
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T21b HARD 0, WARN K7(이주율 70% < 곡선 80%, 처분은 T23). 예산: Common 407/410, Sysr 306/320, Fbb 147/200, Fwb 156/170, Lwb 231/250, Ver 284/300, Val 80/80. 상주 컨텍스트 약 19.0KB(한도 20KB, 카드·handoff 포함)
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate·근거 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md, GateF_T16.md, GateL_T20.md, L3Ccf_T21a.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00~T19 완료(T13·T16 Gate 판정은 사용자) | T20 완료(Gate-L 통과, D-28) | T21a·T21c·T21b 완료(A-13~A-17 기록) | T22 선택(건너뜀) | T23·T24 대기(전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-31 확정(D-31: L3 Q&A 상대 위치). 안전 값 승인 A-01~A-17 기록(A-17: A-06 보류 유지). 열린 이슈: OI-01·02(도구), OI-07(pilotAssumed 33·tbd 2·reviewed 0), OI-18(레거시 unmapped 파일 9개, T23), OI-20(상태는 사용자가 정함), OI-21·23·25·26·27·28(T24 한계), OI-22(T21c 반영, 상태는 사용자). 다음 사람 게이트: T23 레거시 처분·삭제 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T21b.md, T21c.md (근거·Gate·AQ 보고서: memory/handoffs/AqResults_T21b.md, L3Ccf_T21a.md, GateR_T13.md, GateF_T16.md, GateL_T20.md)
