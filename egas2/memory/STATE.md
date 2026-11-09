# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T19 안전 아키텍처 (handoffs/T19.md. D-24: UF-07을 `L2OutputComponent`로 분리해 LC 5개, safe demand가 L1을 거치지 않음. LC ASIL B inherited·분해 없음(A-04), p1Fdti 500 ms·p1Frti 300 ms ≤ sg01Ftti 1 s(A-05), A-02 조건은 L1 고장에 한해 구조적 확인·충족 기록 보류(A-06). OI-19·OI-20 open). T16 Gate-F 판정은 사용자
- 다음 Task: T20 Gate-L (tasks/T20.md 초안 draft, 사용자가 approved로 바꾼 뒤 실행). 모델 수정 없는 점검 Task이며 상위 모델 사용
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T19-safety-architecture (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 154 defs, 1938줄 (Common 374 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 275 + Fbb 109 + Fwb 136 + Lbb 6 + Lwb 158 + Ver 222)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T19 PASS, 경보 없음. Common 374/380, Val 80/80, Ver 222/225(99%), Sysr 275/300, Lwb 158/200, 이주율 63%
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md)으로 둔다(D-18). T16 보고서는 GateF_T16.md, T20 보고서는 GateL_T20.md로 둔다
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07 완료 | T08 완료 | T09 완료 | T10 완료 | T11 완료 | T12 완료 | T13 완료(Gate 판정은 사용자) | T14 완료 | T15 완료 | T16 완료(Gate-F 판정은 사용자) | T17 완료 | T18 완료 | T19 완료 | T20~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-24 확정(D-24: UF-07 분리와 LC 5개, Common 예산 380). 안전 값 승인 A-01~A-06 기록. 열린 이슈: OI-01·OI-02(도구), OI-07(안전 값 승인: 모델 status는 pilotAssumed 27·tbd 0·reviewed 0 그대로), OI-18(레거시 `1-2 FE Behavior`·`2-1`·`4-1`·`4-2`·`03 1-4` 처분 남음, T20~T23), OI-19(Fbb `egasUf` flow와 LC 채널 대응, T20), OI-20(A-02 잔여 한계: 모드 채널의 L1 의존, `l2Reaction`·`l2Output` 직렬 단일점, 공유 입력 CCF, T20). OI-03·06·11~17은 resolved. 다음 사람 게이트: T20 Gate-L(논리 계층 통과, OI-19·OI-20 처리 방안), T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T19.md (Gate 보고서: memory/handoffs/GateR_T13.md, GateF_T16.md)
