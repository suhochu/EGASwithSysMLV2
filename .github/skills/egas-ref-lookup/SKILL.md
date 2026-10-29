---
name: egas-ref-lookup
description: "EGAS v6.0 표준의 문단 ID(EGAS_e###)와 SPES 규칙을 REF_DIGEST.md에서 찾아 요약하고 SourceRef를 만든다. 표준 근거가 필요한 요구·값·안전 목표를 쓸 때 사용한다."
---
# egas-ref-lookup

- 먼저 `egas2/memory/REF_DIGEST.md`에서 찾는다. 원문 PDF를 다시 읽으라고 요구하지 않는다.
- 찾으면 문단 ID와 한 줄 요약을 인용하고, 모델에는 SourceRef(document=`EGAS v6.0`, itemId=`EGAS_e###`)를 붙인다. SourceRef의 정확한 SysML 형태는 T02에서 정해진 Common 메타데이터를 따른다.
- 없으면 값을 추측하지 말고 `status=tbd`로 두고 사용자에게 해당 쪽의 텍스트를 요청한다. EGAS가 `project specific` 또는 `calibratable`로 남긴 값은 `tbd`다.
- 표준에 없는 안전 값(S/E/C, FTTI, FIT, DC)은 `standard`로 표시하지 않는다.
