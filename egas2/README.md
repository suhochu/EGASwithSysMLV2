# egas2: EGAS SysML v2 리팩터링 파일럿

같은 저장소 안에서 레거시 모델을 SPES·EGAS 기준으로 다시 짓는 작업 공간입니다. 끝나면 레거시를 지웁니다.

## 구조
- `memory/` 작업 기억: STATE, DECISIONS, REGISTRY, OPEN_ISSUES, EVALLOG, REF_DIGEST, MIGRATION_MAP.csv, handoffs/
- `tasks/` 전체 지도(MAP.md), 설계 지도(DESIGN_MAP.md), Task 카드(Txx.md)
- `model/` 새 SysML v2 모델(00_Common ~ 04_Views)
- `tools/` check_namespace.py, kpi.py(+kpi_config.json), legacy_inventory.py, legacy_query.py (lint.py는 T03)
- `archive/` 강등된 상세. 확장자는 `.sysml.archived`
- 저장소 루트의 `.github/`에 지침, 프롬프트, 에이전트, 스킬이 있습니다.

## 실행 방법 (VS Code, Copilot Chat Agent 모드)
1. `/start-task T01`: 카드를 읽고 실행합니다. GATE에서는 질문하고 기다립니다.
2. 결과를 검토하고 `/close-task`: 검사, handoff, STATE 갱신, 커밋, 다음 카드 초안.
3. 다음 카드를 읽고 `status: approved`로 바꾼 뒤 `/start-task Txx`.
4. Gate 카드(T13, T16, T20)는 `/gate-review`를 씁니다.
5. 통합 브랜치 `egas2-pilot`에서 Task마다 `egas2/<ID>-<slug>` 브랜치가 갈라지고, `/close-task` 뒤에 사용자가 `egas2-pilot`으로 머지합니다. 머지한 뒤 다음 Task를 시작하세요.

## 네임스페이스 규칙
SysML v2는 전역 네임스페이스를 공유합니다. 새 모델의 최상위 패키지는 `EgasArch_`로 시작하고, 레거시와 겹치는 이름을 쓰지 않으며, 레거시를 참조하지 않습니다. 모든 Task는 `python egas2/tools/check_namespace.py` 오류 0으로 끝나야 합니다.

## 레거시 삭제 게이트 (T23)
1. MIGRATION_MAP.csv에 unmapped가 없다.
2. `egas2/model`만으로 컴파일된다.
3. 새 모델에 레거시 참조가 없다(check_namespace 오류 0).
4. 사용자가 DECISIONS.md에 삭제 승인을 기록한다.
그다음 `git rm -r`로 레거시 폴더를 지웁니다. 이름을 바꿀 필요는 없습니다.

## KPI와 토큰
`memory/KPI.md`에 목표 이탈 방지 지표가 있고 `kpi.py`가 매 Task 끝에 계산합니다. Copilot은 2026년 6월부터 토큰 기준(AI Credits)으로 과금되므로, 카드는 자급자족으로 쓰고, 상주 컨텍스트는 20KB 이하로 유지하며, 한 채팅에서 한 Task만 합니다. 규칙은 `.github/instructions/egas2.instructions.md`의 "토큰 절약" 절에 있습니다.

## 안전 값
ASIL, FTTI, FIT 등은 표준에 있는 값만 status=standard입니다. AI가 만든 값은 pilotAssumed 또는 tbd이며 사용자가 DECISIONS.md에 승인으로 기록하기 전에는 확정이 아닙니다.
