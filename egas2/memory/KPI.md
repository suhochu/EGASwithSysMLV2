# KPI: 목표 이탈 방지 (T01에서 수치를 확정한다)

## North Star
시스템 아키텍처 수준의 SysML v2 모델을 SPES·EGAS 기준으로 다시 짓고, SysML v2 아키텍팅의 효과성을 평가한다.
비목적(기본값, T01에서 수정): ① 레거시 전체 재현 ② 인증용 안전 사례 ③ HW·SW 상세 설계(WCET, 단계별 ms 할당) ④ 모든 UC를 깊게 모델링 ⑤ 도구 개발.

## 지표
`python egas2/tools/kpi.py --task <ID>`가 자동 지표를 계산해 KPI_SNAPSHOT.md(덮어씀)와 KPI_LOG.csv(추가)에 쓴다. 기준값은 tools/kpi_config.json.

| ID | 지표 | 측정 | 목표 | 판정 |
|---|---|---|---|---|
| K1 | 계층별 줄 수 | 자동 | 계층 예산 이내(합계 2,500) | 예산 초과 WARN, 125% 초과 HARD |
| K2 | 계층별 def 수 | 자동 | 계층 예산 이내 | 같음 |
| K3 | 네임스페이스·계층 위반 | 자동 | 0 (접두사, 레거시 충돌·참조, 계층 토큰, 상향 import, 순환) | HARD |
| K4 | 중복 정의, Registry 미등록 | 자동 | 0 (Registry는 T03부터 HARD) | 중복 HARD |
| K5 | Common 밖 수치 리터럴 | 자동 | 0 | HARD |
| K6 | satisfy 방향, 블랙박스 순도, 이력 태그 | 자동 | 0 | HARD |
| K7 | 레거시 이주율과 레거시 무변경 | 자동 | 이주율은 곡선(T13 20%, T16 40%, T20 80%, T23 100%), 레거시 파일 수정 0 | 수정 HARD, 곡선 미달 WARN |
| K8 | 안전 값 위생 | 자동 | status 분포 보고, standard ≤ SourceRef | WARN. Gate에서는 승인 필요 목록 제출 |
| K9 | 상주 컨텍스트 크기 | 자동 | 상주 파일 합 20KB 이하(한글 3바이트 기준, 약 4k 토큰), STATE 100줄, handoff 80줄, 카드 120줄 | HARD |
| K10 | Golden Path 사슬 완전도 | Gate | T20에서 GP-A, GP-B 100% | 미달이면 다음 Phase 중단 |
| K11 | 수용 질의(AQ) 답변 가능 수 | Gate | T04 2개, T13 4개, T20 7개, T21 8개 | 미달 WARN |
| K12 | 목표 정렬 | Gate | 비목적 위반 0, MAP 목적과 다른 산출 0 | 위반 시 중단 |
| K14 | IDE 진단 오류 수 | 보고(`--ide-errors N`, 에이전트 진단 도구 또는 사용자) | 0 | 미보고 WARN(Gate는 FAIL), N>0 HARD |
| K13 | Task 비용 | 사용자 입력(EVALLOG 크레딧) | 기준선(T01~T03 평균)의 150% 이내, Task당 상한(D-09) 이내 | 초과 시 카드 분할 또는 모델 등급 조정 |

TREND 경보: 직전 Task보다 합계 줄 수가 40% 넘게 늘고 100줄 이상 늘면 WARN.

## 이탈 방지 장치
1. 매 Task 끝에 스크립트가 지표를 계산한다(AI가 스스로 보고하는 값이 아니다). HARD가 있으면 닫지 못한다.
2. 다음 카드의 목적은 MAP.md 행을 그대로 옮기며, 달라지면 DECISIONS에 사유를 남긴다.
3. 3개 Task마다 KPI_LOG.csv 추세를 한 번 훑는다(사용자 확인 포인트: T04, T07, T10, T13, ...).
4. 기준(예산, 곡선, 비목적)은 DECISIONS.md에 기록해야만 바꿀 수 있다.
5. Pilot Gate 0(T04 직후). 통과 조건: ① 얇은 사슬이 OBJ부터 LC까지 한 개씩 존재하고 IDE 진단 0 ② AQ 2개 이상 답변 가능 ③ T02~T04의 K3 HARD 재발이 Task당 평균 1회 이하 ④ Task당 크레딧이 상한 이내 ⑤ viewpoint·view 중 Syside가 렌더하는 종류를 확인. 하나라도 아니면 구성을 단순화(프롬프트·스킬 축소, 카드 분할)한 뒤 T05로 간다.
6. KPI는 구조·프로세스 이탈만 잡는다. 내용의 질(요구가 맞는가, 값이 타당한가)은 Gate마다 사용자가 샘플 3개를 레거시·표준과 대조해 확인한다(gate-review).
7. 레거시를 정당하게 수정해야 하면 `legacy_inventory.py --rebaseline`을 실행하고 DECISIONS.md에 기록한다.
