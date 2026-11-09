### Handoff — T16 Gate-F 보고서 (2026-11-09)

판정 요약: HARD 0, WARN 0, 재오픈 후보 7건(중간 1, 높음 1, 낮음 5). 보고 시점에는 모델 파일 변경이 없었고, 사용자 결정 후 11절의 후속 조치(R3 view 추가, R6 값 채움)를 반영했다. 목표 이탈 의심은 없다. 통과 여부와 T17 진행은 사용자가 판단한다.

## 1. 도구 출력

- `kpi.py --task T16 --gate --ide-errors 0 --no-write`: PASS
  - lines 1671/2610, defs 141, migrated 53%, status standard:14/project:3/pilotassumed:8/tbd:14/reviewed:0, resident 15995B(보고서 작성 후 재실행), ide errors 0, no alerts
  - 층별 줄/예산: Common 318/350, Obj 19/30, Needs 75/120, Ctx 80/180, Safety 115/130, Shr 102/160, Val 75/80, Scn 98/200, Beh 89/200, Sysr 275/300, Fbb 96/200, Fwb 125/170, Lbb 7/100, Lwb 12/200, Ver 185/190
- `check_namespace.py`: 오류 0·경고 0. `lint.py`: 오류 0·경고 0. IDE 진단 0(사용자 보고). K15 고아 0.

## 2. UF 경계 (입출력 vs Ctx 경계 신호 7개 + 내부 신호 4개)

| UF    | 입력                                                                            | 출력                                         | 경계 일치                                        |
| ----- | ------------------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------ |
| UF-01 | pedalPosition, engineSensor(경계)                                               | excessFlag(내부 `TorqueExcessFlag`)          | 경계 입력 2개는 Ctx 포트 item과 이름·타입 일치   |
| UF-02 | excessFlag                                                                      | safeStateRequest(내부)                       | 내부만                                           |
| UF-03 | safeStateRequest, modeChannel, demand(`TorqueDemand`)                           | safeDemand, warning(경계 `DashboardWarning`) | warning이 `dashboardOutput` 포트와 일치          |
| UF-04 | pedalPosition(경계)                                                             | pedalFault(내부 `PedalFaultStatus`)          | 일치                                             |
| UF-05 | pedalFault, modeChannel, demand                                                 | limitedDemand(`TorqueDemand`)                | 내부만                                           |
| UF-06 | pedalPosition, brakePosition, torqueRequest(경계), pedalFault, safeStateRequest | demand(`TorqueDemand`), modeChannel(내부)    | 경계 입력 3개 일치                               |
| UF-07 | demand, engineSensor(경계), modeChannel                                         | airFlow, fuelCommand(경계)                   | 출력 2개가 `airIntake`·`fuelCommand` 포트와 일치 |

- 경계 신호 7개는 모두 UF에서 쓰인다. 내부 4개의 생산·소비: `TorqueExcessFlag` UF-01→02, `SafeStateRequest` UF-02→03·06, `PedalFaultStatus` UF-04→05·06, `ModeChannel` UF-06→03·05·07.
- 중복 정의 없음: `item def` 11개는 Common_Signals에, `TorqueDemand`는 Beh에 한 번씩만 있다. 다만 카드 가정("경계 7 + 내부 4의 부분집합")과 달리 UF 4개가 Beh의 `TorqueDemand`를 쓴다(R2).
- 결함(R1): `safeDemand`(UF-03)와 `limitedDemand`(UF-05)를 소비하는 UF가 없다. UF-07은 `demand`만 받는다. `EgasUserFunctions`에는 UF 사이 `flow`·`connection`이 없어 연결은 이름 일치뿐이다.

## 3. `satisfy` 완전성

