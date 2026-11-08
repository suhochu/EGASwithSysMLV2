# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T13 Gate-R (모델 수정 없음. 보고서 memory/handoffs/GateR_T13.md, 요약 handoffs/T13.md. HARD 0, 승인 없는 안전 값 22개, 재오픈 후보 R1~R6)
- 다음 Task: T14 Functional BB (tasks/T14.md 초안 draft, 사용자가 Gate-R 판단(R1·R2)과 R3~R5 처리를 정한 뒤 approved)
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T13-gate-r (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 119 defs, 1407줄 (Common 305 + Obj 19 + Needs 75 + Ctx 78 + Safety 115 + Shr 101 + Val 75 + Scn 89 + Beh 89 + Sysr 275 + 나머지 사슬 + Ver 141)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. Common 305/350줄(87%, 예산 상향 D-17). WARN K15: SYSR def 10개 고아(OI-11, T14 해소). Sysr 275/300, Ver 141/180
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07 완료 | T08 완료 | T09 완료 | T10 완료 | T11 완료 | T12 완료 | T13 완료(Gate 판정은 사용자) | T14~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-18 확정(D-17은 사용자가 확정, Common 줄 예산 250 → 350). 열린 이슈: OI-01·OI-02(도구), OI-03(UF/FN 재분류, T14), OI-06(내부 신호 추가, T14), OI-07(S/E/C·FTTI·safeState 승인, 사용자가 DECISIONS.md에 기록 예정, T19 전), OI-11(SYSR 고아 def, T14), OI-12~14(Gate-R R3~R5, T14에 흡수). OI-08은 resolved. 안전 값: S2·E4·C2, safeState TorqueLimited, FSR 6개는 pilotAssumed, FTTI와 카탈로그 tbd 4개 등은 tbd이며 "안전 값 승인" 절은 비어 있다(pilotAssumed 8·tbd 14·reviewed 0). 다음 사람 게이트: T13 Gate-R 통과 판단과 안전 값 승인(사용자), T16·T20 Gate, T19 안전 판단, T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T13.md (Gate 보고서 전문: memory/handoffs/GateR_T13.md)
