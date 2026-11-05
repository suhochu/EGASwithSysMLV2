---
name: iso26262-concept-assistant
description: "HARA-lite 행(S/E/C, ASIL), Safety Goal, safeState, FTTI를 작성·검토할 때 ISO 26262-3 표로 ASIL을 검증하고 EGAS 근거 인용과 ValueStatus를 강제한다. T07, T12, T19와 안전 값을 다루는 모든 Task에서 사용한다."
---

# iso26262-concept-assistant

`egas-ref-lookup`으로 EGAS 문단을 찾은 뒤 이 절차를 따른다. 최종 판단은 사용자가 한다.

## ASIL 결정표 (ISO 26262-3:2018 Table 4)

값을 쓰기 전에 아래 표로 계산한다. 암산(합계)이나 기억에 의존하지 않는다.

| S   | E     | C1  | C2  | C3  |
| --- | ----- | --- | --- | --- |
| S1  | E1~E2 | QM  | QM  | QM  |
| S1  | E3    | QM  | QM  | A   |
| S1  | E4    | QM  | A   | B   |
| S2  | E1    | QM  | QM  | QM  |
| S2  | E2    | QM  | QM  | A   |
| S2  | E3    | QM  | A   | B   |
| S2  | E4    | A   | B   | C   |
| S3  | E1    | QM  | QM  | A   |
| S3  | E2    | QM  | A   | B   |
| S3  | E3    | A   | B   | C   |
| S3  | E4    | B   | C   | D   |

S0, E0, C0은 ASIL 평가 대상이 아니므로 QM이다.

## 규칙

1. 모든 HARA 행은 EGAS가 준 ASIL을 출발점으로 한다. EGAS 값이 있으면 S/E/C가 위 표와 일치하는지 검증하고, 불일치하면 S/E/C를 고치지 말고 사용자에게 알린다.
2. EGAS에 S/E/C가 없으면 값은 `pilotAssumed`이고 rationale에 "EGAS에 값 없음, 표 4로 ASIL과 일치시킴, 사용자 승인 대기"를 적는다. 근거를 비우지 않는다.
3. 값마다 SourceRef가 있어야 한다. EGAS 값은 `EGAS_e###`, ISO 표는 `document = "ISO 26262-3:2018"`, `itemId = "Table 4"`다.
4. 표준에 없는 S/E/C, FTTI, safeState 단계, FIT, DC는 `standard`로 쓰지 않는다. FTTI는 근거가 없으면 값 없이 `tbd`로 둔다.
5. `reviewed`는 `DECISIONS.md`의 "안전 값 승인" 표에 A-xx 행이 있을 때만 쓴다. AI는 그 표를 수정하지 않는다.
6. EGAS가 "고려 제외"한 위험 사건은 SG로 만들지 않고 제외 사유(문단 ID 포함)를 행에 남긴다.
7. safeState 단계는 "허용 시간 안에 위험을 제거하는가"를 근거로 적는다. 가용성만 근거로 삼지 않는다. 확정 전에는 `pilotAssumed`다.
8. ASIL과 FTTI는 Common 카탈로그(`Catalog_SafetyTargets`)에 한 번만 두고 SG와 메타데이터는 참조한다.
9. 하위 요구(FSR, TSR)는 상위 SG의 ASIL을 상속한다. 분해(decomposition)는 사용자 승인 없이 쓰지 않는다.

## 점검 후 보고

- 행마다 (S, E, C) → 표 4 결과 → 모델의 ASIL 일치 여부를 표로 보인다.
- `pilotAssumed`와 `tbd` 값 목록과 사용자가 승인해야 할 항목을 마지막에 나열한다.
