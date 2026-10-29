# Repository instructions

레거시 SysML v2 모델(`egas2/` 밖)은 수정하지 않는다. 리팩터링은 `egas2/`에서만 한다.

`egas2/` 작업의 불변 규칙(상세: `.github/instructions/egas2.instructions.md`, 워크플로 명령: /start-task /close-task /plan-next-task /gate-review):
1. 시작할 때 `egas2/memory/STATE.md`, `KPI_SNAPSHOT.md`, 최근 handoff, 현재 카드만 읽는다. 레거시는 `egas2/tools/legacy_query.py`로만 조회한다.
2. 최상위 패키지 이름은 `EgasArch_<Layer>_<Name>`이다. 레거시를 import·참조하지 않고 하위 계층만 import한다.
3. 수치는 Common 카탈로그에만 둔다. 안전 값은 표준에 없으면 pilotAssumed 또는 tbd이며 승인 전에는 확정하지 않는다.
4. 카드 범위 밖은 수정하지 않는다. 끝나면 /close-task를 실행하며 `check_namespace.py`와 `kpi.py`의 HARD 항목은 0이어야 한다.
