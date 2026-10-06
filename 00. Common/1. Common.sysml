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
        /* Impact on safety/functionality if unmet. */
        enum Critical; // System failure/safety hazard
        enum Major; // Major degradation
        enum Minor; // Minor degradation/workaround
        enum Negligible; // No impact
    }

    // 2. Quality & Validation
    enum def ReqVerificationStatus {
        doc
        /* Syntax/rule verification status. */
        enum Draft;
        enum InReview;
        enum Verified;
        enum Rejected;
    }

    enum def ReqValidationStatus {
        doc
        /* Stakeholder need validation status. */
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
} // package ReqCommon
