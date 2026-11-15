# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T26 효과성 재채점 (handoffs/T26.md, EffectReport_T26.md). 23/35 제안, 사용자 조정으로 도구 성숙도 5점 포함 25/35. AqResults_T21b.md 수치 갱신. 모델 변경 없음. 직전: T25, T24a, T24
- 다음 Task: 없음. 파일럿 중단(D-40, 범위 확대 없음). 재개하려면 새 D-xx와 새 카드가 필요하다. 재개 선행 조건은 EffectReport_T26.md 4절
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T26-rescore (커밋 후 사용자가 egas2-pilot에 통합한다)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시: `.sysml`은 `SysideViews.sysml`(외부 벤더 라이브러리) 1개만 남음. 복구는 git 기록. 모델의 레거시 참조 0
- 파일럿 SysML 요소 수: 185 defs, 2528줄 (Common 424 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 430 + Fbb 147 + Fwb 156 + Lbb 6 + Lwb 367 + Ver 340). SYSR 12(FSR 7)+SUD TSR 2, UF 9, FN 13, LC 6+SUD 유닛 3, 검증 케이스 14(SYSR·TSR 전부)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (삭제 후 1개 파일, 541줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T26 HARD 0, WARN 0, 이주율 100%. 예산: Common 424/450, Sysr 430/440, Lwb 367/380(D-36·D-37), Ver 340/420, Fbb 147/200, Fwb 156/170, Val 80/80. Sysr·Lwb는 상한 근접. 상주 컨텍스트는 kpi.py가 측정(한도 20KB)
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate·근거 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md, GateF_T16.md, GateL_T20.md, L3Ccf_T21a.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용은 사용자가 est 유지를 선택(EVALLOG 전부 est).

## 진행표

T00~T19 완료(T13·T16 Gate 판정은 사용자) | T20 완료(Gate-L 통과, D-28) | T21a·T21c·T21b 완료(A-13~A-17 기록) | T22 완료(추상화 1회전, 안전 값 승인 미기록) | T23 완료(레거시 처분·삭제, D-32) | T24 완료(보고서, 승인 대기) | T24a 완료(모델 공백·lint L9~L11) | T25 완료(trace_query.py, AQ1~8 재현·`--diag`) | T26 완료(재채점 25/35, 파일럿 중단 D-40)

## 열린 결정

D-01~D-40 확정(D-40: T26 후 파일럿 중단, A-02·A-06·A-17 보류 판정 최종 확정, A-21 기록; D-39: T26은 점수 제안·한계 기록만; D-38: 파일럿 계속·T24 권고 승인·T25 kpi/lint 수정 허용, D-37: Sysr 440·Lwb 380·Ver defs 30 보정, D-36: Common 450·Sysr 400·Lwb 360·Ver 420 상향, D-35: T24a에서 Shr·Scn·Beh·Sysr 변경 허용;D-33: 비 SysML 사본 정리, D-34: Sysr·Lwb 예산 상향). 안전 값 승인 A-01~A-19 기록(A-18: T22 SUD 구조 승인, A-19: 시간 후보값 pilotAssumed, 승인 아님). 열린 이슈: OI-01·02(도구), OI-07(pilotAssumed 40·tbd 0·reviewed 2), OI-18(처분 완료, resolved 표시), OI-20(상태는 사용자가 정함), OI-21·23·25·26·27·28·29(T24 보고서에 한계로 기록, 후속은 사용자 결정), OI-22(T21c 반영, 상태는 사용자), OI-30(.env 이력, 사용자 확인), OI-31(질의 이름 고정·옛 AQ 수치, T25). OI-28은 resolved(T24a, 사용자 위임 2026-11-16), OI-29·27·21은 T24a 메모 추가. A-02·A-06·A-17은 D-40으로 보류 최종 확정(pilotAssumed 유지, 충족 선언 없음). EVALLOG 실측 크레딧·소요와 문서 기준선은 est 유지(AI 협업·문서 대비 노력 3점 상한). OI-20·22·25·26은 D-40으로 한계 확정, OI-31 open. 다음 사람 게이트: 파일럿 재개 여부(새 D-xx).

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T26.md, T25.md (근거·Gate·AQ·효과성 보고서: memory/handoffs/EffectReport_T26.md, AqCompare_T25.md, EffectReport_T24.md, AqResults_T21b.md, L3Ccf_T21a.md, GateR_T13.md, GateF_T16.md, GateL_T20.md)