- SYSR 11개 모두 UF에 `satisfy`된다(Fbb 104~114행). UF-06이 5개(BrakeOverride, ArbitrationPriority, InterventionReduction, InterventionRelease, SteadyStateTracking), UF-01~05·07이 각 1개.
- SYSR 없는 UF 0. SHR 부모 없는 SYSR 0(11개 모두 `#derivation`). K15 고아 0.
- FN 11개는 직접 `satisfy`가 없고 UF에 plain `dependency`만 있다(D-20).

## 4. BB↔WB 포트 점검

- UF-01~05의 입력 8개와 출력 5개가 모두 FN 포트에 `bind`된다. 빠진 포트 0, 같은 포트 중복 바인딩 0(`safeStateRequest`가 FN-06·07로 나뉘는 것은 팬아웃), 타입 불일치 0.
- FN 사이 `flow` 5개(FN-01→03, 02→03, 04→05, 08→09, 10→11)는 출력과 입력의 타입이 같다(`TorqueQuantity`, `Boolean`). 모든 FN 입력이 `bind` 또는 `flow`로 채워진다.
- FN `action def` 11개 모두 WB에서 사용 중, 고아 0. 합성 동작은 입출력 타입 수준에서 UF와 같다(BB 입출력 = WB `bind` 집합).
- UF-06·07은 D-20에 따라 분해하지 않았다.

## 5. K10 Golden Path 사슬 (LC는 T17·T18 이후)

| 단계     | GP-A                                                                                        | GP-B                                                                      |
| -------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| OBJ      | `SafeTorqueObjective`                                                                       | 같음                                                                      |
| CON      | `UnintendedAccelerationConcern`(`:>` OBJ)                                                   | `HardwareFailureConcern`(`:>` OBJ). `MonitorTorqueRequirement`가 `frame`  |
| SG       | `UnintendedAccelerationGoal`(SG-01)                                                         | 같음                                                                      |
| SHR      | `MonitorTorqueRequirement`(`:>` SG)                                                         | 같음                                                                      |
| SC       | `L2TorqueMonitorScenario`(refine SHR·OBJ)                                                   | `PvsFaultLimpHomeScenario`(refine SHR·OBJ)                                |
| Behavior | `EgasBehavior`/`l2Behavior`(refine SHR·SC)                                                  | `limpHome` 상태, `LimitTorque`(refine SC). 고장 조건은 tbd 주석           |
| SYSR     | `sysrTorqueComparison`, `sysrExcessConfirmation`, `sysrSafeStateEnforcement`(`#derivation`) | `sysrPedalSensorFaultDetection`, `sysrLimpHomeTorqueLimit`(`#derivation`) |
| UF       | UF-01, UF-02, UF-03(`satisfy`)                                                              | UF-04, UF-05(`satisfy`)                                                   |
| FN       | FN-01~07(`dependency`)                                                                      | FN-08~11(`dependency`)                                                    |
| LC       | `l2MonitorComponent`가 FN-03만 `allocation`                                                 | 없음(T18)                                                                 |

OBJ→SYSR→UF→FN은 GP-A·GP-B 모두 끊김이 없다. SG→SYSR의 FSR 값은 `derivedFrom` 문자열이지만 SHR의 `:>` SG와 `#derivation`으로 모델 경로가 있다. LC 이하는 T17·T18이 채운다.

## 6. K11 수용 질의

| AQ            | 판정                | 근거                                                                                       |
| ------------- | ------------------- | ------------------------------------------------------------------------------------------ |
| AQ1           | 부분                | SG-01←SHR←`#derivation`←SYSR←`satisfy` UF까지 질의된다. FN은 `dependency` 경유, LC는 1개뿐 |
| AQ3           | 부분                | UF는 7개 모두 SYSR이 있어 빈 결과가 정당하다. FN 11개는 직접 `satisfy`가 없다              |
| AQ4           | 가능                | SYSR 11개 모두 SHR derivation이 있다(빈 결과)                                              |
| AQ6           | 가능(결과는 미충족) | SYSR 검증은 `TorqueComparison` 1/11. SG-01은 `validatedShr`로만 간접                       |
| AQ8           | 가능                | `EgasContext` 액터-포트-item 표. `torqueMonitor`는 내부 포트로 doc 표시(OI-13)             |
| AQ2, AQ5, AQ7 | 불가                | 분배·ASIL 할당·시나리오-구성요소 경로 없음(T17~T20)                                        |

