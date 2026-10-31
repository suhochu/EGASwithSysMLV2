---
name: lint-triage
description: "check_namespace.py와 lint.py의 출력(N1~N8 등)을 읽고 원인별 수정 지시로 바꾼다. 검사 오류를 고칠 때 사용한다."
---

# lint-triage

| 코드 | 의미                                                                    | 조치                                              |
| ---- | ----------------------------------------------------------------------- | ------------------------------------------------- |
| N1   | 최상위 패키지에 접두사 없음                                             | 이름을 `EgasArch_...`로 바꾸고 참조를 모두 고친다 |
| N2   | 새 모델 안에서 최상위 이름 중복                                         | 하나로 합치거나 이름을 구분한다                   |
| N3   | 레거시 패키지와 이름 충돌                                               | 새 이름으로 바꾼다. 레거시를 고치지 않는다        |
| N4   | 표준 라이브러리 이름과 충돌                                             | 접두사 이름으로 바꾼다                            |
| N5   | 레거시를 참조(`Name::`)                                                 | 참조를 지우고 필요한 내용을 새 패키지로 이주한다  |
| N6   | 패키지 밖의 요소                                                        | 해당 패키지 안으로 옮긴다                         |
| N7   | 파일 하나에 최상위 패키지가 여럿(경고)                                  | 파일을 나눈다                                     |
| N8   | archive에 `.sysml` 파일(경고)                                           | `.sysml.archived`로 이름을 바꾼다                 |
| L1   | 정의가 Registry에 없음                                                  | Registry에 먼저 등록한다(concept-registry-guard)  |
| L2   | 정의·Registry 행 중복, home package 불일치, 잘못된 status               | 병합하거나 home package를 고친다                  |
| L3   | retired·outOfScope인데 정의됨(오류), planned인데 정의됨(경고)           | 정의가 들어오면 Registry status를 active로 바꾼다 |
| L4   | 상위 계층 참조 또는 import 순환                                         | 공유 개념을 낮은 계층이나 Common으로 내린다       |
| L5   | 관계 구문이 허용 계층 밖                                                | `memory/MODELING_RULES.md`의 관계 표를 따른다     |
| L6   | 블랙박스에 port·doc 외 요소                                             | 블랙박스에는 port와 doc만 둔다                    |
| L7   | SPES Hint 위반(시나리오 선·후조건, 목표-시나리오 연결, 메타데이터 위치) | `memory/MODELING_RULES.md`의 Hint 규칙을 따른다   |
| L8   | 숫자 속성에 `@SourceRef`·`@ValueStatus` 없음                            | 두 주석을 속성 바로 앞에 붙인다                   |

수정 후 검사를 다시 실행해 오류 0을 확인한다. 같은 오류가 반복되면 규칙 문제인지 보고 OPEN_ISSUES에 적는다.
