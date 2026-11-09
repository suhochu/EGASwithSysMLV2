# Gate-L 보고서 (T20, 2026-11-09)

판정은 사용자가 한다. 보고 시점(2026-11-09)에는 모델을 수정하지 않았다. 2026-11-10 사용자 지시로 R1·R3을 모델에 반영하고 R2·R4~R8을 처리했다(12절, D-25·D-26).

## 1. 자동 검사

`python egas2/tools/kpi.py --task T20 --gate --ide-errors 0 --no-write`: check_namespace 0·0, lint 0·0, IDE 진단 0(진단 도구 No errors).

```
# KPI_SNAPSHOT (T20) FAIL  lines 1938/2675, defs 154, migrated 63%, status standard:14/project:3/pilotassumed:27/tbd:0/reviewed:0, resident 20211B
- HARD K9 resident context 20211B > 20000B
- WARN K7 migration 63% < curve 80%
```

- K9 HARD: 합계 = 고정 파일 9756B + T19 handoff 4289B + T20 카드 6166B. 카드가 커서 생긴 일시적 초과다. `handoffs/T20.md`가 T19.md를 대체하므로 4078B 이하로 쓰면 해소된다(T20.md 작성 후 재측정은 close 때).
- K7 WARN: 이주율 63% < 곡선 80%. MIGRATION_MAP의 planned·unmapped 행(OI-18의 `1-2 FE Behavior`·`2-1`·`4-1`·`4-2`·`03 1-4` 포함)이 남았다. 17점 차이를 이 행들이 모두 설명하는지는 확인하지 않았다. 조치: T23 처분 또는 곡선 조정(사용자 결정).

## 2. 경계 보존

`LogicalEgasSystem :> EgasSystem`은 port와 doc만 가진다(Lbb 6줄). 8개 포트는 상속되어 UF 경계와 같고, 모두 LC 포트에 `connect`된다.

| 경계 포트          | 방향(item)                     | connect 대상 LC 포트                     |
| ------------------ | ------------------------------ | ---------------------------------------- |
| accelerationInput  | in (AccelerationPedalPosition) | l1InputDiagnostics, l1Control, l2Monitor |
| brakeInput         | in (BrakePedalPosition)        | l1Control                                |
| torqueIntervention | in (TorqueInterventionRequest) | l1Control                                |
| sensorInput        | in (EngineSensorData)          | l2Output, l2Monitor                      |
| torqueMonitor      | item 없음(빈 포트)             | l2Monitor                                |
| airIntake          | out (IntakeAirFlow)            | l2Output                                 |
| fuelCommand        | out (FuelIgnitionCommand)      | l2Output                                 |
| dashboardOutput    | out (DashboardWarning)         | l2Reaction                               |

경계 불일치 0. 참고: `torqueMonitor`는 item이 없고 UF 출력도 대응하지 않는다(Ctx doc에 내부 감시 포트로 명시).

## 3. 할당과 satisfy (K15)

- FN 11/11이 LC에 `allocation`된다(fn01~fn11). 고아 FN 0.
- UF 7/7이 LC에 `allocation`된다. UF-07은 `l2Output`으로 이동됐고 `satisfy sysrPedalOutputResponse`도 `l2Output`이다(D-24 반영 확인). 모든 UF가 LC 하나에만 대응해 UF 하나가 여러 LC로 갈라지는 경우는 없다(UF-01·02, UF-05·06은 한 LC에 모임). UF-05의 FN 두 개도 같은 LC다.
- LC `satisfy` SYSR 11건, SYSR 11개 모두 LC가 `satisfy`한다. SYSR 없는 LC 0, LC 없는 SYSR 0. 고아 0.
- 발견(R3): FSR `sysrSafeStateEnforcement`("L1과 독립")는 `l2Reaction`만 `satisfy`한다. 독립 반응 경로의 마지막 단인 `l2Output`이 `satisfy`하는 것은 비안전 SYSR `sysrPedalOutputResponse`(SourceRef 레거시 SYSR-13, `SafetyRequirementData` 없음)뿐이다. ASIL B를 받은 `l2Output`이 FSR 추적에서 빠진다.

## 4. 포트 계약

