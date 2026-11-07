# STATE (Task마다 다시 쓴다. 100줄 이내)

## 현재 상태

- 마지막 완료 Task: T11 (EgasBehavior 상태머신 1개: 상태 5·전이 6, 액션 3, item 1, 모드 enum `OperatingMode`, 레거시 5-1·5-2 처리 완료)
- 다음 Task: T12 (tasks/T12.md 초안 draft, 사용자 approved 후 실행)
- 통합 브랜치: egas2-pilot (Task 브랜치에서 사용자가 통합한다)
- 현재 Task 브랜치: egas2/T11-system-behavior (사용자가 통합 후 갱신)
- 브랜치 규칙: egas2/<ID>-<slug>
- IDE 진단 방식: user-report
- 레거시 컴파일 기준선: 오류 0 / 경고 0 (사용자 보고)
- 파일럿 SysML 요소 수: 105 defs, 1100줄 (Common 270 + Obj 19 + Needs 75 + Ctx 78 + Safety 115 + Shr 101 + Val 75 + Scn 89 + Beh 89 + 나머지 사슬 + Ver 126)
- 레거시 규모: memory/LEGACY_INVENTORY.md 참조 (31개 파일, 13,769줄)
- KPI: memory/KPI_SNAPSHOT.md(자동), 정의는 memory/KPI.md. T11 WARN K1: Common 270/250줄(108%, OI-08). Val 75/80, Beh 89/200
- 크레딧: 월 약 2,000 AI Credits, Task당 약 64 Credits는 계획 기준. 실제 비용과 T01~T03 평균은 사용자 입력 대기.

## 진행표

T00 완료 | T01 완료 | T02 완료 | T03 완료 | T04 완료 | T05 완료 | T06 완료 | T07 완료 | T08 완료 | T09 완료 | T10 완료 | T11 완료 | T12~T24 대기 (전체 지도: tasks/MAP.md)

## 열린 결정

D-01~D-16 확정. 열린 이슈: OI-01·OI-02(도구), OI-03(UF/FN 재분류, T14), OI-06(내부 신호 추가, T14), OI-07(S/E/C·safeState 승인, T12·T19 전), OI-08(Common 예산 108%), OI-09(SHR·Val tbd 값 3개, T12), OI-10(limp home 제한 값 tbd, T12). 안전 값: S2·E4·C2, safeState TorqueLimited는 pilotAssumed, FTTI와 limp home 제한 값은 tbd이며 "안전 값 승인" 절은 비어 있다. 다음 사람 게이트: T12·T19 안전 판단, T13·T16·T20 Gate, T23 레거시 처분 승인.

## 포인터

- 규칙: .github/instructions/egas2.instructions.md
- 설계 지도: tasks/DESIGN_MAP.md
- 개념 사전: memory/REGISTRY.md / 참조 요약: memory/REF_DIGEST.md
- 최근 handoff: memory/handoffs/T11.md
