package ReqCommon {
    private import ScalarValues::*;

    doc
    /* Shared enums and CM metadata for consistency across the Requirements Viewpoint. */

    @MetaInformation {
        version = "v0.1";
    }

    // 0. CM Metadata
    metadata def MetaInformation {
        doc
        /* CM metadata for version tracking. */
        attribute version : String; // Version string
        attribute updatedBy : ProjectMember [0..1]; // Last updater
        attribute changeNote : String [0..1]; // Change summary
    }

    // 1. Project & Priority
    enum def ProjectMember {
        doc
        /* Requirement authors/owners. */
        suhoChu;
    }

    enum def PriorityLevel {
        doc
        /* Business value/urgency. */
        enum High;
        enum Medium;
        enum Low;
    }

    enum def CriticalityLevel {
        doc
        /* 요구사항 미충족 시 시스템 안전/기능에 미치는 영향의 치명도
         * [M6] 하위 요구(SYSR)의 치명도는 traceToParent 상위 SHR의 최대 치명도를 넘을 수 없다.
         * 상향이 필요하면 상위 SHR의 치명도를 올리거나, 하위 요구 본문에 "상향 근거"를 명시한다.
         */
        enum Critical; // System failure/safety hazard
        enum Major; // Major degradation
        enum Minor; // Minor degradation/workaround
        enum Negligible; // No impact
    }

    // 2. Quality & Validation
    enum def ReqVerificationStatus {
        doc
        /* 요구사항 "문장" 자체가 표준 구문/작성 규칙을 잘 따르는지에 대한 검증 상태 (Need/Requirement Verification)
         * [M6] 요구 문장이나 제약식이 수정되면 InReview 이하로 되돌린다.
         */
        enum Draft;
        enum InReview;
        enum Verified;
        enum Rejected;
    }

    enum def ReqValidationStatus {
        doc
        /* 요구사항이 이해관계자의 실제 니즈를 올바르게 대변하는지에 대한 유효성 확인 상태 (Need/Requirement Validation)
         * [M6] 승격 순서는 Draft < InReview < Validated. 하위 요구(SYSR)의 상태는 traceToParent 상위 SHR의
         * 최저 상태를 넘을 수 없다. 상위가 승인된 뒤에만 하위를 승격한다.
         */
        enum Draft;
        enum InReview;
        enum Validated;
        enum Rejected;
    }

    enum def VVMethod {
        doc
        /* V&V methodologies. */
        enum Test;
        enum Analysis;
        enum Inspection;
        enum Demonstration;
        enum Audit;
    }

    // 3. Goal Refinement & Relations
    enum def RefinementKind {
        doc
        /* Goal breakdown logic. */
        enum AND; // All required
        enum OR; // Any required
    }

    metadata def GoalRefinement {
        doc
        /* Metadata for AND/OR goal decomposition. */
        attribute kind : RefinementKind;
        attribute rationale : String [0..1];
        attribute formula : String [0..1]; // 하위 목표의 논리 결합식. 예: "(SHR-04-1 AND SHR-04-2) OR SHR-04-3"
    }

    enum def ContributionPolarity {
        doc
        /* Impact direction between goals. */
        enum Positive; // Supports (+)
        enum Negative; // Conflicts (-)
    }

    metadata def GoalRelationship {
        doc
        /* Metadata for goal contributions/conflicts. */
        attribute relatedGoal : String;
        attribute polarity : ContributionPolarity;
        attribute rationale : String;
    }

    // 4. Interface Enums
    enum def IgnitionStatusEnum {
        enum Off;
        enum On;
        enum Start;
    }

    // 5. Constraints
    metadata def PlantObservation {
        doc
        /* Closed-loop plant observation constraints, used for testing criteria rather than direct EGAS control. */
    }

    enum def DashboardWarningStatusEnum {
        enum Normal; // Off
        enum Warning; // General warning
        enum Critical; // Failsafe triggered
    }

    enum def InterventionTypeEnum {
        doc
        /* 외부 제어기의 토크 개입 요청 유형.
         * Relative: requestedTorqueDelta를 운전자/기준 요구 대비 상대 증감량으로 해석한다 (음수 저감, 0 이상 해제). 현재 지원하는 유일한 유형.
         * Absolute: 예약 (절대 토크 한계). 미지원이며 지원할 때 requestedTorqueDelta와 별도 필드가 필요하다.
         */
        enum Absolute; // Absolute torque limit
        enum Relative; // Relative torque reduction
    }

    enum def SafeStateLevel {
        doc
        /* 안전 상태 단계. 단계별 출력 조건은 RV_InterfaceModel의 IsTorqueLimited / IsFuelCutOff / IsFullCutOff가 단일 출처이다. */
        enum TorqueLimited; // L1: 공기/연료를 공회전 수준 이하로 제한 (엔진 유지)
        enum FuelCutOff; // L2: 연료/점화 차단 (공기 경로는 제어 불능일 수 있음)
        enum FullCutOff; // L3: 공기/연료 전면 차단
    }

    enum def FaultCause {
        doc
        /* 확정된 치명 고장의 원인. NoFault이면 정상. */
        enum NoFault;
        enum PedalSensorDeviation; // 가속 페달 센서 PVS1/PVS2 편차 (SYSR-02)
        enum ThrottleSensorDeviation; // 스로틀 위치 센서 TPS1/TPS2 편차 (SYSR-06)
        enum Overheat; // 엔진 냉각수 과열 (SHR-09)
    }

    enum def CruiseControlRequestEnum {
        doc
        /* 운전자가 크루즈 레버로 EGAS에 내리는 요청 (순간 명령). 크루즈의 현재 상태가 아니다. */
        enum None; // 요청 없음 (레버 중립)
        enum Set; // 지정한 속도로 설정하고 활성화
        enum Resume; // 기억된 설정 속도로 복귀
        enum Cancel; // 일시 해제 (설정 속도는 기억)
        enum Off; // 크루즈 스위치 OFF (설정 속도 삭제)
    }

    enum def CruiseControlStateEnum {
        doc
        /* EGAS 내부의 크루즈 상태. 레버 입력이 아니라 EGAS 상태머신이 관리한다 (SYSR-23). */
        enum Off; // 설정 속도 없음
        enum Active; // 설정 속도를 유지 제어 중
        enum Suspended; // 설정 속도는 기억하되 제어하지 않음 (제동/가속 페달/Cancel 이후, Resume 대기)
    }

    enum def CalibrationOperationEnum {
        doc
        /* 캘리브레이션 접근 유형 */
        enum Read; // 메모리 읽기 (정차 여부와 무관)
        enum Write; // 메모리 쓰기 (정차 중에만 허용, 체크섬으로 무결성 검증)
    }

    enum def ZeroPointRoutineEnum {
        doc
        /* UDS RoutineControl(영점 조정)의 대상 센서 */
        enum PedalSensor;
        enum ThrottleSensor;
    }

    enum def InterventionSourceEnum {
        doc
        /* 토크 개입 요청의 송신원. 정책: 먼저 시작한 송신원만 활성이며 해제도 그 송신원만 할 수 있다. */
        enum ESP;
        enum TCU;
    }
} // package ReqCommon
