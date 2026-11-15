# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T24 효과성 평가 보고서 (handoffs/T24.md, 본문 handoffs/EffectReport_T24.md). 점수 21/35(전 기준 3점)·권고 5개는 AI 제안이며 사용자 승인 대기. 모델 줄 변화 없음. 직전: T23, T22, T21b
- 다음 Task: T24a 효과성 점수 개선(tasks/T24a.md approved, 브랜치 egas2/T24a-score-uplift 시작됨) → T25 추적 질의·진단 도구(tasks/T25.md draft, 권고 2) → 재채점. MAP.md의 계획 Task는 T24로 끝남. 파일럿 계속·중단·확대 결정은 사용자
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T24a-score-uplift (T24는 egas2-pilot에 통합됨)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시: `.sysml`은 `SysideViews.sysml`(외부 벤더 라이브러리) 1개만 남음. 복구는 git 기록. 모델의 레거시 참조 0
- 파일럿 SysML 요소 수: 177 defs, 2342줄 (Common 407 + Obj 19 + Needs 75 + Ctx 80 + Safety 115 + Shr 102 + Val 80 + Scn 98 + Beh 89 + Sysr 362 + Fbb 147 + Fwb 156 + Lbb 6 + Lwb 307 + Ver 290). SYSR 12(FSR 7)+SUD TSR 2, UF 9, FN 13, LC 6+SUD 유닛 3, 검증 케이스 7
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (삭제 후 1개 파일, 541줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T24 HARD 0, 이주율 100%, WARN K1(Common 416/410, D-36 이전 예산). 예산: Common 416/450, Sysr 362/400, Lwb 307/360, Ver 290/420(D-36 상향), Fbb 147/200, Fwb 156/170, Val 80/80. 상주 컨텍스트 약 14KB(한도 20KB)
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate·근거 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md, GateF_T16.md, GateL_T20.md, L3Ccf_T21a.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용은 사용자가 est 유지를 선택(EVALLOG 전부 est).

## 진행표

T00~T19 완료(T13·T16 Gate 판정은 사용자) | T20 완료(Gate-L 통과, D-28) | T21a·T21c·T21b 완료(A-13~A-17 기록) | T22 완료(추상화 1회전, 안전 값 승인 미기록) | T23 완료(레거시 처분·삭제, D-32) | T24 완료(보고서, 승인 대기) | T25 초안(draft, 사용자 결정 후)

## 열린 결정

D-01~D-36 확정(D-36: Common 450·Sysr 400·Lwb 360·Ver 420 상향, D-35: T24a에서 Shr·Scn·Beh·Sysr 변경 허용, 400줄 초과 시 T24b 분할;D-33: 비 SysML 사본 정리, D-34: Sysr·Lwb 예산 상향). 안전 값 승인 A-01~A-19 기록(A-18: T22 SUD 구조 승인, A-19: 시간 후보값 pilotAssumed, 승인 아님). 열린 이슈: OI-01·02(도구), OI-07(pilotAssumed 38·tbd 0·reviewed 2), OI-18(처분 완료, resolved 표시), OI-20(상태는 사용자가 정함), OI-21·23·25·26·27·28·29(T24 보고서에 한계로 기록, 후속은 사용자 결정), OI-22(T21c 반영, 상태는 사용자), OI-30(.env 이력, 사용자 확인). 사용자 결정 대기: A-17 재판정 여부(l3 후보값 있음). 다음 사람 게이트: T24 점수·권고 승인과 파일럿 계속·중단·확대 결정.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T24.md, T23.md (근거·Gate·AQ·효과성 보고서: memory/handoffs/EffectReport_T24.md, AqResults_T21b.md, L3Ccf_T21a.md, GateR_T13.md, GateF_T16.md, GateL_T20.md)
