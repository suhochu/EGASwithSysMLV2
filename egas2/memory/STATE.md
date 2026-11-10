# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T21c L3 Q&A 상대 연결 (handoffs/T21c.md). UF-09(`qnaAnswering`)를 `l1Control`에 할당하고 `l3Monitor.qnaPort`와 연결(OI-22 대응, 상태는 사용자 판정). 독립성 문구 정리, OI-26·27 신설. 직전: T21a(handoffs/T21a.md, L3Ccf_T21a.md; A-02 충족·A-06 보류 해제·OI-20 상태는 사용자 판정 대기)
- 다음 Task: T21b 검증·추적·AQ·OI-23·24(tasks/T21b.md draft). 사용자가 approved로 바꾼 뒤 실행. 안전 판단이 있어 상위 모델과 safety-reviewer 사용
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T21c-qna-partner (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 165 defs, 2106줄 (Common 391 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 304 + Fbb 136 + Fwb 158 + Lbb 6 + Lwb 231 + Ver 222). SYSR 12(FSR 7), UF 9, FN 13, LC 6
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T21c HARD 0, WARN K7(이주율 63% < 곡선 80%, 처분은 T23). 예산(D-29·D-30): Common 391/410, Sysr 304/320, Fbb 136/200, Fwb 158/170, Lwb 231/250, Ver 222/300, Val 80/80. 상주 컨텍스트 약 16.8KB(한도 20KB)
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate·근거 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md, GateF_T16.md, GateL_T20.md, L3Ccf_T21a.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00~T19 완료(T13·T16 Gate 판정은 사용자) | T20 완료(Gate-L 통과, D-28) | T21a 완료(A-02·A-06 판정 대기) | T21c 완료(승인 대기) | T21b·T22~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-30 확정(D-27: Ver 예산 300·L3와 CCF 모델링·K11 8개 인정, D-28: Gate-L 통과, D-29: L3·CCF 범위와 예산, D-30: OI-22→T21c, OI-23·24→T21b, OI-21→T24, Lwb 250). 안전 값 승인 A-01~A-09 기록. 열린 이슈: OI-01·02(도구), OI-07(pilotAssumed 32·tbd 0·reviewed 0 그대로), OI-18(레거시 5개 파일 처분 남음, T21~T23), OI-20(상태는 사용자가 정함), OI-21·25·26(T24), OI-22(T21c 반영 완료, 상태는 사용자), OI-23·24(T21b), OI-27(T21b 또는 T24). 다음 사람 게이트: T21c 안전 값 승인(UF-09의 `l1Control` 할당, `l1Control`의 `satisfy`, OI-22 판정), A-02·A-06 충족 판정과 OI-20 상태(근거: L3Ccf_T21a.md 4절), T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T21c.md, T21a.md (근거·Gate 보고서: memory/handoffs/L3Ccf_T21a.md, GateR_T13.md, GateF_T16.md, GateL_T20.md)
