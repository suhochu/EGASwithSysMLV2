package EgasFunctionLevelUseCasesGrayBox {
    // ==========================================
    // 그레이박스 관점 (Gray-Box Perspective)
    // - 시스템 내부의 핵심 컴포넌트(ECU, Pedal, Throttle)가 Subject가 됨
    // - 블랙박스 유스케이스가 내부적으로 어떻게 분산/실행되는지 정의
    // ==========================================

    private import EgasSystemContext::*;
    private import EgasUseCaseActivities::*;
    private import ReqCommon::*;

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

        @MetaInformation {
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

        @MetaInformation {
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

        @MetaInformation {
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

        @MetaInformation {
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

        @MetaInformation {
            version = "v0.1";
        }
    }
} // package EgasFunctionLevelUseCasesGrayBox
