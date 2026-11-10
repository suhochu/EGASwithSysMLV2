# L3 셧오프 경로와 CCF 근거 (T21a, 2026-11-10)

A-02·A-06 충족 판정을 위한 근거 정리다. 충족 여부는 AI가 판단하지 않는다. 모든 안전 값은 pilotAssumed다.

## 1. 모델 변경 요약

| 항목          | 내용                                                                                                                                               |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| ① modeChannel | UF-03·UF-07·FN-06·`l2Reaction`·`l2Output`에서 입력과 연결 제거. UF-05·06·FN-10은 L1 안이라 유지. `ModeChannelPort`·`l1Control.modeChannelOut` 제거 |
| ② L3          | `sysrControllerMonitoring`(FSR, ASIL B inherited, FuelCutOff), UF-08, FN-12·13, `l3Monitor`(`questionAnswer`·L3), `ShutOffPort`·`QnaPort`          |
| ③ CCF         | `FailureMode` 메타데이터와 `ccfSharedAccelerationInput`·`ccfSharedSensorInput`·`ccfSharedEcu`                                                      |

## 2. L3 경로의 connect (Lwb)

- `l3Monitor`에 닿는 connect: `l3Monitor.shutOffOut to l2Output.shutOffIn` 한 건이다. `qnaPort`는 연결이 없다.
- `l2Output`에 닿는 connect: 경계 `sensorInput`, 경계 `airIntake`·`fuelCommand`, `l2Reaction.safeDemandOut`, `l3Monitor.shutOffOut`.
- `l3Monitor`는 `l1*`·`l2Monitor`·`l2Reaction`과 입력 포트를 공유하지 않는다. 셧오프 요청은 `l2Output` 입력까지 L1·L2를 거치지 않는다.
- K10: UF-08은 `sysrControllerMonitoring`을, `l3Monitor`·`l2Output`은 같은 SYSR을 `satisfy`하고 SYSR은 `parentShr`에서 `derivation`으로 내려온다. FN-12·13·UF-08은 `l3Monitor`에 `allocation`된다.

## 3. 고장 사례별 구조 근거 (충족 판단 아님)

| 사례     | 모델이 보이는 것                                                                                                                                    | 한계                                                                                                                                                                      |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| L1 고장  | L2 경로(`l2Monitor`→`l2Reaction`→`l2Output`)가 `l1Control`의 `modeChannel`에 의존하지 않는다. 정상 demand는 `l2Reaction`을 거쳐 `l2Output`으로 간다 | `l2Reaction`·`l2Output`이 정상 경로에 직렬이다(A-04 이전 한계 유지)                                                                                                       |
| L2 고장  | `l3Monitor`의 셧오프 요청이 `l2Reaction` 없이 `l2Output`에 닿는다                                                                                   | 출력단 `l2Output`은 두 경로의 공통 요소다(OI-21). 검출은 Q&A에 의존하나 상대가 연결되지 않았다(OI-22)                                                                     |
| 공통원인 | 3건을 `FailureMode`로 적었다                                                                                                                        | 완화는 없거나 불완전하다. `accelerationInput`은 L3가 보지 않고, `sensorInput`은 검출이 없고, ECU는 L3도 같은 ECU다. 독립성이 입증된 것이 아니므로 ASIL 분해는 하지 않았다 |
| FTTI     | `sysrControllerMonitoring`은 `sg01Ftti`를 참조한다                                                                                                  | L3 FDTI·FRTI는 없다(OI-23). 셧오프 의미(래치·우선순위·모드)가 미정이다(OI-24)                                                                                             |

## 4. 승인 필요 안전 값 (사용자가 DECISIONS "안전 값 승인"에 기록)

1. `sysrControllerMonitoring`의 ASIL B inherited와 FSR 지위(A-03은 6개 기준).
2. `L3MonitorComponent`의 ASIL B inherited와 LC 6개(A-04는 5개 기준).
3. `l3Monitor` 메커니즘 kind `questionAnswer`·level L3.
4. 셧오프 안전 상태 단계 `FuelCutOff`(SG-01 safeState `TorqueLimited`와의 관계는 OI-24).
5. CCF 3건의 완화 상태(`detectedBy` 문구).
6. A-02 충족 여부와 A-06 보류 해제.

## 5. safety-reviewer 결과

지적 10건. 문구 수정으로 처리한 것: #1 독립성 표현을 "`l2Output` 입력까지"로 한정, #3 `ccfSharedEcu.detectedBy`를 "none"으로, #8 e101 인용 한정, #10 `detects`를 좁히고 e340·e369·e383 인용 추가. OI로 올린 것: #1·#9→OI-21, #2→OI-22, #4→OI-23, #5→OI-24, #6→OI-25. #7(D-29 기록)은 사용자 몫이다.