LC 사이 채널 `connect` 7건 모두 송신 `port def`(out)와 수신 `~`켤레가 일치하고 item 타입이 같다.

| connect                                                       | 포트 def(수신은 ~)   | item             | 판정 |
| ------------------------------------------------------------- | -------------------- | ---------------- | ---- |
| l1InputDiagnostics.pedalFaultOut → l1Control.pedalFaultIn     | PedalFaultPort       | PedalFaultStatus | 일치 |
| l2Monitor.safeStateRequestOut → l1Control.safeStateRequestIn  | SafeStateRequestPort | SafeStateRequest | 일치 |
| l2Monitor.safeStateRequestOut → l2Reaction.safeStateRequestIn | 같음                 | 같음             | 일치 |
| l1Control.modeChannelOut → l2Reaction.modeChannelIn           | ModeChannelPort      | ModeChannel      | 일치 |
| l1Control.modeChannelOut → l2Output.modeChannelIn             | 같음                 | 같음             | 일치 |
| l1Control.demandOut → l2Reaction.demandIn                     | TorqueDemandPort     | TorqueDemand     | 일치 |
| l2Reaction.safeDemandOut → l2Output.demandIn                  | 같음                 | 같음             | 일치 |

경계 `connect` 11건은 같은 `port def`를 쓰고 방향이 맞는다. 불일치 0. 이 점검은 텍스트 대조이며 도구가 의미를 검증한 것은 `syside check`(T19 통과)까지다.

OI-19(Fbb flow와 LC 채널): Fbb `egasUf`의 flow 13개 중 11개는 LC 채널과 대응한다. 2개(`torqueArbitration.demand → pedalOutputResponse.demand`, `limpHomeTorqueLimit.limitedDemand → pedalOutputResponse.demand`)는 UF-07에 직접 연결되지만 LC에서는 `l2Reaction`을 거쳐 `l2Output`으로 간다. FN-06이 demand를 입력받아 safeDemand를 내는 구조라 통과가 맞다. Fbb flow가 부정확하다(R1).

## 5. K10 Golden Path 사슬

관계 종류: 구체화(`:>`), frame, #refinement, #derivation, satisfy, dependency, allocation. 끊김 0, 단 SG→SYSR은 `derivedFrom = "SG-01"` 문자열과 SHR 상속의 이중 연결이다.

| 단계     | GP-A (L2 토크 감시)                                                                                      | GP-B (PVS 이중 채널 고장 → limp home)                        |
| -------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| OBJ      | SafeTorqueObjective                                                                                      | SafeTorqueObjective                                          |
| CON      | UnintendedAccelerationConcern                                                                            | HardwareFailureConcern                                       |
| SG       | UnintendedAccelerationGoal(SG-01)                                                                        | 같음                                                         |
| SHR      | MonitorTorqueRequirement(`:>` SG, frame concern)                                                         | 같음                                                         |
| SC       | L2TorqueMonitorScenario(refine OBJ·SHR)                                                                  | PvsFaultLimpHomeScenario(refine OBJ·SHR)                     |
| Behavior | EgasBehavior(refine SHR·SC), l2Behavior                                                                  | EgasBehavior, LimitTorque(refine SC)                         |
| SYSR     | sysrTorqueComparison, sysrExcessConfirmation, sysrSafeStateEnforcement(derivation: parentShr·l2Behavior) | sysrPedalSensorFaultDetection, sysrLimpHomeTorqueLimit(같음) |
| UF       | UF-01, 02, 03                                                                                            | UF-04, 05                                                    |
| FN       | FN-01~07(uf01~03Decomposition)                                                                           | FN-08~11(uf04·05Decomposition)                               |
| LC       | l2Monitor, l2Reaction                                                                                    | l1InputDiagnostics, l1Control                                |

GP-B 경로: `pedalFaultOut → pedalFaultIn`, 이후 `l1Control`이 limp home 제한 후 `demandOut → l2Reaction → l2Output`. 100% 연결. 단 GP-A 경로의 safe state 실행은 `l2Output`이 담당하는데 R3 때문에 FSR 추적은 `l2Reaction`에서 끝난다.

## 6. K11 수용 질의

