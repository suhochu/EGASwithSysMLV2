# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T23 레거시 삭제 게이트 (handoffs/T23.md). MIGRATION_MAP `*` 행 unmapped 0(K7 100%), 레거시 `.sysml` 30개 삭제(D-32, 사용자 승인), `SysideViews.sysml`만 keep, archive 3개 추가. 모델 줄 변화 없음. 직전: T22, T21b, T21c
- 다음 Task: T24 효과성 평가 보고서(tasks/T24.md draft). 사용자가 approved로 바꾼 뒤 실행
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T23-legacy-gate (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시: `.sysml`은 `SysideViews.sysml`(외부 벤더 라이브러리) 1개만 남음. 복구는 git 기록. 모델의 레거시 참조 0
- 파일럿 SysML 요소 수: 177 defs, 2333줄 (Common 407 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 362 + Fbb 147 + Fwb 156 + Lbb 6 + Lwb 307 + Ver 290). SYSR 12(FSR 7)+SUD TSR 2, UF 9, FN 13, LC 6+SUD 유닛 3, 검증 케이스 7
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (삭제 후 1개 파일, 541줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T23 HARD 0, 이주율 100%, WARN K1(Common 416/410). 예산: Sysr 362/370, Lwb 307/320(D-34 상향), Fbb 147/200, Fwb 156/170, Ver 290/300, Val 80/80. 상주 컨텍스트 약 16KB(한도 20KB)
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate·근거 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md, GateF_T16.md, GateL_T20.md, L3Ccf_T21a.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00~T19 완료(T13·T16 Gate 판정은 사용자) | T20 완료(Gate-L 통과, D-28) | T21a·T21c·T21b 완료(A-13~A-17 기록) | T22 완료(추상화 1회전, 안전 값 승인 미기록) | T23 완료(레거시 처분·삭제, D-32) | T24 다음 실행(draft, 전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-34 확정(D-33: 비 SysML 사본 정리, D-34: Sysr·Lwb 예산 상향). 안전 값 승인 A-01~A-19 기록(A-18: T22 SUD 구조 승인, A-19: 시간 후보값 pilotAssumed, 승인 아님). 열린 이슈: OI-01·02(도구), OI-07(pilotAssumed 38·tbd 0·reviewed 2), OI-18(처분 완료, resolved 표시), OI-20(상태는 사용자가 정함), OI-21·23·25·26·27·28·29(T24 한계), OI-22(T21c 반영, 상태는 사용자), OI-30(.env 이력, 사용자 확인). 사용자 결정 대기: Common 예산 410 초과(416) 처리, A-17 재판정 여부(l3 후보값 있음). 다음 사람 게이트: T24 점수·권고 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T23.md, T22.md (근거·Gate·AQ 보고서: memory/handoffs/AqResults_T21b.md, L3Ccf_T21a.md, GateR_T13.md, GateF_T16.md, GateL_T20.md)
