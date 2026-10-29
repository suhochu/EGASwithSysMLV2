---
description: "EGAS SysML v2 파일럿(egas2/) 작업 규칙. egas2 하위 파일을 다룰 때 적용된다."
applyTo: "egas2/**"
---
# EGAS2 작업 규칙

## 시작할 때
1. `egas2/memory/STATE.md` → 가장 최근 `egas2/memory/handoffs/*.md` → 현재 `egas2/tasks/Txx.md` 순서로만 읽는다. 다른 파일은 카드가 지시할 때만 읽는다.
2. 레거시 모델은 통째로 읽지 않는다. `python egas2/tools/legacy_query.py list|show|grep`으로 필요한 요소만 조회한다.
3. 카드의 status가 approved가 아니면 시작하지 않고 사용자에게 알린다.

## 네임스페이스 (SysML v2는 전역 네임스페이스를 공유한다)
- `egas2/model`의 최상위 패키지 이름은 반드시 `EgasArch_`로 시작한다. 파일 하나에 최상위 패키지 하나만 두고, 패키지 밖에는 요소를 두지 않는다.
- 이름 규칙: `EgasArch_<Layer>_<Name>`. Layer는 아래 계층 순서와 같은 토큰이다: Common, Obj, Needs, Ctx, Safety, Shr, Val, Scn, Beh, Sysr, Fbb, Fwb, Lbb, Lwb, Ver (예: `EgasArch_Common_Units`, `EgasArch_Ctx_Context`). 토큰이 계층 검사(kpi.py)의 기준이므로 임의로 바꾸지 않는다. 표준 라이브러리 이름과 같은 최상위 이름은 쓰지 않는다.
- 레거시 패키지를 import하거나 `Name::`으로 참조하지 않는다. 필요하면 내용을 새 패키지로 이주한다.
- 보관할 상세 모델은 `egas2/archive/`에 `.sysml.archived` 확장자로 둔다(`.sysml`로 두면 언어 서버가 읽는다).
- 파일을 만들거나 고친 뒤 `python egas2/tools/check_namespace.py`를 실행해 오류 0을 확인한다.

## 계층 순서와 의존 방향
L0 Common → L1 Objective → L2 Needs → L3 Context(BB) → L4 Safety(HARA·SG) → L5 StakeholderReq → L6 Validation → L7 Scenario → L8 SystemBehavior → L9 SystemReq → L10 FunctionalBB → L11 FunctionalWB → L12 LogicalBB → L13 LogicalWB → L14 Verification·Views
- 패키지는 자기보다 낮은 계층만 import한다. 상위가 하위를 참조하지 않으며 순환 import는 금지한다. (D-01 결정 전에는 이 순서를 따른다.)
- `satisfy`는 설계 요소(L10 이상)가 요구를 만족할 때만 쓴다. 시나리오와 거동은 요구를 satisfy하지 않고 목표·SHR을 refine하는 dependency를 쓴다.
- 블랙박스(`EgasSystem`, `LogicalEgasSystem`)에는 port와 doc만 둔다. part, perform, action, state, exhibit, assert는 두지 않는다.

## 개념과 수치
- 새 part/item/action/enum/requirement를 정의하기 전에 `egas2/memory/REGISTRY.md`를 검색하고 있으면 재사용한다. 새 개념은 Registry에 먼저 등록한다.
- 수치와 판정 기준은 Common 카탈로그(`EgasArch_Common_*`)에만 정의하고 다른 곳은 참조한다. 값마다 SourceRef와 status(standard, project, pilotAssumed, tbd, reviewed)를 붙인다.
- 단계별 ms 할당과 WCET은 요구·기능·논리 계층에 두지 않는다.
- ID: OBJ, CON, STK, SG, SHR, SC, SYSR, UF(BB의 user function), FN(WB의 function), LC(logical component), VC.
- 코드 주석에 작업 이력 태그를 남기지 않는다. 이력은 git과 handoff가 맡는다.

## 안전 값
- ASIL, S/E/C, FTTI, FIT, DC는 EGAS 표준에 있는 값만 status=standard로 쓴다. 나머지는 pilotAssumed 또는 tbd로 표시하고 근거를 적는다.
- AI가 정한 안전 값을 확정으로 취급하지 않는다. `status = reviewed`는 사용자가 `DECISIONS.md`의 "안전 값 승인" 표에 A-xx 행을 추가한 값에만 쓴다. AI는 그 표를 수정하지 않는다.

## 범위와 마무리
- closed 상태의 결정(DECISIONS.md)은 고치지 않는다. 바꾸려면 새 D-xx 행으로 대체한다.
- 카드에 적힌 파일만 수정한다. 상위 계층의 결함은 고치지 말고 `OPEN_ISSUES.md`에 적는다.
- 끝나면 `/close-task`를 실행한다. `check_namespace.py`와 `python egas2/tools/kpi.py --task <ID>`에 HARD 항목이 남아 있으면 Task를 닫지 않는다.
- 언어: SysML 식별자와 요구 문장은 영어, doc 설명은 한국어를 허용한다(T03에서 확정).

## 토큰 절약 (Copilot은 토큰 기준으로 과금된다)
- 시작 때 읽는 것은 STATE.md, KPI_SNAPSHOT.md, 최근 handoff 1개, 현재 카드뿐이다. MAP·DESIGN_MAP·REF_DIGEST는 카드가 지시한 행만 읽는다(필요한 내용은 카드에 복사되어 있다).
- 200줄이 넘는 파일은 통째로 읽지 말고 grep이나 줄 범위로 읽는다. 같은 Task 안에서 같은 파일을 다시 읽지 않는다.
- 레거시는 `legacy_query.py`로 조회하고 `--max`로 출력 길이를 제한한다.
- 터미널 출력은 대화에 요약만 남긴다. 검사는 파일을 추가한 직후 `check_namespace.py`만, 전체 검사(kpi.py)는 Task 끝에 한 번 실행한다.
- 파일은 한 번에 쓰고 전체 재작성을 반복하지 않는다. 한 Task의 모델 산출은 400줄, md 산출은 150줄 이내로 한다. 넘을 것 같으면 멈추고 Task 분할을 제안한다.
- 한 채팅에서 Task 하나만 한다. 대화가 길어지면 `/close-task` 후 새 채팅으로 이어간다.