| AQ                       | 실제 질의                                                                                                                                                           | 결과                                  |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| AQ1 SG→LC                | SG-01 → MonitorTorqueRequirement·BrakeOverrideRequirement → FSR 6 → UF → LC 4(l2Monitor, l2Reaction, l1InputDiagnostics, l1Control)                                 | 가능. `l2Output`은 SG 경로에 없음(R3) |
| AQ2 변경 영향            | 컴포넌트 → satisfy SYSR → derivation → SHR → SG. 예: l1Control → 6 SYSR → SHR 5 → SG-01(brake·limp home 경로)                                                       | 가능                                  |
| AQ3 SYSR 없는 요소       | UF 7, LC 5, SYSR 11 전수 확인: 빈 결과                                                                                                                              | 가능(정당한 빈 결과). FN은 UF 경유    |
| AQ4 부모 SHR 없는 SYSR   | 11/11 derivation 있음, 빈 결과                                                                                                                                      | 가능                                  |
| AQ5 ASIL과 독립성        | LC 5개 B inherited(A-04), 독립성 요구는 e101, 분해 없음 근거 있음. 독립성·FFI를 요소로 쓴 모델은 없고 doc·Registry에만 있음                                         | 부분                                  |
| AQ6 검증 없는 SG·SYSR    | 검증 케이스 1개(`TorqueComparisonVerification` → sysrTorqueComparison). SYSR 1/11, FSR 1/6. SG는 Val 6개가 SHR을 검증하고 SG 직접은 없음                            | 부분                                  |
| AQ7 SC가 지나는 컴포넌트 | SC → SHR → SYSR → UF → LC 경로는 있음. 그러나 `parentShr` 하나가 SYSR 5개로 퍼져 GP-B가 GP-A의 LC까지 포함한다. Behavior→SYSR는 `l2Behavior` 하나라 구분하지 못한다 | 부분                                  |
| AQ8 액터별 포트          | 액터 6개, 포트 7개와 방향·item. `torqueMonitor`는 액터 없음(내부 감시 포트, 정당한 빈 결과)                                                                         | 가능                                  |

가능 5 + 부분 3. K11(T20 7개)은 부분을 포함하면 8, 가능만 세면 5다. 이 해석은 사용자가 정한다. 질의는 IDE 요소 조회와 grep으로 수행했고 도구가 실행하는 쿼리는 아직 없다(OI-01·02).

## 7. 안전 아키텍처

FFI 검토 대상 채널(L1→L2, 4개)은 모두 L1 출력이다. 분해하지 않았으므로 FFI 충족 주장은 없다.

| 채널                                               | 방향                   | 위험(출처)                                                                              |
| -------------------------------------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| modeChannelOut → l2Reaction.modeChannelIn          | l1Control → l2Reaction | L1 고장이 모드 선택을 오염시킴(OI-20 ①)                                                 |
| modeChannelOut → l2Output.modeChannelIn            | l1Control → l2Output   | 같음                                                                                    |
| demandOut → l2Reaction.demandIn                    | l1Control → l2Reaction | 정상 경로가 l2Reaction에 직렬(OI-20 ②)                                                  |
| safeStateRequestOut → l1Control.safeStateRequestIn | l2Monitor → l1Control  | L2의 safe state 요청이 L1(UF-06)을 거쳐 모드에 반영되므로 L1 고장이 반영을 막을 수 있음 |

ASIL B 분해 없음 근거: EGAS e101(L1·L2는 독립 개발해야 함)과 e102(ECU 하드웨어 무결성 확인)가 요구하는 독립성이 같은 ECU, 공유 입력 포트(`accelerationInput`·`sensorInput`)로 입증되지 않는다(A-04). 하드웨어 지표 목표는 판 확인 필요, FIT·DC는 모델링하지 않았다.

A-02 조건 근거(AI는 충족 여부를 판단하지 않는다): 구조적으로 `safeDemandOut`이 L1을 거치지 않는다. 한계는 OI-20 ①②③이다. A-06이 보류를 기록했다.

### 재오픈 표(OI-19·OI-20 처리 방안)