가능 3 + 부분 2로 T13과 같다. T20 목표 7개를 위해 T18(LC 할당)·T19(ASIL 할당)가 필요하다.

## 7. K12 목표 정렬과 일관성

- CHARTER 비목적 위반 없음: `02_Functional`·`03_Logical`에 WCET·ms·ASIL·FTTI 값·보정·진단 없음(grep 0). UF-06 doc의 크루즈는 "범위 밖" 표기뿐. MAP T14·T15 목적 외 산출 없음.
- Registry: FN 10개·`ExcessConfirmationFunction` 등 UF 7개·view 4개·내부 신호 4개 등록됨, 중복·미등록 0(lint 0).
- view 점검(DESIGN_MAP 52~53행 vs Ver): `ufHierarchyView`, `modeDependencyView`, `ufInterfaceTable` 있음. `fwbDecompositionView`(FnDataflowView 대체) 있음. BbWbMappingTable 없음(D-20, R3).
- 열린 이슈: OI-07(안전 값 승인), OI-01·02(도구). OI-08은 본문이 resolved인데 상태 열이 `open`(R5).

## 8. 안전 값 status (reviewed 0)

standard 14 / project 3 / pilotAssumed 8 / tbd 14 / reviewed 0(T13 이후 변화 없음). 승인 필요 목록:

- pilotAssumed 8: `haraSz01.rating`(S2·E4·C2), SG-01 safeState `TorqueLimited`, FSR 6(ASIL B inherited). A-01~A-03은 기록됐으나 모델 status는 pilotAssumed 그대로.
- tbd 14: `sg01Ftti`, 카탈로그 4, SHR 3, SYSR 3, Val 3(T13 보고서와 같은 구성).
- 상태 표기가 없어 위 집계에 안 잡히는 것: `activeModes` 7개(pilot allocation, 주석만), limpHome·safeState 진입 조건(tbd 주석), FN doc의 tbd 5개(FN-04·09 확인 시간, FN-06 안전 상태 값, FN-08 편차 한계, FN-11 제한 값). 승인은 사용자가 DECISIONS.md "안전 값 승인" 절에 A-xx로 기록한다. AI는 `reviewed`를 쓰지 않았다.

## 9. 사용자 샘플 점검 3개

| #   | 대상                                  | 모델                                                                                                              | 근거                                                                                                 | 확인할 점                                                                                    |
| --- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| 1   | UF-01 분해와 `permissibleTorque` 도출 | FN-01(pedalPosition→permissibleTorque), FN-02(engineSensor→actualTorque), FN-03이 비교해 `excessFlag`. Fwb 8~29행 | EGAS e117~e128(L2: 허용 토크와 실제 값 비교), REF_DIGEST 20행, MIGRATION_MAP 23행                    | 허용 토크를 페달 위치만으로 도출해도 되는가(엔진 속도 등 다른 입력 불필요한가)               |
| 2   | 레거시 3-3 rebuilt 판정               | `CriticalSensorFaultFailSafe_WhiteBox`(classifyFault 2.0 ms→shutdownSystem 3.0 ms, 공기·연료 차단, 경고)→FN-06·07 | 레거시 `3-3 FW UF3 WhiteBox Model.sysml` 115~174행, MIGRATION_MAP 25행                               | ms 제약·`failSafeStageBudget`을 버리고 분류 단계를 UF-02·04로 분산한 rebuilt 판정이 타당한가 |
| 3   | FN-06 safeState 대체                  | 레거시는 공기·연료를 0으로 차단. FN-06은 `safeDemand`를 내고 값은 tbd. SG-01 safeState는 `TorqueLimited`          | EGAS e46(단계적 반응)·e50(엔진 정지는 다른 반응이 없을 때만), DECISIONS A-02(T19에서 FTTI 확인 조건) | 전면 차단 제거가 맞는가. `safeDemand`가 UF-07로 연결되지 않는 점(R1)                         |

