package EgasFunctionLevelUseCases {
    doc
    /* [유스케이스 뷰포인트 - 기능 수준]
     * EGAS 시스템이 외부 액터와 어떻게 상호작용하는지를 블랙박스/그레이박스 관점으로 정의한다.
     * - 블랙박스(1번 섹션): subject = EgasSystem 전체. 05번 파일의 내부 컴포넌트는 은닉된다.
     * - 그레이박스(2번 섹션): subject = ecu/pedal/throttle 등 내부 컴포넌트. 블랙박스 기능이 내부에서
     *   어떻게 분담되는지를 `include use case`로 연결한다.
     * 각 유스케이스는 `action ... : '...Activity'`로 자신을 실현하는 액티비티(EgasUseCaseActivities 패키지)를 바인딩하고,
     * `satisfy requirement ... by ...`로 06번 파일의 SYSR 시스템 요구사항을 어떤 액티비티가 만족시키는지 명시한다.
     */
    private import EgasBaseArchitecture::*;
    private import EgasUseCaseActivities::*;
    private import EgasSystem_Requirements::*;
    private import ReqCommon::*;

    @ElementVersion {
        version = "v0.1";
    }

    // ==========================================
    // 1. 블랙박스 관점 (Black-Box Perspective)
    // - 관심 시스템(EgasSystem) 전체를 단일 Subject로 취급
    // - 가속 페달과 스로틀 밸브는 시스템 내부에 은닉됨
    // - 외부 액터(Cruise Control, Brake, Add ECU, Sensors, Fuel/Ignition)와의 기능적 상호작용만 정의
    // ==========================================

    use case def 'Manage Vehicle Speed via Cruise Control' {
        doc
        /* 외부 크루즈 컨트롤 레버의 입력을 받아 시스템 내부적으로 목표 토크를 산출하고 차량 속도를 유지하는 기능 */
        subject egasSystem : EgasSystem;
        actor ccLever : CruiseControlLever;

        objective {
            doc
            /* 운전자의 페달 입력이 없더라도 크루즈 컨트롤 설정 속도를 유지하기 위해 요구되는 엔진 동력을 지속적으로 발생시킨다. */
        }

        action manageVehicleSpeedViaCruiseControl
            : 'Manage Vehicle Speed via Cruise Control Activity';
        satisfy requirement reqCruiseControlBrakeCancel by manageVehicleSpeedViaCruiseControl;

        // 요구 토크는 ECU의 토크 중재(Arbitrate Torque Requests)를 거쳐 반영됨 (트레이서빌리티)
        include use case arbitrateTorqueRequests : 'Arbitrate Torque Requests';

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Process Braking Intent' {
        doc
        /* 주행 중 외부 브레이크 조작이 감지되었을 때, 가속 요구보다 감속/제동을 기능적으로 우선 처리하는 로직 */
        subject egasSystem : EgasSystem;
        actor brake : Brake;

        objective {
            doc
            /* 브레이크 페달 신호 입력 시, 시스템 내부의 가속 요구량을 즉각적으로 무시하거나 줄여 제동력을 확보한다. (기본 제동 협조 제어) */
        }

        action processBrakingIntent : 'Process Braking Intent Activity';
        satisfy requirement reqBrakeOverrideLogic by processBrakingIntent;
        satisfy requirement reqBrakeOverrideTiming by processBrakingIntent;

        // 제동 우선 처리(Override)는 ECU의 토크 중재(Arbitrate Torque Requests)를 거쳐 반영됨 (트레이서빌리티)
        include use case arbitrateTorqueRequests : 'Arbitrate Torque Requests';

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Coordinate External Torque Interventions' {
        doc
        /* 주행 안정성(ESP) 및 변속 충격 완화(TCU)를 위해 외부 제어기(Add ECU)가 요청하는 토크 개입을 처리하는 기능 */
        subject egasSystem : EgasSystem;
        actor addEcu : AddEcu;

        objective {
            doc
            /* 외부 ECU의 토크 증감 요구를 수신하고, 현재 운전자의 가속 요구량과 중재하여 최종 시스템 목표 토크를 조정한다. */
        }

        action coordinateExternalTorqueInterventions
            : 'Coordinate External Torque Interventions Activity';
        satisfy requirement reqExternalInterventionLatency by coordinateExternalTorqueInterventions;
        satisfy requirement reqProtocolIntegrityCheck by coordinateExternalTorqueInterventions;

        // 외부 개입 요구는 ECU의 토크 중재(Arbitrate Torque Requests)를 거쳐 반영됨 (트레이서빌리티)
        include use case arbitrateTorqueRequests : 'Arbitrate Torque Requests';

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Regulate Engine Combustion' {
        doc
        /* 최종 계산된 목표 토크를 달성하기 위해 외부 환경 데이터를 수집하고 연소 구동계에 제어 명령을 내리는 메인 기능 */
        subject egasSystem : EgasSystem;
        actor sensors : AddSensorComponents;
        actor fuelSys : FuelInjectionIgnitionSystem;

        objective {
            doc
            /* 외부 센서 데이터를 기반으로 공기량, 연료 분사량, 점화 시기를 계산하고, 구동계에 제어 명령을 내려 물리적인 엔진 토크를 발생시킨다. */
        }

        action regulateEngineCombustion : 'Regulate Engine Combustion Activity';

        // 블랙박스 기능은 그레이박스 컴포넌트 유스케이스의 수행으로 실현됨 (트레이서빌리티)
        include use case actuateThrottleValve : 'Actuate Throttle Valve';
        include use case commandFuelAndIgnition : 'Command Fuel and Ignition';

        @ElementVersion {
            version = "v0.1";
        }
    }

    // ==========================================
    // 2. 그레이박스 관점 (Gray-Box Perspective)
    // - 시스템 내부의 핵심 컴포넌트(ECU, Pedal, Throttle)가 Subject가 됨
    // - 블랙박스 유스케이스가 내부적으로 어떻게 분산/실행되는지 정의
    // ==========================================

    use case def 'Acquire Driver Acceleration Demand' {
        doc
        /* 내부 컴포넌트인 가속 페달이 운전자의 물리적 밟힘 정도를 측정하여 ECU에 전달하는 기능 */
        subject pedal : AccelerationPedal;
        actor ecu : EngineControlUnit; // Pedal 입장에서는 ECU가 데이터를 수신하는 Actor 역할 수행

        objective {
            doc
            /* 페달의 각도를 전기적 신호(AccelerationPedalPosition)로 변환하여 ECU가 운전자의 기본 요구 토크를 계산할 수 있도록 데이터를 지속적으로 제공한다. */
        }

        action acquireDriverAccelerationDemand : 'Acquire Driver Acceleration Demand Activity';
        satisfy requirement reqPvsRedundancyFaultDetection by acquireDriverAccelerationDemand;

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Arbitrate Torque Requests' {
        doc
        /* 중앙 ECU가 페달(내부) 및 외부 액터들의 다양한 토크 요구를 수집하고 중재하여 단일 목표 토크를 산출하는 로직 (Torque Coordinator) */
        subject ecu : EngineControlUnit;

        // ECU 입장에서는 시스템 내부의 페달도 입력을 제공하는 Actor로 취급됨
        actor pedal : AccelerationPedal;
        actor ccLever : CruiseControlLever;
        actor brake : Brake;
        actor addEcu : AddEcu;
        actor throttle : ThrottleValve; // 스로틀 밸브의 실제 개도각 피드백을 제공하는 내부 Actor 역할 수행

        objective {
            doc
            /* PVS(페달), CC(크루즈), 외부 제어기(ESP/TCU), 브레이크 신호를 우선순위 기반으로 중재하여 스로틀 및 연료계 제어를 위한 최종 'Indicated Torque'를 결정한다. */
        }

        action arbitrateTorqueRequests : 'Arbitrate Torque Requests Activity';
        satisfy requirement reqModularInterfaceExtensibility by arbitrateTorqueRequests;

        // 운전자 요구 토크 산출을 위해 페달 신호 획득(Acquire Driver Acceleration Demand)을 수행함 (트레이서빌리티)
        include use case acquireDriverAccelerationDemand : 'Acquire Driver Acceleration Demand';

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Actuate Throttle Valve' {
        doc
        /* 내부 컴포넌트인 스로틀 밸브가 ECU의 명령을 받아 실제 공기 흡입량을 조절하는 물리적 구동 기능 */
        subject throttle : ThrottleValve;
        actor ecu : EngineControlUnit;

        objective {
            doc
            /* ECU가 보낸 목표 개도각(ThrottlePositionCommand)에 맞춰 모터를 구동하고, 현재 밸브 위치(ThrottlePositionFeedback)를 ECU로 반환하여 목표 공기량을 맞춘다. */
        }

        action actuateThrottleValve : 'Actuate Throttle Valve Activity';
        satisfy requirement reqThrottleClosedLoopAccuracy by actuateThrottleValve;
        satisfy requirement reqTpsRedundancyFaultDetection by actuateThrottleValve;

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Command Fuel and Ignition' {
        doc
        /* 산출된 목표 토크와 공기량을 바탕으로 ECU가 최종 연료/점화 시스템을 직접 제어하는 로직 */
        subject ecu : EngineControlUnit;
        actor sensors : AddSensorComponents;
        actor fuelSys : FuelInjectionIgnitionSystem;

        objective {
            doc
            /* RPM 및 흡기 온도 등의 센서(Sensors) 데이터를 기반으로, 스로틀 밸브의 제어(공기량)와 동기화된 최적의 연료 분사 시기 및 점화 타이밍 명령을 산출하여 전송한다. */
        }

        action commandFuelAndIgnition : 'Command Fuel and Ignition Activity';
        satisfy requirement reqCombustionControlExecutionTiming by commandFuelAndIgnition;

        @ElementVersion {
            version = "v0.1";
        }
    }

    use case def 'Enforce Safe State on Actuator Fault' {
        doc
        /* 스로틀 및 연료/점화 구동계의 오작동이 감지되었을 때, 목표 토크를 안전 수준(아이들/0)으로 강제 제한하는 EGAS Level 2 안전 반응 로직 */
        subject ecu : EngineControlUnit;

        objective {
            doc
            /* 스로틀 피드백 및 연료/점화 구동계 고장 감지 플래그를 종합하여, 이상 발생 시 목표 토크를 안전 수준으로 강제 제한하고 안전 상태 진입 여부를 시스템에 알린다. */
        }

        action enforceSafeStateOnActuatorFault : 'Enforce Safe State on Actuator Fault Activity';
        satisfy requirement reqSafeStateEnforcementOnFault by enforceSafeStateOnActuatorFault;

        // 두 안전 모니터링 플래그(throttleFaultDetected, combustionFaultDetected)의 발생원을 수행함 (트레이서빌리티)
        include use case arbitrateTorqueRequests : 'Arbitrate Torque Requests';
        include use case commandFuelAndIgnition : 'Command Fuel and Ignition';

        @ElementVersion {
            version = "v0.1";
        }
    }
} // package EgasFunctionLevelUseCases