| 항목                        | 처리 방안(AI 제안, 사용자 결정)                                                                              | 후보 Task         |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------- |
| OI-19 Fbb flow 2개          | flow 2개를 `safeStateEnforcement.demand` 경유로 정정(Fbb -2줄 안팎). 또는 통과 동작을 doc에 둠               | T21               |
| OI-20 ① 모드 채널의 L1 의존 | `l2Output`이 `safeStateRequest`에서 자체로 safe state를 판단하게 `modeChannel` 의존을 제거. 또는 한계로 기록 | T21 또는 T24 한계 |
| OI-20 ② 직렬 단일점         | L3 경로(셧오프)를 추가하면 D-05·D-23(L3 LC 없음)을 새 D-xx로 바꿔야 함. 파일럿은 한계로 기록 권장            | 사용자 결정       |
| OI-20 ③ 공유 입력 CCF       | 공통원인 고장 검토는 모델링하지 않고 T24 한계로 기록                                                         | T24               |

## 8. K12 목표 정렬

- 비목적: WCET·단계별 ms 없음(grep). ms 값은 Common 카탈로그의 요구 수준 예산 5건뿐이다. D-05 범위 밖 요소 없음. 레거시 변경 0, 레거시 import·참조 0(check_namespace).
- 이탈 신호(비차단): ① Charter 범위에 "L3 Q&A"가 있으나 D-23이 L3 LC를 두지 않았고 `qnaCycleMax`·`qnaQuestionCountMin`(Common)은 어디서도 참조되지 않는다. Charter 문구를 고칠지 L3를 T22에서 얇게 다룰지 결정이 필요하다. ② LC 5개(카드는 4개 전제), Common 예산 380은 D-23·D-24로 기록·승인됐다.
- SPES: 블랙박스 Lbb에 part·action 없음. LC가 `satisfy`하고 FN은 하지 않아 규칙 준수. Registry: LC 5개·`AsilAllocatedComponent`·`MechanismKind`·`SafetyMechanism` 모두 등록, 중복·미등록 0.
- view 누락(DESIGN_MAP 3절 대비): `channelView`와 `fnAllocationMatrix`는 없다(`allocationView`·`logicalDecompositionView`가 대신한다). `MonitoringLevelView`·`FailurePropagationView`는 T19가 보류했다. 이름 불일치는 의도된 것으로 기록돼 있으나 DESIGN_MAP와 Ver를 맞출지는 사용자가 결정한다. Ver 222/225라 추가 여지는 3줄이다.

## 9. 안전 값

status별: pilotAssumed 27, standard 14, project 3, tbd 0, reviewed 0. 승인 A-01~A-06은 기록됐으나 모델 status는 AI가 바꾸지 않았다. `reviewed` 후보(승인 행 있음): haraSz01 rating(A-01), FSR 6개(A-03), LC ASIL(A-04), `p1Fdti`·`p1Frti`(A-05). `sg01Ftti`·safeState는 A-02·A-06 보류로 제외 권고. 승인 필요 목록:

| 값                                 | 위치                          | 상태                                                      |
| ---------------------------------- | ----------------------------- | --------------------------------------------------------- |
| p1Fdti 500 ms, p1Frti 300 ms       | Catalog_SafetyTargets         | A-05 있음. 자기 충족 가정이라 reviewed 전환은 사용자 판단 |
| LC ASIL 5개                        | `AsilAllocatedComponent` 1곳  | A-04 있음                                                 |
| 메커니즘 kind·monitoringLevel(2개) | L1InputDiagnostics, L2Monitor | 승인 행 없음                                              |
| 이전 pilotAssumed 22개             | Catalog·SG·SHR·SYSR·Val       | 대부분 A-xx 대응 없음                                     |

## 10. 사용자 샘플 점검 3개

