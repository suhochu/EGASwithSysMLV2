---
description: "Gate 점검(T13, T16, T20): 계층을 닫아도 되는지와 목표 이탈 여부를 검토한다"
agent: agent
---
현재 Gate(T13=요구, T16=기능, T20=논리 중 사용자가 지정한 것)를 점검하고 `egas2/memory/handoffs/<Task ID>.md`에 보고서를 쓴다. 모델 파일은 수정하지 않는다. 토큰 절약 규칙을 지킨다.

1. IDE 진단 오류 수를 확인한 뒤 `python egas2/tools/kpi.py --task <Task ID> --gate --ide-errors <N>` 실행. WARN도 실패로 본다. 출력을 그대로 보고서에 넣는다.
2. K10 Golden Path 사슬 완전도: GP-A, GP-B가 OBJ → CON → SG → SHR → SC → Behavior → SYSR → UF → FN → LC 중 현재 계층까지 끊김 없는가(요소 이름으로 확인, 표로 보고).
3. K11 수용 질의 AQ1~AQ8 중 이 Gate에서 답할 수 있어야 하는 것(EVAL_PLAN.md의 곡선)을 실제로 질의해 가능·부분·불가로 보고.
4. K12 목표 정렬: CHARTER.md의 비목적을 어긴 산출이 있는가, MAP.md의 Task 목적에서 벗어난 산출이 있는가.
5. SPES 일관성 규칙(액터 일치, 목표↔시나리오, 입출력 일관성)과 Registry 중복·미등록, 열린 TBD·이슈.
6. 안전 값(ASIL, FTTI, FIT)을 status별 개수로 보고하고 사용자 승인이 필요한 목록을 낸다. `reviewed`는 DECISIONS.md의 A-xx 승인 행이 있는 값만 가능하다.
   DESIGN_MAP.md 3절에서 이 Gate까지의 Task 행에 적힌 viewpoint·view가 모두 존재하는지 이름으로 확인한다.
   사용자 샘플 점검: 이 Gate에서 만든 요소 중 3개를 골라(안전 값 1개 포함) 레거시·표준 근거와 함께 표로 제시한다. 사용자가 직접 대조한다.
7. 불합격 항목은 재오픈할 Task 번호와 함께 표로 쓴다. 이탈이 의심되면 이후 카드 진행을 멈추라고 권고한다.
