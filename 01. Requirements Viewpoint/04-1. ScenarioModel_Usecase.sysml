package EgasUseCases {
    private import EgasSystemContext::*;
    private import EgasStakeholderRequirements::*;
    private import SI::*;

    constraint validationCriteria;

    use case def <UC1> 'Driving Torque Demand Arbitration & Control' {
        doc
        /* 운전자(가속/제동) 및 크루즈 컨트롤의 토크 요구를 수용 및 중재(Brake Override 포함)하여 
         * 엔진과 연료/점화 시스템으로 최종 제어 명령을 출력하고 상태를 피드백받는 유스케이스
         */

        subject egas : EgasSystem;

        // 입력 액터
        actor driver : Driver;
        actor ccLever : CruiseControlLever;
        actor brake : Brake;

        // 출력 및 피드백 액터
        actor fuelSys : FuelInjectionIgnitionSystem;
        actor engine : Engine;

        satisfy requirement 'SHR-01'; // reqSafeTorqueArbitration
        satisfy requirement 'SHR-08'; // reqDriverPedalResponsiveness
        satisfy requirement 'SHR-02-1'; // reqSteadyStatePrecision

        // ==========================================
        // 액션(시나리오) 정의 - 각 액션이 하나의 완전한 시나리오를 대변함
        // ==========================================

        action UC1_Normal_Manual_Acceleration {
            doc
            /* [주 성공 시나리오] 
             * 운전자의 가속 페달 입력을 50ms 이내에 처리하고, 승차감(Jerk)과 정밀도(오버슈트)를 
             * 통제하면서 산출된 요구 토크를 엔진 및 연료계로 전달하여 부드럽게 가속하는 전체 흐름
             */

            constraint precondition {
                doc
                /* 운전자가 가속 페달을 물리적으로 밟아 가속 의지가 전달된 상태여야 함 */
                egas.accelPort.accelIntent.pedalDisplacement > 0.0 [mm]
            }

            // [Messages]
            message msgAccel of AccelerationIntent
                from driver.pressesAccelPedal to egas.commandsManualTorque {
                bind payload = egas.accelPort.accelIntent;
            }

            message msgAirCmd of IntakeAirFlow
                from egas.commandsManualTorque to engine.receivesAirFlow {
                bind payload = egas.airIntakePort.airFlow;
            }

            message msgFuelCmd of FuelIgnitionCommand
                from egas.commandsManualTorque to fuelSys.injectsFuel {
                bind payload = egas.fuelCmdPort.fuelCmd;
            }

            // ==========================================
            // 2. 피드백 메시지 정의 및 비기능 제약(정밀도/승차감) 인라인 적용
            // ==========================================
            message msgFeedback of CombustionSystemStatus
                from fuelSys.injectsFuel to egas.commandsManualTorque {
                bind payload = egas.combustionStatusPort.combustionStatus;
                ref constraint <uc1_vc02>;
            }

            message msgDynamics of VehicleDynamicsFeedback
                from engine.receivesAirFlow to egas.commandsManualTorque {
                bind payload = egas.dynamicsFeedbackPort.dynamicsStatus;
                ref constraint <uc1_vc03>;
            }

            // [Sequence Flow]
            first msgAccel;

            // 입력 수신 후 병렬(동시)로 공기량 및 연료량 제어 명령 출력
            then fork commandOut;
                then msgAirCmd;
                then msgFuelCmd;

            first msgAirCmd then j;
            first msgFuelCmd then j;

            // 제어 명령 하달 후 병렬로 연소 상태 및 차량 거동 피드백 수신
            join j;
            then fork feedbackIn;
                then msgFeedback;
                then msgDynamics;

            // [Verification Criterias]
            constraint <uc1_vc01> responseTimeConstraint :> validationCriteria {
                doc
                /* [VC#01] 응답 시간 (Processing Time):
                 * 가속 입력(msgAccel) 수신 완료 시점부터 공기량 제어 명령(msgAirCmd & msgFuelCmd) 하달 시작 시점까지 50ms 이내여야 함
                 */
                msgAirCmd.start - msgAccel.done <= 50.0 [milli * s] and
                msgFuelCmd.start - msgAccel.done <= 50.0 [milli * s]
            }

            constraint <uc1_vc02> :> validationCriteria {
                doc
                /* 정밀도: 
                 * 피드백되는 연소 상태의 목표 토크 오버슈트가 5.0% 이내여야 함
                 */
                msgFeedback.payload.torqueOvershoot <= 5.0
            }

            constraint <uc1_vc03> :> validationCriteria {
                doc
                /* 승차감: 
                 * 가속에 따른 종방향 가속도 변화율(Jerk)이 10.0 이하를 유지해야 함
                 */
                msgDynamics.payload.longitudinalJerk <= 10.0
            }
        }

        action UC1_Alternative_Cruise_Control_Driving {
            doc
            /* [대안 시나리오] 
             * 크루즈 시스템이 설정된 목표 속도를 유지하기 위해 자체적으로 속도 오차를 계산하고, 
             * 정밀 폐루프 제어로 토크를 자동 산출하여 구동계로 전달하는 전체 정속 주행 흐름
             */
            constraint precondition {
                doc
                /* 크루즈 컨트롤 시스템에 유효한 목표 속도가 설정 및 활성화된 상태여야 함 */
                egas.ccPort.ccCmd.setSpeed > 0.0 [km / h]
            }

            // [Messages]
            message msgCcReq of CruiseControlCommand
                from ccLever.setsCruiseSpeed to egas.commandsCruiseTorque {
                bind payload = egas.ccPort.ccCmd;
            }

            message msgAirCmd_CC of IntakeAirFlow
                from egas.commandsCruiseTorque to engine.receivesAirFlow_CC {
                bind payload = egas.airIntakePort.airFlow;
            }

            message msgFuelCmd_CC of FuelIgnitionCommand
                from egas.commandsCruiseTorque to fuelSys.injectsFuel_CC {
                bind payload = egas.fuelCmdPort.fuelCmd;
            }

            message msgFeedback_CC of CombustionSystemStatus
                from fuelSys.injectsFuel_CC to egas.commandsCruiseTorque {
                bind payload = egas.combustionStatusPort.combustionStatus;
                ref constraint <uc1_vc04>;
            }

            // [Sequence Flow]
            first msgCcReq;

            fork commandOut;
                then msgAirCmd_CC;
                then msgFuelCmd_CC;

            first msgAirCmd_CC then j;
            first msgFuelCmd_CC then j;

            join j;
            then msgFeedback_CC;

            // [Verification Criterias]
            constraint <uc1_vc04> :> validationCriteria {
                doc
                /* [VC#04] 정밀도: 
                 * 설정된 목표 속도와 실제 속도 간의 정상 상태 오차(Steady-state error)가 2.0% 이내로 정밀하게 유지되어야 함
                 */
                msgFeedback_CC.payload.steadyStateError <= 2.0
            }
        }

        action UC1_Exception_Brake_Override_Intervention {
            doc
            /* [예외 시나리오] 
             * 수동 가속 또는 크루즈 컨트롤 주행 중 운전자가 브레이크를 밟을 경우, 
             * 진행 중인 모든 가속 요구를 즉각 무효화하고 제동을 최우선으로 하여 
             * 스로틀 공기 유입량을 강제 차단하는 전체 안전 개입 흐름
             */
            constraint precondition {
                doc
                /* 주행 중 운전자의 브레이크 페달 조작이 감지되어 제동 요구가 발생한 상태여야 함 */
                egas.brakePort.brakeInput.pressure > 0.0 [Pa]
            }

            // [Messages]
            message msgBrakeInput of BrakePedalPosition
                from brake.pressesBrakePedal to egas.overridesAndCutsTorque {
                bind payload = egas.brakePort.brakeInput;
            }

            message msgAirCutCmd of IntakeAirFlow
                from egas.overridesAndCutsTorque to engine.receivesAirCut {
                bind payload = egas.airIntakePort.airFlow;
                ref constraint <uc1_vc06>;
            }

            message msgFuelCutCmd of FuelIgnitionCommand
                from egas.overridesAndCutsTorque to fuelSys.cutsFuel {
                bind payload = egas.fuelCmdPort.fuelCmd;
                ref constraint <uc1_vc07>;
            }

            // [Sequence Flow]
            first msgBrakeInput;
            fork commandOut;
                then msgAirCutCmd;
                then msgFuelCutCmd;

            // [Verification Criterias]
            constraint <uc1_vc05> overrideResponseTimeConstraint :> validationCriteria {
                doc
                /* [VC#05] 제동 최우선 개입 응답 시간: 
                 * 브레이크 입력(msgBrakeInput) 수신 즉시 진행 중인 제어를 무효화하고 
                 * 10ms 이내에 차단 명령(msgAirCutCmd & msgFuelCutCmd)이 하달되어야 함
                 */
                msgAirCutCmd.start - msgBrakeInput.done <= 10.0 [milli * s] and
                msgFuelCutCmd.start - msgBrakeInput.done <= 10.0 [milli * s]
            }

            constraint <uc1_vc06> :> validationCriteria {
                doc
                /* [VC#06] 페일세이프: 스로틀 공기 유입을 원천 차단하여 안전 확보 */
                msgAirCutCmd.payload.massFlow <= 0.0 [kg / s]
            }

            constraint <uc1_vc07> :> validationCriteria {
                doc
                /* [VC#07] 페일세이프: 연료 분사 전면 차단 */
                msgFuelCutCmd.payload.injectionPulseWidth <= 0.0 [s]
            }
        }

        // ==========================================
        // 상호작용 및 시나리오 흐름(Flow) 정의
        // ==========================================

        // 1. 주 성공 시나리오(Normal)의 입출력 상호작용
        flow from driver to UC1_Normal_Manual_Acceleration;
        flow from UC1_Normal_Manual_Acceleration to engine;
        flow from UC1_Normal_Manual_Acceleration to fuelSys;
        flow from fuelSys to UC1_Normal_Manual_Acceleration; // 연소 상태 피드백 수신

        // 2. 대안 시나리오(Alternative)의 입출력 상호작용
        flow from ccLever to UC1_Alternative_Cruise_Control_Driving;
        flow from UC1_Alternative_Cruise_Control_Driving to engine;
        flow from UC1_Alternative_Cruise_Control_Driving to fuelSys;
        flow from fuelSys to UC1_Alternative_Cruise_Control_Driving; // 연소 상태 피드백 수신

        // 3. 예외 시나리오(Exception)의 입출력 상호작용
        flow from brake to UC1_Exception_Brake_Override_Intervention;
        flow from UC1_Exception_Brake_Override_Intervention to engine; // 스로틀 강제 차단 명령
        flow from UC1_Exception_Brake_Override_Intervention to fuelSys; // 연료 차단 명령
    }

    use case def <UC2> 'Emergency Intervention' {
        doc
        /* 빙판길 미끄럼 등 긴급 상황에서 ESP/TCU의 토크 저감 요청 시, 
         * 스로틀 공기량 제어와 연료/점화 지각 제어를 병렬로 수행하여 
         * 15ms 이내에 즉각적으로 물리적 토크를 저감하는 유스케이스
         */

        subject egas : EgasSystem;

        // 입력 액터
        actor addEcu : AddEcu; // ESP, TCU 등 외부 제어기

        // 출력 액터
        actor engine : Engine;
        actor fuelSys : FuelInjectionIgnitionSystem;

        satisfy requirement 'SHR-04-1'; // reqTorqueInterventionByAirflow
        satisfy requirement 'SHR-04-2'; // reqTorqueInterventionByFuelIgnition

        // ==========================================
        // 액션(시나리오) 정의 - 각 액션이 하나의 완전한 시나리오를 대변함
        // ==========================================

        action UC2_Normal_Emergency_Torque_Reduction {
            doc
            /* [주 성공 시나리오] 
             * ESP/TCU의 긴급 토크 저감 요청을 수신하여 15ms 이내에 목표 공기량을 축소함과 동시에, 
             * 연료 인젝션 펄스 단축 및 점화 시기를 지각시켜 신속하게 토크를 저감하는 전체 정상 제어 흐름
             */
            constraint precondition {
                doc
                /* ESP/TCU 등 외부 제어기에서 미끄럼 방지 등을 위한 토크 저감 요구(음수 값)를 전달한 상태여야 함 */
                egas.torqueInterventionPort.torqueReq.requestedTorqueDelta < 0.0 [N * m]
            }

            // [Messages]
            message msgInterventionReq of TorqueInterventionRequest
                from addEcu.requestsIntervention to egas.commandsEmergencyReduction {
                bind payload = egas.torqueInterventionPort.torqueReq;
            }

            message msgEmergAirCmd of IntakeAirFlow
                from egas.commandsEmergencyReduction to engine.receivesReducedAir {
                bind payload = egas.airIntakePort.airFlow;
                ref constraint <uc2_vc02>;
            }

            message msgEmergFuelCmd of FuelIgnitionCommand
                from egas.commandsEmergencyReduction to fuelSys.executesReducedFuel {
                bind payload = egas.fuelCmdPort.fuelCmd;
                ref constraint <uc2_vc03>;
            }

            // [Sequence Flow]
            first msgInterventionReq;

            // 토크 저감 요청 수신 후, 공기량 축소와 연료 분사 단축을 15ms 이내 병렬 하달
            fork commandOut;
                then msgEmergAirCmd;
                then msgEmergFuelCmd;

            // [Verification Criterias]
            constraint <uc2_vc01> emergencyResponseTime :> validationCriteria {
                doc
                /* [VC#01] 긴급 개입 응답 시간: 
                 * 토크 저감 요청 수신 후 15ms 이내에 공기량 및 연료 제어 명령이 병렬 하달되어야 함
                 */
                msgEmergAirCmd.start - msgInterventionReq.done <= 15.0 [milli * s] and
                msgEmergFuelCmd.start - msgInterventionReq.done <= 15.0 [milli * s]
            }

            constraint <uc2_vc02> :> validationCriteria {
                doc
                /* 공기량 즉각 축소: 직전 주기보다 물리적 공기량이 작아야 함 */
                msgEmergAirCmd.payload.massFlow < msgEmergAirCmd.payload.previousMassFlow
            }

            constraint <uc2_vc03> :> validationCriteria {
                doc
                /* 연료량 즉각 축소: 직전 주기보다 인젝션 펄스가 짧아야 함 */
                msgEmergFuelCmd.payload.injectionPulseWidth <
                msgEmergFuelCmd.payload.previousPulseWidth
            }
        }

        action UC2_Alternative_Communication_Delay_Compensation {
            doc
            /* [대안 시나리오] 
             * 외부 제어기와의 통신 지연으로 일시적인 토크 저감 신호 누락 발생 시, 
             * 타임아웃 전까지 직전의 유효한 토크 저감 요구값을 기반으로 자체 보상 제어를 유지하는 흐름
             */

            constraint precondition {
                doc
                /* 외부 제어기와의 통신 지연 또는 노이즈로 인해 토크 저감 요청 신호의 수신 지연이 15ms를 초과한 상태여야 함 */
                egas.torqueInterventionPort.torqueReq.latency > 15.0 [milli * s]
            }

            // [Messages]
            message msgInterventionReq_Delay of TorqueInterventionRequest
                from addEcu.requestsIntervention_Delayed to egas.compensatesCommDelay {
                bind payload = egas.torqueInterventionPort.torqueReq;
            }

            message msgMaintainAirCmd of IntakeAirFlow
                from egas.compensatesCommDelay to engine.receivesMaintainedAir {
                bind payload = egas.airIntakePort.airFlow;
                ref constraint <uc2_vc04>;
            }

            message msgMaintainFuelCmd of FuelIgnitionCommand
                from egas.compensatesCommDelay to fuelSys.executesMaintainedFuel {
                bind payload = egas.fuelCmdPort.fuelCmd;
                ref constraint <uc2_vc05>;
            }

            // [Sequence Flow]
            first msgInterventionReq_Delay;
            fork commandOut;
                then msgMaintainAirCmd;
                then msgMaintainFuelCmd;

            // [Verification Criterias]
            constraint <uc2_vc04> :> validationCriteria {
                doc
                /* 공기량 동결: 통신 지연 시 직전 주기의 공기량을 그대로 유지 */
                msgMaintainAirCmd.payload.massFlow == msgMaintainAirCmd.payload.previousMassFlow
            }

            constraint <uc2_vc05> :> validationCriteria {
                doc
                /* 연료량 동결: 통신 지연 시 직전 주기의 연료량을 그대로 유지 */
                msgMaintainFuelCmd.payload.injectionPulseWidth ==
                msgMaintainFuelCmd.payload.previousPulseWidth
            }
        }

        action UC2_Exception_Actuator_Stuck_Fuel_Cut {
            doc
            /* [예외 시나리오] 
             * 긴급 개입 중 스로틀 밸브 고착(Stuck) 등 하드웨어 오류로 공기량 축소가 불가능함이 감지될 경우, 
             * 즉시 공기량 제어 시도를 포기하고 엔진 보호를 위해 연료 시스템을 전면 차단(Fuel Cut)하는 흐름
             */
            constraint precondition {
                doc
                /* 긴급 개입 시도에도 불구하고 스로틀 공기량이 줄어들지 않아 밸브 고착(Stuck)이 강력히 의심되는 상태여야 함 */
                egas.airIntakePort.airFlow.massFlow >= egas.airIntakePort.airFlow.previousMassFlow
            }

            // [Messages]
            message msgInterventionReq_Stuck of TorqueInterventionRequest
                from addEcu.requestsIntervention_Stuck to egas.commandsEmergencyFuelCut {
                bind payload = egas.torqueInterventionPort.torqueReq;
            }

            message msgFuelCutCmd of FuelIgnitionCommand
                from egas.commandsEmergencyFuelCut to fuelSys.executesFuelCut {
                bind payload = egas.fuelCmdPort.fuelCmd;
                ref constraint <uc2_vc07>;
            }

            // [Sequence Flow]
            first msgInterventionReq_Stuck;

            // 공기량 제어가 불가능하므로, 연료 시스템으로만 차단 명령을 즉시 하달
            then msgFuelCutCmd;

            // [Verification Criterias]
            constraint <uc2_vc06> stuckResponseTime :> validationCriteria {
                doc
                /* 고착 감지 후 연료 차단 명령까지 10ms 이내 보장 */
                msgFuelCutCmd.start - msgInterventionReq_Stuck.done <= 10.0 [milli * s]
            }

            constraint <uc2_vc07> :> validationCriteria {
                doc
                /* 페일세이프: 엔진 보호를 위한 연료 전면 차단 */
                msgFuelCutCmd.payload.injectionPulseWidth <= 0.0 [s]
            }
        }

        // ==========================================
        // 상호작용 및 시나리오 흐름(Flow) 정의
        // ==========================================

        // 1. 주 성공 시나리오(Normal)의 입출력 상호작용
        flow from addEcu to UC2_Normal_Emergency_Torque_Reduction;
        flow from UC2_Normal_Emergency_Torque_Reduction to engine;
        flow from UC2_Normal_Emergency_Torque_Reduction to fuelSys;

        // 2. 대안 시나리오(Alternative)의 입출력 상호작용
        flow from addEcu to UC2_Alternative_Communication_Delay_Compensation;
        flow from UC2_Alternative_Communication_Delay_Compensation to engine;
        flow from UC2_Alternative_Communication_Delay_Compensation to fuelSys;

        // 3. 예외 시나리오(Exception)의 입출력 상호작용 (스로틀 제어를 포기하므로 engine으로의 flow 생략)
        flow from addEcu to UC2_Exception_Actuator_Stuck_Fuel_Cut;
        flow from UC2_Exception_Actuator_Stuck_Fuel_Cut to fuelSys;
    }

    use case def <UC3> 'Hardware Fail-safe' {
        doc
        /* 이중화 센서 데이터를 실시간으로 모니터링하여 하드웨어 결함(온도 초과 등) 발생 시 즉각적인 페일세이프를 수행하고, 
         * 정상 작동 중에는 하드웨어 마찰 및 지연을 보정하여 실화를 방지하는 유스케이스
         */

        subject egas : EgasSystem;

        // 입력 액터
        actor sensors : AddSensorComponents;

        // 출력 및 피드백 액터
        actor engine : Engine;
        actor fuelSys : FuelInjectionIgnitionSystem;

        satisfy requirement 'SHR-03'; // reqFailSafeSensorMonitoring
        satisfy requirement 'SHR-02-2'; // reqMisfirePrevention

        // ==========================================
        // 액션(시나리오) 정의 - 각 액션이 하나의 완전한 시나리오를 대변함
        // ==========================================

        action UC3_Normal_Hardware_Delay_Compensation {
            doc
            /* [주 성공 시나리오] 
             * 양산 부품의 물리적 한계(마찰, 응답 지연 등)를 시스템이 실시간으로 자체 보정하여, 
             * 제어 명령 산출 후 액추에이터 지연을 10ms 이내로 통제하고 엔진 실화를 0Hz로 유지하는 전체 보정 제어 흐름
             */

            constraint precondition {
                doc
                /* 엔진 냉각수 온도가 120도 이하로, 시스템이 정상 구동 가능한 물리적 안전 한계 내에 있는 상태여야 함 */
                egas.sensorPort.sensorData.coolantTemp <= 120.0 ['°']
            }

            // [Messages]
            message msgNormalData of EngineSensorData
                from sensors.sendsNormalSensorData to egas.compensatesDelayAndFriction {
                bind payload = egas.sensorPort.sensorData;
            }

            message msgCompensatedAirCmd of IntakeAirFlow
                from egas.compensatesDelayAndFriction to engine.receivesCompensatedAir {
                bind payload = egas.airIntakePort.airFlow;
            }

            message msgCompensatedFuelCmd of FuelIgnitionCommand
                from egas.compensatesDelayAndFriction to fuelSys.executesCompensatedFuel {
                bind payload = egas.fuelCmdPort.fuelCmd;
                ref constraint <uc3_vc1>;
            }

            message msgCombustionFeedback of CombustionSystemStatus
                from fuelSys.sendsCombustionFeedback to egas.compensatesDelayAndFriction {
                bind payload = egas.combustionStatusPort.combustionStatus;
                ref constraint <uc3_vc2>;
            }

            // [Sequence Flow]
            first msgNormalData;

            // 정상 센서 데이터 수신 후 보정된 공기/연료 제어 명령을 병렬 하달
            fork commandOut;
                then msgCompensatedAirCmd;
                then msgCompensatedFuelCmd;
            first msgCompensatedAirCmd then j;
            first msgCompensatedFuelCmd then j;

            // 명령 수행 후 실화율 등 연소 상태 피드백 수신
            join j;
            then msgCombustionFeedback;

            // [Verification Criterias]
            constraint <uc3_vc1> :> validationCriteria {
                doc
                /* [VC#15] 응답 지연 통제: 
                 * 보정 제어가 적용된 액추에이터 지연 시간(Actuator Latency)이 10ms 이내여야 함
                 */
                msgCompensatedFuelCmd.payload.actuatorLatency <= 10.0 [milli * s]
            }

            constraint <uc3_vc2> :> validationCriteria {
                doc
                /* [VC#16] 실화 방지: 
                 * 피드백되는 연소 상태에서 엔진 실화(Misfire Rate)가 완벽히 억제(0Hz)되어야 함
                 */
                msgCombustionFeedback.payload.misfireRate <= 0.0 [Hz]
            }
        }

        action UC3_Exception_Critical_Sensor_Fault_FailSafe {
            doc
            /* [예외 시나리오] 
             * 엔진 냉각수 온도가 120도를 초과하는 등 이중화 센서에 치명적 결함값이 입력될 경우, 
             * 급발진 및 엔진 파손을 막기 위해 즉각 공기 유입을 차단하고 연료 제어를 전면 중단하는 전체 페일세이프 흐름
             */
            constraint precondition {
                doc
                /* 엔진 냉각수 온도가 120도를 초과하는 등, 치명적인 시스템 파손이나 제어 불능이 우려되는 하드웨어 결함이 감지된 상태여야 함 */
                egas.sensorPort.sensorData.coolantTemp > 120.0 ['°']
            }

            // [Messages]
            message msgFaultyData of EngineSensorData
                from sensors.sendsFaultyData to egas.triggersEmergencyFailSafe {
                bind payload = egas.sensorPort.sensorData;
            }

            message msgAirCutCmd of IntakeAirFlow
                from egas.triggersEmergencyFailSafe to engine.receivesAirCut {
                bind payload = egas.airIntakePort.airFlow;
                ref constraint <uc3_vc3>;
            }

            message msgFuelCutCmd of FuelIgnitionCommand
                from egas.triggersEmergencyFailSafe to fuelSys.executesFuelCut {
                bind payload = egas.fuelCmdPort.fuelCmd;
                ref constraint <uc3_vc4>;
            }

            // [Sequence Flow]
            first msgFaultyData;

            // 결함 센서 데이터 수신 즉시 스로틀 공기량 차단과 연료 분사 차단 명령을 병렬 하달
            fork commandOut;
                then msgAirCutCmd;
                then msgFuelCutCmd;

            // [Verification Criterias]
            constraint <uc3_vc3> :> validationCriteria {
                doc
                /* [VC#17] 페일세이프: 엔진 파손 및 급발진 방지를 위한 스로틀 공기 유입 원천 차단 */
                msgAirCutCmd.payload.massFlow <= 0.0 [kg / s]
            }

            constraint <uc3_vc4> :> validationCriteria {
                doc
                /* [VC#18] 페일세이프: 시스템 보호를 위한 연료 분사 전면 차단 */
                msgFuelCutCmd.payload.injectionPulseWidth <= 0.0 [s]
            }

            constraint <uc3_vc5> failSafeResponseTime :> validationCriteria {
                doc
                /* [VC#19] 페일세이프 응답 시간: 
                 * 치명적 결함 데이터(msgFaultyData) 감지 즉시 10ms 이내에 차단 명령이 병렬 하달되어야 함
                 */
                msgAirCutCmd.start - msgFaultyData.done <= 10.0 [milli * s] and
                msgFuelCutCmd.start - msgFaultyData.done <= 10.0 [milli * s]
            }
        }

        // ==========================================
        // 상호작용 및 시나리오 흐름(Flow) 정의
        // ==========================================

        // 1. 주 성공 시나리오(Normal)의 입출력 상호작용
        flow from sensors to UC3_Normal_Hardware_Delay_Compensation;
        flow from fuelSys to UC3_Normal_Hardware_Delay_Compensation; // 연소 상태(실화율) 및 액추에이터 응답 지연 피드백 수신
        flow from UC3_Normal_Hardware_Delay_Compensation to engine; // 보정 반영된 목표 공기량 전달
        flow from UC3_Normal_Hardware_Delay_Compensation to fuelSys; // 보정 반영된 연료/점화 명령 전달

        // 2. 예외 시나리오(Exception)의 입출력 상호작용
        flow from sensors to UC3_Exception_Critical_Sensor_Fault_FailSafe; // 결함 센서 데이터 감지
        flow from UC3_Exception_Critical_Sensor_Fault_FailSafe to engine; // 즉각적인 공기 유입 차단 명령 전달
        flow from UC3_Exception_Critical_Sensor_Fault_FailSafe to fuelSys; // 즉각적인 연료 차단(Fuel Cut) 명령 전달
    }

    use case def <UC4> 'Powertrain Calibration' {
        doc
        /* 엔진 성능 및 배출가스 최적화를 위해 외부 캘리브레이션 툴의 유효한 메모리 접근을 허가하고, 
         * 튜닝 데이터 업데이트 시 무결성을 검증하여 오염된 데이터로 인한 오작동을 차단하는 유스케이스
         */

        subject egas : EgasSystem;

        // 입출력 액터
        actor calTool : CalibrationTool; // 캘리브레이션 엔지니어 장비

        satisfy requirement 'SHR-05-1'; // reqCalibrationMemoryAccess
        satisfy requirement 'SHR-05-2'; // reqCalibrationDataIntegrity

        // ==========================================
        // 액션(시나리오) 정의 - 각 액션이 하나의 완전한 시나리오를 대변함
        // ==========================================

        action UC4_Normal_Memory_Access_Authorization {
            doc
            /* [주 성공 시나리오 1: 메모리 접근 인가] 
             * 캘리브레이션 툴이 유효한 메모리 주소로 맵 데이터 접근을 요청 시, 
             * 제어기가 정상 상태 코드(200)를 반환하여 통신 세션 및 접근을 허용하는 전체 흐름
             */
            constraint precondition {
                doc
                /* 캘리브레이션 툴이 접근을 요청한 대상 메모리 주소가 0보다 큰 유효한 내부 영역인 상태여야 함 */
                egas.calibrationPort.calReq.targetMemoryAddress > 0
            }

            // [Messages]
            message msgAccessReq of CalibrationRequest
                from calTool.requestsValidAccess to egas.authorizesAccess {
                bind payload = egas.calibrationPort.calReq;
            }

            message msgAccessRes of CalibrationStatus
                from egas.authorizesAccess to calTool.receivesAuthOk {
                bind payload = egas.calibrationPort.calStatus;
                ref constraint <uc4_vc1>;
            }

            // [Sequence Flow]
            first msgAccessReq;

            // 캘리브레이션 툴의 접근 요청 수신 후 정상 상태 코드(200) 반환
            then msgAccessRes;

            // [Verification Criterias]
            constraint <uc4_vc1> :> validationCriteria {
                doc
                /* 인가 응답: 유효한 접근 요청에 대해 정상 상태 코드(200)를 반환 */
                msgAccessRes.payload.responseCode == 200
            }

            constraint <uc4_vc2> authResponseTime :> validationCriteria {
                doc
                /* 통신 응답 시간: 
                 * 메모리 접근 요청(msgAccessReq) 수신 후 50ms 이내에 인가 상태 코드(msgAccessRes)를 반환해야 함
                 */
                msgAccessRes.start - msgAccessReq.done <= 50.0 [milli * s]
            }
        }

        action UC4_Normal_Data_Integrity_Verification {
            doc
            /* [주 성공 시나리오 2: 맵 데이터 무결성 검증] 
             * 파라미터 튜닝 데이터가 제어기에 기록된 직후, 시스템이 자체 검증 로직을 수행하여 
             * 유효한 메모리 체크섬을 툴로 반환하고 안전하게 업데이트를 확정하는 전체 흐름
             */
            constraint precondition {
                doc
                /* 유효한 메모리 주소에 새로운 튜닝 파라미터 데이터 기록이 수행된 직후의 상태여야 함 */
                egas.calibrationPort.calReq.targetMemoryAddress > 0
            }

            // [Messages]
            message msgWriteDataReq of CalibrationRequest
                from calTool.sendsTuningData to egas.verifiesAndCommitsData {
                bind payload = egas.calibrationPort.calReq;
            }
            message msgChecksumRes of CalibrationStatus
                from egas.verifiesAndCommitsData to calTool.receivesVerifiedChecksum {
                bind payload = egas.calibrationPort.calStatus;
                ref constraint <uc4_vc3>;
            }

            // [Sequence Flow]
            first msgWriteDataReq;

            // 튜닝 데이터 수신 및 자체 검증 완료 후 유효한 체크섬 반환
            then msgChecksumRes;

            // [Verification Criterias]
            constraint <uc4_vc3> :> validationCriteria {
                doc
                /* 무결성 검증: 자체 검증 로직 통과 시 0보다 큰 유효한 체크섬(Checksum) 반환 */
                msgChecksumRes.payload.verifiedChecksum > 0
            }

            constraint <uc4_vc4> verificationResponseTime :> validationCriteria {
                doc
                /* 무결성 검증 응답 시간: 
                 * 데이터 기록 요청(msgWriteDataReq) 수신 후 검증 연산을 거쳐 100ms 이내에 체크섬(msgChecksumRes)을 반환해야 함
                 */
                msgChecksumRes.start - msgWriteDataReq.done <= 100.0 [milli * s]
            }
        }

        action UC4_Exception_Invalid_Access_Or_Verification_Failure {
            doc
            /* [예외 시나리오] 
             * 유효하지 않은 메모리 주소로 접근하거나, 데이터 기록 후 체크섬 검증에 실패할 경우, 
             * 통신 에러 응답을 반환하고 업데이트된 데이터를 롤백하여 엔진 오작동을 차단하는 흐름
             */
            constraint precondition {
                doc
                /* 캘리브레이션 툴이 0 이하의 잘못된 메모리 주소로 접근을 시도하거나 보호 구역을 침범한 상태여야 함 */
                egas.calibrationPort.calReq.targetMemoryAddress <= 0
            }

            // [Messages]
            message msgInvalidReq of CalibrationRequest
                from calTool.requestsInvalidAccess to egas.rejectsAndRollsBack {
                bind payload = egas.calibrationPort.calReq;
            }

            message msgErrorRes of CalibrationStatus
                from egas.rejectsAndRollsBack to calTool.receivesErrorResponse {
                bind payload = egas.calibrationPort.calStatus;
                ref constraint <uc4_vc5>;
            }

            // [Sequence Flow]
            first msgInvalidReq;

            // 비유효한 요청 수신 즉시 에러 응답 및 기록 거부/롤백 처리
            then msgErrorRes;

            // [Verification Criterias]
            constraint <uc4_vc5> :> validationCriteria {
                doc
                /* 예외 방어: 비정상적 접근이므로 상태 코드 200 이외의 에러 코드를 반환하여 데이터 기록을 차단 */
                msgErrorRes.payload.responseCode != 200
            }

            constraint <uc4_vc6> rejectionResponseTime :> validationCriteria {
                doc
                /* 보안/거절 응답 시간: 
                 * 잘못된 메모리 접근 요청에 대해 시스템 보호를 위해 10ms 이내에 즉각 통신을 거절해야 함
                 */
                msgErrorRes.start - msgInvalidReq.done <= 10.0 [milli * s]
            }
        }

        // ==========================================
        // 상호작용 및 시나리오 흐름(Flow) 정의
        // ==========================================

        // 1. 주 성공 시나리오 1 (메모리 접근 인가)의 입출력 상호작용
        flow from calTool to UC4_Normal_Memory_Access_Authorization; // 메모리 접근 요청
        flow from UC4_Normal_Memory_Access_Authorization to calTool; // 200 응답 반환

        // 2. 주 성공 시나리오 2 (무결성 검증)의 입출력 상호작용
        flow from calTool to UC4_Normal_Data_Integrity_Verification; // 튜닝 데이터(mapDataPayload) 전송
        flow from UC4_Normal_Data_Integrity_Verification to calTool; // 검증된 체크섬 및 업데이트 완료 반환

        // 3. 예외 시나리오 (접근 거부 및 검증 실패)의 입출력 상호작용
        flow from calTool to UC4_Exception_Invalid_Access_Or_Verification_Failure;
        flow from UC4_Exception_Invalid_Access_Or_Verification_Failure to calTool; // 에러 코드 및 롤백 알림 반환
    }

    use case def <UC5> 'Diagnostics & Maintenance' {
        doc
        /* 시스템 결함 시 명확한 고장 진단 코드(DTC)를 제공하고, 
         * 부품 교체 후 용이한 영점 조정 프로세스를 지원하여 
         * A/S 정비사의 수리 시간 단축 및 유지보수 편의성을 보장하는 유스케이스
         */

        subject egas : EgasSystem;

        // 입출력 액터
        actor diagTool : DiagnosticTool; // 서비스 센터 A/S 정비사 진단기
        actor sensors : AddSensorComponents; // 물리적 결함 상태 제공(입력)

        satisfy requirement 'SHR-06'; // reqDiagnosticAndMaintenanceSupport

        // ==========================================
        // 액션(시나리오) 정의 - 각 액션이 하나의 완전한 시나리오를 대변함
        // ==========================================

        action UC5_Normal_Read_DTC_Scenario {
            doc
            /* [주 성공 시나리오 1: 고장 코드 조회] 
             * 냉각수 120도 초과 등 센서 결함 상태에서 진단기의 DTC 조회 요청(serviceId == 1) 수신 시, 
             * 제어기가 정상 응답(200)과 함께 유효한 고장 코드(DTC)를 즉시 반환하는 전체 진단 흐름
             */
            constraint precondition {
                doc
                /* 외부 진단기가 고장 진단 코드(DTC) 조회를 의미하는 서비스 ID(1)를 전송한 상태여야 함 */
                egas.diagPort.diagReq.serviceId == 1
            }

            // [Messages]
            message msgSensorFault of EngineSensorData
                from sensors.sendsFaultyData to egas.registersSensorFault {
                bind payload = egas.sensorPort.sensorData;
            }
            message msgDtcReq of DiagnosticRequest
                from diagTool.requestsDtcRead to egas.processesDtcRequest {
                bind payload = egas.diagPort.diagReq;
            }
            message msgDtcRes of DiagnosticStatus
                from egas.processesDtcRequest to diagTool.receivesDtcResponse {
                bind payload = egas.diagPort.diagStatus;
                ref constraint <uc5_vc1>;
            }
            // [Sequence Flow]
            first msgSensorFault;

            // 결함이 기록된 상태에서 진단기의 DTC 조회 요청 수신 후 유효한 고장 코드 반환
            then msgDtcReq;
            then msgDtcRes;

            // [Verification Criterias]
            constraint <uc5_vc1> :> validationCriteria {
                doc
                /* 유효 고장 코드 반환: 
                 * 통신 정상 응답 코드(200)와 함께 시스템 내부에 기록된 실제 유효 고장 코드(DTC > 0) 값을 반환해야 함
                 */
                msgDtcRes.payload.responseCode == 200 and msgDtcRes.payload.dtcCode > 0
            }

            constraint <uc5_vc2> dtcResponseTime :> validationCriteria {
                doc
                /* 진단 응답 시간: 진단기의 조회 요청 수신 후 50ms 이내에 DTC 응답을 반환해야 함 */
                msgDtcRes.start - msgDtcReq.done <= 50.0 [milli * s]
            }
        }

        action UC5_Normal_Zero_Point_Calibration_Scenario {
            doc
            /* [주 성공 시나리오 2: 부품 영점 조정] 
             * 부품 교체 후 정비사가 진단기를 통해 영점 조정(serviceId == 2)을 요청 시, 
             * 제어기가 별도의 추가 프로그래밍 작업 없이 완료 응답(200)을 반환하여 수리 절차를 마무리하는 전체 흐름
             */
            constraint precondition {
                doc
                /* 하드웨어 부품 교체 후 진단기가 영점 조정 루틴 실행을 의미하는 서비스 ID(2)를 전송한 상태여야 함 */
                egas.diagPort.diagReq.serviceId == 2
            }

            // [Messages]
            message msgZeroPointReq of DiagnosticRequest
                from diagTool.requestsZeroPointCal to egas.processesZeroPointCal {
                bind payload = egas.diagPort.diagReq;
            }
            message msgZeroPointRes of DiagnosticStatus
                from egas.processesZeroPointCal to diagTool.receivesZeroPointResponse {
                bind payload = egas.diagPort.diagStatus;
                ref constraint <uc5_vc3>;
            }

            // [Sequence Flow]
            first msgZeroPointReq;

            // 영점 조정 요청 수신 후, 추가 개입 없이 성공 상태 코드(200) 반환
            then msgZeroPointRes;

            // [Verification Criterias]
            constraint <uc5_vc3> :> validationCriteria {
                doc
                /* 영점 조정 완료: 성공적인 영점 조정 후 정상 상태 코드(200) 반환 */
                msgZeroPointRes.payload.responseCode == 200
            }

            constraint <uc5_vc4> zeroPointResponseTime :> validationCriteria {
                doc
                /* 영점 조정 처리 시간: 영점 조정 요청 수신 후 보정 연산을 거쳐 100ms 이내에 완료 응답을 반환해야 함 */
                msgZeroPointRes.start - msgZeroPointReq.done <= 100.0 [milli * s]
            }
        }

        action UC5_Exception_Invalid_Diagnostic_Request {
            doc
            /* [예외 시나리오] 
             * 지원하지 않는 serviceId가 요청되거나, 물리적 결함이 없는데 DTC를 요구하는 등 유효하지 않은 요청 시, 
             * 에러 응답(Negative Response)을 반환하고 통신을 종료하는 흐름
             */
            constraint precondition {
                doc
                /* 진단기에서 시스템이 정의하거나 지원하지 않는 잘못된 서비스 ID를 전송한 상태여야 함 */
                egas.diagPort.diagReq.serviceId != 1 and egas.diagPort.diagReq.serviceId != 2
            }

            // [Messages]
            message msgInvalidReq of DiagnosticRequest
                from diagTool.requestsInvalidService to egas.rejectsInvalidRequest {
                bind payload = egas.diagPort.diagReq;
            }

            message msgErrorRes of DiagnosticStatus
                from egas.rejectsInvalidRequest to diagTool.receivesErrorResponse {
                bind payload = egas.diagPort.diagStatus;

                ref constraint <uc5_vc5>;
            }

            // [Sequence Flow]
            first msgInvalidReq;

            // 미지원 서비스 ID 요청 시 에러 응답(Negative Response) 반환
            then msgErrorRes;

            // [Verification Criterias]
            constraint <uc5_vc5> :> validationCriteria {
                doc
                /* 에러 응답: 처리할 수 없는 요청에 대해 에러 상태 코드를 반환하여 방어 (Negative Response) */
                msgErrorRes.payload.responseCode != 200
            }

            constraint <uc5_vc6> errorResponseTime :> validationCriteria {
                doc
                /* 거절 응답 시간: 잘못된 진단 서비스 요청에 대해 10ms 이내에 즉각 통신 거절 응답을 반환해야 함 */
                msgErrorRes.start - msgInvalidReq.done <= 10.0 [milli * s]
            }
        }

        // ==========================================
        // 상호작용 및 시나리오 흐름(Flow) 정의
        // ==========================================

        // 1. 주 성공 시나리오 1 (DTC 조회)의 입출력 상호작용
        flow from sensors to UC5_Normal_Read_DTC_Scenario; // 센서로부터 물리적 결함(온도 초과 등) 감지
        flow from diagTool to UC5_Normal_Read_DTC_Scenario; // 진단기의 DTC 읽기 요청 수신
        flow from UC5_Normal_Read_DTC_Scenario to diagTool; // 유효한 DTC 코드 및 200 응답 반환

        // 2. 주 성공 시나리오 2 (영점 조정)의 입출력 상호작용
        flow from diagTool to UC5_Normal_Zero_Point_Calibration_Scenario; // 진단기의 영점 조정 요청 수신
        flow from UC5_Normal_Zero_Point_Calibration_Scenario to diagTool; // 영점 조정 완료 및 200 응답 반환

        // 3. 예외 시나리오 (잘못된 요청)의 입출력 상호작용
        flow from diagTool to UC5_Exception_Invalid_Diagnostic_Request;
        flow from UC5_Exception_Invalid_Diagnostic_Request to diagTool; // 거부/에러 응답 반환
    }
} // package EgasUseCases
