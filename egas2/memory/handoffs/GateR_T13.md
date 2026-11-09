### Handoff — T13 Gate-R 보고서 (2026-11-09)

판정 요약: HARD 0, 승인 없는 안전 값 22개(pilotAssumed 8 + tbd 14), 불합격 4건. 모델 파일 변경 없음. 통과 여부와 T14 진행은 사용자가 판단한다. 이탈 의심은 없고, 아래 재오픈 표의 R1(안전 값 승인)과 R2(Common 예산)를 T14 전에 정할 것을 권고한다.

## 1. 도구 출력

- `kpi.py --task T13 --gate --ide-errors 0`: FAIL(Gate에서 WARN을 실패로 본다)
  - lines 1407/2500, defs 119, migrated 35%, status standard:14/project:3/pilotassumed:8/tbd:14/reviewed:0, ide errors 0
  - WARN K1 Common 305/250(122%) — D-17·OI-08. 조치는 사용자 결정(R2).
  - WARN K15 고아 def 10 — SYSR가 `satisfy`·`verify` 없이 `#derivation`만 가진다. T14에서 UF가 `satisfy`하면 해소(OI-11).
- `check_namespace.py`: 오류 0·경고 0. `lint.py`: 오류 0·경고 0. IDE 진단 0(사용자 보고).

## 2. K10 Golden Path 사슬 (UF 이하는 T14 이후)

| 단계     | GP-A (L2 감시)                                                                                        | GP-B (PVS 이중 채널 고장 → limp home)                                                                         |
| -------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| OBJ      | `SafeTorqueObjective`                                                                                 | `SafeTorqueObjective`                                                                                         |
| CON      | `UnintendedAccelerationConcern` (`:>` OBJ)                                                            | `HardwareFailureConcern`(`:>` OBJ)은 어떤 SHR도 frame하지 않음. SHR는 `UnintendedAccelerationConcern`을 frame |
| SG       | `UnintendedAccelerationGoal`(SG-01). `MonitorTorqueRequirement :>` SG                                 | 같음                                                                                                          |
| SHR      | `MonitorTorqueRequirement`                                                                            | 같음                                                                                                          |
| SC       | `L2TorqueMonitorScenario`(refine SHR·OBJ)                                                             | `PvsFaultLimpHomeScenario`(refine SHR·OBJ)                                                                    |
| Behavior | `EgasBehavior`/`l2Behavior`(refine SHR·SC), `normal→excessSuspected→safeState`                        | `limpHome` 상태·`LimitTorque`(refine SC). `toLimpHome`에 고장 조건 없음(pedal 수신만)                         |
| SYSR     | `TorqueComparison`, `ExcessConfirmation`, `SafeStateEnforcement` (SHR·`l2Behavior`에서 `#derivation`) | `PedalSensorFaultDetection`, `LimpHomeTorqueLimit` (같은 방식)                                                |
| UF·LC    | `l2Monitor`·`l2MonitorComponent`가 `TorqueComparison`만 `satisfy`(T04 얇은 사슬)                      | 없음(T14)                                                                                                     |

끊김: GP-A는 SYSR까지 이어진다. OBJ·CON과 SG 사이에 직접 관계는 없고 SHR를 거쳐서 이어진다. SG→SYSR은 모델 관계가 아니라 `derivedFrom = "SG-01"` 문자열이다. GP-B는 CON에서 끊긴다(`HardwareFailureConcern` 미사용). K10은 UF 이하가 T14 이후이므로 현재 판정 보류, 위 두 끊김은 R3.

## 3. K11 수용 질의 (T13 목표 4개 이상)

| AQ                             | 판정                | 근거                                                                                                                                    |
| ------------------------------ | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| AQ4 부모 SHR 없는 SYSR         | 가능                | SYSR 11개 모두 `#original ::> *Shr` derivation이 있다. 빈 결과(무고아)                                                                  |
| AQ6 검증 없는 SG·SYSR          | 가능(결과는 미충족) | SYSR 검증은 `TorqueComparison` 1/11뿐. SG-01은 `validatedShr`가 SHR를 통해 간접 검증                                                    |
| AQ8 액터별 포트                | 가능(결함 1)        | `EgasContext` connect 6개로 액터-포트-item 표가 된다. `EgasSystem.torqueMonitor`는 `TorqueMonitorPort`가 비어 있고 연결·액터가 없다(R4) |
| AQ1 SG를 만족하는 UF·LC        | 부분                | SG-01→`MonitorTorqueRequirement`→`TorqueComparison`→`l2Monitor`→`l2MonitorComponent` 한 경로뿐                                          |
| AQ3 SYSR를 만족하지 않는 UF·LC | 부분                | `satisfy`가 1건이라 목록은 나오나 결과가 의미 없음                                                                                      |
| AQ2, AQ5, AQ7                  | 불가                | 분배·ASIL 할당·시나리오-구성요소 경로 없음(T14 이후)                                                                                    |

가능 3, 부분 2. 부분을 포함하면 5로 목표(4) 충족, 가능만 세면 3으로 미달이다. 판단은 사용자.

## 4. K12 목표 정렬