## 10. 재오픈·조치 표

| #   | 항목                                                                                                              | 심각도 | 재오픈 Task 또는 담당 | 비고                                       |
| --- | ----------------------------------------------------------------------------------------------------------------- | ------ | --------------------- | ------------------------------------------ |
| R1  | `safeDemand`·`limitedDemand` 미소비, UF 사이 `flow` 없음. UF-06 priority와 UF-03·05가 같은 일을 중복              | 중간   | T14 재오픈 또는 T17   | UF-06 입력으로 연결하거나 UF-06 doc을 정정 |
| R2  | `ufInterfaceTable`이 Beh `TorqueDemand`를 expose하지 않음. 신호가 Signals 밖에도 있음                             | 낮음   | T17·T20               | Ver +1줄(185/190)                          |
| R3  | BbWbMappingTable 없음(D-20 통합). FN→UF는 plain `dependency`                                                      | 낮음   | 사용자 결정           | 추가 시 Ver 여유 5줄                       |
| R4  | FN 직접 `satisfy` 없음, LC `satisfy`·`allocation` 1건. AQ1·3 부분                                                 | 낮음   | T18                   | FN 10개의 LC 할당                          |
| R5  | OI-08 상태 열 `open`(본문은 resolved)                                                                             | 낮음   | 사용자(문서 정리)     | 이 Task 범위 밖이라 수정하지 않음          |
| R6  | 안전 값 22개 승인 없음(OI-07), 상태 없는 tbd·`activeModes`                                                        | 높음   | 사용자, 이후 T19      | T19 타이밍 예산 전                         |
| R7  | MIGRATION_MAP의 `1-2 FE Behavior`·`2-1`·`4-1`·`4-2`가 unmapped planned. `1-2`의 "Fwb 상태 재구성"은 T15에서 안 됨 | 낮음   | T17~T20, T23          | 처분을 정해 map에 반영                     |

## 11. 권고와 사용자 결정(D-21)

이탈 신호는 없다. 사용자가 다음과 같이 정했다.

- R1: T17에 흡수(OI-15). R2·R5: T17·T20(OI-16). R4: T18(OI-17). R7: T17~T20·T23(OI-18).
- R3: `bbWbMappingTable : GridView`를 Ver에 추가했다(Ver 185 → 190/190, Registry 등록). 이후 Ver 줄 추가는 예산 조정이 필요하다.
- R6: 사용자가 값 선정을 AI에게 위임했다. 카탈로그 5개를 pilotAssumed 값으로 채웠다: `sg01Ftti` 1 s, `interventionResponseBudget` 50 ms, `pedalResponseBudget` 100 ms, `limpHomeTorqueLimit` 50 N·m, `steadyStateTrackingLimit` 5. SHR 3·SYSR 3·Val 3의 status도 pilotAssumed로 바꿨다. status는 pilotAssumed 8 → 22, tbd 14 → 0, reviewed 0이다. AI가 정한 값이라 승인이 아니며 `reviewed`로 바꾸려면 사용자가 DECISIONS "안전 값 승인" 절에 A-xx를 추가해야 한다. FN doc의 tbd(확인 시간 2개, 편차 한계, 안전 상태 값)와 `activeModes`는 값 없이 남았다.
- 반영 후 검사: `kpi.py --gate` PASS(줄 1710/2610, Common 336/350, Val 80/80, Fwb 136/170, Ver 190/190, pilotassumed:22/tbd:0; 줄 증가는 포매터의 줄바꿈 포함), `check_namespace` 0, `lint` 0, `syside check` 통과. 에이전트 진단 오류 0(사용자 IDE 진단은 close 때 재확인).
