# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- T30 추가 범위 진행 중(D-45): SourceRef ID 정규화·범위 펼침은 완료했으나 기존 모델 오류로 lint·KPI·SysIDE 검증이 실패해 닫지 못함. 아래 T30 수치와 KPI 스냅샷은 변경 전 기록이다.
- 마지막 완료 Task: T30 스로틀 센서 고장 FSR-05와 TSR 문장 다듬기(D-44, OI-32·OI-33 resolved): FSR-05(Shr)→TSR→UF-10→FN-14→l2Monitor→검증 2개, 예산 Ver defs 32·Fwb 190. 직전: T29(FSR/TSR 계층 재구성, D-43), T28(D-42)
- 다음 Task: 없음. 안전 값 승인(FSR 5개 ASIL 등 A-xx)은 사용자 입력 대기. 파일럿 중단(D-40)은 유지된다. 재개에는 별도 새 D-xx와 새 카드가 필요하다. 재개 선행 조건은 EffectReport_T26.md 4절
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: T28 (T29·T30은 이 브랜치에서 작업, 커밋하지 않음)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report (최근 Task는 에이전트 진단 도구 No errors로 확인)
- 레거시: `.sysml`은 `SysideViews.sysml`(외부 벤더 라이브러리) 1개만 남음. 복구는 git 기록. 모델의 레거시 참조 0
- 파일럿 SysML 요소 수: 202 defs, 2791줄 (Common 431 + Obj 19 + Needs 75 + Ctx 80 + Safety 119 + Shr 252 + Val 80 + Scn 117 + Beh 98 + Sysr 428 + Fbb 161 + Fwb 169 + Lbb 6 + Lwb 372 + Ver 384). FSR 5(Shr)+TSR 8+SUD TSR 2, SYSR 5, UF 10, FN 14, LC 6+SUD 유닛 3, 검증 케이스 20(FSR·TSR·SYSR 전부)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (삭제 후 1개 파일, 541줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T30 완료 예산: Common 431/450, Shr 252/280, Sysr 428/440, Lwb 372/380, Ver 384/420(defs 32/32), Fbb 161/200, Fwb 169/190, Val 80/80. Sysr·Lwb·Val·Ver defs는 상한 근접. 상주 컨텍스트는 kpi.py가 측정(한도 20KB)
- K9 주의: 상주 컨텍스트 20KB 한도 때문에 Gate·근거 보고서처럼 긴 문서는 handoffs/T\*.md가 아닌 이름(GateR_T13.md, GateF_T16.md, GateL_T20.md, L3Ccf_T21a.md)으로 둔다(D-18)
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용은 사용자가 est 유지를 선택(EVALLOG 전부 est).

## 진행표

T00~T19 완료(T13·T16 Gate 판정은 사용자) | T20 완료(Gate-L 통과, D-28) | T21a·T21c·T21b 완료(A-13~A-17 기록) | T22 완료(추상화 1회전, 안전 값 승인 미기록) | T23 완료(레거시 처분·삭제, D-32) | T24 완료(보고서, 승인 대기) | T24a 완료(모델 공백·lint L9~L11) | T25 완료(trace_query.py, AQ1~8 재현·`--diag`) | T26 완료(재채점 25/35, 파일럿 중단 D-40) | T27 완료(문서 형식만 정리, D-41) | T28 완료(사용자 직접 리팩터링, D-42) | T29 완료(FSR/TSR 계층 재구성, D-43) | T30 완료(FSR-05·TSR 문장, D-44)

## 열린 결정

D-01~D-44 확정(D-44: T30 FSR-05 추가·예산 Ver defs 32·Fwb 190; D-43: T29 FSR/TSR 계층 재구성, 안전 값·status 불변; D-42: T28 사용자 직접 리팩터링 승인, 범위는 폴더 구조·마이너 이슈; D-40: T26 후 파일럿 중단, A-02·A-06·A-17 보류 판정 최종 확정, A-21 기록; D-39: T26은 점수 제안·한계 기록만; D-38: 파일럿 계속·T24 권고 승인·T25 kpi/lint 수정 허용, D-37: Sysr 440·Lwb 380·Ver defs 30 보정, D-36: Common 450·Sysr 400·Lwb 360·Ver 420 상향, D-35: T24a에서 Shr·Scn·Beh·Sysr 변경 허용;D-33: 비 SysML 사본 정리, D-34: Sysr·Lwb 예산 상향). 안전 값 승인 A-01~A-19 기록(A-18: T22 SUD 구조 승인, A-19: 시간 후보값 pilotAssumed, 승인 아님). 열린 이슈: OI-01·02(도구), OI-07(pilotAssumed 40·tbd 0·reviewed 2), OI-18(처분 완료, resolved 표시), OI-20(상태는 사용자가 정함), OI-21·23·25·26·27·28·29(T24 보고서에 한계로 기록, 후속은 사용자 결정), OI-22(T21c 반영, 상태는 사용자), OI-30(.env 이력, 사용자 확인), OI-31(질의 이름 고정·옛 AQ 수치, T25). OI-32·OI-33은 T30에서 resolved. OI-28은 resolved(T24a, 사용자 위임 2026-11-16), OI-29·27·21은 T24a 메모 추가. A-02·A-06·A-17은 D-40으로 보류 최종 확정(pilotAssumed 유지, 충족 선언 없음). EVALLOG 실측 크레딧·소요와 문서 기준선은 est 유지(AI 협업·문서 대비 노력 3점 상한). OI-20·22·25·26은 D-40으로 한계 확정, OI-31 open. 다음 사람 게이트: 파일럿 재개 여부(새 D-xx).

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T30.md, T29.md, T27.md (근거·Gate·AQ·효과성 보고서: memory/handoffs/EffectReport_T26.md, AqCompare_T25.md, EffectReport_T24.md, AqResults_T21b.md, L3Ccf_T21a.md, GateR_T13.md, GateF_T16.md, GateL_T20.md)