package EgasUseCaseActivities {
    doc
    /* [유스케이스 실현 액티비티 뷰포인트]
     * 위 EgasFunctionLevelUseCases 패키지의 각 유스케이스가 생략(elide)한 내부 로직을 action 흐름으로 구체화한다.
     * 각 action def는 자신을 사용하는 유스케이스와 1:1로 대응하므로 별도 버전 태그 없이 소유 유스케이스와 함께 관리된다.
     */
    private import EgasBaseArchitecture::*;

    // ==========================================
    // 유스케이스 액티비티 (Use Case Activity)
    // ==========================================

    action def 'Manage Vehicle Speed via Cruise Control Activity' {
        doc
        /* 크루즈 컨트롤 기능을 통해 차량의 목표 속도를 유지하는 전체 기능 흐름 */

        // [외부 인터페이스 매개변수]
        in ccCommand : CruiseControlCommand; // 운전자의 레버 조작 신호 (Set, Cancel 등)를 시스템으로 전달함
        in sensorData : EngineSensorData; // 차량 속도 계산을 위한 바퀴 속도, 엔진 상태 등 외부 센서 데이터 수신
        out throttleCmd : ThrottlePositionCommand; // 산출된 토크를 구현하기 위해 스로틀 모터로 보내는 목표 개도각 신호
        out fuelCmd : FuelIgnitionCommand; // 스로틀 제어와 협조하여 엔진 출력을 내기 위한 연료 분사/점화 신호

        // [세부 액션 1] 크루즈 컨트롤 입력 수신 (I/O)
        action 'Evaluate Cruise Control Input' {
            doc
            /* 운전자의 조작을 해독하여 목표 속도와 제어기 상태를 결정함 */
            in cmd : CruiseControlCommand; // 외부 레버 조작 원시 데이터
            out setSpeed; // 시스템이 유지해야 할 최종 목표 속도
            out ccState; // 제어기 활성화 여부를 통제하는 상태 변수 (Active, Standby, Off)
        }

        // [세부 액션 2] 현재 차량 속도 및 상태 수집 (I/O)
        action 'Acquire Vehicle Speed and State' {
            doc
            /* 센서 노이즈를 제거하고 제어 로직에 쓸 순수 차량 속도를 추출함 */
            in sData : EngineSensorData; // 복합 센서 원시 데이터
            out currentSpeed; // 필터링 처리된 현재 차량 속도
        }

        // [세부 액션 3] 크루즈 컨트롤 토크 요구량 연산 (Core)
        action 'Calculate CC Requested Torque' {
            doc
            /* 목표 속도와 현재 속도의 편차를 줄이기 위해 필요한 엔진 토크를 PI 제어기 등으로 연산함 */
            in targetSpd; // 도달해야 할 목표 속도
            in currSpd; // 현재 차량 속도
            in iState; // 연산 수행 여부 및 적분기(I) 초기화 시점을 결정하는 스위치
            out ccTorqueRequest; // 속도 유지를 위해 요구되는 토크 값
        }

        // [세부 액션 4] 최종 목표 토크 산출 (Core)
        action 'Determine Final Target Torque' {
            doc
            /* 크루즈 제어기의 요구 토크를 바탕으로 엔진이 내야 할 최종 출력 목표를 확정함 */
            in reqTorque; // CC 알고리즘이 요구한 토크
            out finalTargetTorque; // 안전 개입이 없다는 가정하에 확정된 시스템 최종 목표 토크
        }

        // [세부 액션 5] 액추에이터 제어 명령 생성 (I/O)
        action 'Generate Actuator Commands' {
            doc
            /* 목표 토크를 실제 동력으로 변환하기 위해 공기량(스로틀) 및 연료/점화 제어값으로 분배함 */
            in targetTorque; // 달성해야 할 최종 목표 토크
            out thCmd : ThrottlePositionCommand; // 스로틀 밸브 제어 명령
            out flCmd : FuelIgnitionCommand; // 연료 인젝터 및 점화 코일 제어 명령
        }

        // [바인딩 및 흐름 연결]
        bind ccCommand = 'Evaluate Cruise Control Input'.cmd;
        bind sensorData = 'Acquire Vehicle Speed and State'.sData;

        flow
            from 'Evaluate Cruise Control Input'.setSpeed
            to 'Calculate CC Requested Torque'.targetSpd;
        flow from 'Evaluate Cruise Control Input'.ccState to 'Calculate CC Requested Torque'.iState;
        flow
            from 'Acquire Vehicle Speed and State'.currentSpeed
            to 'Calculate CC Requested Torque'.currSpd;
        flow
            from 'Calculate CC Requested Torque'.ccTorqueRequest
            to 'Determine Final Target Torque'.reqTorque;
        flow
            from 'Determine Final Target Torque'.finalTargetTorque
            to 'Generate Actuator Commands'.targetTorque;

        bind 'Generate Actuator Commands'.thCmd = throttleCmd;
        bind 'Generate Actuator Commands'.flCmd = fuelCmd;
    }

    action def 'Process Braking Intent Activity' {
        doc
        /* 주행 중 가속 요구보다 제동을 우선적으로 처리하여(Brake Override) 추진력을 안전한 수준으로 제한하는 전체 기능 흐름 */

        // [외부 인터페이스 매개변수]
        in brakeInput : BrakePedalPosition; // 운전자의 물리적 브레이크 페달 조작 상태 (이중화된 스위치 및 압력 센서 값)
        in driverTorqueReq; // 가속 페달(PVS) 등을 통해 현재 시스템에 요구되고 있는 추진 토크
        out safeTargetTorque; // 브레이크 개입이 반영되어 차단되거나 제어 가능한 수준으로 제한된 최종 목표 토크
        out brakeOverrideActive; // 가속/제동 동시 조작에 따른 제동 우선 처리(Override) 활성화 플래그 (크루즈 컨트롤 강제 해제 등에 활용됨)

        // [세부 액션 1] 브레이크 입력 수신 (I/O)
        action 'Acquire Brake Input' {
            doc
            /* 하드웨어 스위치 및 센서의 원시 데이터를 해독하여 실제 제동 여부와 신호의 유효성을 판별함 */
            in rawBrake : BrakePedalPosition; // 브레이크 스위치/센서 원시 데이터
            out isBraking; // 최종 확인된 브레이크 작동 여부 (Boolean)
        }

        // [세부 액션 2] 가속/제동 동시 조작 타당성 평가 (Core)
        action 'Evaluate Brake Plausibility' {
            doc
            /* 운전자가 가속 페달을 밟은 상태에서 최소 페달 답력으로 브레이크를 조작하는 가속/제동 동시 상황(Plausibility)을 감지함 */
            in brakingState; // 현재 제동 활성화 여부
            in torqueReq; // 현재 가속 요구 토크
            out overrideTrigger; // 브레이크 우선 처리 조건 충족 여부
        }

        // [세부 액션 3] 제동 협조 토크 제한 연산 (Core)
        action 'Calculate Reduced Safe Torque' {
            doc
            /* 브레이크 우선 처리 조건 발동 시, 추진력을 제어 가능한 최대 한계치(Controllable maximum limit)로 강제 저감함 */
            in trigger; // 제동 우선 처리 개입 플래그
            in originalTorque; // 제한 전 원본 요구 토크
            out reducedTorque; // 제동을 위해 0 또는 아이들(Idle) 수준으로 제한된 안전 토크
        }

        // [세부 액션 4] 최종 제어 상태 출력 (I/O)
        action 'Output Safe Torque State' {
            doc
            /* 연산된 안전 토크와 오버라이드 상태를 시스템의 최종 토크 중재기(Torque Coordinator)나 타 제어 로직으로 전달함 */
            in finalTorque;
            in overrideFlag;
            out sysSafeTorque;
            out sysOverrideActive;
        }

        // [바인딩 및 흐름 연결]
        bind brakeInput = 'Acquire Brake Input'.rawBrake;

        flow from 'Acquire Brake Input'.isBraking to 'Evaluate Brake Plausibility'.brakingState;
        flow from driverTorqueReq to 'Evaluate Brake Plausibility'.torqueReq;

        flow
            from 'Evaluate Brake Plausibility'.overrideTrigger
            to 'Calculate Reduced Safe Torque'.trigger;
        flow from driverTorqueReq to 'Calculate Reduced Safe Torque'.originalTorque;

        flow
            from 'Calculate Reduced Safe Torque'.reducedTorque
            to 'Output Safe Torque State'.finalTorque;
        flow
            from 'Evaluate Brake Plausibility'.overrideTrigger
            to 'Output Safe Torque State'.overrideFlag;

        bind 'Output Safe Torque State'.sysSafeTorque = safeTargetTorque;
        bind 'Output Safe Torque State'.sysOverrideActive = brakeOverrideActive;
    }

    action def 'Coordinate External Torque Interventions Activity' {
        doc
        /* 주행 안정성(ESP) 및 변속 충격 완화(TCU) 등을 위해 외부 제어기의 토크 개입 요청을 검증하고, 기본 요구 토크와 중재(Arbitration)하는 전체 기능 흐름 */

        // [외부 인터페이스 매개변수]
        in extReq : TorqueInterventionRequest; // 외부 제어기에서 CAN/FlexRay 등 통신 버스를 통해 전달된 토크 증감 요구 원시 메시지
        in baseTorque; // 가속 페달(운전자) 또는 크루즈 컨트롤 시스템에서 요구하여 1차적으로 계산된 기본 목표 토크
        out finalArbitratedTorque; // 외부 개입 요구가 반영되어 최종적으로 중재가 완료된 시스템 목표 토크
        out interventionStatus; // 외부 개입의 정상 적용 여부 또는 통신/데이터 오류에 따른 차단(Inhibition) 상태 정보

        // [세부 액션 1] 외부 개입 요청 수신 및 유효성 검사 (I/O)
        action 'Receive and Validate External Request' {
            doc
            /* 통신 버스를 통해 수신된 토크 요구 메시지의 프로토콜 무결성(체크섬, 메시지 카운터, 수신 타임아웃 등)을 검증함 */
            in rawReq : TorqueInterventionRequest; // 네트워크 계층에서 수신된 원시 데이터
            out validReqTorque; // 통신 프로토콜 검증을 통과한 유효한 개입 토크 값
            out isReqValid; // 메시지의 정상 수신 여부 플래그 (Boolean)
        }

        // [세부 액션 2] 개입 요구량 타당성 평가 및 필터링 (Core)
        action 'Evaluate Intervention Plausibility' {
            doc
            /* 수신된 외부 토크 요구량이 물리적 한계 내에 있는지 평가하며, 통신 오류나 비정상 데이터 발생 시 개입 요청을 무시(Inhibition) 처리함 */
            in reqTorque;
            in isValid;
            out safeInterventionTorque; // 오류 시 개입을 무효화(0 또는 제한값)한 안전 토크
            out statusFlag; // 개입 처리 상태 (정상 적용, 제한 적용, 통신 오류로 인한 무시 등)
        }

        // [세부 액션 3] 토크 중재 및 우선순위 결정 (Core)
        action 'Merge Base and Intervention Torque' {
            doc
            /* 기본 목표 토크와 안전하게 필터링된 외부 개입 토크 간의 우선순위를 비교(예: 미끄럼 방지를 위한 토크 감소 우선)하여 최종 출력 토크를 결정함 */
            in baseTq;
            in interventionTq;
            out arbitratedTq; // 우선순위에 따라 가감산 또는 상/하한 제한이 적용된 최종 토크
        }

        // [세부 액션 4] 최종 중재 결과 출력 (I/O)
        action 'Output Arbitrated Torque' {
            doc
            /* 중재된 최종 토크 및 개입 적용 상태를 연소/구동계 제어 로직 등 다음 처리 단계로 전달함 */
            in finalTq;
            in status;
            out outTq;
            out outStatus;
        }

        // [바인딩 및 흐름 연결]
        bind extReq = 'Receive and Validate External Request'.rawReq;

        flow
            from 'Receive and Validate External Request'.validReqTorque
            to 'Evaluate Intervention Plausibility'.reqTorque;
        flow
            from 'Receive and Validate External Request'.isReqValid
            to 'Evaluate Intervention Plausibility'.isValid;

        flow
            from 'Evaluate Intervention Plausibility'.safeInterventionTorque
            to 'Merge Base and Intervention Torque'.interventionTq;
        flow from baseTorque to 'Merge Base and Intervention Torque'.baseTq;

        flow
            from 'Merge Base and Intervention Torque'.arbitratedTq
            to 'Output Arbitrated Torque'.finalTq;
        flow
            from 'Evaluate Intervention Plausibility'.statusFlag
            to 'Output Arbitrated Torque'.status;

        bind 'Output Arbitrated Torque'.outTq = finalArbitratedTorque;
        bind 'Output Arbitrated Torque'.outStatus = interventionStatus;
    }

    action def 'Regulate Engine Combustion Activity' {
        doc
        /* 최종 목표 토크를 달성하기 위해 엔진 센서 데이터를 수집하고, 스로틀 액추에이션 및 연료/점화 제어를 그레이박스 컴포넌트 활동에 위임하는 전체 기능 흐름 */

        // [외부 인터페이스 매개변수]
        in targetTorque; // 이전 단계(Torque Coordinator)에서 모든 제어기 및 안전 로직의 중재를 거쳐 확정된 시스템의 최종 요구 토크
        in sensorData : EngineSensorData; // 엔진 회전수(RPM), 흡기 압력/유량(Air Mass), 온도, 람다(Lambda) 센서 등 엔진 상태 원시 데이터
        in combustionStatus : CombustionSystemStatus; // 연료/점화 구동계로부터 수신되는 작동 상태 및 고장 진단 피드백
        out throttleCmd : ThrottlePositionCommand; // 스로틀 밸브의 목표 개도각 제어 신호
        out throttleFeedback : ThrottlePositionFeedback; // 스로틀 밸브로부터 반환된 실제 개도각 피드백
        out fuelIgnitionCmd : FuelIgnitionCommand; // 인젝터 분사 시간(Injection time duration) 및 점화 플러그 점화각(Spark angle) 제어 신호
        out combustionFaultDetected; // 연료/점화 구동계 이상 감지 시 발생하는 안전 모니터링 플래그

        // [세부 액션 1] 엔진 구동 상태 수집 및 진단 (I/O)
        action 'Acquire Engine State' {
            doc
            /* 복합 센서 원시 데이터를 물리적 단위로 변환하고 센서의 고장 여부(SRC High/Low 등)를 1차 진단함 */
            in rawSensors : EngineSensorData;
            out engineRpm; // 변환된 엔진 회전수
            out airLoad; // 흡기 매니폴드 압력 및 공기 유량
        }

        // [세부 액션 2] 목표 공기량 및 스로틀 제어값 연산 (Core)
        action 'Calculate Air Path Command' {
            doc
            /* 요구 토크를 발생시키기 위해 필요한 실린더 내 목표 공기량을 산출하고 스로틀 밸브의 제어각을 결정함 */
            in reqTq;
            in rpm;
            in load;
            out targetThrottleAngle; // 목표 공기량 도달을 위한 스로틀 밸브 개도각
        }

        // [세부 액션 3] 스로틀 제어 명령 패키징 (I/O)
        action 'Package Throttle Command' {
            doc
            /* 연산된 개도각을 실제 구동 하드웨어(액추에이터)가 이해할 수 있는 전기적 명령(PWM 등)으로 변환함 */
            in thAngle;
            out thOutCmd : ThrottlePositionCommand;
        }

        // [세부 액션 4] 스로틀 밸브 액추에이션 위임 (그레이박스 컴포넌트 활동 재사용, 중복 연산 제거)
        action actuateThrottleValve : 'Actuate Throttle Valve Activity';

        // [세부 액션 5] 연료/점화 제어 위임 (그레이박스 컴포넌트 활동 재사용, 중복 연산 제거)
        action commandFuelAndIgnition : 'Command Fuel and Ignition Activity';

        // [바인딩 및 흐름 연결]
        bind sensorData = 'Acquire Engine State'.rawSensors;

        // 스로틀 경로: 공기량 연산 -> 명령 패키징 -> 액추에이션 위임
        flow from targetTorque to 'Calculate Air Path Command'.reqTq;
        flow from 'Acquire Engine State'.engineRpm to 'Calculate Air Path Command'.rpm;
        flow from 'Acquire Engine State'.airLoad to 'Calculate Air Path Command'.load;
        flow
            from 'Calculate Air Path Command'.targetThrottleAngle
            to 'Package Throttle Command'.thAngle;
        flow from 'Package Throttle Command'.thOutCmd to actuateThrottleValve.throttleCmd;

        bind 'Package Throttle Command'.thOutCmd = throttleCmd;
        bind actuateThrottleValve.throttleFeedback = throttleFeedback;

        // 연료/점화 경로: 그레이박스 활동에 원시 입력을 그대로 위임
        bind targetTorque = commandFuelAndIgnition.targetTorque;
        bind sensorData = commandFuelAndIgnition.sensorData;
        bind combustionStatus = commandFuelAndIgnition.combustionStatus;
        bind commandFuelAndIgnition.fuelIgnitionCmd = fuelIgnitionCmd;
        bind commandFuelAndIgnition.combustionFaultDetected = combustionFaultDetected;
    }

    action def 'Acquire Driver Acceleration Demand Activity' {
        doc
        /* 운전자의 물리적인 가속 페달 조작을 측정하여 이중화된 전기적 센서 신호(PVS)로 변환한 뒤 ECU로 전송하는 전체 기능 흐름 */
        // 그레이박스 관점에서 'AccelerationPedal' 내부의 아키텍처 동작을 명세함

        // [외부 인터페이스 매개변수]
        in physicalPedalAngle; // 운전자가 페달을 밟는 물리적 각도 및 압력 (0~100% 범위의 기계적 변위)
        out pedalPositionData : AccelerationPedalPosition; // ECU로 전달되는 최종 전기적 센서 데이터 (PVS1, PVS2 신호 포함, 단선/단락 오류 감지를 위해 물리적으로 분리된 신호 경로 사용)

        // [세부 액션 1] 물리적 변위 측정
        action 'Measure Mechanical Angle' {
            doc
            /* 운전자의 발에 의해 발생한 기계적인 페달의 움직임을 스프링 및 레버 구조를 통해 감지함 */
            // 센서부로 전달되기 전의 순수 물리적 변화량 획득
            in angleIn; // 시스템 외부에서 입력된 기계적 각도
            out displacement; // 감지된 내부 기계적 변위량
        }

        // [세부 액션 2] 이중화된 센서 신호 생성 (Core)
        action 'Generate Redundant Sensor Signals' {
            doc
            /* 기계적 변위량을 바탕으로 두 개의 독립적인 센서 전압(PVS1, PVS2)을 생성함 */
            // 센서 1과 센서 2는 상호 검증을 위해 서로 다른 기울기 또는 전압 스윙 범위를 가져야 함
            in mechDisplacement; // 측정된 내부 기계적 변위량
            out pvs1Voltage; // 첫 번째 가속 페달 센서(PVS1)의 변환된 전기적 출력
            out pvs2Voltage; // 두 번째 가속 페달 센서(PVS2)의 변환된 전기적 출력
        }

        // [세부 액션 3] 신호 출력 (I/O)
        action 'Transmit Signals to ECU' {
            doc
            /* 변환된 아날로그 전압 또는 디지털 프로토콜(예: SENT) 신호를 ECU의 입력단으로 송출함 */
            // 와이어링 하네스를 거쳐 ECU의 A/D 컨버터로 전달되는 최종 인터페이스 역할
            in v1; // 내부 PVS1 전압
            in v2; // 내부 PVS2 전압
            out outData : AccelerationPedalPosition; // 외부(ECU)로 송출되는 최종 페달 센서 데이터 세트
        }

        // [바인딩 및 흐름 연결]
        bind physicalPedalAngle = 'Measure Mechanical Angle'.angleIn;

        flow
            from 'Measure Mechanical Angle'.displacement
            to 'Generate Redundant Sensor Signals'.mechDisplacement;

        flow from 'Generate Redundant Sensor Signals'.pvs1Voltage to 'Transmit Signals to ECU'.v1;
        flow from 'Generate Redundant Sensor Signals'.pvs2Voltage to 'Transmit Signals to ECU'.v2;

        bind 'Transmit Signals to ECU'.outData = pedalPositionData;
    }

    action def 'Arbitrate Torque Requests Activity' {
        doc
        /* ECU 내부에서 운전자(가속 페달), 크루즈 컨트롤, 외부 제어기(TCU/ESP) 및 브레이크의 요구사항을 수집하여 최종 목표 토크를 결정하는 전체 기능 흐름 */
        // 그레이박스 관점에서 'EngineControlUnit' 내부의 Torques Coordinator 로직을 명세함
        // 기능 아키텍처(Functional Architecture)로 매핑 시 핵심 Core 로직 블록이 됨

        // [외부 인터페이스 매개변수]
        in pedalPos : AccelerationPedalPosition; // 가속 페달에서 전달된 운전자 요구 전기적 센서 데이터
        in ccCmd : CruiseControlCommand; // 크루즈 컨트롤 시스템에서 발생한 설정 속도 유지 토크 요구 명령
        in brakePos : BrakePedalPosition; // 브레이크 페달 조작 유무 및 제동 상태 신호
        in extReq : TorqueInterventionRequest; // 변속기, 차체자세제어장치 등 외부 제어기가 요구하는 토크 증감 및 제한 메시지
        in throttleFeedback : ThrottlePositionFeedback; // 스로틀 밸브로부터 수신된 실제 개도각 피드백 (폐루프 모니터링용)
        out finalArbitratedTorque; // 모든 요구조건과 안전/우선순위 로직이 반영되어 최종적으로 확정된 시스템 목표 토크
        out throttleFaultDetected; // 스로틀 피드백 이상 감지 시 발생하는 안전 모니터링 플래그

        // [세부 액션 1] 개별 요구 토크 산출 및 해독 (I/O & Core)
        action 'Calculate Individual Demands' {
            doc
            /* 페달, CC, 외부 ECU의 원시 입력값을 바탕으로 각각의 물리적 요구 토크(Nm)를 산출함 */
            // 운전자 요구 토크는 내부의 페달 맵(Pedal Map)을 통해 엔진 속도와 연동하여 변환됨

            in pvs : AccelerationPedalPosition; // 가속 페달 변위량 입력
            in cc : CruiseControlCommand; // 크루즈 컨트롤 명령 입력
            in ext : TorqueInterventionRequest; // 외부 제어기 개입 요구 입력
            out driverTq; // 운전자 가속 요구 토크 (Nm)
            out ccTq; // 크루즈 컨트롤 요구 토크 (Nm)
            out extTq; // 외부 제어기 개입 요구 토크 (Nm)
        }

        // [세부 액션 2] 브레이크 오버라이드 평가 (Core)
        action 'Evaluate Brake Override Condition' {
            doc
            /* 가속 요구와 브레이크 조작이 동시에 발생했는지 확인하여 제동 우선 처리 플래그를 생성함 */
            // EGAS 안전 규격에 따라 브레이크 조작 시 가속 토크를 무효화하기 위한 선행 판단 로직

            in brk : BrakePedalPosition; // 브레이크 센서 입력
            out overrideFlag; // 브레이크 오버라이드(제동 우선) 발동 여부
        }

        // [세부 액션 3] 액추에이터 피드백 모니터링 (Core / Safety Monitoring)
        action 'Monitor Actuator Feedback' {
            doc
            /* 스로틀 밸브의 실제 개도각 피드백을 감시하여 액추에이터 오작동 여부를 판별하는 안전 모니터링 로직 */

            in throttleFb : ThrottlePositionFeedback; // 스로틀 밸브로부터 수신된 실제 개도각 피드백
            out faultDetected; // 액추에이터 오작동(단선/단락/불일치 등) 감지 여부
        }

        // [세부 액션 4] 토크 중재기 실행 (Core)
        action 'Execute Torque Coordinator' {
            doc
            /* 운전자 요구, CC 요구, 외부 제어기 개입, 브레이크 오버라이드 플래그를 종합하여 우선순위에 따라 단일 토크로 중재함 */
            // 최대/최소값 필터링 및 우선순위 룰(예: 안전 제동 최우선, 자세 제어 감산 우선) 적용

            in drvTq; // 산출된 운전자 토크
            in cruiseTq; // 산출된 CC 토크
            in externalTq; // 산출된 외부 개입 토크
            in brkOverride; // 브레이크 오버라이드 플래그
            in actuatorFault; // 액추에이터 피드백 모니터링에서 감지된 오작동 플래그
            out arbitratedTq; // 중재 완료된 목표 토크
        }

        // [세부 액션 5] 최종 결과 출력 (I/O)
        action 'Output Final Torque' {
            doc
            /* 중재기에서 결정된 최종 토크를 연소 및 공기량 제어 로직(Air/Fuel Path)으로 전달하기 위해 출력함 */
            // 산출된 토크 값의 유효 범위 제한(Limitation) 로직이 포함될 수 있음

            in arbTq; // 내부 중재 토크 결과
            out outTq; // 시스템 외부(타 액티비티)로 전달할 최종 토크 값
        }

        // [바인딩 및 흐름 연결]
        // 외부 입력을 내부 액션의 파라미터로 매핑
        bind pedalPos = 'Calculate Individual Demands'.pvs;
        bind ccCmd = 'Calculate Individual Demands'.cc;
        bind extReq = 'Calculate Individual Demands'.ext;
        bind brakePos = 'Evaluate Brake Override Condition'.brk;
        bind throttleFeedback = 'Monitor Actuator Feedback'.throttleFb;

        // 액션 간의 데이터 흐름 및 제어 흐름 정의
        flow from 'Calculate Individual Demands'.driverTq to 'Execute Torque Coordinator'.drvTq;
        flow from 'Calculate Individual Demands'.ccTq to 'Execute Torque Coordinator'.cruiseTq;
        flow from 'Calculate Individual Demands'.extTq to 'Execute Torque Coordinator'.externalTq;
        flow
            from 'Evaluate Brake Override Condition'.overrideFlag
            to 'Execute Torque Coordinator'.brkOverride;
        flow
            from 'Monitor Actuator Feedback'.faultDetected
            to 'Execute Torque Coordinator'.actuatorFault;

        flow from 'Execute Torque Coordinator'.arbitratedTq to 'Output Final Torque'.arbTq;

        // 내부 출력값을 외부 인터페이스로 매핑
        bind 'Output Final Torque'.outTq = finalArbitratedTorque;
        bind 'Monitor Actuator Feedback'.faultDetected = throttleFaultDetected;
    }

    action def 'Actuate Throttle Valve Activity' {
        doc
        /* ECU의 제어 명령을 수신하여 스로틀 밸브 모터를 물리적으로 구동하고, 현재 개도각을 이중화된 센서(TPS1, TPS2)를 통해 피드백하는 전체 기능 흐름 */
        // 그레이박스 관점에서 'ThrottleValve' 파트 내부의 아키텍처 동작을 명세함

        // [외부 인터페이스 매개변수]
        in throttleCmd : ThrottlePositionCommand; // ECU로부터 전달된 스로틀 밸브 목표 개도각 제어 신호 (PWM 등)
        out throttleFeedback : ThrottlePositionFeedback; // ECU로 다시 전달되는 현재 스로틀 밸브의 위치 피드백 센서 데이터 (TPS1, TPS2 포함, 폐루프 제어 및 고장 진단을 위해 사용됨)

        // [세부 액션 1] 제어 명령 수신 및 변환 (I/O)
        action 'Receive Throttle Command' {
            doc
            /* ECU로부터 수신된 전기적 제어 신호를 모터 구동을 위한 내부 전력 신호로 변환함 */
            // PWM 듀티비 등을 해석하여 내부 모터 드라이버의 구동 전력으로 매핑하는 역할

            in cmdIn : ThrottlePositionCommand; // 외부에서 입력된 스로틀 제어 명령
            out motorPower; // 스로틀 구동 모터로 인가될 전력 및 전압 신호
        }

        // [세부 액션 2] 물리적 밸브 구동 (Core / Physical)
        action 'Drive Throttle Motor' {
            doc
            /* 인가된 전력을 바탕으로 모터를 회전시켜 기계적인 스로틀 밸브 플랩의 각도를 변경함 */
            // 전기 에너지를 기계적 회전 에너지(공기량 조절)로 변환하는 물리적 작동 단계

            in pwr; // 모터 구동용 전력 입력
            out mechanicalAngle; // 모터 구동으로 인해 변경된 밸브의 기계적 실제 개도각
        }

        // [세부 액션 3] 개도각 측정 및 이중화 신호 생성 (Core / Sensor)
        action 'Measure Valve Position' {
            doc
            /* 밸브의 기계적 각도를 측정하여 이중화된 센서 전압(TPS1, TPS2)으로 변환함 */
            // 높은 진단 민감도를 위해 센서 1과 센서 2는 반대 방향(opposite direction)의 특성 곡선을 가지도록 설계됨

            in mechAngle; // 밸브의 기계적 실제 개도각 입력
            out tps1Voltage; // 첫 번째 스로틀 위치 센서(TPS1)의 전기적 출력 전압
            out tps2Voltage; // 두 번째 스로틀 위치 센서(TPS2)의 전기적 출력 전압 (역방향 특성)
        }

        // [세부 액션 4] 피드백 신호 전송 (I/O)
        action 'Transmit Feedback to ECU' {
            doc
            /* 생성된 TPS1, TPS2 센서 전압 신호를 통합하여 ECU의 입력단으로 송출함 */
            // ECU 내부의 제어 로직 및 모니터링 로직으로 피드백을 전달하는 최종 인터페이스

            in v1; // 내부 TPS1 전압
            in v2; // 내부 TPS2 전압
            out fbOut : ThrottlePositionFeedback; // 외부(ECU)로 송출되는 통합 스로틀 위치 피드백 데이터
        }

        // [바인딩 및 흐름 연결]
        // 외부 입력을 내부 액션의 파라미터로 매핑
        bind throttleCmd = 'Receive Throttle Command'.cmdIn;

        // 액션 간의 데이터 및 제어 흐름 정의
        flow from 'Receive Throttle Command'.motorPower to 'Drive Throttle Motor'.pwr;
        flow from 'Drive Throttle Motor'.mechanicalAngle to 'Measure Valve Position'.mechAngle;

        flow from 'Measure Valve Position'.tps1Voltage to 'Transmit Feedback to ECU'.v1;
        flow from 'Measure Valve Position'.tps2Voltage to 'Transmit Feedback to ECU'.v2;

        // 내부 출력값을 외부 인터페이스로 매핑
        bind 'Transmit Feedback to ECU'.fbOut = throttleFeedback;
    }

    action def 'Command Fuel and Ignition Activity' {
        doc
        /* 산출된 목표 토크와 엔진 센서 데이터를 바탕으로 ECU가 실제 연료 분사량(시간) 및 점화 시기를 계산하여 출력하는 전체 기능 흐름 */
        // ECU 내부의 연소 제어(Fuel/Ignition Path) 핵심 로직을 명세함

        // [외부 인터페이스 매개변수]
        in targetTorque; // Torque Coordinator 등에서 중재가 완료되어 시스템이 최종적으로 달성해야 할 목표 토크 (브레이크 오버라이드나 안전 제한이 모두 반영된 최종 값)
        in sensorData : EngineSensorData; // 엔진 회전수(RPM), 온도 등 목표 토크 구현을 위해 필요한 주변 환경 및 엔진 상태 원시 데이터
        in combustionStatus : CombustionSystemStatus; // 연료/점화 구동계로부터 수신되는 작동 상태 및 고장 진단 피드백
        out fuelIgnitionCmd : FuelIgnitionCommand; // 연료 인젝터 개방 시간 및 점화 플러그 타이밍이 포함된 최종 구동계 제어 명령 (하드웨어 타이머(예: TPU)를 통해 구동계로 전달됨)
        out combustionFaultDetected; // 연료/점화 구동계 이상 감지 시 발생하는 안전 모니터링 플래그

        // [세부 액션 1] 센서 데이터 획득 및 처리 (I/O)
        action 'Process Engine Sensor Data' {
            doc
            /* 수신된 원시 센서 데이터를 연소 제어 알고리즘에 직접 사용할 수 있는 공학 단위(RPM, 온도 등)로 스케일링함 */
            // A/D 컨버터에서 읽어들인 값을 물리값으로 변환

            in rawSensors : EngineSensorData; // 외부에서 입력된 복합 원시 센서 데이터
            out rpm; // 변환된 엔진 회전수 (Engine Speed)
            out temp; // 변환된 엔진 냉각수 및 흡기 온도
        }

        // [세부 액션 2] 연료 분사 시간 연산 (Core)
        action 'Calculate Injection Time' {
            doc
            /* 요구 토크와 현재 엔진 상태(RPM, 온도)를 바탕으로 필요한 연료량을 산출하고 이를 인젝터 개방 시간으로 변환함 */
            // 공연비(Lambda) 제어 로직이 포함될 수 있는 부분

            in reqTq; // 연소에 필요한 목표 토크
            in currentRpm; // 현재 엔진 회전수
            in currentTemp; // 현재 엔진 온도
            out injectionDuration; // 산출된 연료 인젝터 밸브 개방 시간 (ms 단위 등)
        }

        // [세부 액션 3] 점화 시기 연산 (Core)
        action 'Calculate Spark Angle' {
            doc
            /* 요구 토크와 엔진 회전수를 바탕으로 노킹(Knocking)을 방지하고 최적의 효율을 낼 수 있는 점화 타이밍을 결정함 */
            // 엔진 맵(Map) 데이터를 활용하여 크랭크축 회전 각도를 계산

            in reqTq; // 연소에 필요한 목표 토크
            in currentRpm; // 현재 엔진 회전수
            out sparkTiming; // 크랭크축 기준 점화 각도 (Spark Angle)
        }

        // [세부 액션 4] 구동계 명령 출력 (I/O)
        action 'Output Fuel and Ignition Commands' {
            doc
            /* 연산된 연료 분사 시간과 점화 시기를 실제 구동계 하드웨어가 인식할 수 있는 구조(전기적 제어 신호)로 통합하여 송출함 */
            //  기능에서 계산된 제어 변수들을 외부 파트로 전달하는 최종 인터페이스

            in injTime; // 내부 연산된 인젝터 개방 시간
            in spkAngle; // 내부 연산된 점화 시기 각도
            out cmdOut : FuelIgnitionCommand; // 외부(연료 및 점화 구동계)로 송출되는 통합 제어 명령
        }

        // [세부 액션 5] 구동계 상태 모니터링 (Core / Safety Monitoring)
        action 'Monitor Combustion Feedback' {
            doc
            /* 연료/점화 구동계의 상태 피드백을 감시하여 고장 여부를 판별하는 안전 모니터링 로직 */

            in status : CombustionSystemStatus; // 연료/점화 구동계로부터 수신된 작동 상태 및 고장 진단 데이터
            out faultDetected; // 구동계 고장(인젝터/점화 이상 등) 감지 여부
        }

        // [바인딩 및 흐름 연결]
        // 외부 입력 매개변수를 내부 액션으로 연결
        bind sensorData = 'Process Engine Sensor Data'.rawSensors;

        // 연료 분사 시간 연산을 위한 데이터 흐름
        flow from targetTorque to 'Calculate Injection Time'.reqTq;
        flow from 'Process Engine Sensor Data'.rpm to 'Calculate Injection Time'.currentRpm;
        flow from 'Process Engine Sensor Data'.temp to 'Calculate Injection Time'.currentTemp;

        // 점화 시기 연산을 위한 데이터 흐름
        flow from targetTorque to 'Calculate Spark Angle'.reqTq;
        flow from 'Process Engine Sensor Data'.rpm to 'Calculate Spark Angle'.currentRpm;

        // 연산 결과를 출력 액션으로 전달
        flow
            from 'Calculate Injection Time'.injectionDuration
            to 'Output Fuel and Ignition Commands'.injTime;
        flow
            from 'Calculate Spark Angle'.sparkTiming
            to 'Output Fuel and Ignition Commands'.spkAngle;

        // 내부 출력값을 외부 인터페이스 매핑으로 연결
        bind 'Output Fuel and Ignition Commands'.cmdOut = fuelIgnitionCmd;
        bind combustionStatus = 'Monitor Combustion Feedback'.status;
        bind 'Monitor Combustion Feedback'.faultDetected = combustionFaultDetected;
    }

    action def 'Enforce Safe State on Actuator Fault Activity' {
        doc
        /* 스로틀 및 연료/점화 구동계의 오작동 감지 플래그를 종합하여, 이상 발생 시 목표 토크를 안전 수준(아이들/0)으로 강제 제한하는 전체 기능 흐름 */

        // [외부 인터페이스 매개변수]
        in throttleFault; // 'Arbitrate Torque Requests Activity'의 스로틀 피드백 이상 감지 플래그
        in combustionFault; // 'Command Fuel and Ignition Activity'의 연료/점화 구동계 이상 감지 플래그
        in requestedTorque; // 안전 반응 적용 전의 원래 목표 토크
        out safeTorqueCommand; // 안전 반응이 적용된 최종 목표 토크
        out safeStateActive; // 안전 상태(Safe State) 진입 여부

        // [세부 액션 1] 복합 고장 상태 평가 (Core)
        action 'Evaluate Combined Fault Status' {
            doc
            /* 스로틀 및 연료/점화 구동계 중 하나라도 고장이 감지되면 안전 상태 진입 조건을 충족시킴 */

            in throttleFlt; // 스로틀 피드백 이상 감지 플래그
            in combustionFlt; // 연료/점화 구동계 이상 감지 플래그
            out faultActive; // 둘 중 하나라도 발생 시 참이 되는 복합 고장 플래그
        }

        // [세부 액션 2] 안전 토크 강제 제한 연산 (Core)
        action 'Force Safe Torque' {
            doc
            /* 복합 고장 플래그 발동 시, 목표 토크를 제어 가능한 최대 한계치(Controllable maximum limit)로 강제 저감함 */

            in trigger; // 안전 상태 진입 플래그
            in originalTorque; // 제한 전 원본 목표 토크
            out limitedTorque; // 고장 시 0 또는 아이들(Idle) 수준으로 제한된 안전 토크
        }

        // [세부 액션 3] 최종 안전 상태 출력 (I/O)
        action 'Output Safe State' {
            doc
            /* 연산된 안전 토크와 안전 상태 플래그를 시스템의 최종 토크 사용처(연소/구동계 제어 로직)로 전달함 */

            in finalTorque; // 강제 제한이 적용된 목표 토크
            in triggerFlag; // 안전 상태 진입 플래그
            out outTorque; // 시스템 외부(타 액티비티)로 전달할 최종 토크 값
            out outSafeStateActive; // 시스템 외부로 전달할 안전 상태 진입 여부
        }

        // [바인딩 및 흐름 연결]
        bind throttleFault = 'Evaluate Combined Fault Status'.throttleFlt;
        bind combustionFault = 'Evaluate Combined Fault Status'.combustionFlt;
        bind requestedTorque = 'Force Safe Torque'.originalTorque;

        flow from 'Evaluate Combined Fault Status'.faultActive to 'Force Safe Torque'.trigger;
        flow from 'Force Safe Torque'.limitedTorque to 'Output Safe State'.finalTorque;
        flow from 'Evaluate Combined Fault Status'.faultActive to 'Output Safe State'.triggerFlag;

        bind 'Output Safe State'.outTorque = safeTorqueCommand;
        bind 'Output Safe State'.outSafeStateActive = safeStateActive;
    }
} // package EgasUseCaseActivities

