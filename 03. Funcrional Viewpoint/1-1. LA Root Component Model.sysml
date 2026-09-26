package LA_RootComponentModel {
    doc
    /* [논리 관점 (Logical Viewpoint) - 1단계: 루트 논리 컴포넌트 정의]
     * SPES 2020 방법론에 따라 기능 관점(Functional Viewpoint)에서 정의된 
     * EgasSystem의 외부 경계를 그대로 채택하여 논리 관점의 최상위 루트 컴포넌트를 선언합니다.
     * 이 컴포넌트는 향후 논리 아키텍처 분해(Decomposition)의 최상위 컨테이너 역할을 수행합니다.
     */
     
    private import RV_ContextModel::*;
    private import RV_InterfaceModel::*;
    private import ScalarValues::*;
    private import ReqCommon::*;
    private import SI::*;

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 1. 루트 논리 컴포넌트 (Logical System Under Development)
    // ==========================================
    part def LogicalEgasSystem :> EgasSystem {
        doc
        /* 부모 블록인 EgasSystem의 모든 port와 정의를 그대로 물려받습니다.
         * 하위 논리 컴포넌트 분해(Decomposition) 및 제약 조건 추가를 위한 컨테이너입니다.
         */

        // (포트 선언 생략: EgasSystem으로부터 자동 상속됨)

        // 1.1 시스템 경계 수준에서 유지해야 할 핵심 제약조건 (전체 아키텍처 제약)

        // [성능] 가속 응답성 전체 지연시간 제약 (50ms)
        assert constraint SystemAccelLatency {
            accelPort.accelIntent.latency <= 50.0 [milli * s]
        }

        // [성능] 긴급 토크 개입 요구 수용 전체 지연시간 제약 (15ms)
        assert constraint SystemInterventionLatency {
            torqueInterventionPort.torqueReq.latency <= 15.0 [milli * s]
        }

        // [안전] 제동 우선 오버라이드 시 물리적 출력 차단 제약 (Zero-Torque)
        assert constraint SystemBrakeOverrideSafeState {
            brakePort.brakeInput.pressure > 0.0 [Pa] implies
            (airIntakePort.airFlow.massFlow <= 0.0 [kg / s] and
                fuelCmdPort.fuelCmd.injectionPulseWidth <= 0.0 [s])
        }

        // [안전] 치명적 센서 결함(온도 초과) 시 엔진 차단 제약
        assert constraint SystemFatalFaultCutoff {
            sensorPort.sensorData.coolantTemp > 120.0 ['°'] implies
            (airIntakePort.airFlow.massFlow <= 0.0 [kg / s] and
                fuelCmdPort.fuelCmd.injectionPulseWidth <= 0.0 [s] and
                dashboardPort.dashboardWarning.status ==
                ReqCommon::DashboardWarningStatusEnum::Critical)
        }
    }
} // package LA_RootComponentModel