| 샘플                                   | 모델 근거                                                                        | 표준·레거시 근거                                                                                         | 한계                              |
| -------------------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------- |
| `l2Output` 독립 경로                   | Lwb `L2OutputComponent`, connect `safeDemandOut→l2Output.demandIn`               | EGAS e127(반응은 기능 컨트롤러와 독립). 레거시 `ActuatorControlComponent`는 주석 처리됐고 독립 경로 없음 | R3, OI-20 ①②③                     |
| `p1TimingBudget`                       | Catalog_SafetyTargets 57~60행 `p1Fdti + p1Frti <= sg01Ftti`                      | ISO 26262-1 FDTI+FRTI≤FTTI. EGAS e435 500 ms는 토크 감시 검출→반응 시작 벤치마크 예시. 레거시 근거 없음  | 세 값 모두 가정, 자기 충족적      |
| `L1InputDiagnosticsComponent` 메커니즘 | `@SafetyMechanism` plausibility·L1·`derivedFrom = sysrPedalSensorFaultDetection` | EGAS e105·e107(SReq-01·03 신뢰성 검사). 레거시 `InputProcessingComponent`(1-2, 주석)                     | kind·level은 파일럿 배정, DC 없음 |

## 11. 불합격·재오픈 표 (Gate 시점)

| ID  | 항목                                                                                     | 심각도     | 재오픈 Task            |
| --- | ---------------------------------------------------------------------------------------- | ---------- | ---------------------- |
| R1  | OI-19: Fbb flow 2개가 UF-03 통과를 건너뜀                                                | 중         | T21                    |
| R2  | OI-20 ①②③ 처리 방안 결정                                                                 | 높음(A-02) | 사용자 결정 후 T21·T24 |
| R3  | `l2Output`의 FSR 추적 누락: `satisfy sysrSafeStateEnforcement by l2Output` 1줄 또는 대안 | 높음       | T21(Lwb +1줄)          |
| R4  | AQ6 검증 1/11, Ver 3줄 여유                                                              | 중         | T21 예산 결정          |
| R5  | AQ7 해상도(SHR 수준)                                                                     | 낮음       | T21 추적 매트릭스      |
| R6  | Charter L3 Q&A와 D-23 불일치, qna 값 미사용                                              | 낮음       | 사용자 결정            |
| R7  | K7 WARN 63% < 80%                                                                        | 낮음       | T23                    |
| R8  | 누락 view 4개                                                                            | 낮음       | 사용자 결정            |

권고: R2·R3을 결정하기 전에는 T21 진행을 멈추고, 결정 후 진행한다. 이 보고서는 Gate 통과를 선언하지 않는다.

## 12. 처리 결과 (2026-11-10, D-25·D-26)

| ID  | 처리                                                                                                                                                                                    | 상태                  |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| R1  | Fbb 직접 flow 2개를 없애고 `limpHomeTorqueLimit.limitedDemand`를 UF-03 입력에 연결. UF-03이 정상 demand의 유일한 경로가 되므로 activeModes를 4개 모드로 정정. flow 12개, LC 채널과 일치 | OI-19 resolved        |
| R3  | `sysrSafeStateEnforcement`를 `l2Output`(Lwb)과 UF-07(Fbb)이 `satisfy`(LC가 UF의 SYSR을 따르는 규칙 유지). AQ1 경로에 `l2Output` 포함                                                    | 반영                  |
| R2  | ① T21에서 UF-03·UF-07 `modeChannel` 입력 제거(모드는 activeModes로 표현, L2 경로가 L1 모드에 의존하지 않게). ②③ 한계로 T24에 기록. A-02 충족은 판단하지 않음                            | OI-20 open(계획 확정) |
| R4  | T21이 FSR 5개 검증 케이스 추가. Ver 줄 예산 225→265(def 12/20, 추가 후 17)                                                                                                              | 계획                  |
| R5  | AQ7은 SHR 수준 해상도로 부분 인정, T21 매트릭스와 T24에 명시                                                                                                                            | 인정                  |
| R6  | CHARTER의 L3 Q&A를 범위 밖으로 정정, qna Common 값은 표준 참조로 유지                                                                                                                   | 반영                  |
| R7  | K7 WARN 유지. 처분은 T23 사용자 승인. `03 1-4`·`EgasViews`(거의 전부 주석)는 삭제 후보, `4-1`·`4-2`는 T21 Ver 재구축 후보                                                               | WARN 유지             |
| R8  | DESIGN_MAP을 실제 view 이름으로 정정, view 4개는 추가하지 않음                                                                                                                          | 반영                  |

변경 파일: Fbb·Lwb(모델), kpi_config.json, DECISIONS, OPEN_ISSUES, CHARTER, DESIGN_MAP. 재검사 결과는 T20.md에 있다.