- CHARTER 비목적 위반 없음: WCET·단계별 ms 없음(응답 예산은 tbd 카탈로그 참조), 시나리오 6개, 레거시 전체 복제 없음, 새 도구 없음.
- MAP 목적 벗어난 산출 없음. Registry 미등록·중복 없음(lint 0).
- SPES 점검: 액터 일치는 6개 액터와 7개 포트 중 `torqueMonitor`만 짝이 없음(R4). 목표↔시나리오: `BrakeOverride`·`TorqueIntervention`·`SafetyAssessment`는 SHR만 refine하고 OBJ는 refine하지 않음. `ScenarioViewpoint` 설명은 "goal과 SHR 모두"라 불일치(R5).
- view 점검(DESIGN_MAP 3절 T05~T12 vs Ver): 있음 — goalTreeView, stakeholderConcernMatrix, contextView, actorInterfaceTable, haraTable, safetyGoalView, shrTable, validationCoverageMatrix, goalScenarioMatrix, sysrTable, fsrView, modeStateView(StateView 대응). 없음 — OperationalFlowView, InfoStructureView, TraceView(SYSR). `scenarioView : SequenceView`는 `ScenarioViewpoint`가 아닌 `ChainTraceViewpoint`에 묶여 있음(R5).
- 열린 이슈: OI-07·08·11, D-17 proposed.

## 5. 안전 값 status (reviewed 0)

standard 14 / project 3 / pilotAssumed 8 / tbd 14 / reviewed 0. 승인 필요 목록:

- pilotAssumed 8: `haraSz01.rating`(S2·E4·C2), SG-01 safeState `TorqueLimited`, FSR 6(ASIL B inherited).
- tbd 14: `sg01Ftti`, 카탈로그 4(`steadyStateTrackingLimit`, `interventionResponseBudget`, `pedalResponseBudget`, `limpHomeTorqueLimit`), SHR 3(Precision·Intervention·PedalResponse), SYSR 3(InterventionReduction·PedalOutputResponse·SteadyStateTracking), Val 3(SteadyState·Intervention·PedalResponse).
- 승인은 사용자가 DECISIONS.md "안전 값 승인" 절(현재 비어 있음)에 A-xx로 기록한다. AI는 `reviewed`를 쓰지 않았다.

## 6. 사용자 샘플 점검 3개

| #   | 대상                                                   | 모델                                                                                                                                                          | 근거                                                                                                           | 확인할 점                                                                                     |
| --- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 1   | 안전 값: `SafeStateEnforcementRequirement`의 ASIL 상속 | `asil = sg01Asil`(B), `asilOrigin = inherited`, `derivedFrom = "SG-01"`, 분해 없음. status pilotAssumed, `ftti = sg01Ftti`(tbd)                               | EGAS e83(SZ-01 ASIL B), e87(허용 시간 내 안전 상태), e127(기능 컨트롤러와 독립 반응). Sysr_Requirement 55~72행 | ASIL B 상속이 맞는가, `TorqueLimited`가 FTTI 안에 위험을 제거하는가(SG doc도 T19 확인을 요구) |
| 2   | 레거시 SYSR 판정: SYSR-07·20 → merge                   | 레거시 SYSR-07: 확정·래치 시 L3(공기·연료 전면 차단, 토크 0, `FullCutOff`)로 제한. 파일럿은 `TorqueLimited` 한 단계로 병합하고 전면 차단 단계는 이주하지 않음 | 레거시 `6. System Requirements Model.sysml` 192행, MIGRATION_MAP 14행(SYSR-20→07 병합), EGAS e87               | 전면 차단 단계 제외가 SG 안전 상태 선택(`TorqueLimited`)과 일관된가                           |
| 3   | SG-01 근거                                             | `haraSz01`(S2·E4·C2 pilotAssumed, ASIL B standard), `UnintendedAccelerationGoal`(safeState pilotAssumed, FTTI tbd)                                            | EGAS e83·e87·e90, REF_DIGEST 18행("S/E/C와 FTTI 값은 없음"), ISO 26262-3 Table 4                               | S2·E4·C2로 ASIL B가 나오는 조합이 맞는지, 값 교체 여부                                        |

## 7. 재오픈·조치 표

| #   | 항목                                                                                                                                       | 심각도    | 재오픈 Task 또는 담당                  | 비고                                                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------- | -------------------------------------- | -------------------------------------------------------- |
| R1  | 안전 값 22개 승인 없음(OI-07)                                                                                                              | 높음      | 사용자(T13 GATE), 이후 T19             | 미승인으로 T14는 진행 가능하나 T19 타이밍 예산 전에 필요 |
| R2  | Common 305/250(122%), D-17 proposed(OI-08)                                                                                                 | 중간      | 사용자 결정                            | 예산 조정 또는 정리. 125% 근접                           |
| R3  | GP-B의 `HardwareFailureConcern` 미사용, SG→SYSR이 문자열 관계, `toLimpHome`에 고장 조건 없음                                               | 중간      | T09 또는 T11                           | SHR에서 frame하거나 CON을 정리, 조건은 tbd로 표시        |
| R4  | `TorqueMonitorPort` 비어 있고 액터 연결 없음                                                                                               | 낮음      | T04·T05(Ctx) 또는 T14에서 의도 확정    | AQ8 결과에 구멍                                          |
| R5  | 누락 view(OperationalFlowView, InfoStructureView, SYSR TraceView), `scenarioView`의 viewpoint 불일치, 시나리오 3개가 OBJ를 refine하지 않음 | 낮음      | T10·T11·T12 재오픈 또는 T14·T20에 흡수 | 사용자가 선택                                            |
| R6  | K15 고아 10(OI-11), AQ1·3 부분                                                                                                             | 해소 예정 | T14                                    | UF의 `satisfy`                                           |

## 8. 권고

이탈 신호는 없다. R1과 R2의 사용자 결정 후 T14를 진행한다. R3~R5는 T14 카드에 흡수할지 재오픈할지 정한다.
