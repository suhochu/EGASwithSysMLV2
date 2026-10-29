# DECISIONS (추가만 한다. 안전 값의 확정은 여기에 승인으로 기록될 때만 유효)

| ID | 결정할 것 | 선택지 | 추천 | 상태 | 결정 | 날짜 |
|---|---|---|---|---|---|---|
| D-01 | 요구사항 작업 순서 | A) 사용자 순서 Objective → Needs → Context. B) SPES 책 순서 Context → Goal | A 유지(레거시·Views 호환). SPES의 컨텍스트↔시나리오 일치 규칙은 lint로 강제. Needs는 Context를 import하지 않음. B를 고르면 kpi_config.json의 layers 순서와 instructions의 계층 순서를 함께 바꾼다 | open | | |
| D-02 | SHR 계층 | A) 별도 계층. B) Goal의 잎(hard goal)으로 흡수 | 별도 정의 유지, SHR을 hard goal의 하위 유형으로 모델링 | open | | |
| D-03 | Golden Path | A) 레거시: 브레이크 오버라이드, 센서 고장 페일세이프. B) EGAS: GP-A SZ-01 L2 감시 경로, GP-B PVS 이중 채널 고장 → limp home(EGAS 11.1.1) | B. 브레이크 오버라이드는 얇은 시나리오로 유지 | open | | |
| D-04 | ISO 26262 판 | A) 2011 1판(EGAS 인용). B) 2018 2판(FDTI·FRTI 등) | B 용어 사용, EGAS 인용은 SourceRef로 구분 | open | | |
| D-05 | EGAS 범위 | 가솔린 매니폴드·직분사, 디젤 토크·가속도 비교, 가솔린 가속도 비교, A-SaCo | 가솔린 매니폴드 분사 토크 비교 감시 + L3 Q&A. 나머지는 범위 밖(사유를 Registry에) | open | | |
| D-06 | 용어 정리 | SafeStateLevel(L1~L3)이 EGAS 모니터링 Level 1~3과 충돌. 레거시 CF/UF가 SPES 정의와 반대 | MonitoringLevel은 EGAS 의미, SafeStateLevel은 SafeStateStage로 개명. UF=BB user function, FN=WB function, LC=logical component | open | | |
| D-07 | 평가 증거 | 효과성을 무엇으로 판단할지 | 수용 질의 8개 + 채점표 7항목(T01에서 확정) | open | | |
| D-08 | 패키지 접두사 | `EgasArch_`(기본) 또는 다른 접두사 | `EgasArch_`. 바꾸려면 tools/sysml_scan.py의 PREFIX와 규칙 파일을 함께 수정 | open | | |
| D-09 | 비용 예산과 모델 정책 | Task당 AI Credits 상한, 모델 등급 배정(기계적 작업은 저가 모델, T02·T07·T12·T19 같은 설계·안전 판단은 상위 모델) | 월 예산의 80%를 Task 25개로 나눈 값을 상한으로 삼고, T01~T03 평균을 기준선으로 삼는다 | open | | |
| D-10 | KPI 기준 | tools/kpi_config.json의 계층별 줄·def 예산, 이주 곡선, 비목적 5개 | 기본값 유지 후 T01에서 조정 | open | | |

## 안전 값 승인 (사용자만 추가한다. AI는 수정하지 않는다)

| A-ID | 요소 | 값과 status | 근거 | 승인자 | 날짜 |
|---|---|---|---|---|---|