/* [EGAS 통합 주행 시나리오: 긴급 제동 및 차체 제어 개입]
 *
 * Phase 1: 정상 주행 및 크루즈 컨트롤 활성화
 * [UC5] Acquire Driver Acceleration Demand: 가속 페달 센서(PVS)는 운전자의 발이 페달에서 떨어져 있더라도 지속적으로 이중화된 센서 데이터를 ECU로 전송하며 대기 상태를 유지합니다.
 * [UC1] Manage Vehicle Speed via Cruise Control: 운전자가 크루즈 컨트롤을 활성화하면, 시스템은 외부 센서로부터 차량 속도를 읽어 목표 속도 유지를 위한 요구 토크를 지속적으로 계산하여 내부에 전달합니다.
 *
 * Phase 2: 긴급 상황 발생 및 외부/운전자 개입
 * [UC3] Coordinate External Torque Interventions: 빙판길에서 바퀴가 미끄러지기 시작하면, 차량의 ESP 제어기가 통신 버스를 통해 긴급 토크 저감(-100Nm)을 요청합니다[cite: 4]. 시스템은 이 메시지의 무결성을 확인하고 안전 개입 요구로 승인합니다[cite: 4].
 * [UC2] Process Braking Intent: 운전자가 브레이크 페달을 밟으면, 시스템은 하드웨어 스위치와 센서를 통해 제동 의지를 즉각적으로 인식하고 가속보다 제동을 우선시하는 오버라이드(Brake Override) 조건을 발동시킵니다[cite: 4].
 *
 * Phase 3: ECU의 중앙 토크 중재 (Torque Arbitration)
 * [UC6] Arbitrate Torque Requests: ECU 내부의 Torques Coordinator 로직이 작동하여 크루즈 컨트롤의 가속 요구, ESP의 감산 요구, 브레이크 오버라이드 플래그를 동시에 입력받습니다. 시스템은 크루즈 컨트롤 요구를 즉시 무효화하고 제동 및 ESP의 감산 요구를 최우선으로 반영하여 최종 목표 토크를 '0' 또는 최소 아이들(Idle) 수준으로 강제 제한합니다.
 *
 * Phase 4: 물리적 구동 및 엔진 제어
 * [UC4] Regulate Engine Combustion: 중재가 완료된 안전 목표 토크를 실제 물리적인 엔진 구동력으로 변환하기 위한 전반적인 블랙박스 연산이 시작됩니다[cite: 3].
 * [UC7] Actuate Throttle Valve: ECU의 명령을 받은 스로틀 밸브가 즉각적으로 닫히며 엔진으로 유입되는 공기량을 물리적으로 차단하고, 이중화된 TPS 센서를 통해 성공적으로 닫혔음을 ECU에 피드백합니다[cite: 3].
 * [UC8] Command Fuel and Ignition: 동시에 연료 및 점화 제어 로직이 작동하여 인젝터의 연료 분사 시간을 최소화하거나 차단(Injection Cut Off)하고, 점화 시기를 지연시켜 폭발력을 억제함으로써 차량을 안전하게 감속시킵니다[cite: 3].
 */
