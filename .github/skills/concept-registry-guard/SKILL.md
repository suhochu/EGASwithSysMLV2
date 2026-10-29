---
name: concept-registry-guard
description: "새 part, item, action, enum, requirement를 정의하기 전에 Registry에서 중복을 확인하고 병합·등록·폐기 판단을 한다. 모델에 새 정의를 추가할 때마다 사용한다."
---
# concept-registry-guard

REGISTRY.md 열: `concept | kind | home package | legacy names | status | note`.

1. 정의하려는 개념의 이름과 동의어를 Registry와 레거시(`legacy_query.py grep`)에서 검색한다.
2. 같은 개념이 있으면 재사용한다. 이름만 다르고 의미가 같으면 병합하고 legacy names에 옛 이름을 적는다.
3. 없으면 home package를 정하고 한 줄로 먼저 등록한 뒤 모델에 정의한다. home은 하나여야 한다.
4. 같은 신호·수치·판정식을 두 패키지에 정의하려는 순간 멈추고 Common으로 올린다.
5. 폐기한 개념은 삭제하지 말고 status=retired와 대체 개념을 적는다.
